ROM-Soup
========

Tool for exploring the ROM Soup from Newton ROM images.  This reads all of the NewtonScript objects from a given ROM image, and recreates them inside a NEWT/0 virtual machine.  It then allows you to explore these recreations.

Download the app from [the releases tab](https://github.com/pablomarx/ROM-Soup/releases).  If you build from source, remember to initialize&update the git submodules.

Need a ROM image? Try:

- [Newt J1 Armistice v629AS.00](https://archive.org/download/AppleNewtonROMs/Newt%20J1Armistice%20image)
- [Newton Notepad 1.0b1](https://archive.org/download/AppleNewtonROMs/Notepad%20v1.0b1.rom)
- [Original MessagePad 1.3 (414059)](https://archive.org/download/AppleNewtonROMs/MessagePad%20OMP%20v1.3.rom)


Features
--------

### Interactive NEWT/0 Console

<img width="619" alt="ROM Soup Console Screenshot" src="https://user-images.githubusercontent.com/179162/126057056-523b38d7-c4ba-4621-8daf-bee56bb8155d.png">

- Includes a copy of [Jason Harper's ViewFrame](http://nixietube.info) to decompile NewtonScript functions (**note**: presently disabled in 64-bit builds). Not all functions decompile yet, as there are some [NEWT/0 bugs](https://github.com/pablomarx/NEWT0-1/commit/50815fb801a3747647b5be4e5cd000c5f63f5c33) preventing ViewFrame from functioning properly.
- Uses WebKit's Inspector for the console.  Yes, JS->ObjC->NewtonScript is strange. But I find this more enjoyable than a basic NSTextView console. 

### Bitmap + PICT Browser

<img width="619" alt="ROM Soup Image Browser Screenshot" src="https://user-images.githubusercontent.com/179162/126057063-ce44428d-80a2-4ff6-a9b9-decca02a8331.png">

- Right click image(s) to save them as PNG files.
- Some images may not decode properly in the 64-bit version. 

### Sound Browser

<img width="619" alt="ROM Soup Sound Browser Screenshot" src="https://user-images.githubusercontent.com/179162/126057067-44f1a6d3-ae23-4c01-91b5-d71d1f115019.png">

- Double click or use the enter key to play the sound in the tool.
- Right click sounds(s) to save them as AIFF files.

### Blob Browser

<img width="509" alt="ROM Soup Blob Browser Screenshot" src="https://user-images.githubusercontent.com/179162/126057077-41648aa9-9cc3-44d2-ac9c-541d78bdbc39.png">

- Double click to view a [HexFiend](http://ridiculousfish.com/hexfiend/) powered hex dump of the blob.
- Right click blob(s) to export them to disk.

### Strings Browser

<img width="619" alt="ROM Soup Strings Browser Screenshot" src="https://user-images.githubusercontent.com/179162/126057081-ac42191c-f0bb-4289-ada8-a04a5eb0228f.png">
