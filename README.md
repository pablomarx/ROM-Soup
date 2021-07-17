ROM-Soup
========

Tool for exploring the ROM Soup from Newton ROM images.  This reads all of the NewtonScript objects from a given ROM image, and recreates them inside a NEWT/0 virtual machine.  It then allows you to explore these recreations.

Download the app from (https://www.dropbox.com/s/s3qubbau9pp5cgz/ROM%20Soup.zip).  If you build from source, remember to initialize&update the git submodules.

Need a ROM image? Try:

- [Newt J1 Armistice v629AS.00](https://archive.org/download/AppleNewtonROMs/Newt%20J1Armistice%20image)
- [Newton Notepad 1.0b1](https://archive.org/download/AppleNewtonROMs/Notepad%20v1.0b1.rom)
- [Original MessagePad 1.3 (414059)](https://archive.org/download/AppleNewtonROMs/MessagePad%20OMP%20v1.3.rom)

Modern Branch
--------

This branch compiles and executes on 64-bit x86_64 and M1.  Sounds, Blobs and Strings tabs appear to function correctly.  The Images tab displays bitmaps fine, however PICT images are not being decoded properly via [NSPICTImageRep](https://github.com/pablomarx/ROM-Soup/blob/cf308d44c76528f8d192c17e53fec2d6b09d73bf/ROM%20Soup/Exporters/NWTPICTExtractor.m#L23).  The console tab crashes when trying to expand the default object. 

<img width="593" alt="Screen Shot 2021-07-17 at 13 13 57" src="https://user-images.githubusercontent.com/179162/126048391-c55ea30e-7a2a-44af-85e6-4100ebbbe836.png">


Features
--------

### Interactive NEWT/0 Console

![ROM Soup Console Screenshot](http://i.imgur.com/JV9NV4k.png)

- Includes a copy of [Jason Harper's ViewFrame](http://nixietube.info) to decompile NewtonScript functions.  Not all functions decompile yet, as there are some [NEWT/0 bugs](https://github.com/pablomarx/NEWT0-1/commit/50815fb801a3747647b5be4e5cd000c5f63f5c33) preventing ViewFrame from functioning properly.
- Uses WebKit's Inspector for the console.  Yes, JS->ObjC->NewtonScript is strange. But I find this more enjoyable than a basic NSTextView console. 

### Bitmap + PICT Browser

![ROM Soup Image Browser Screenshot](http://i.imgur.com/4T70gsX.png)

- Right click image(s) to save them as PNG files.

### Sound Browser

![ROM Soup Sound Browser Screenshot](http://i.imgur.com/pGO62KQ.png)

- Double click or use the enter key to play the sound in the tool.
- Right click sounds(s) to save them as AIFF files.

### Blob Browser

![ROM Soup Blob Browser Screenshot](http://i.imgur.com/9vKYhOe.png)

- Double click to view a [HexFiend](http://ridiculousfish.com/hexfiend/) powered hex dump of the blob.
- Right click blob(s) to export them to disk.

### Strings Browser

![ROM Soup Strings Browser Screenshot](http://i.imgur.com/I7GlZdR.png)
