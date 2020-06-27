#
# From the TinyML book...with TF 1.15
#
import tensorflow as tf
import io
import PIL
import numpy as np

def representative_dataset_gen():
    # Change the path to the validation records as needed
    record_iterator = tf.python_io.tf_record_iterator(path='visualwakewords/val.record-00000-of-00010')

    count = 0
    for string_record in record_iterator:
        example = tf.train.Example()
        example.ParseFromString(string_record)
        image_stream = io.BytesIO(example.features.feature['image/encoded'].bytes_list.value[0])
        image = PIL.Image.open(image_stream)
        image = image.resize((32, 32))
        image = image.convert('L')
        array = np.array(image)
        array = np.expand_dims(array, axis=2)
        array = np.expand_dims(array, axis=0)
        array = ((array / 127.5) - 1.0).astype(np.float32)
        yield([array])
        count += 1
        if count > 300:
            break

converter = tf.lite.TFLiteConverter.from_keras_model_file('LeNet-MNIST.h5')

converter.inference_input_type = tf.lite.constants.INT8
converter.inference_output_type = tf.lite.constants.INT8
converter.optimizations = [tf.lite.Optimize.DEFAULT]

converter.representative_dataset = representative_dataset_gen
tflite_quant_model = converter.convert()
open("LeNet-MNIST-32-fully-quantized.tflite", "wb").write(tflite_quant_model)
