//
//  NWTSoundsExtractor.h
//  NEWT
//
//  Created by Steve White on 2/10/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "NewtType.h"

@interface NWTSoundsExtractor : NSObject

- (NSData *) aiffDataFromSoundRef:(newtRef)soundRef
                            error:(NSError *__autoreleasing *)error;

@end
