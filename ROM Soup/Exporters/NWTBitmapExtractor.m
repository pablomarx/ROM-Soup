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

@implementation NWTBitmapExtractor

- (CGImageRef) newImageRefForBitmap:(newtRef)bitmapRef
                              error:(NSError *__autoreleasing *)error
{
  newtRef bits = NcGetSlot(bitmapRef, NSSYM(bits));
  if (NewtRefIsNIL(bits) == YES) {
    NSLog(@"no bits in the frame %i", bitmapRef);
    return nil;
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
  
  newtRef mask = NcGetSlot(bitmapRef, NSSYM(mask));
  const char *maskData = NULL;
  if (NewtRefIsNIL(mask) == NO) {
    maskData = NewtRefToData(mask) + 16;
  }
  
  int width = NewtRefToInteger(widthRef);
  int height = NewtRefToInteger(heightRef);
  const char *bitmap = NewtRefToData(bits) + 16;
  
  NSMutableData *bitmapData = [NSMutableData dataWithLength:width * height * 4];
  uint32_t *buffer = [bitmapData mutableBytes];
  
  int i=0;
  for (int y=0; y<height; y++) {
    for (int x=0; x<width;) {
      for (int t=128; t>=1 && x<width; t=t/2) {
        BOOL white = ((bitmap[i]&0xff)&t);
        int pixel;
        if (white == NO) {
          pixel = 0xffffffff;
        }
        else {
          pixel = 0x000000ff;
        }
        
        if (maskData != NULL) {
          BOOL mask = (((maskData[i]&0xff)&t)!=0);
          if (mask == true) {
            pixel &= 0xffffff00;
          }
        }
        
        *buffer = pixel;
        buffer++;
        x++;
      }
      i++;
    }
    if (i % 4 != 0) {
      i += 4 - (i % 4);
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
