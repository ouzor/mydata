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

echo "K-data: split, convert pdfs to png"
for i in {1..12}
do
	pdftk K-data.pdf cat $i output K-data_processed/K-data_split_$i.pdf
	convert -quiet -density 600 -size 210 × 297 -depth 8 K-data_processed/K-data_split_$i.pdf K-data_processed/K-data_split_$i.png
done

% Process in R here: split to two, remove lines
% Script: bonusdata_process.R

echo "K-data: run OCR"
for i in {1..10}
do
	tesseract K-data_processed/K-data_half_linesremoved_$i.png -l fin -psm 6 K-data_processed/K-data_half_linesremoved_`expr $i + 10`
done

% Combine all text files into one
cat K-data_processed/*.txt >> K-data_processed/K-data_raw.txt

% The data is next curated manually and then finally processed in R
