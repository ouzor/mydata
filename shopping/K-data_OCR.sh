#!/bin/bash

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
