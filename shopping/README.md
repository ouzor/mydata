# Shopping data

## Page being updated during 3.11.2013!!!


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
  * Tesseract shell scripts: [S-data](S-data_OCR.sh), [K-data] (coming)
* Use [R](http://www.r-project.org/) for processing and analysing the data
  * R scripts: [S-data](S-data_process.R), K-data (coming)
* More details in the end of this page!

See the [video animation](http://ouzo.kuvat.fi/kuvat/Videos/Kanta-asiakkuuden+j%C3%A4ljet/)!

Here are also some visualizations of the data:

![fig1](https://raw.github.com/ouzor/mydata/master/shopping/Bonusdata_ShopCategory-Time.png)

![fig2](https://raw.github.com/ouzor/mydata/master/shopping/Bonusdata_Helsinkimap.png)

## More details of the tools used

### Tesseract

* Useful instructions [here](http://blog.bobkuo.com/2011/02/installing-and-using-tesseract-2-04-on-mac-os-x-10-6-6-with-homebrew/)
* Additionally, the [Finnish language pack](https://code.google.com/p/tesseract-ocr/downloads/detail?name=tesseract-ocr-3.02.fin.tar.gz&can=2&q=) is needed
* This [blog post](http://elmargol.wordpress.com/2011/01/27/howto-scan-multiple-pages-to-a-pdf-file-and-ocr-using-tesseract-on-archlinux/) was helpful for getting started with Tesseract

### Data sonification

* coming
