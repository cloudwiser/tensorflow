/* Copyright 2019 The TensorFlow Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
==============================================================================*/

// This data was created from a sample image from without a dog in it.
// Convert original image to simpler format:
// convert -resize 96x96\! nodog.PNG nodog.bmp3
// Skip the 54 byte bmp3 header and add the rest of the bytes to a C array:
// xxd -s 54 -i /tmp/nodog.bmp3 > /tmp/nodog.cc

#ifndef TENSORFLOW_LITE_MICRO_EXAMPLES_DOG_DETECTION_NO_DOG_IMAGE_DATA_H_
#define TENSORFLOW_LITE_MICRO_EXAMPLES_DOG_DETECTION_NO_DOG_IMAGE_DATA_H_

#include <cstdint>

extern const int g_no_dog_data_size;
extern const uint8_t g_no_dog_data[];

#endif  // TENSORFLOW_LITE_MICRO_EXAMPLES_DOG_DETECTION_NO_DOG_IMAGE_DATA_H_
