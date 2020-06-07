
# Build target
make --makefile=./tensorflow/lite/micro/tools/make/Makefile \
TARGET=sparkfun_edge <TARGET_BIN_NAME>

# Expected response
'
arm-none-eabi-objcopy tensorflow/lite/micro/tools/make/gen/sparkfun_edge_cortex-m4/bin/<TARGET> 
   tensorflow/lite/micro/tools/make/gen/sparkfun_edge_cortex-m4/bin/<TARGET>.bin-O binary
'

# Test for successful build
test -f \
./tensorflow/lite/micro/tools/make/gen/sparkfun_edge_cortex-m4/bin/<TARGET>.bin && \
echo "Binary was successfully created" || echo "Binary is missing"

    # One-off setup for dummy crypto keys
    cp ./tensorflow/lite/micro/tools/make/downloads/AmbiqSuite-Rel2.2.0/tools/apollo3_scripts/keys_info0.py \
    tensorflow/lite/micro/tools/make/downloads/AmbiqSuite-Rel2.2.0/tools/apollo3_scripts/keys_info.py

# Create signed binary
python3 ./tensorflow/lite/micro/tools/make/downloads/AmbiqSuite-Rel2.2.0/tools/apollo3_scripts/create_cust_image_blob.py \
--bin ./tensorflow/lite/micro/tools/make/gen/sparkfun_edge_cortex-m4/bin/<TARGET>.bin \
--load-address 0xC000 \
--magic-num 0xCB \
-o main_nonsecure_ota \
--version 0x0

# Create bootable binary
python3 ./tensorflow/lite/micro/tools/make/downloads/AmbiqSuite-Rel2.2.0/tools/apollo3_scripts/create_cust_wireupdate_blob.py \
--load-address 0x20000 \
--bin main_nonsecure_ota.bin \
-i 6 \
-o main_nonsecure_wire \
--options 0x1

# Connect & power-up the SparkFun Edge board

# If you are using MacOS: 
ls /dev/cu*
# If you are using Linux: 
# ls /dev/tty*

# Set USB device name - on MacOS, select the one with '/dev/cu.wch***[-]<number>'
export DEVICENAME=/dev/cu.wchusbserial1440

# Set USB programmer serial baud rate
export BAUD_RATE=921600

# Flash device...
# Press button 14 ----> press reset button -----> KEEP HOLDING button 14 down ------> and hit Enter on the below:
python3 tensorflow/lite/micro/tools/make/downloads/AmbiqSuite-Rel2.2.0/tools/apollo3_scripts/uart_wired_update.py -b ${BAUD_RATE} ${DEVICENAME} -r 1 -f main_nonsecure_wire.bin -i 6

# Expected response
'
Connecting with Corvette over serial port /dev/cu.usbserial-1440...
Sending Hello.
Received response for Hello
Received Status
length =  0x58
version =  0x3
Max Storage =  0x4ffa0
Status =  0x2
State =  0x7
AMInfo =
0x1
0xff2da3ff
0x55fff
0x1
0x49f40003
0xffffffff
[...lots more 0xffffffff...]
Sending OTA Descriptor =  0xfe000
Sending Update Command.
number of updates needed =  1
Sending block of size  0x158b0  from  0x0  to  0x158b0
Sending Data Packet of length  8180
[...lots more Sending Data Packet of length  8180...]
Sending Data Packet of length  8180
Sending Data Packet of length  6440
Sending Reset Command.
Done.
'

# Read debug output
screen ${DEVICENAME} 115200
# Ctrl + A then Ctrl + D  to exit

# Write debug to output : tensorflow/lite/micro/examples/micro_speech/sparkfun_edge/command_responder.cc
'
use printf tokens in...
error_reporter->Report("Heard %s (%d) @%dms", found_command, score, current_time);
'
