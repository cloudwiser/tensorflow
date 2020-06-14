#!/usr/bin/env python
import sys

BMP_HEADER_LEN = 54
RGB_LEN = 3

# Open the input and output filenames provided
rfp = open(sys.argv[1], "rb")
wfp = open(sys.argv[2], "wb+")

# Jump the read pointer over the 54 byte BMP header
rfp.seek(BMP_HEADER_LEN)

# Loop to the end of read file...
while True:
    # ...read in the RGB triplet (all 3 values will be the same if properly grayscaled by ImageMagick convert)
    triplet = bytearray(rfp.read(RGB_LEN))
    # ...if eof, break
    if len(triplet) == 0:
        break
    # ...else write the first byte out to the output file
    wfp.write(''.join(chr(triplet[0])).encode('charmap'))

# Close both files
rfp.close()
wfp.close()
