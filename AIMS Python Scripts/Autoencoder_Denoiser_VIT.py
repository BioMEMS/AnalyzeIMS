import torch
from einops.layers.torch import Rearrange
import torch.nn as nn
import torch
import numpy as np
import torch.nn.functional as F
from torch import nn
from torch import Tensor
from einops import rearrange, repeat
from einops.layers.torch import Rearrange


def random_masking(x, mask_ratio):
    """
    X: (B T C)
    random masking to create randomly shuffled unmasked patches
    """
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


class MaskedAutoEncoder(nn.Module):
    def __init__(self, emb_size=1024, decoder_emb_size=512, patch_size=16, num_head=16, encoder_num_layers=24,
                 decoder_num_layers=8, in_channels=3, img_size=224):
        super().__init__()
        self.patch_embed = PatchEmbedding(emb_size=emb_size)
        self.decoder_embed = nn.Linear(emb_size, decoder_emb_size)
        self.decoder_pos_embed = nn.Parameter(torch.zeros(1, (img_size // patch_size) ** 2 + 1, decoder_emb_size),
                                              requires_grad=False)
        self.decoder_pred = nn.Linear(decoder_emb_size, patch_size ** 2 * in_channels, bias=True)
        self.mask_token = nn.Parameter(torch.zeros(1, 1, decoder_emb_size))
        self.encoder_transformer = nn.Sequential(*[Block(emb_size, num_head) for _ in range(encoder_num_layers)])
        self.decoder_transformer = nn.Sequential(
            *[Block(decoder_emb_size, num_head) for _ in range(decoder_num_layers)])
        self.project = nn.Sequential(
            nn.Conv2d(in_channels=3, out_channels=patch_size ** 2 * in_channels, kernel_size=patch_size,
                      stride=patch_size),
            Rearrange('b e (h) (w) -> b (h w) e'),
        )

    def encoder(self, x, mask_ratio):
        x = self.patch_embed(x)

        cls_token = x[:, :1, :]
        x = x[:, 1:, :]

        x, mask, restore_id = random_masking(x, mask_ratio)

        x = torch.cat((cls_token, x), dim=1)

        x = self.encoder_transformer(x)

        return x, mask, restore_id

    def decoder(self, x, restore_id):
        x = self.decoder_embed(x)

        mask_tokens = self.mask_token.repeat(x.shape[0], restore_id.shape[1] + 1 - x.shape[1], 1)
        x_ = torch.cat([x[:, 1:, :], mask_tokens], dim=1)
        x_ = torch.gather(x_, dim=1, index=restore_id.unsqueeze(-1).repeat(1, 1, x.shape[2]))
        x = torch.cat([x[:, :1, :], x_], dim=1)

        # add pos embed
        x = x + self.decoder_pos_embed

        x = self.decoder_transformer(x)

        # predictor projection
        x = self.decoder_pred(x)

        # remove cls token
        x = x[:, 1:, :]

        return x

    def loss(self, imgs, pred, mask):
        """
        imgs: [N, 3, H, W]
        pred: [N, L, patch*patch*3]
        mask: [N, L], 0 is keep, 1 is remove,
        """
        target = self.project(imgs)

        loss = (pred - target) ** 2
        loss = loss.mean(dim=-1)

        loss = (loss * mask).sum() / mask.sum()
        return loss

    def forward(self, img):
        mask_ratio = 0.75

        x, mask, restore_ids = self.encoder(img, mask_ratio)
        pred = self.decoder(x, restore_ids)
        loss = self.loss(img, pred, mask)
        return loss, pred, mask


def PositionEmbedding(seq_len, emb_size):
    embeddings = torch.ones(seq_len, emb_size)
    for i in range(seq_len):
        for j in range(emb_size):
            embeddings[i][j] = np.sin(i / (pow(10000, j / emb_size))) if j % 2 == 0 else np.cos(
                i / (pow(10000, (j - 1) / emb_size)))
    return torch.tensor(embeddings)


class PatchEmbedding(nn.Module):
    def __init__(self, in_channels: int = 3, patch_size: int = 16, emb_size: int = 768, img_size=224):
        self.patch_size = patch_size
        super().__init__()
        self.projection = nn.Sequential(
            nn.Conv2d(in_channels, emb_size, kernel_size=patch_size, stride=patch_size),
            Rearrange('b e (h) (w) -> b (h w) e'),
        )

        self.cls_token = nn.Parameter(torch.rand(1, 1, emb_size))
        self.pos_embed = nn.Parameter(PositionEmbedding((img_size // patch_size) ** 2 + 1, emb_size))

    def forward(self, x: Tensor) -> Tensor:
        b, _, _, _ = x.shape
        x = self.projection(x)

        cls_token = repeat(self.cls_token, ' () s e -> b s e', b=b)

        x = torch.cat([cls_token, x], dim=1)

        x = x + self.pos_embed
        return x


class MultiHead(nn.Module):
    def __init__(self, emb_size, num_head):
        super().__init__()
        self.emb_size = emb_size
        self.num_head = num_head
        self.key = nn.Linear(emb_size, emb_size)
        self.value = nn.Linear(emb_size, emb_size)
        self.query = nn.Linear(emb_size, emb_size)
        self.att_dr = nn.Dropout(0.1)

    def forward(self, x):
        k = rearrange(self.key(x), 'b n (h e) -> b h n e', h=self.num_head)
        q = rearrange(self.query(x), 'b n (h e) -> b h n e', h=self.num_head)
        v = rearrange(self.value(x), 'b n (h e) -> b h n e', h=self.num_head)

        wei = q @ k.transpose(3, 2) / self.num_head ** 0.5
        wei = F.softmax(wei, dim=2)
        wei = self.att_dr(wei)

        out = wei @ v

        out = rearrange(out, 'b h n e -> b n (h e)')
        return out


class FeedForward(nn.Module):
    def __init__(self, emb_size):
        super().__init__()
        self.ff = nn.Sequential(
            nn.Linear(emb_size, 4 * emb_size),
            nn.Linear(4 * emb_size, emb_size)
        )

    def forward(self, x):
        return self.ff(x)


class Block(nn.Module):
    def __init__(self, emb_size, num_head):
        super().__init__()
        self.att = MultiHead(emb_size, num_head)
        self.ll = nn.LayerNorm(emb_size)
        self.dropout = nn.Dropout(0.1)
        self.ff = FeedForward(emb_size)

    def forward(self, x):
        x = x + self.dropout(self.att(self.ll(x)))  # self.att(x): x -> (b , n, emb_size)
        x = x + self.dropout(self.ff(self.ll(x)))
        return x


class VissionTransformer(nn.Module):
    def __init__(self, num_layers, img_size, emb_size, patch_size, num_head, num_class):
        super().__init__()
        self.attention = nn.Sequential(*[Block(emb_size, num_head) for _ in range(num_layers)])
        self.patchemb = PatchEmbedding(patch_size=patch_size, img_size=img_size)
        self.ff = nn.Linear(emb_size, num_class)

    def forward(self, x):  # x -> (b, c, h, w)
        embeddings = self.patchemb(x)
        x = self.attention(embeddings)
        x = self.ff(x[:, 0, :])
        return x

if __name__ == '__main__':
    # Example usage
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    x = torch.rand(1, 3, 224, 224).to(device)
    model = MaskedAutoEncoder().to(device)
    print(model(x)[1].shape)