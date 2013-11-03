#!/bin/bash

# Copyright (C) 2013 Juuso Parkkinen.
# Contact: <juuso.parkkinen@iki.fi>. 
# All rights reserved.

# This program is open source software; you can redistribute it and/or modify
# it under the terms of the FreeBSD License (keep this notice):
# http://en.wikipedia.org/wiki/BSD_licenses

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

echo "S-data: split, convert pdfs to png, run ocr"
echo "Note! The scripts outputs a lot of warnings, but worked fine anyway for me…"

for i in {1..31}
do
	pdftk S-data.pdf cat $i output S-data_processed/S-data_split_$i.pdf
	convert -quiet -density 600 -size 210 × 297 -depth 8 S-data_processed/S-data_split_$i.pdf	S-data_processed/S-data_split_$i.png
 	tesseract S-data_processed/S-data_split_$i.png -l fin S-data_processed/S-data_split_$i
done

% Need to change all filename from -1.png to -01.png to preserve ordering in the next phase
% Could be done automatically as well!

% Combine all text files into one
cat S-data_processed/*.txt >> S-data_processed/S-data_raw.txt

% The data is next curated manually and then finally processed in R