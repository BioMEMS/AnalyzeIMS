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
import cv2
from pytorch_metric_learning.losses import NTXentLoss

Data_Path = 'C:\\Users\\Reid Honeycutt\\Documents\\DMS data test set'

Data_Path = Path(Data_Path)
Dir_Files = os.listdir(Data_Path)
Dir_Files = [x for x in Dir_Files if ('Pos.xls' in x)]
Dir_Files = [Path(str(Data_Path)+'\\'+x) for x in Dir_Files]

loss_func = NTXentLoss(temperature=0.10)

def add_gaussian_noise(image, mean=0, std=0.05):
    noise = np.random.normal(mean, std, image.shape).astype(float)
    noisy_image = cv2.add(image, noise)
    return noisy_image

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

train_x = Image_Array[:12,:,:,:]
test_x = Image_Array[12:,:,:,:]
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

    #up2 = UpSampling2D((2,2))(conv7) # 28 x 28 x 32
    #decoded = Conv2D(1, (3, 1), activation='relu', padding='same')(conv1) # 28 x 28 x 1
    #decoder = Conv2DTranspose(256, (3, 3), activation='relu', padding='same')(encoder)
    #decoder = UpSampling2D((2, 2))(decoder)
    #decoder = Conv2DTranspose(128, (3, 3), activation='relu', padding='same')(x)
    decoder = UpSampling2D((2, 2))(x)
    decoder = Conv2DTranspose(64, (3, 3), activation='relu', padding='same')(decoder)
    decoder = UpSampling2D((2, 2))(decoder)
    decoder = Conv2DTranspose(64, (3, 3), activation='relu', padding='same')(decoder)
    #decoder = BatchNormalization()(decoder)
    decoder = UpSampling2D((2, 2))(decoder)
    decoded = Conv2DTranspose(1, (3, 3), padding='same')(decoder)
    return decoded

# define dataset
X, y = make_classification(n_samples=1000, n_features=100, n_informative=10, n_redundant=90, random_state=1)
# number of input columns
n_inputs = X.shape[1]
# split into train test sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.33, random_state=1)
# scale data
t = MinMaxScaler()
t.fit(X_train)
X_train = t.transform(X_train)
X_test = t.transform(X_test)
# define encoder
visible = Input(shape=(n_inputs,))

callback = EarlyStopping(monitor='val_loss', patience=3)

autoencoder = Model(input_img, decoder(encoder(input_img)))
autoencoder.compile(loss='mean_absolute_error', optimizer = RMSprop(learning_rate=0.0001,), )

train_x_noisy = add_gaussian_noise(train_x)

autoencoder_train = autoencoder.fit(train_x_noisy, train_x, batch_size=batch_size,epochs=epochs,verbose=1,validation_data=(test_x, test_x), callbacks=[callback],)

def projection_head(enco):
    #flat = Flatten()(enco)
    metric_rep = Dense(32, activation='relu')(enco)
    #out = Dense(num_classes, activation='softmax')(den)
    return metric_rep

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