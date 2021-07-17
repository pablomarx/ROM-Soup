//
//  NWTBitmapExtractor.m
//  NEWT
//
//  Created by Steve White on 2/2/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTBitmapExtractor.h"

#include "NewtEnv.h"
#include "NewtFns.h"
#include "NewtObj.h"

#define ROUND_UP(a,b)              (((a) + (b) - 1) & ~((b) - 1))

@implementation NWTBitmapExtractor

- (CGImageRef) newImageRefForBitmap:(newtRef)bitmapRef
                              error:(NSError *__autoreleasing *)error
{
  int depth = 0;
  newtRef bits = NcGetSlot(bitmapRef, NSSYM(bits));
  newtRef colordata = kNewtRefNIL;
  if (NewtRefIsNIL(bits) == NO) {
    depth = 1;
  }
  else {
    colordata = NcGetSlot(bitmapRef, NSSYM(colordata));
    if (NewtRefIsNIL(colordata) == YES) {
      NSLog(@"No bits, and no colordata in the frame: %i", bitmapRef);
      return nil;
    }
    if (NewtRefIsArray(colordata) == YES) {
      for (int i=0; i<NewtLength(colordata); i++) {
        newtRef colorEntry = NewtGetArraySlot(colordata, i);
        if (NewtRefIsFrame(colorEntry) == NO) {
          continue;
        }


        newtRef bitdepth = NcGetSlot(colorEntry, NSSYM(bitdepth));
        if (NewtRefIsInteger(bitdepth)) {
          int thisDepth = NewtRefToInteger(bitdepth);
          if (thisDepth > depth) {
            bits = NcGetSlot(colorEntry, NSSYM(cbits));
            depth = thisDepth;
          }
        }
      }
    }
    if (NewtRefIsNIL(bits)) {
      return nil;
    }
  }
  
  newtRef bounds = NcGetSlot(bitmapRef, NSSYM(bounds));
  if (NewtRefIsFrame(bounds) == NO) {
    NSLog(@"bounds %i isn't a frame", bounds);
    return nil;
  }
  
  newtRef widthRef = NcGetSlot(bounds, NSSYM(right));
  newtRef heightRef = NcGetSlot(bounds, NSSYM(bottom));
  if (NewtRefIsNIL(widthRef) || NewtRefIsFrame(heightRef)) {
    NSLog(@"width/right or height/bottom is nil in bounds: %i", bounds);
    return nil;
  }
  int width = NewtRefToInteger(widthRef);
  int height = NewtRefToInteger(heightRef);
  
  newtRef mask = NcGetSlot(bitmapRef, NSSYM(mask));
  const char *maskData = NULL;
  if (NewtRefIsNIL(mask) == NO) {
    maskData = NewtRefToData(mask) + 16;
  }
  
  const uint32_t grayscaleTable[] = {0xffffffff,0xeeeeeeff,0xddddddff,0xccccccff,0xbbbbbbff,0xaaaaaaff,0x999999ff,0x888888ff,0x777777ff,0x666666ff,0x555555ff,0x444444ff,0x333333ff,0x222222ff,0x111111ff,0x000000ff};
  
  const char *bitmap = NewtRefToData(bits) + 16;
  NSMutableData *bitmapData = [NSMutableData dataWithLength:width * height * 4];
  uint32_t *buffer = [bitmapData mutableBytes];
  int i=0;
  for (int y=0; y<height; y++) {
    for (int x=0; x<width;) {
      if (depth == 4) {
        uint8_t twoPixels = (bitmap[i] & 0xff);
        *buffer++ = grayscaleTable[(twoPixels & 0xf0) >> 4];
        x++;
        if (x < width) {
          *buffer++ = grayscaleTable[(twoPixels & 0xf)];
          x++;
        }
        i++;
      }
      else {
        for (int t=128; t>=1 && x<width; t=t/2) {
          BOOL white = ((bitmap[i]&0xff)&t);
          int pixel;
          if (white == NO) {
            pixel = 0xffffffff;
          }
          else {
            pixel = 0x000000ff;
          }
          
          
          *buffer = pixel;
          buffer++;
          x++;
        }
        i++;
      }
    }
    i = ROUND_UP(i, 4);
  }

  if (maskData != NULL) {
    i = 0;
    uint32_t *buffer = [bitmapData mutableBytes];
    for (int y=0; y<height; y++) {
      for (int x=0; x<width;) {
        for (int t=128; t>=1 && x<width; t=t/2) {
          BOOL mask = (((maskData[i]&0xff)&t)!=0);
          if (mask == true) {
            *buffer &= 0xffffff00;
          }
          buffer++;
          x++;
        }
      }
      i++;
      i = ROUND_UP(i, 4);
    }
  }
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate([bitmapData mutableBytes],
                                               width,
                                               height,
                                               8,
                                               4 * width,
                                               colorSpace,
                                               kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Host);
  
  
  CGImageRef image = CGBitmapContextCreateImage(context);
  
  CGColorSpaceRelease(colorSpace);
  CGContextRelease(context);
  return image;
}

- (NSData *) pngRepresentationOfBitmap:(newtRef)bitmapRef
                                 error:(NSError *__autoreleasing *)error
{
  CGImageRef imageRef = [self newImageRefForBitmap:bitmapRef
                                             error:error];
  if (imageRef == NULL) {
    return nil;
  }
  
  
  NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
  NSData * pngData = [imageRep representationUsingType: NSPNGFileType properties: nil];
  [imageRep release];
  CGImageRelease(imageRef);
  return pngData;
}

@end
