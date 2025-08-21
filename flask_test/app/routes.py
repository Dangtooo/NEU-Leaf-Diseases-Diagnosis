from flask import Blueprint, request, jsonify
import os
import random
from werkzeug.utils import secure_filename
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
import shutil
import numpy as np

UPLOAD_FOLDER = 'image_folder'
main = Blueprint('main', __name__)
model = load_model(r'/home/ubuntu/app/Tomato-Diseases-Detection/flask_test/Tomato_Leaf_Diseases_Model_backup.keras')
model.summary()
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

class_encode = {
    0: 'Bacterial spot',
    1: 'Early blight',
    2: 'Healthy',
    3: 'Late blight',
    4: 'Mold',
    5: 'Mosaic virus',
    6: 'Septoria spot',
    7: 'Target spot',
    8: 'Two spotted spider mites',
    9: 'Yellow virus'
}

@main.route('/diagnose', methods=['POST'])
def diagnose_image():
    if 'image' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['image']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    if file:
        filename = secure_filename(file.filename)
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.save(filepath)
        ext = os.path.splitext(filename)[1]

        img = image.load_img(filepath, target_size=(224, 224))
        img_array = image.img_to_array(img) / 255.0
        img_array = np.expand_dims(img_array, axis=0)

        predictions = model.predict(img_array)
        predicted_index = int(np.argmax(predictions))
        predicted_class = class_encode[predicted_index]
        confidence = float(np.max(predictions))

        counter = 1
        while True:
            filename2 = f"{predicted_class}{counter}{ext}"
            filepath2 = os.path.join(UPLOAD_FOLDER, filename2)
            if not os.path.exists(filepath2):
                break
            counter += 1

        shutil.move(filepath, filepath2)

        return jsonify({
            'message': 'Diagnosis complete',
            'filename': filename,
            'result': predicted_class,
            'confidece level': confidence
        })

    return jsonify({'error': 'Invalid file type'}), 400
