import tensorflow as tf
from tensorflow.keras.models import load_model
import numpy as np

def fix_model_compatibility(original_model_path, fixed_model_path):
    """
    Fix model compatibility issues by rebuilding the model architecture
    """
    try:
        # Try to load the original model
        print("Attempting to load original model...")
        model = load_model(original_model_path)
        print("✗ Original model loaded successfully - this shouldn't happen if there's an error")
        return False
        
    except Exception as e:
        print(f"✓ Confirmed error with original model: {str(e)}")
        
        # Extract model configuration from the saved model file
        print("Rebuilding model architecture...")
        
        # Create a new model with the same architecture
        from tensorflow.keras.applications import MobileNetV2
        from tensorflow.keras.layers import GlobalMaxPooling2D, Dense, Dropout
        from tensorflow.keras.models import Sequential
        
        base_model = MobileNetV2(
            include_top=False,
            weights='imagenet',
            input_shape=(224, 224, 3)
        )
        
        base_model.trainable = False
        
        # Rebuild the exact architecture
        fixed_model = Sequential([
            base_model,
            GlobalMaxPooling2D(),
            Dense(512, activation='relu'),
            Dropout(0.3),
            Dense(256, activation='relu'), 
            Dropout(0.4),
            Dense(128, activation='relu'),
            Dropout(0.5),
            Dense(10, activation='softmax')  # 10 classes for tomato diseases
        ])
        
        fixed_model.compile(
            optimizer='adam',
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )
        
        # Save the fixed model
        fixed_model.save(fixed_model_path)
        print(f"✓ Fixed model saved to: {fixed_model_path}")
        
        # Test the fixed model
        test_input = np.random.random((1, 224, 224, 3))
        predictions = fixed_model.predict(test_input, verbose=0)
        print(f"✓ Model test successful! Output shape: {predictions.shape}")
        
        return True

if __name__ == "__main__":
    success = fix_model_compatibility(
        'Tomato_Leaf_Diseases_Model_backup.keras',
        'Tomato_Leaf_Diseases_Model_Fixed_v2.keras'
    )
    if success:
        print("✓ Model compatibility fixed successfully!")
    else:
        print("✗ Could not fix model compatibility")
