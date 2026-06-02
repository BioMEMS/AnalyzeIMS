import torch
from einops.layers.torch import Rearrange
import torch.nn as nn
import torch
import numpy as np
import torch.nn.functional as F
from torch import nn, optim
from torch import Tensor
from torch.utils.data import DataLoader, TensorDataset
from einops import rearrange, repeat
from einops.layers.torch import Rearrange
from pathlib import Path
import os
from torchvision.transforms import v2
import pandas as pd
import matplotlib.pyplot as plt
import scipy
from pybaselines import Baseline2D
from pybaselines import Baseline
from torchinfo import summary
import time



contrast_transforms = v2.Compose([v2.RandomResizedCrop(size=(800,80), scale=(0.9,0.9)),
                                          #transforms.RandomApply([
                                          v2.ColorJitter(brightness=0.5, contrast=0.5,),
                                          #                           saturation=0.5,
                                          #                           hue=0.1)
                                          #], p=0.8),
                                          #transforms.RandomGrayscale(p=0.2),
                                          v2.GaussianBlur(kernel_size=9),
                                          #transforms.ToTensor(),
                                          v2.RandomEqualize(p=1.0)
                                         ])
image_transforms = v2.Compose([v2.Normalize(mean=[0.76], std=[1.73])])
IMAGE_NORM_MEAN = 14.33
IMAGE_NORM_STD = 6.87

# Occupancy thresholding settings
OCCUPANCY_NONZERO_EPS = 3 # values with abs(x) > eps count as nonzero
OCCUPANCY_ROW_THRESH = 0.05   # min proportion of nonzeros in a row
OCCUPANCY_COL_THRESH = 0.03   # min proportion of nonzeros in a column
OCCUPANCY_MIN_RUN = 5         # minimum contiguous rows/cols to keep


def random_masking(x, mask_ratio):
    """
    X: (B T C)
    random masking to create randomly shuffled unmasked patches
    """
    if mask_ratio <= 0:
        # no masking; return identity indices and zero mask
        B, T, _ = x.shape
        ids_restore = torch.arange(T, device=x.device).unsqueeze(0).repeat(B, 1)
        mask = torch.zeros([B, T], device=x.device)
        return x, mask, ids_restore
    B, T, D = x.shape
    len_keep = int(T * (1 - mask_ratio))
    # creating noise of shape (B, T) to latter generate random indices
    noise = torch.rand(B, T, device=x.device)

    # sorting the noise, and then ids_shuffle to keep the original indexe format
    ids_shuffle = torch.argsort(noise, dim=1)
    ids_restore = torch.argsort(ids_shuffle, dim=1)

    # gathering the first few samples
    ids_keep = ids_shuffle[:, :len_keep]
    x = torch.gather(x, dim=1, index=ids_keep.unsqueeze(-1).repeat(1, 1, D))

    # generate the binary mask: 0 is keep, 1 is remove
    mask = torch.ones([B, T], device=x.device)
    mask[:, :len_keep] = 0

    # unshuffle to get the binary mask
    mask = torch.gather(mask, dim=1, index=ids_restore)

    return x, mask, ids_restore


def _num_patches(img_size, patch_size):
    if isinstance(img_size, int):
        h = w = img_size
    else:
        h, w = img_size
    return (h // patch_size) * (w // patch_size)


def _contiguous_runs(idxs):
    if len(idxs) == 0:
        return []
    runs = []
    start = idxs[0]
    prev = idxs[0]
    for i in idxs[1:]:
        if i == prev + 1:
            prev = i
            continue
        runs.append((start, prev))
        start = i
        prev = i
    runs.append((start, prev))
    return runs


def _pick_central_run(runs, center_idx, min_len):
    if not runs:
        return None
    filtered = [r for r in runs if (r[1] - r[0] + 1) >= min_len]
    if not filtered:
        return None
    # prefer longest run; tie-breaker: closest to center
    def key_fn(r):
        length = r[1] - r[0] + 1
        mid = (r[0] + r[1]) / 2.0
        return (-length, abs(mid - center_idx))
    return sorted(filtered, key=key_fn)[0]


def _occupancy_bounds_2d(mat, row_thresh, col_thresh, min_run, eps):
    mat = np.asarray(mat)
    nonzero = mat > eps
    if nonzero.size == 0:
        return 0, mat.shape[0] - 1, 0, mat.shape[1] - 1
    row_occ = nonzero.mean(axis=1)
    col_occ = nonzero.mean(axis=0)
    row_idxs = np.where(row_occ >= row_thresh)[0]
    col_idxs = np.where(col_occ >= col_thresh)[0]

    row_runs = _contiguous_runs(row_idxs)
    col_runs = _contiguous_runs(col_idxs)

    row_center = (mat.shape[0] - 1) / 2.0
    col_center = (mat.shape[1] - 1) / 2.0

    row_run = _pick_central_run(row_runs, row_center, min_run)
    col_run = _pick_central_run(col_runs, col_center, min_run)

    if row_run is None:
        r0, r1 = 0, mat.shape[0] - 1
    else:
        r0, r1 = row_run
    if col_run is None:
        c0, c1 = 0, mat.shape[1] - 1
    else:
        c0, c1 = col_run

    return int(r0), int(r1), int(c0), int(c1)


def _to_float_matrix(arr):
    if isinstance(arr, np.ndarray) and arr.dtype != object:
        out = arr.astype(float, copy=False)
    else:
        df = pd.DataFrame(arr)
        out = df.apply(pd.to_numeric, errors="coerce").to_numpy(dtype=float)
    return np.nan_to_num(out, nan=0.0, posinf=0.0, neginf=0.0)


def _interval_from_bounds(bounds_list, interval=0.95):
    lo_q = (1.0 - interval) / 2.0
    hi_q = 1.0 - lo_q
    mins = np.array([b[0] for b in bounds_list], dtype=float)
    maxs = np.array([b[1] for b in bounds_list], dtype=float)
    min_q = int(np.floor(np.quantile(mins, lo_q)))
    max_q = int(np.ceil(np.quantile(maxs, hi_q)))
    return min_q, max_q


class MaskedAutoEncoder(nn.Module):
    def __init__(
        self,
        emb_size=1024,
        decoder_emb_size=512,
        patch_size=8,
        num_head=16,
        latent_dim=16,
        #encoder_num_layers=10,
        encoder_num_layers=5,
        #decoder_num_layers=6,
        decoder_num_layers=3,
        in_channels=1,
        img_size=(224, 224),
        peak_alpha=6.0,
        peak_power=2.0,
        peak_eps=1e-6,
    ):
        super().__init__()
        self.patch_size = patch_size
        self.img_size = img_size
        self.num_patches = _num_patches(img_size, patch_size)
        self.latent_dim = latent_dim
        self.patch_embed = PatchEmbedding(emb_size=emb_size, in_channels=in_channels, patch_size=patch_size,
                                          img_size=img_size)
        self.decoder_pos_embed = nn.Parameter(
            PositionEmbedding2D(img_size, patch_size, decoder_emb_size),
            requires_grad=False,
        )
        self.decoder_pred = nn.Linear(decoder_emb_size, patch_size ** 2 * in_channels, bias=True)
        self.encoder_transformer = nn.Sequential(*[Block(emb_size, num_head) for _ in range(encoder_num_layers)])
        self.encoder_norm = nn.LayerNorm(emb_size)
        self.bottleneck_down = nn.Sequential(
            nn.LayerNorm(emb_size),
            nn.Linear(emb_size, latent_dim),
            nn.GELU(),
        )
        self.bottleneck_up = nn.Sequential(
            nn.LayerNorm(latent_dim),
            nn.Linear(latent_dim, decoder_emb_size),
            nn.GELU(),
        )
        self.decoder_transformer = nn.Sequential(*[Block(decoder_emb_size, num_head) for _ in range(decoder_num_layers)])
        self.decoder_norm = nn.LayerNorm(decoder_emb_size)
        #self.project = nn.Sequential(nn.Conv2d(in_channels=in_channels, out_channels=patch_size ** 2 * in_channels, kernel_size=patch_size, stride=patch_size),Rearrange('b e (h) (w) -> b (h w) e'),)

        self.in_channels = in_channels
        # Loss weighting to emphasize high-intensity peaks.
        self.peak_alpha = peak_alpha
        self.peak_power = peak_power
        self.peak_eps = peak_eps

    def encoder(self, x, mask_ratio):
        x = self.patch_embed(x)

        cls_token = x[:, :1, :]
        x = x[:, 1:, :]

        x, mask, restore_id = random_masking(x, mask_ratio)

        x = torch.cat((cls_token, x), dim=1)

        x = self.encoder_transformer(x)
        x = self.encoder_norm(x)

        return x, mask, restore_id

    def bottleneck(self, x):
        x = self.bottleneck_down(x)
        x = self.bottleneck_up(x)
        return x

    def decoder(self, x, restore_id):
        x = self.bottleneck(x)
        x = x + self.decoder_pos_embed

        x = self.decoder_transformer(x)
        x = self.decoder_norm(x)

        # predictor projection
        x = self.decoder_pred(x)

        # remove cls token
        x = x[:, 1:, :]

        return x

    def loss(self, imgs, pred, mask):
        """
        imgs: [N, C, H, W]
        pred: [N, L, patch*patch*C]
        mask: [N, L], 0 is keep, 1 is remove,
        """
        target = self.patchify(imgs)

        # Weighted L1 loss to focus errors on high-intensity peaks.
        # Weights grow with positive target magnitude (background stays near 1x).
        target_pos = torch.relu(target)
        scale = target_pos.abs().mean(dim=-1, keepdim=True).clamp_min(self.peak_eps)
        weights = 1.0 + self.peak_alpha * (target_pos / scale) ** self.peak_power
        #loss = (weights * torch.abs(pred - target)).mean(dim=-1)
        loss = (torch.square(pred - target)).mean(dim=-1)

        if mask is None:
            loss = loss.mean()
        else:
            denom = mask.sum().clamp_min(1.0)
            loss = (loss * mask).sum() / denom
        return loss

    def patchify(self, imgs):
        """
        imgs: [B, C, H, W]
        returns: [B, L, patch_size*patch_size*C]
        """
        p = self.patch_size
        B, C, H, W = imgs.shape

        assert H == self.img_size[0] and W == self.img_size[1]
        assert H % p == 0 and W % p == 0

        h = H // p
        w = W // p

        x = imgs.reshape(B, C, h, p, w, p)
        x = x.permute(0, 2, 4, 3, 5, 1).contiguous()
        x = x.reshape(B, h * w, p * p * C)

        return x

    def unpatchify(self, x):
        """
        x: [B, L, patch*patch*C] -> [B, C, H, W]
        """
        p = self.patch_size
        h, w = self.img_size
        gh, gw = h // p, w // p
        if gh * gw != x.shape[1]:
            raise ValueError(
                f"Unpatchify size mismatch: expected {gh * gw} patches from img_size={self.img_size} "
                f"and patch_size={p}, got L={x.shape[1]}"
            )
        x = x.reshape(x.shape[0], gh, gw, p, p, self.in_channels)
        x = x.permute(0, 5, 1, 3, 2, 4).contiguous()
        return x.reshape(x.shape[0], self.in_channels, h, w)

    def forward(self, img, mask_ratio=0.0):
        x, mask, restore_ids = self.encoder(img, mask_ratio)
        pred = self.decoder(x, restore_ids if mask_ratio > 0 else None)
        loss = self.loss(img, pred, mask if mask_ratio > 0 else None)
        recon = self.unpatchify(pred)
        return loss, pred, mask, recon


def PositionEmbedding(seq_len, emb_size):
    embeddings = torch.ones(seq_len, emb_size)
    for i in range(seq_len):
        for j in range(emb_size):
            embeddings[i][j] = np.sin(i / (pow(10000, j / emb_size))) if j % 2 == 0 else np.cos(
                i / (pow(10000, (j - 1) / emb_size)))
    return torch.tensor(embeddings)


def PositionEmbedding1D(positions, emb_size):
    if emb_size % 2 != 0:
        raise ValueError("1D sine-cosine positional embedding size must be even.")

    positions = torch.as_tensor(positions, dtype=torch.float32).reshape(-1)
    omega = torch.arange(emb_size // 2, dtype=torch.float32)
    omega = 1.0 / (10000 ** (omega / (emb_size // 2)))
    out = positions[:, None] * omega[None, :]
    return torch.cat([torch.sin(out), torch.cos(out)], dim=1)


def PositionEmbedding2D(img_size, patch_size, emb_size, cls_token=True):
    if emb_size % 4 != 0:
        raise ValueError("2D sine-cosine positional embedding size must be divisible by 4.")

    if isinstance(img_size, int):
        h = w = img_size
    else:
        h, w = img_size

    grid_h = h // patch_size
    grid_w = w // patch_size
    y, x = torch.meshgrid(
        torch.arange(grid_h, dtype=torch.float32),
        torch.arange(grid_w, dtype=torch.float32),
        indexing="ij",
    )

    pos_embed = torch.cat(
        [
            PositionEmbedding1D(y.reshape(-1), emb_size // 2),
            PositionEmbedding1D(x.reshape(-1), emb_size // 2),
        ],
        dim=1,
    )

    if cls_token:
        cls_embed = torch.zeros(1, emb_size, dtype=torch.float32)
        pos_embed = torch.cat([cls_embed, pos_embed], dim=0)

    return pos_embed.unsqueeze(0)


class PatchEmbedding(nn.Module):
    def __init__(self, in_channels: int = 3, patch_size: int = 16, emb_size: int = 768, img_size=(224, 224)):
        self.patch_size = patch_size
        super().__init__()
        self.projection = nn.Sequential(
            nn.Conv2d(in_channels, emb_size, kernel_size=patch_size, stride=patch_size),
            Rearrange('b e (h) (w) -> b (h w) e'),
        )

        self.cls_token = nn.Parameter(torch.rand(1, 1, emb_size))
        self.pos_embed = nn.Parameter(
            PositionEmbedding2D(img_size, patch_size, emb_size),
            requires_grad=False,
        )

    def forward(self, x: Tensor) -> Tensor:
        b, _, _, _ = x.shape
        x = self.projection(x)

        cls_token = repeat(self.cls_token, ' () s e -> b s e', b=b)

        x = torch.cat([cls_token, x], dim=1)

        x = x + self.pos_embed
        return x


class MultiHead(nn.Module):
    def __init__(self, emb_size, num_head, dropout=0.1):
        super().__init__()
        assert emb_size % num_head == 0

        self.num_head = num_head
        self.head_dim = emb_size // num_head
        self.scale = self.head_dim ** -0.5

        self.qkv = nn.Linear(emb_size, emb_size * 3)
        self.proj = nn.Linear(emb_size, emb_size)
        self.attn_drop = nn.Dropout(dropout)
        self.proj_drop = nn.Dropout(dropout)

    def forward(self, x):
        B, N, C = x.shape

        qkv = self.qkv(x)
        qkv = qkv.reshape(B, N, 3, self.num_head, self.head_dim)
        qkv = qkv.permute(2, 0, 3, 1, 4)

        q, k, v = qkv[0], qkv[1], qkv[2]

        attn = (q @ k.transpose(-2, -1)) * self.scale
        attn = attn.softmax(dim=-1)
        attn = self.attn_drop(attn)

        x = attn @ v
        x = x.transpose(1, 2).reshape(B, N, C)
        x = self.proj(x)
        x = self.proj_drop(x)

        return x


class FeedForward(nn.Module):
    def __init__(self, emb_size, mlp_ratio=4.0, dropout=0.1):
        super().__init__()

        hidden_size = int(emb_size * mlp_ratio)

        self.ff = nn.Sequential(
            nn.Linear(emb_size, hidden_size),
            nn.GELU(),
            nn.Dropout(dropout),
            nn.Linear(hidden_size, emb_size),
            nn.Dropout(dropout),
        )

    def forward(self, x):
        return self.ff(x)


class Block(nn.Module):
    def __init__(self, emb_size, num_head, mlp_ratio=4.0, dropout=0.1):
        super().__init__()

        self.norm1 = nn.LayerNorm(emb_size)
        self.attn = MultiHead(emb_size, num_head, dropout=dropout)

        self.norm2 = nn.LayerNorm(emb_size)
        self.ff = FeedForward(
            emb_size,
            mlp_ratio=mlp_ratio,
            dropout=dropout,
        )

    def forward(self, x):
        x = x + self.attn(self.norm1(x))
        x = x + self.ff(self.norm2(x))
        return x

class VissionTransformer(nn.Module):
    def __init__(self, num_layers, img_size, emb_size, patch_size, num_head, num_class, in_channels=1):
        super().__init__()
        self.attention = nn.Sequential(*[Block(emb_size, num_head) for _ in range(num_layers)])
        self.patchemb = PatchEmbedding(patch_size=patch_size, img_size=img_size, in_channels=in_channels)
        self.ff = nn.Linear(emb_size, num_class)

    def forward(self, x):  # x -> (b, c, h, w)
        embeddings = self.patchemb(x)
        x = self.attention(embeddings)
        x = self.ff(x[:, 0, :])
        return x


def train_masked_autoencoder(
    model,
    train_tensor,
    device,
    num_epochs=20,
    batch_size=8,
    mask_ratio=0.75,
    lr=1e-3,
    weight_decay=1e-8,
    log_every=1,
):
    dataset = TensorDataset(train_tensor)
    loader = DataLoader(dataset, batch_size=batch_size, shuffle=True, drop_last=False)
    optimizer = optim.Adam(model.parameters(), lr=lr, weight_decay=weight_decay)

    model.train()
    for epoch in range(num_epochs):
        running_loss = 0.0
        num_batches = 0

        for (batch,) in loader:
            if torch.isnan(batch).any() or torch.isinf(batch).any():
                batch = torch.nan_to_num(batch, nan=0.0, posinf=0.0, neginf=0.0)
            batch = batch.to(device)
            optimizer.zero_grad()
            loss, _, _, _ = model(batch, mask_ratio=mask_ratio)
            loss.backward()
            optimizer.step()

            running_loss += loss.item()
            num_batches += 1

        if (epoch + 1) % log_every == 0:
            avg_loss = running_loss / max(1, num_batches)
            print(f"epoch {epoch + 1}/{num_epochs}  loss={avg_loss:.6f}")

## Loading Data
Data_Path = 'C:\\Users\\Reid Honeycutt\\Documents\\20250812_NN_trainingdata\\GCDMS_data'
model_save_path = Data_Path + '\\Autoencoder_model.pt'
model_save_path = Path(model_save_path)
Data_Path = Path(Data_Path)
Dir_Files = os.listdir(Data_Path)
Dir_Files = [x for x in Dir_Files if ('Neg.xls' in x)]
Dir_Files = [Path(str(Data_Path)+'\\'+x) for x in Dir_Files]

file_list = []
for file in Dir_Files:
    try:
        xls = pd.read_excel(file)
        xls = np.array(xls.iloc[2:,:]).astype(float)
        xls = np.nan_to_num(xls, nan=np.nanmean(xls), posinf=np.nanmean(xls), neginf=np.nanmean(xls))
        xls2 = scipy.signal.savgol_filter(xls[:,1:], 7, 3, axis=0)
        baseline_fitter = Baseline2D(x_data=xls2[:,0])
        baseline, params = baseline_fitter.individual_axes(xls2[:,:], axes=0, method='asls', method_kwargs={'lam': 1e5, 'p': 0.1})
        xls[:,1:] = xls[:,1:] - baseline.astype(float)
        #plt.imshow(xls[:,1:], norm='linear')
        file_list.append(xls[:, :])


        #xls = np.loadtxt(file, dtype=object, delimiter='\t', skiprows=3)
    except:
        print('pause')

    #print('pause')
file_list = [x for x in file_list if len(x)>1900]
window_min = np.max([np.min(x[:,0].astype(float)) for x in file_list])
window_max = np.min([np.max(x[:,0].astype(float)) for x in file_list])

#file_list[0][np.where(np.logical_and(file_list[0][:,0].astype(float)>=window_min, file_list[0][:,0].astype(float)<=window_max))[0],:]
file_list_cropped = [x[np.where(np.logical_and(x[:,0].astype(float)>=window_min, x[:,0].astype(float)<=window_max))[0],:] for x in file_list]
shortest_file = np.min([len(x) for x in file_list_cropped])-2
#file_list_double_cropped = [x[:shortest_file,1:] for x in file_list_cropped]
file_list_double_cropped = [x[:1840,-96:] for x in file_list_cropped]
#file_list_double_cropped = [x[200:1000,40:] for x in file_list_double_cropped]

_bounds = [
    _occupancy_bounds_2d(
        _to_float_matrix(x),
        row_thresh=OCCUPANCY_ROW_THRESH,
        col_thresh=OCCUPANCY_COL_THRESH,
        min_run=OCCUPANCY_MIN_RUN,
        eps=OCCUPANCY_NONZERO_EPS,
    )
    for x in file_list_double_cropped
]
r0, r1 = _interval_from_bounds([(b[0], b[1]) for b in _bounds], interval=0.95)
c0, c1 = _interval_from_bounds([(b[2], b[3]) for b in _bounds], interval=0.95)
r0 = max(0, r0)
c0 = max(0, c0)
r1 = min(file_list_double_cropped[0].shape[0] - 1, r1)
c1 = min(file_list_double_cropped[0].shape[1] - 1, c1)
file_list_final = [x[-1600:, -64:] for x in file_list_double_cropped]
#file_list_final = [x[r0:r1 + 1, c0:c1 + 1] for x in file_list_double_cropped]

Image_Array = np.array(file_list_final).astype('float32')

train_x = torch.tensor(Image_Array).reshape(-1, 1, 1600, 64)
train_x = torch.nan_to_num(train_x, nan=0.0, posinf=0.0, neginf=0.0)
train_x = nn.functional.interpolate(train_x, scale_factor=(0.25,1.0), mode='bilinear')
train_x = image_transforms(train_x)
# train_x = torch.tensor(Image_Array[:12,:,:,:].reshape(-1,800,80))
# train_x = torch.tensor(np.stack((Image_Array[:12,:,:,:].reshape(-1,800,80),)*3, axis=1))
# train_x_aug = contrast_transforms(train_x)
# test_x = torch.tensor(Image_Array[12:,:,:,:].reshape(-1,800,80))
# test_x = torch.tensor(np.stack((Image_Array[12:,:,:,:].reshape(-1,800,80),)*3, axis=1))
# test_x_aug = contrast_transforms(test_x)
#plt.imshow(train_x[10,0,:,:], norm='linear')
#plt.show()
start = time.perf_counter()

if __name__ == '__main__':
    # Example usage
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    x = torch.rand(1, 1, 1840, 96).to(device)
    if model_save_path.exists():
        model = MaskedAutoEncoder(in_channels=1, img_size=(400, 64), ).to(device)
        model.load_state_dict(torch.load(model_save_path, weights_only=True))
    else:
        model = MaskedAutoEncoder(in_channels=1, img_size=(400, 64), patch_size=16, ).to(device)
        summary(model, input_size=(16, 1, 400, 64))
        images = train_x[:, :, :, :].to(device)
        train_masked_autoencoder(
            model=model,
            train_tensor=train_x,
            device=device,
            num_epochs=300,
            batch_size=16,
            mask_ratio=0.0,
            lr=3e-4,
            weight_decay=1e-8,
            log_every=1,
        )
    model.eval()
    loss, pred, mask, recon = model(train_x[[0],:,:,:].to(device), mask_ratio=0.0)
    recon = recon.detach().cpu().numpy().reshape(400, 64)
    target = train_x[[0],:,:,:].detach().cpu().numpy().reshape(400, 64)
    # Note: model is trained on normalized data, so outputs are near 0 in that space.
    recon_denorm = recon * IMAGE_NORM_STD + IMAGE_NORM_MEAN
    target_denorm = target * IMAGE_NORM_STD + IMAGE_NORM_MEAN
    end = time.perf_counter()
    runtime = end - start
    print(runtime)
    plt.imshow(recon_denorm.astype(float), norm='linear')
    plt.show()
    plt.imshow(target_denorm)
print('pause')
#torch.save(model.state_dict(), model_save_path)
