# Shopping data

### Watch first the video animation [Kanta-asiakkuuden jäljet](http://ouzo.kuvat.fi/kuvat/Videos/Kanta-asiakkuuden+j%C3%A4ljet/)!

## How to get my shopping data?

S-group: Fill in a form in a customer service desk.

K-group: Fill in a paper form and mail it to X (sorry forgot the details, trying to search for the link).

Both S and K will send you your data in a paper format via mail. This makes processing the data much harder but not impossible. In the future the data will hopefully be provided in a convenient machine readable format.

Some news about the data [here](http://www.taloussanomat.fi/yrittaja/2012/10/31/bonuskortti-paljastaa-nain-kauppias-arvioi-sinua/201240974/137) and [here](http://www.talouselama.fi/uutiset/yle+sryhma+tietaa+kantaasiakkaistaan+taman++kryhma+tietaa+paljon+enemman/a2173601)

## How to analyze my shopping data?

In short, you need to
* Scan your data 
* Use some [Optical character recognition](http://en.wikipedia.org/wiki/Optical_character_recognition) (OCR) tool to convert scanned data into a machine readable format
* Process and analyse the converted data

Here's an example workflow that worked for me
* Scan your data into a PDF
* Use [Tesseract](https://code.google.com/p/tesseract-ocr/) for OCR
  * Tesseract shell scripts: [S-data](S-data_OCR.sh), [K-data](K-data_OCR.sh)
* Use [R](http://www.r-project.org/) for processing and analysing the data
  * [R script](bonusdata_process.R) with a lot of different processing stages
* More details in the end of this page!

See the video animation [Kanta-asiakkuuden jäljet](http://ouzo.kuvat.fi/kuvat/Videos/Kanta-asiakkuuden+j%C3%A4ljet/)!

Here are also some visualizations of the data:

![fig1](https://raw.github.com/ouzor/mydata/master/shopping/Bonusdata_ShopCategory-Time.png)

![fig2](https://raw.github.com/ouzor/mydata/master/shopping/Bonusdata_Helsinkimap.png)

## More details of the tools used

Some tips and details of installing and using the tools on OSX 1.8.5.

### OCR with Tesseract

Installation
* Useful instructions [here](http://blog.bobkuo.com/2011/02/installing-and-using-tesseract-2-04-on-mac-os-x-10-6-6-with-homebrew/)
* Additionally, the [Finnish language pack](https://code.google.com/p/tesseract-ocr/downloads/detail?name=tesseract-ocr-3.02.fin.tar.gz&can=2&q=) is needed
* [PDFTK](http://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/) also needed
* This [blog post](http://elmargol.wordpress.com/2011/01/27/howto-scan-multiple-pages-to-a-pdf-file-and-ocr-using-tesseract-on-archlinux/) was helpful for getting started with Tesseract

Running OCR
* If data is given in a table format with borders, OCR will be in trouble. There might be some option for Tesseract to adapt to this, but at least I didn't find anything. So I ended up removing the horizontal lines in R, which was not trivial since the lines were not exactly horizontal but a bit tilted instead
* It would have also been useful too add custom vocabulary such as "supermarket", but I did not get this to work with Tesseract (some hints [here](http://code.google.com/p/tesseract-ocr/wiki/FAQ#How_do_I_unpack_or_alter_existing_language_data_files?))

### Animation

* Used R package [animation](http://cran.r-project.org/web/packages/animation/index.html)
* Needs [ffmpeg](http://www.renevolution.com/how-to-install-ffmpeg-on-mac-os-x/)
* Needed to also install [otool](http://apple.stackexchange.com/questions/58057/is-otool-removed-in-mountain-lion)

### Data sonification

* Used R package [playitbyr](http://playitbyr.org/)
* Needs [Csound](http://csounds.com/), installing instructions [here](http://playitbyr.org/csound.html)
* Note! playitbyr does not work with Csound 6, so install version 5 instead!