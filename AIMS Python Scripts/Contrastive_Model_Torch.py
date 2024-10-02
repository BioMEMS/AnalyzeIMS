import numpy as np
import torch
import torch.nn as nn
from torchvision.transforms import v2
from pathlib import Path
import os
from pytorch_metric_learning.losses import NTXentLoss
import matplotlib
matplotlib.use("TkAgg")
from matplotlib import pyplot as plt
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
import torchvision.models as models
from torchvision import transforms
from torchvision.models import resnet18, ResNet18_Weights

# Load a pre-trained model
model = models.resnet18(pretrained=True)
weights = ResNet18_Weights.DEFAULT
preprocess = weights.transforms()
# Create a feature extractor
feature_extractor = torch.nn.Sequential(*list(model.children())[:-1])

# load the dataset
batch_size = 2
epochs = 1000
inChannel = 1
x, y = 800, 80
model_width=32
#input_img = Input(shape = (x, y, inChannel))
#enco = Input(shape = (128,))
#metric_rep = Input(shape = (128,))

num_classes = 2
train_model = True
Data_Path = 'C:\\Users\\Reid Honeycutt\\Documents\\DMS data test set'

class encoder(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.network = torch.nn.Sequential(
            nn.Conv2d(1, 32, 3, padding='same'),
            nn.Flatten(),
            nn.Linear(800*80*32, 32),
            nn.ReLU(),
        )
    def forward(self, x):
        encoded = self.network(x)
        return encoded

class projection_head(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.projection_head = torch.nn.Sequential(
            torch.nn.Linear(32, 32),
            torch.nn.ReLU(),
        )
    def forward(self, x):
        metric = self.projection_head(x)
        return metric

class linear_probe(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.linear_probe = torch.nn.Sequential(
            nn.Linear(32, 1),
            nn.ReLU(),
        )
    def forward(self, x):
        classification = self.linear_probe(x)
        return classification

class contrastive_model(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.encoder = encoder()
        self.projection_head = projection_head()
        self.linear_probe = linear_probe()

    def forward(self, x):
        encoded = self.encoder(x)
        metric = self.projection_head(encoded)
        #classification = self.linear_probe(metric)
        return metric

class GrayscaleColorJitter:
    def __init__(self, brightness=0.5, contrast=0.5):
        self.color_jitter = v2.ColorJitter(brightness=brightness, contrast=contrast)

    def __call__(self, img):
        # The ColorJitter can be applied to a grayscale image as well
        return self.color_jitter(img)

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

Data_Path = Path(Data_Path)
Dir_Files = os.listdir(Data_Path)
Dir_Files = [x for x in Dir_Files if ('Pos.xls' in x)]
Dir_Files = [Path(str(Data_Path)+'\\'+x) for x in Dir_Files]

file_list = []
for file in Dir_Files:
    xls = np.loadtxt(file, dtype=object, delimiter='\t')
    file_list.append(xls[3:,:])
    #print('pause')
window_min = np.max([np.min(x[:,0].astype(float)) for x in file_list])
window_max = np.min([np.max(x[:,0].astype(float)) for x in file_list])
Health_Array = np.array([1,0,1,0,1,0,1,0,1,0,1,0,
                1,0,1,0,1,0,1,0,1,0,1,0])
#np.logical_and(np.asarray(TEWL_Peak_Starts)>time_ind_start, np.asarray(TEWL_Peak_Starts)<time_ind_end)
#file_list[0][np.where(np.logical_and(file_list[0][:,0].astype(float)>=window_min, file_list[0][:,0].astype(float)<=window_max))[0],:]
file_list_cropped = [x[np.where(np.logical_and(x[:,0].astype(float)>=window_min, x[:,0].astype(float)<=window_max))[0],:] for x in file_list]
shortest_file = np.min([len(x) for x in file_list_cropped])-2
file_list_double_cropped = [x[:shortest_file,81:] for x in file_list_cropped]
file_list_double_cropped = [x[200:1000,40:] for x in file_list_double_cropped]
Image_Array = np.array(file_list_double_cropped).astype('float32').reshape(-1,800,80,1)
Image_Array = Image_Array/np.max(Image_Array)

train_x = torch.tensor(Image_Array[:12,:,:,:].reshape(-1,800,80))
#train_x_aug = contrast_transforms(train_x)
test_x = torch.tensor(Image_Array[12:,:,:,:].reshape(-1,800,80))
#test_x_aug = contrast_transforms(test_x)
train_y = Health_Array[:12]
test_y = Health_Array[12:]

cont_model = contrastive_model()

loss_fn = NTXentLoss(temperature=0.2)
optimizer = torch.optim.Adam(cont_model.parameters(), lr=0.0000001)

n_epochs = 60  # number of epochs to run
batch_size = 12  # size of each batch
batches_per_epoch = len(train_x) // batch_size
save_path = Path(str(Data_Path) + '\\contrastive_model.pt')
if train_model:

    for epoch in range(n_epochs):
        cont_model.train()
        total_loss = 0
        for i in range(batches_per_epoch):
            start = i * batch_size
            # take a batch
            Xbatch = train_x[start:start + batch_size]
            Xbatch_aug_1 = contrast_transforms(Xbatch.reshape(-1,1,800,80))
            Xbatch_aug_2 = contrast_transforms(Xbatch.reshape(-1,1,800,80))
            for i, _ in enumerate(Xbatch_aug_1):
               plt.imshow(Xbatch[i, :, :].reshape(800, 80))
               plt.show()
            #    plt.imshow(Xbatch_aug_2[i, :, :].reshape(800, 80))
            #    plt.show()
            ybatch = train_y[start:start + batch_size]
            indices = torch.arange(0, Xbatch_aug_1.size(0))
            #labels = torch.cat([torch.tensor(ybatch), torch.tensor(ybatch)])
            labels = torch.cat((indices, indices))
            # forward pass
            y_pred_1 = cont_model(Xbatch_aug_1.reshape(-1,1,800,80))
            y_pred_2 = cont_model(Xbatch_aug_2.reshape(-1, 1, 800, 80))
            embeddings = torch.cat((y_pred_1, y_pred_2))
            a = embeddings.detach().numpy().astype(float)
            loss = loss_fn(embeddings, labels)
            print(loss)
            # backward pass
            optimizer.zero_grad()
            loss.backward()
            # update weights
            optimizer.step()
    torch.save(cont_model, save_path)
else:
    cont_model.load_state_dict(torch.load(save_path, weights_only=True))
clf = LogisticRegression(verbose=1)

train_x_encoded = cont_model(train_x.reshape(-1,1,800,80)).detach().numpy()
test_x_encoded = cont_model(test_x.reshape(-1,1,800,80)).detach().numpy()
clf.fit(train_x_encoded, train_y,)
test_x_pred = clf.predict(test_x_encoded)
clf_acc = accuracy_score(test_x_pred, test_y)
print('pause')