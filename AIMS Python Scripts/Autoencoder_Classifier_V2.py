# train autoencoder for classification with with compression in the bottleneck layer
import tensorflow as tf
from sklearn.datasets import make_classification
from sklearn.preprocessing import MinMaxScaler
from sklearn.model_selection import train_test_split
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Input
from tensorflow.keras.layers import Dense
from tensorflow.keras.layers import LeakyReLU
from tensorflow.keras.layers import BatchNormalization
from tensorflow.keras.utils import plot_model
from matplotlib import pyplot
import keras
from keras.layers import Input,Dense,Flatten,Dropout,concatenate,Reshape,Conv2D,MaxPooling2D,UpSampling2D,Conv2DTranspose
from keras.optimizers import RMSprop
from pathlib import Path
import os
import numpy as np
from PIL import Image
from sklearn.ensemble import RandomForestClassifier
import matplotlib
matplotlib.use("TkAgg")
from matplotlib import pyplot as plt
from keras.callbacks import EarlyStopping
from numpy import dot
from numpy.linalg import norm
import torchvision
from torchvision.datasets import STL10
from torchvision.transforms import v2
import torch

Data_Path = 'C:\\Users\\Reid Honeycutt\\Documents\\DMS data test set'

class ContrastiveTransformations(object):

    def __init__(self, base_transforms, n_views=2):
        self.base_transforms = base_transforms
        self.n_views = n_views

    def __call__(self, x):
        return [self.base_transforms(x) for i in range(self.n_views)]

contrast_transforms = v2.Compose([v2.RandomHorizontalFlip(),
                                          v2.RandomResizedCrop(size=(800,80), scale=(0.8,0.8)),
                                          #transforms.RandomApply([
                                          #    transforms.ColorJitter(brightness=0.5,
                                          #                           contrast=0.5,
                                          #                           saturation=0.5,
                                          #                           hue=0.1)
                                          #], p=0.8),
                                          #transforms.RandomGrayscale(p=0.2),
                                          v2.GaussianBlur(kernel_size=9),
                                          #transforms.ToTensor(),
                                          #v2.Normalize(mean=(0.1,), std=(0.1,))
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
Image_Array = np.array(file_list_double_cropped).astype(float).reshape(-1,800,80,1)
Image_Array = Image_Array/np.max(Image_Array)

train_x = torch.tensor(Image_Array[:12,:,:,:].reshape(-1,800,80)).reshape(-1,800,80,1)
train_x_aug = contrast_transforms(torch.tensor(Image_Array[:12,:,:,:].reshape(-1,800,80))).reshape(-1,800,80,1)
test_x = torch.tensor(Image_Array[12:,:,:,:].reshape(-1,800,80)).reshape(-1,800,80,1)
test_x_aug = contrast_transforms(torch.tensor(Image_Array[12:,:,:,:].reshape(-1,800,80))).reshape(-1,800,80,1)
train_y = Health_Array[:12]
test_y = Health_Array[12:]



batch_size = 2
epochs = 1000
inChannel = 1
x, y = 800, 80
input_img = Input(shape = (x, y, inChannel))
num_classes = 2

def encoder(input_img):
    # Encoder part
    encoder = Conv2D(64, (3, 3), activation='relu', padding='same')(input_img)
    encoder = MaxPooling2D((2, 2))(encoder)
    #encoder = BatchNormalization()(encoder)
    encoder = Conv2D(128, (3, 3), activation='relu', padding='same')(encoder)
    encoder = MaxPooling2D((2, 2))(encoder)
    #encoder = Conv2D(256, (3, 3), activation='relu', padding='same')(encoder)
    #encoder = MaxPooling2D((2, 2))(encoder)
    flat = Flatten()(encoder)
    den = Dense(512)(flat)
    #den = BatchNormalization()(den)
    return den

def decoder(den):
    #decoder
    x = Dense(np.prod((100, 10)), activation='relu')(den)
    x = Reshape((100, 10, -1))(x)

    decoder = UpSampling2D((2, 2))(x)
    decoder = Conv2DTranspose(64, (3, 3), activation='relu', padding='same')(decoder)
    decoder = UpSampling2D((2, 2))(decoder)
    decoder = Conv2DTranspose(64, (3, 3), activation='relu', padding='same')(decoder)
    #decoder = BatchNormalization()(decoder)
    decoder = UpSampling2D((2, 2))(decoder)
    decoded = Conv2DTranspose(1, (3, 3), padding='same')(decoder)
    return decoded



callback = EarlyStopping(monitor='val_loss', patience=3)

autoencoder = Model(input_img, decoder(encoder(input_img)))
autoencoder.compile(loss='mean_absolute_error', optimizer = RMSprop(learning_rate=0.0001,), )

autoencoder_train = autoencoder.fit(train_x_aug, train_x, batch_size=batch_size,epochs=epochs,verbose=1,validation_data=(test_x_aug, test_x), callbacks=[callback],)

def fc(enco):
    flat = Flatten()(enco)
    den = Dense(128, activation='relu')(flat)
    #out = Dense(num_classes, activation='softmax')(den)
    return den

#encode = encoder(input_img)
#encoder_model = Model(input_img,fc(encode))
encoder_model = Model(input_img, encoder(input_img))

#Image.fromarray((autoencoder.predict(test_x[0,:,:,:].reshape(-1,1488,200,1))).reshape(1488,200), mode='L').show()
#Image.fromarray(((test_x[0,:,:,:].reshape(-1,1488,200,1))).reshape(1488,200), mode='L').show()
for i, _ in enumerate(test_x):
    plt.imshow(autoencoder.predict(test_x[i,:,:,:].reshape(-1,800,80,1)).reshape(800,80))
    plt.show()
    plt.imshow(test_x[i,:,:,:].reshape(-1,800,80,1).reshape(800,80))
    plt.show()


im = Image.fromarray((autoencoder.predict(test_x[0,:,:,:].reshape(-1,800,80,1))).reshape(800,80))
train_x_encoded = encoder_model.predict(train_x)
test_x_encoded = encoder_model.predict(test_x)

clf = RandomForestClassifier(max_depth=2, n_estimators=10, random_state=0, verbose=10)
clf.fit(train_x_encoded, train_y)
clf_score_train = clf.score(train_x_encoded, train_y)
clf_score = clf.score(test_x_encoded, test_y)
# compile autoencoder model
model.compile(optimizer='adam', loss='mse')
cos_sim = dot(train_x_encoded[0,:], train_x_encoded[1,:])/(norm(train_x_encoded[0,:])*norm(train_x_encoded[1,:]))
# plot the autoencoder
#plot_model(model, 'autoencoder_compress.png', show_shapes=True)
# fit the autoencoder model to reconstruct input
history = model.fit(X_train, X_train, epochs=200, batch_size=16, verbose=2, validation_data=(X_test,X_test))
# plot loss
pyplot.plot(history.history['loss'], label='train')
pyplot.plot(history.history['val_loss'], label='test')
pyplot.legend()
pyplot.show()
# define an encoder model (without the decoder)
encoder = Model(inputs=visible, outputs=bottleneck)
#plot_model(encoder, 'encoder_compress.png', show_shapes=True)
# save the encoder to file
encoder.save('encoder.h5')