//
//  NWTPICTExtractor.h
//  NEWT
//
//  Created by Steve White on 2/3/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "NewtType.h"

@interface NWTPICTExtractor : NSObject

- (CGImageRef) newImageRefForPICT:(newtRef)pictRef
                            error:(NSError *__autoreleasing *)error;
- (NSData *) pngRepresentationOfPICT:(newtRef)pictRef
                               error:(NSError *__autoreleasing *)error;

@end
