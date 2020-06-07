# 
# Training a model for TF Lite Micro using Visual Wakewords dataset on a GCP Deep Learning VM
# -------------------------------------------------------------------------------------------
#
#   1. This uses TF 1.15 rather than 2.0 given slim is not ported nor has a compatability mode...
#       ...try and run this on TF 2.0 and you will encounter exceptions all the way
#   2. This is GPU-enabled...so don't leave it running and burn your free annual GCP GPU credit and/or hard cash!
#   3. The model training script(s) assigns to /device:GPU0 and will fail if you attempt to run on a CPU-only instance
#

# Ensure you have the GCP CLI tools installed for your native OS and...
# ...authenicate your session from here on in (which will take you to a web page to approve your Google creds)
<local_host>$ gcloud auth login

<local_host>$ export IMAGE_FAMILY="tf-latest-gpu"
<local_host>$ export ZONE="us-west1-b"
<local_host>$ export INSTANCE_NAME="tf1-cuda-wakewords"

# You can change your GPU instance to suit zone availability and your budget...see the GCP docs for acclerator types
# Don't forget that you may need to apply for GPU usage approval on your GCP account if you have not used them before
# We also need to increase the default boot disk size from 50GB 
<local_host>$ gcloud compute instances create $INSTANCE_NAME \
  --zone=$ZONE \
  --image-family=$IMAGE_FAMILY \
  --image-project=deeplearning-platform-release \
  --maintenance-policy=TERMINATE \
  --accelerator="type=nvidia-tesla-k80,count=1" \
  --metadata="install-nvidia-driver=True" \
  --boot-disk-size=200GB

# OK...let's login to the VM CLI
# Replace following command line with that generated by the gcloud option in SSH dropdown in your GCP VM instances console
<local_host>$ gcloud beta compute ssh --zone \"$ZONE\" \"$INSTANCE_NAME\" --project "weird-name-123456"

#
# Now you should be logged in to the GCP VM so...
#
sudo apt-get update
sudo apt-get upgrade

# Edit .bashrc to add the python path at the end...
export PYTHONPATH=$PYTHONPATH:models/research/slim

# Clone the TF models
cd ~
git clone https://github.com/tensorflow/models.git


# Edit '/models/research/slim/datasets/download_and_convert_visualwakewords_lib.py'
#
# If you are running python 3.x then line 204 needs to be changed to:
#    annotations_index = {int(k): v for k, v in annotations_index.items()}
# 
# Otherwise you'll get: AttributeError: 'dict' object has no attribute 'iteritems'
#

# Download and process the Visual Wakeword dataset for dogs as the foreground class to detect
#
#   Notes :
#   1. This can take a while as it downloads the training, validation & annnotation zip files and runs the processing chain
#   2. At the start, you should see libcudart.so.<> success message...this shows we are on a CUDA/GPU-enabled VM 
#   3. Other tf.io.gfile deprecation warnings may also appear but (hopefully) exceptions
#   4. stderr is redirected to stdout to show tf.logging
#
python models/research/slim/download_and_convert_data.py \
    --logtostderr \
    --dataset_name=visualwakewords \
    --dataset_dir=./visualwakewords \
    --small_object_area_threshold=0.005 \
    --foreground_class_of_interest='dog' \
    2>&1


# Run the model training session
#
#   Notes:
#   1. Depending on your choice of GPU, this can take several days to complete
#   2. ...but you should have a useable model after a few hours to experiment with (see the TF Lite Micro tutorials)
#   3. stderr is redirected to stdout to show tf.logging
#   4. Don't forget to stop the instance once you have finished!!
#
python models/research/slim/train_image_classifier.py \
    --train_dir=vww_96_grayscale \
    --dataset_name=visualwakewords \
    --dataset_split_name=train \
    --dataset_dir=./visualwakewords \
    --model_name=mobilenet_v1_025 \
    --preprocessing_name=mobilenet_v1 \
    --train_image_size=96 \
    --input_grayscale=True \
    --save_summaries_secs=300 \
    --learning_rate=0.045 \
    --label_smoothing=0.1 \
    --learning_rate_decay_factor=0.98 \
    --num_epochs_per_decay=2.5 \
    --moving_average_decay=0.9999 \
    --batch_size=96 \
    --max_number_of_steps=1000000 \
    2>&1

# Run the model evaluation
#
#   Notes:
#     1. Replace the numeric model.ckpt with the relevant checkpoint to evaluate
#
python models/research/slim/eval_image_classifier.py \
    --alsologtostderr \
    --checkpoint_path=vww_96_grayscale/model.ckpt-131369 \
    --dataset_dir=./visualwakewords/ \
    --dataset_name=visualwakewords \
    --dataset_split_name=val \
    --model_name=mobilenet_v1_025 \
    --preprocessing_name=mobilenet_v1 \
    --use_grayscale=True \
    --train_image_size=96
#   --input_grayscale=True \

# Export the model to a GraphDef file
#
#   Notes:
#     1. A few INFO & WARNING messages are shown under TF 1.13 but you should still have a .pb file generated
#
python models/research/slim/export_inference_graph.py \
    --alsologtostderr \
    --dataset_name=visualwakewords \
    --model_name=mobilenet_v1_025 \
    --image_size=96 \
    --input_grayscale=True \
    --output_file=vww_96_grayscale_graph.pb

# Clone TF 1.15
#
#   Notes:
#     1. freeze_graph.py will exception under TF 2.x at the time of writing
#
cd ~
git clone -b r1.15 https://github.com/tensorflow/tensorflow.git

# Freeze the graph weights
#
#   Notes:
#     1. Replace the numeric model.ckpt with the relevant checkpoint (see evaluation above)
#
python tensorflow/tensorflow/python/tools/freeze_graph.py \
--input_graph=vww_96_grayscale_graph.pb \
--input_checkpoint=vww_96_grayscale/model.ckpt-131369 \
--input_binary=true --output_graph=vww_96_grayscale_frozen.pb \
--output_node_names=MobilenetV1/Predictions/Reshape_1

# Quantize the frozen model
#
#   Notes:
#     1. Code is a mix of that in the O'Reilly TinyML book plus https://github.com/tensorflow/tensorflow/issues/34720#issuecomment-563367319
#
python vww_96_grayscale_quantize.py

# Install xxd & ImageMagick
#
sudo apt-get -qq install xxd imagemagick

# Save the file as a C source file
#
xxd -i vww_96_grayscale_quantized.tflite > dog_detect_model_data.cc

# Copy the C source file to your local host from the VM
#
<local_host>$ gcloud compute scp $INSTANCE_NAME:dog_detect_model_data.cc <local_path>

# Now create dog and no_dog image arrays from sample png files (on your local host)
#
# Move the images onto the gcp instance (or run this process locally)
<local_host>$ gcloud compute scp <local_path>/dog.png $INSTANCE_NAME:dog.png
<local_host>$ gcloud compute scp <local_path>/no_dog.png $INSTANCE_NAME:no_dog.png

# Convert original image to simpler format via ImageMagick:
convert -resize 96x96\! dog.png dog.bmp3
convert -resize 96x96\! no_dog.png no_dog.bmp3

# Convert RGB colorspace to grayscale
# convert <img_in> -set colorspace Gray -separate -average <img_out>

# Skip the 54 byte bmp3 header and add the rest of the bytes to a C array:
xxd -s 54 -i dog.bmp3 > dog_image_data.cc
xxd -s 54 -i no_dog.bmp3 > no_dog_image_data.cc

# Copy the C source files to your local host from the VM
#
<local_host>$ gcloud compute scp $INSTANCE_NAME:dog_image_data.cc <local_path>
<local_host>$ gcloud compute scp $INSTANCE_NAME:no_dog_image_data.cc <local_path>
