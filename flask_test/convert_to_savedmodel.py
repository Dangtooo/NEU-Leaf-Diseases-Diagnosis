# This is what you would run on your LOCAL machine:

"""
import tensorflow as tf
from tensorflow.keras.models import load_model

# Load your working model
model = load_model('Tomato_Leaf_Diseases_Model.keras')

# Save as SavedModel format (more universal)
model.save('tomato_model_savedmodel', save_format='tf')

print("Model saved in SavedModel format!")
"""

print("Run this on your LOCAL machine to save in SavedModel format.")
print("Then compress and transfer the 'tomato_model_savedmodel' directory.")
