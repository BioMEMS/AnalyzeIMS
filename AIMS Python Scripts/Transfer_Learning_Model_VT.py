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
from torchvision.models import vit_b_16, ViT_B_16_Weights
import xgboost as xgb
from xgboost import cv
from xgboost import XGBClassifier
import torch.optim as optim
import time
from torch.autograd import Variable
import copy
from sklearn.model_selection import train_test_split
from PIL import Image


USE_TENSORBOARD = False
BASE_LR = 0.001
EPOCH_DECAY = 30 # number of epochs after which the Learning rate is decayed exponentially.
DECAY_WEIGHT = 0.1

num_augs = 5

num_classes = 2
# Load a pre-trained model
model = models.vit_b_16(weights="DEFAULT")
for i, param in enumerate(model.parameters()):
    param.requires_grad = False
num_ftrs = model.heads.head.in_features
model.heads = torch.nn.Linear(num_ftrs, num_classes)


for param in model.parameters():
    print(param.requires_grad)
# new_model = torch.nn.Sequential(*(list(model.children())[:-1]))
weights = ViT_B_16_Weights.DEFAULT
#preprocess = weights.transforms()
# Create a feature extractor
#feature_extractor = torch.nn.Sequential(*list(model.children())[:-1])

# load the dataset
batch_size = 2
epochs = 1000
inChannel = 1
x, y = 800, 80
model_width=32
#input_img = Input(shape = (x, y, inChannel))
#enco = Input(shape = (128,))
#metric_rep = Input(shape = (128,))


train_cont_model = False
Data_Path = 'C:\\Users\\Reid Honeycutt\\Documents\\Dispersion data test set'
#Data_Path = 'C:\\Users\\Reid Honeycutt\\Documents\\DMS data test set'
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


def train_model(model, criterion, optimizer, lr_scheduler, num_epochs=100):
    since = time.time()

    best_model = model
    best_acc = 0.0

    for epoch in range(num_epochs):
        print('Epoch {}/{}'.format(epoch, num_epochs - 1))
        print('-' * 10)

        # Each epoch has a training and validation phase
        for phase in ['train', 'val']:
            if phase == 'train':
                mode = 'train'
                optimizer = lr_scheduler(optimizer, epoch)
                model.train()  # Set model to training mode
            else:
                model.eval()
                mode = 'val'

            running_loss = 0.0
            running_corrects = 0

            counter = 0
            # Iterate over data.
            for i in range(batches_per_epoch):
                start = i * batch_size
                # take a batch
                if phase == 'train':
                    inputs_raw = train_x[start:start + batch_size]
                    for i in np.arange(num_augs):
                        try:
                            inputs_temp = preprocess(inputs_raw)
                            inputs = torch.cat([inputs, inputs_temp], dim=0)
                            labels_temp = torch.tensor(train_y[start:start + batch_size]).long()
                            labels = torch.cat([labels, labels_temp], dim=0)
                        except:
                            inputs = preprocess(inputs_raw)
                            labels = torch.tensor(train_y[start:start + batch_size]).long()

                    #for i, _ in enumerate(inputs):
                    #    plt.imshow(inputs[i,0, :, :])#.reshape(224, 224))
                    #   plt.show()

                if phase == 'val':
                    inputs_raw = test_x[start:start + batch_size]
                    labels = torch.tensor(test_y[start:start + batch_size]).long()
                    inputs = preprocess(inputs_raw)

                print(inputs.size())
                # wrap them in Variable

                inputs, labels = Variable(inputs), Variable(labels)

                # Set gradient to zero to delete history of computations in previous epoch. Track operations so that differentiation can be done automatically.
                optimizer.zero_grad()
                outputs = model(inputs)
                _, preds = torch.max(outputs.data, 1)

                loss = criterion(outputs, labels)
                # print('loss done')
                # Just so that you can keep track that something's happening and don't feel like the program isn't running.
                # if counter%10==0:
                #     print("Reached iteration ",counter)
                counter += 1

                # backward + optimize only if in training phase
                if phase == 'train':
                    # print('loss backward')
                    loss.backward()
                    # print('done loss backward')
                    optimizer.step()
                    # print('done optim')
                # print evaluation statistics
                try:
                    # running_loss += loss.data[0]
                    running_loss += loss.item()
                    # print(labels.data)
                    # print(preds)
                    running_corrects += torch.sum(preds == labels.data)
                    # print('running correct =',running_corrects)
                except:
                    print('unexpected error, could not calculate loss or do a sum.')
            print('trying epoch loss')
            epoch_loss = running_loss / float(len(labels)*batches_per_epoch)
            epoch_acc = running_corrects.item() / float(len(labels)*batches_per_epoch)
            print('{} Loss: {:.4f} Acc: {:.4f}'.format(
                phase, epoch_loss, epoch_acc))

            # deep copy the model
            if phase == 'val':
                if USE_TENSORBOARD:
                    foo.add_scalar_value('epoch_loss', epoch_loss, step=epoch)
                    foo.add_scalar_value('epoch_acc', epoch_acc, step=epoch)
                if epoch_acc > best_acc:
                    best_acc = epoch_acc
                    best_model = copy.deepcopy(model)
                    print('new best accuracy = ', best_acc)
    time_elapsed = time.time() - since
    print('Training complete in {:.0f}m {:.0f}s'.format(
        time_elapsed // 60, time_elapsed % 60))
    print('Best val Acc: {:4f}'.format(best_acc))
    print('returning and looping back')
    return best_model


# This function changes the learning rate over the training model.
def exp_lr_scheduler(optimizer, epoch, init_lr=BASE_LR, lr_decay_epoch=EPOCH_DECAY):
    """Decay learning rate by a factor of DECAY_WEIGHT every lr_decay_epoch epochs."""
    lr = init_lr * (DECAY_WEIGHT ** (epoch // lr_decay_epoch))

    if epoch % lr_decay_epoch == 0:
        print('LR is set to {}'.format(lr))

    for param_group in optimizer.param_groups:
        param_group['lr'] = lr

    return optimizer

preprocess = v2.Compose([
    v2.Pad((360, 0)),
    v2.Resize(224),
    #v2.RandomResizedCrop(224, scale=(0.9,0.9)),
    #transforms.ToTensor(),
    #v2.ColorJitter(.01,.1,.1),
    #v2.RandomRotation(5),

    v2.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])

preprocess_val = v2.Compose([
    v2.Resize(224),
    #transforms.CenterCrop(224),
    #transforms.ToTensor(),
    #v2.ColorJitter(.1,.1,.1),
    #v2.RandomRotation(5),

    v2.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])

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
    xls = np.loadtxt(file, dtype=object, delimiter='\t', skiprows=3)
    file_list.append(xls[:,1:])
    #print('pause')
window_min = np.max([np.min(x[:,0].astype(float)) for x in file_list])
window_max = np.min([np.max(x[:,0].astype(float)) for x in file_list])
#Health_Array = np.array([1,0,1,0,1,0,1,0,1,0,1,0,
#                1,0,1,0,1,0,1,0,1,0,1,0])
Health_Array = np.array([1 if 'butanone' in str(x) else 0 for x in Dir_Files])

file_list[0][np.where(np.logical_and(file_list[0][:,0].astype(float)>=window_min, file_list[0][:,0].astype(float)<=window_max))[0],:]
file_list_cropped = [x[np.where(np.logical_and(x[:,0].astype(float)>=window_min, x[:,0].astype(float)<=window_max))[0],:] for x in file_list]
shortest_file = np.min([len(x) for x in file_list_cropped])-2
file_list_double_cropped = [x[:shortest_file,80:] for x in file_list_cropped]
file_list_double_cropped = [x[200:1000,40:] for x in file_list_double_cropped]
Image_Array = np.array(file_list_double_cropped).astype('float32').reshape(-1,800,80,1)
#Image_Array = np.array(file_list).astype('float32')
Image_Array = Image_Array/np.max(Image_Array)

#train_x = torch.tensor(Image_Array[:12,:,:,:].reshape(-1,800,80))
#train_x = torch.tensor(np.stack((Image_Array[:12,:,:,:].reshape(-1,800,80),)*3, axis=1))
#train_x_aug = contrast_transforms(train_x)
#test_x = torch.tensor(Image_Array[12:,:,:,:].reshape(-1,800,80))
#test_x = torch.tensor(np.stack((Image_Array[12:,:,:,:].reshape(-1,800,80),)*3, axis=1))
#test_x_aug = contrast_transforms(test_x)

train_x, test_x, train_y, test_y = train_test_split(torch.tensor(np.stack((Image_Array.reshape(-1,800,80),)*3, axis=1)), Health_Array, test_size=0.5, shuffle=False)
#train_x, test_x, train_y, test_y = train_test_split(torch.tensor(np.stack((Image_Array.reshape(-1,100,100),)*3, axis=1)), Health_Array, test_size=0.5, shuffle=True)

#train_y = Health_Array[:12]
#test_y = Health_Array[12:]

cont_model = contrastive_model()

loss_fn = NTXentLoss(temperature=0.2)
optimizer = torch.optim.Adam(cont_model.parameters(), lr=0.0000001)

n_epochs = 60  # number of epochs to run
batch_size = 12  # size of each batch
batches_per_epoch = len(train_x) // batch_size
save_path = Path(str(Data_Path) + '\\contrastive_model.pt')

clf = LogisticRegression(verbose=1)
xgb_classifier = XGBClassifier()
#for i, _ in enumerate(train_x):
#    plt.imshow(preprocess(train_x)[i, 0, :,:])
#    plt.show()

#train_x_encoded = new_model(preprocess(train_x)).reshape(12,512).detach().numpy()
#test_x_encoded = new_model(preprocess(test_x)).reshape(12,512).detach().numpy()
#xgb_classifier.fit(train_x_encoded,train_y,eval_set=[(test_x_encoded, test_y)],)
#clf.fit(train_x_encoded, train_y,)
#test_x_pred = clf.predict(test_x_encoded)

optimizer_ft = optim.RMSprop(model.parameters(), lr=0.0001)

criterion = nn.CrossEntropyLoss()

# Run the functions and save the best model in the function model_ft.
model_ft = train_model(model, criterion, optimizer_ft, exp_lr_scheduler,
                       num_epochs=100)


test_x_pred = xgb_classifier.predict(test_x_encoded).reshape(-1,1)
clf_acc = accuracy_score(test_x_pred, test_y)
print('pause')