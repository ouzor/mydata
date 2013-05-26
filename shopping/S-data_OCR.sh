#!/bin/bash

% Copyright (C) 2013 Juuso Parkkinen.
% Contact: <http://ouzor.github.com/contact>. 
% All rights reserved.

% This program is open source software; you can redistribute it and/or modify
% it under the terms of the FreeBSD License (keep this notice):
% http://en.wikipedia.org/wiki/BSD_licenses

% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

% This script assumes you have a scanned your S-group data into file S-data.pdf

% Create folders for the output
mkdir TEMP_PDF
mkdir TEMP_PNG
mkdir TEMP_TXT

echo "S-data: split pdfs, convert to png, run ocr"
for i in {1..31}
do
  pdftk S-data.pdf cat $i output TEMP_PDF/S-data_split_$i.pdf
  convert -quiet -density 600 -size 210 × 297 -depth 8 TEMP_PDF/S-data_split_$i.pdf TEMP_PNG/S-data_split_$i.png
  tesseract TEMP_PNG/S-data_split_$i.png -l fin TEMP_TXT/S-data_split_$i
done
