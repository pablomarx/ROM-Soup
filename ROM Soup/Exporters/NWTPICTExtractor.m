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

- (CGImageRef) imageRefForPICT:(newtRef)pictRef
                         error:(NSError *__autoreleasing *)error
{
  NSData *pictData = [NSData dataWithBytes:NewtRefToData(pictRef)
                                    length:NewtBinaryLength(pictRef)];

  NSPICTImageRep *pictRep = [NSPICTImageRep imageRepWithData:pictData];
  NSGraphicsContext *gc = [NSGraphicsContext currentContext];
  NSRect proposedRect = [pictRep boundingBox];
  return [pictRep CGImageForProposedRect:&proposedRect
                                 context:gc
                                   hints:nil];
}

- (NSData *) pngRepresentationOfPICT:(newtRef)pictRef
                               error:(NSError *__autoreleasing *)error
{
  CGImageRef imageRef = [self imageRefForPICT:pictRef
                                        error:error];
  if (imageRef == NULL) {
    return nil;
  }
  
  NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
  NSData * pngData = [imageRep representationUsingType: NSPNGFileType properties: nil];
  [imageRep release];
  return pngData;
}

@end
