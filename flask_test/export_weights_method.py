# This is what you would run on your LOCAL machine where the model works:

"""
import tensorflow as tf
from tensorflow.keras.models import load_model

# Load your working model
model = load_model('Tomato_Leaf_Diseases_Model.keras')

# Save only the weights (not the architecture)
model.save_weights('model_weights.h5')

# Save model configuration as JSON
with open('model_config.json', 'w') as f:
    f.write(model.to_json())

print("Weights and config exported successfully!")
"""

print("This script should be run on your LOCAL machine where the model works.")
print("It will create:")
print("1. model_weights.h5 - containing the trained weights")
print("2. model_config.json - containing the model architecture")
print("Then transfer these files to the server.")
