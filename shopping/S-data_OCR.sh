#!/bin/bash

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