import torch
import torch.nn as nn
from transformers import AutoImageProcessor
from PIL import Image
import requests
import matplotlib.pyplot as plt
from pathlib import Path
import os

original_file_path = Path("C:\\Users\\Reid Honeycutt\\Documents\\Rhododendron data test set")
synthetic_file_path = "C:\\Users\\Reid Honeycutt\\Documents\\Rhododendron data test set\\Synthetic Data"

original_files = os.listdir(original_file_path)
original_files = [x for x in original_files if not 'Hdr' in x]

print('pause')