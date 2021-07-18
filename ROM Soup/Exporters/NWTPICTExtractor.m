//
//  NWTPICTExtractor.m
//  NEWT
//
//  Created by Steve White on 2/3/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTPICTExtractor.h"

#include "NewtEnv.h"
#include "NewtFns.h"
#include "NewtObj.h"

@implementation NWTPICTExtractor

- (NSData *) dataByUnpackingData:(NSData *)input {
  /*
   * PackBits format info from:
   * http://fileformats.archiveteam.org/wiki/PackBits
   */
  NSMutableData *output = [NSMutableData data];

  const uint8_t *bytes = [input bytes];
  NSUInteger length = [input length];
  NSUInteger offset = 0;
  while (offset < length) {
    uint8_t value = bytes[offset++];
    if (value < 128) {
      // Interpret the next N+1 bytes literally.
      uint8_t count = value + 1;
      for (uint8_t iter=0; iter<count; iter+=1) {
        uint8_t pix = bytes[offset++];
        [output appendBytes:&pix length:1];
      }
    }
    else if (value == 128) {
      NSLog(@"Unexpected Reserved value");
    }
    else {
      // Repeat the next byte 257−N times.
      int8_t count = 257 - value;
      uint8_t pix = bytes[offset++];
      for (uint16_t iter=0; iter<count; iter+=1) {
        [output appendBytes:&pix length:1];
      }
    }
  }
  return output;
}

- (void) enumerateBitsIn:(NSData *)data
                   using:(BOOL(^)(uint8_t bit))block
{
  const uint8_t *bytes = [data bytes];
  NSUInteger length = [data length];

  for (NSUInteger offset=0; offset<length; offset+=1) {
    uint8_t byte = bytes[offset];
    for (int8_t pos=7; pos>=0; pos-=1) {
      uint8_t bit = (byte >> pos) & 1;
      BOOL cont = block(bit);
      if (cont == NO) {
        return;
      }
    }
  }
}

- (NSData *) rgbaDataFromBits:(NSData *)bits
                        width:(uint32_t)width
                     skipping:(uint32_t)inSkip
{
  NSMutableData *result = [NSMutableData dataWithLength:width * 4];
  __block uint32_t *output = [result mutableBytes];
  __block uint32_t offset = 0;
  __block uint32_t skip = inSkip;
  //NSLog(@"skip: %i", skip);

  [self enumerateBitsIn:bits
                  using:^BOOL(uint8_t bit) {
    if (skip > 0) {
      skip -= 1;
      return YES;
    }
    uint32_t rgba = (bit ? 0x00000000 : 0xffffffff);
    output[offset++] = rgba;
    return (offset != width);
  }];

  return result;
}

- (NSData *) pixelDataFromPICT:(NSData *)data
                     imageSize:(CGSize *)imageSize
{
  /*
   * Format information from: Imaging With QuickDraw: Appendix A (Picture Opcodes)
   * https://developer.apple.com/library/archive/documentation/mac/pdf/Imaging_With_QuickDraw/Appendix_A.pdf
   */
  const uint8_t *bytes = [data bytes];
  __block uint32_t offset = 0;

  uint8_t (^read_byte)(void) = ^uint8_t{
    return bytes[offset++];
  };
  uint16_t (^read_word)(void) = ^uint16_t{
    uint16_t r = (bytes[offset] << 8) | bytes[offset+1];
    offset += 2;
    return r;
  };
  CGRect (^read_rect)(void) = ^CGRect{
    CGRect r = CGRectZero;
    // QuickDraw Rect: 8 bytes (top, left, bottom, right: integer)
    r.origin.y = read_word();
    r.origin.x = read_word();
    r.size.height = read_word() - r.origin.y;
    r.size.width = read_word() - r.origin.x;
    return r;
  };

  uint16_t length = read_word();
  if (length != [data length]) {
    NSLog(@"Length mismatch: QuickDraw: %i, data: %i", length, (int)[data length]);
    return nil;
  }

  CGRect picframe = read_rect();

  uint8_t opcode = read_byte();
  if (opcode != 0x11) {
    NSLog(@"expected version opcode, got: %x", opcode);
    return nil;
  }

  uint8_t version = read_byte();
  if (version != 0x01) {
    NSLog(@"unexpected version: %i", version);
    return nil;
  }

  NSMutableData *pixels = nil;
  while (offset < length) {
    opcode = read_byte();
    if (opcode == 0xff) { // OpEndPic
      //NSLog(@"Got OpEndPic, offset=%i, length=%i", offset, length);
      break;
    }
    else if (opcode == 0xa0) { // ShortComment
      read_word();
    }
    else if (opcode == 0x01) { // clipRgn
      uint16_t clipRgnSize = read_word();
      if (clipRgnSize != 10) {
        NSLog(@"expected clipRgnSize 10, got: %i", clipRgnSize);
        return NULL;
      }
      /*CGRect clipRgn =*/ read_rect();
    }
    else if (opcode == 0x98) { // PackBitsRect
      uint16_t rowBytes = read_word();
      CGRect bounds = read_rect();
      CGRect srcRect = read_rect();
      CGRect dstRect = read_rect();
      uint16_t mode = read_word();

      if (mode != 0) {
        NSLog(@"unsupported PackBitsRect mode: %i", mode);
        return nil;
      }
      if (dstRect.size.width != srcRect.size.width) {
        NSLog(@"refusing to proceed due to src/dst width mismatch");
        return nil;
      }
      if (dstRect.size.height != srcRect.size.height) {
        NSLog(@"refusing to proceed due to src/dst height mismatch");
        return nil;
      }
      if (dstRect.size.width != picframe.size.width) {
        NSLog(@"refusing to proceed due to src/pic width mismatch");
        return nil;
      }
      if (dstRect.size.height != picframe.size.height) {
        NSLog(@"refusing to proceed due to src/pic height mismatch");
        return nil;
      }

      if (imageSize != NULL) {
        *imageSize = picframe.size;
      }

      pixels = [NSMutableData data];
      uint16_t height = CGRectGetHeight(picframe);
      uint16_t width = CGRectGetWidth(picframe);
      for (uint32_t y=0; y<height; y+=1) {
        uint16_t byteCount = read_byte();
        if (rowBytes > 250) {
          byteCount = (byteCount << 8) | read_byte();
        }

        NSData *rowData = [NSData dataWithBytes:bytes+offset length:byteCount];
        offset += byteCount;

        NSData *unpacked = [self dataByUnpackingData:rowData];
        NSAssert([unpacked length] == rowBytes, @"unpacker failed");

        NSData *rgba = [self rgbaDataFromBits:unpacked
                                        width:width
                                     skipping:picframe.origin.x - bounds.origin.x];
        NSAssert([rgba length] == width * 4, @"rgba converter failed");
        [pixels appendData:rgba];
      }
    }
    else {
      NSLog(@"unsupported opcode: %02x", opcode);
      return nil;
    }
  }
  return pixels;
}

- (CGImageRef) newImageFromPICTData:(NSData *)pict {
  CGSize imageSize = CGSizeZero;
  NSData *pixels = [self pixelDataFromPICT:pict
                                 imageSize:&imageSize];
  if (pixels == nil) {
    return NULL;
  }

  NSMutableData *bitmap = [pixels mutableCopy];

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate([bitmap mutableBytes],
                                               imageSize.width,
                                               imageSize.height,
                                               8,
                                               4 * imageSize.width,
                                               colorSpace,
                                               kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Host);
  CGImageRef result = CGBitmapContextCreateImage(context);
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);
  return result;
}

- (CGImageRef) newImageRefForPICT:(newtRef)pictRef
                            error:(NSError *__autoreleasing *)error
{
  CGImageRef result = NULL;
  NSData *pictData = [NSData dataWithBytes:NewtRefToData(pictRef)
                                    length:NewtBinaryLength(pictRef)];

  NSPICTImageRep *pictRep = [NSPICTImageRep imageRepWithData:pictData];
  NSRect proposedRect = [pictRep boundingBox];
  if (pictRep != nil && NSIsEmptyRect(proposedRect) == NO) {
    NSGraphicsContext *gc = [NSGraphicsContext currentContext];
    result = [pictRep CGImageForProposedRect:&proposedRect
                                     context:gc
                                       hints:nil];
    if (result != NULL) {
      CGImageRetain(result);
      return result;
    }
  }

  result = [self newImageFromPICTData:pictData];
  if (result != NULL) {
    return result;
  }

  NSImage *image = [NSImage imageNamed:@"badImage"];
  result = [image CGImageForProposedRect:NULL
                                 context:NULL
                                   hints:NULL];
  CGImageRetain(result);
  return result;
}

- (NSData *) pngRepresentationOfPICT:(newtRef)pictRef
                               error:(NSError *__autoreleasing *)error
{
  CGImageRef imageRef = [self newImageRefForPICT:pictRef
                                           error:error];
  if (imageRef == NULL) {
    return nil;
  }
  
  NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
  NSData * pngData = [imageRep representationUsingType: NSBitmapImageFileTypePNG properties: @{}];
  [imageRep release];
  CGImageRelease(imageRef);
  return pngData;
}

@end
