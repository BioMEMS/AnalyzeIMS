import torch
import torch.nn as nn
from transformers import AutoImageProcessor, ViTMAEForPreTraining
from PIL import Image
import requests
import matplotlib.pyplot as plt

# ----- Step 1: Load and Prepare Your Custom Image -----
# For demonstration, we load an image and then simulate a custom grayscale image.
url = "http://images.cocodataset.org/val2017/000000039769.jpg"
image = Image.open(requests.get(url, stream=True).raw)
# Convert to grayscale (one channel)
image = image.convert("RGB")

# Resize to your custom dimensions (1500x100)
custom_width, custom_height = 100, 100
image = image.resize((custom_width, custom_height))
print("Custom image size:", image.size, "Mode:", image.mode)

# ----- Step 2: Load the Pre-trained Model and Processor -----
# Note: The processor may be designed for 3-channel images.
# You might need to adjust pre-processing if required.
image_processor = AutoImageProcessor.from_pretrained("facebook/vit-mae-base")
model = ViTMAEForPreTraining.from_pretrained("facebook/vit-mae-base", ignore_mismatched_sizes=True)
model.config.image_size = (custom_width, custom_height)  # Use a tuple if possible
model.config.num_channels = 1
# ----- Step 3: Modify the Patch Embedding Layer for 1-Channel Input -----
# Access the current patch embedding layer.
# Typically, this is implemented as a Conv2d layer with kernel_size=patch_size and stride=patch_size.
old_patch_embed = model.vit.embeddings.patch_embeddings.projection
hidden_size = model.config.hidden_size          # e.g. 768
patch_size = old_patch_embed.kernel_size          # typically (16, 16)

# Create a new Conv2d that accepts 1 input channel.
new_patch_embed = nn.Conv2d(
    in_channels=1, 
    out_channels=hidden_size, 
    kernel_size=patch_size, 
    stride=patch_size
)

# Initialize new weights (you could also use more advanced initialization or copy from existing weights)
nn.init.xavier_uniform_(new_patch_embed.weight)
if new_patch_embed.bias is not None:
    nn.init.zeros_(new_patch_embed.bias)

# Replace the original patch embedding with the new one.
model.vit.embeddings.patch_embeddings.projection = new_patch_embed

# ----- Step 4: Adjust Positional Embeddings -----
# Calculate the number of patches for your custom image.
# The output grid size = (height // patch_height) x (width // patch_width)
num_patches_height = custom_height // patch_size[0]
num_patches_width = custom_width // patch_size[1]
num_patches = num_patches_height * num_patches_width
print("Number of patches:", num_patches, f"({num_patches_height} x {num_patches_width})")

# Reinitialize the positional embeddings to match the new number of patches.
new_pos_embed = nn.Parameter(torch.zeros(1, num_patches, hidden_size))
nn.init.trunc_normal_(new_pos_embed, std=0.02)
model.vit.embeddings.position_embeddings = new_pos_embed
model.vit.embeddings.num_channels = 1
model.vit.embeddings.patch_embeddings.num_channels = 1


# ----- Step 5: Process the Image and Perform a Forward Pass -----
# Note: The processor might automatically convert grayscale images to 3 channels.
# If so, you might need to override this behavior.
inputs = image_processor(images=image, return_tensors="pt", do_resize=False)
# If the processor converts to 3 channels, override it:
if inputs["pixel_values"].shape[1] == 3:
    # Convert to 1 channel by averaging (or any other appropriate method)
    inputs["pixel_values"] = inputs["pixel_values"].mean(dim=1, keepdim=True)

outputs = model(**inputs, interpolate_pos_encoding=True)

# The model returns logits which are the reconstructed pixel values.
reconstructed_pixel_values = outputs.logits

# ----- Step 6: Post-process and Visualize the Reconstructed Image -----
# Remove the batch dimension and permute the dimensions to (H, W, C)
reconstructed_image = reconstructed_pixel_values[0].permute(1, 2, 0).detach().cpu()

# The outputs are often normalized; clip values to [0,1] (adjust as needed).
reconstructed_image = reconstructed_image.clip(0, 1)

# Since the image is single-channel, squeeze the channel dimension.
plt.imshow(reconstructed_image.squeeze(), cmap="gray")
plt.title("Reconstructed Image")
plt.axis("off")
plt.show()