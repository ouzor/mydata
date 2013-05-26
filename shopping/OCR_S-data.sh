#!/bin/bash

mkdir TEMP_PDF
mkdir TEMP_PNG
mkdir TEMP_TXT

echo "S-data: split, pdfs convert to png, run ocr"
for i in {1..31}
do
  pdftk S-data.pdf cat $i output TEMP_PDF/S-data_split_$i.pdf
  convert -quiet -density 600 -size 210 × 297 -depth 8 TEMP_PDF/S-data_split_$i.pdf TEMP_PNG/S-data_split_$i.png
  tesseract TEMP_PNG/S-data_split_$i.png -l fin TEMP_TXT/S-data_split_$i
done
