import torch
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
import tensorflow_datasets as tfds

DATASET_UNLABELED_SIZE = 100000
DATASET_LABELED_SIZE = 5000
IMAGE_SIZE = 96
IMAGE_CHANNELS = 3

EPOCHS = 20
BATCH_SIZE = 2  # Equivalent to 200 steps per epoch
NETWORK_WIDTH = 128
TEMPERATURE = 0.1

batch_size = 2
epochs = 1000
inChannel = 1
x, y = 800, 80
input_img = Input(shape = (x, y, inChannel))
enco = Input(shape = (128,))
metric_rep = Input(shape = (128,))

num_classes = 2

Data_Path = 'C:\\Users\\Reid Honeycutt\\Documents\\DMS data test set'


def load_datasets():
    # Calculate the batch sizes for labeled and unlabeled samples
    steps_per_epoch = (DATASET_UNLABELED_SIZE + DATASET_LABELED_SIZE) // BATCH_SIZE
    unlabeled_batch_size = DATASET_UNLABELED_SIZE // steps_per_epoch
    labeled_batch_size = DATASET_LABELED_SIZE // steps_per_epoch
    print(f"Batch size: {unlabeled_batch_size} (unlabeled) + {labeled_batch_size} (labeled)")

    # Load the unlabeled and labeled samples for training
    unlabeled_train = (
        tfds.load("stl10", split="unlabelled", as_supervised=True, shuffle_files=True)

    )
    labeled_train = (
        tfds.load("stl10", split="train", as_supervised=True, shuffle_files=True)

    )
    # Load the test samples
    test = (
        tfds.load("stl10", split="test", as_supervised=True)

    )

    # Combine the labeled and unlabeled samples for training
    train = tf.data.Dataset.zip((unlabeled_train, labeled_train)).prefetch(buffer_size=tf.data.AUTOTUNE)

    return train, labeled_train, test


# Load the STL10 dataset
train_dataset, labeled_train_dataset, test_dataset = load_datasets()

class ContrastiveTransformations(object):

    def __init__(self, base_transforms, n_views=2):
        self.base_transforms = base_transforms
        self.n_views = n_views

    def __call__(self, x):
        return [self.base_transforms(x) for i in range(self.n_views)]

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
    den = Dense(128)(flat)
    #den = BatchNormalization()(den)
    return den

def get_encoder():
    return keras.Sequential(
        [
            keras.Input(shape=(800, 80, 1)),
            Conv2D(128, kernel_size=3, activation="relu"),
            Flatten(),
            Dense(128, activation="relu"),
        ],
        name="Encoder",
    )

def projection_head(enco):
    #flat = Flatten()(enco)
    enco = Dense(128, activation='relu')(enco)
    metric_rep = Dense(128)(enco)
    #out = Dense(num_classes, activation='softmax')(den)
    return metric_rep

def linear_probe(metric_rep):
    classification = Dense(1)(metric_rep)
    #out = Dense(num_classes, activation='softmax')(den)
    return classification

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


class ContrastiveModel(keras.Model):
    def __init__(self):
        super().__init__()

        self.temperature = 0.1
        self.contrastive_augmenter = contrast_transforms
        self.classification_augmenter = contrast_transforms
        self.encoder = get_encoder()
        # Non-linear MLP as projection head
        self.projection_head = keras.Sequential(
            [
                keras.Input(shape=(128,)),
                Dense(128, activation="relu"),
                Dense(128),
            ],
            name="Project_Head",
        )
        # Single dense layer for linear probing
        self.linear_probe = keras.Sequential(
            [Input(shape=(128,)), Dense(1)], name="linear_probe"
        )

        self.encoder.summary()
        self.projection_head.summary()
        self.linear_probe.summary()

    def compile(self, contrastive_optimizer, probe_optimizer, **kwargs):
        super().compile(**kwargs)

        self.contrastive_optimizer = contrastive_optimizer
        self.probe_optimizer = probe_optimizer

        # self.contrastive_loss will be defined as a method
        self.probe_loss = keras.losses.SparseCategoricalCrossentropy(from_logits=True)

        self.contrastive_loss_tracker = keras.metrics.Mean(name="c_loss")
        self.contrastive_accuracy = keras.metrics.SparseCategoricalAccuracy(
            name="c_acc"
        )
        self.probe_loss_tracker = keras.metrics.Mean(name="p_loss")
        self.probe_accuracy = keras.metrics.SparseCategoricalAccuracy(name="p_acc")

    @property
    def metrics(self):
        return [
            self.contrastive_loss_tracker,
            self.contrastive_accuracy,
            self.probe_loss_tracker,
            self.probe_accuracy,
        ]

    def contrastive_loss(self, projections_1, projections_2):
        # InfoNCE loss (information noise-contrastive estimation)
        # NT-Xent loss (normalized temperature-scaled cross entropy)

        # Cosine similarity: the dot product of the l2-normalized feature vectors
        projections_1 = tf.math.l2_normalize(projections_1, axis=1)
        projections_2 = tf.math.l2_normalize(projections_2, axis=1)
        similarities = (
            tf.matmul(projections_1, projections_2, transpose_b=True) / self.temperature
        )

        # The similarity between the representations of two augmented views of the
        # same image should be higher than their similarity with other views
        batch_size = tf.shape(projections_1)[0]
        contrastive_labels = tf.range(batch_size)
        self.contrastive_accuracy.update_state(contrastive_labels, similarities)
        self.contrastive_accuracy.update_state(
            contrastive_labels, tf.transpose(similarities)
        )

        # The temperature-scaled similarities are used as logits for cross-entropy
        # a symmetrized version of the loss is used here
        loss_1_2 = keras.losses.sparse_categorical_crossentropy(
            contrastive_labels, similarities, from_logits=True
        )
        loss_2_1 = keras.losses.sparse_categorical_crossentropy(
            contrastive_labels, tf.transpose(similarities), from_logits=True
        )
        return (loss_1_2 + loss_2_1) / 2

    def train_step(self, data):
        (labeled_images, labels) = data

        # Both labeled and unlabeled images are used, without labels
        #images = tf.concat((unlabeled_images, labeled_images), axis=0)
        images = labeled_images
        # Each image is augmented twice, differently
        augmented_images_1 = self.contrastive_augmenter(images, training=True)
        augmented_images_2 = self.contrastive_augmenter(images, training=True)
        with tf.GradientTape() as tape:
            features_1 = self.encoder(augmented_images_1, training=True)
            features_2 = self.encoder(augmented_images_2, training=True)
            # The representations are passed through a projection mlp
            projections_1 = self.projection_head(features_1, training=True)
            projections_2 = self.projection_head(features_2, training=True)
            contrastive_loss = self.contrastive_loss(projections_1, projections_2)
        gradients = tape.gradient(
            contrastive_loss,
            self.encoder.trainable_weights + self.projection_head.trainable_weights,
        )
        self.contrastive_optimizer.apply_gradients(
            zip(
                gradients,
                self.encoder.trainable_weights + self.projection_head.trainable_weights,
            )
        )
        self.contrastive_loss_tracker.update_state(contrastive_loss)

        # Labels are only used in evaluation for an on-the-fly logistic regression
        preprocessed_images = self.classification_augmenter(
            labeled_images, training=True
        )
        with tf.GradientTape() as tape:
            # the encoder is used in inference mode here to avoid regularization
            # and updating the batch normalization parameters if they are used
            features = self.encoder(preprocessed_images, training=False)
            class_logits = self.linear_probe(features, training=True)
            probe_loss = self.probe_loss(labels, class_logits)
        gradients = tape.gradient(probe_loss, self.linear_probe.trainable_weights)
        self.probe_optimizer.apply_gradients(
            zip(gradients, self.linear_probe.trainable_weights)
        )
        self.probe_loss_tracker.update_state(probe_loss)
        self.probe_accuracy.update_state(labels, class_logits)

        return {m.name: m.result() for m in self.metrics}

    def test_step(self, data):
        labeled_images, labels = data

        # For testing, the components are used with a training=False flag
        preprocessed_images = self.classification_augmenter(
            labeled_images, training=False
        )
        features = self.encoder(preprocessed_images, training=False)
        class_logits = self.linear_probe(features, training=False)
        probe_loss = self.probe_loss(labels, class_logits)
        self.probe_loss_tracker.update_state(probe_loss)
        self.probe_accuracy.update_state(labels, class_logits)

        # Only the probe metrics are logged at test time
        return {m.name: m.result() for m in self.metrics[2:]}


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

train_x = torch.tensor(Image_Array[:12,:,:,:].reshape(-1,800,80))
train_x_aug = contrast_transforms(train_x)
test_x = torch.tensor(Image_Array[12:,:,:,:].reshape(-1,800,80))
test_x_aug = contrast_transforms(test_x)
train_y = Health_Array[:12]
test_y = Health_Array[12:]

#autoencoder = Model(input_img, decoder(encoder(input_img)))


# Contrastive pretraining
pretraining_model = ContrastiveModel()
pretraining_model.compile(
    contrastive_optimizer=keras.optimizers.Adam(),
    probe_optimizer=keras.optimizers.Adam(),
)

pretraining_history = pretraining_model.fit([train_x, train_x, train_y], train_y, epochs=30, validation_data=test_x)
print(
    "Maximal validation accuracy: {:.2f}%".format(
        max(pretraining_history.history["val_p_acc"]) * 100
    )
)


print('pause')