//
//  NWTBitmapExtractor.h
//  NEWT
//
//  Created by Steve White on 2/2/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "NewtType.h"

@interface NWTBitmapExtractor : NSObject

- (CGImageRef) newImageRefForBitmap:(newtRef)bitmapRef
                              error:(NSError *__autoreleasing *)error;
- (NSData *) pngRepresentationOfBitmap:(newtRef)bitmapRef
                                 error:(NSError *__autoreleasing *)error;

@end
