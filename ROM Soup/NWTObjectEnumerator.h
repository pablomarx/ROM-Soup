//
//  NWTObjectEnumerator.h
//  ROM Soup
//
//  Created by Steve White on 12/26/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "NewtEnv.h"
#include "NewtType.h"

@interface NWTObjectEnumerator : NSObject

+ (void) enumerateNewtRef:(newtRef)newtRef usingBlock:(void (^)(newtRef parentRef, newtRef keyRef, newtRef valueRef, BOOL *stop))block;
+ (void) enumerateGlobalVarNamed:(NSString *)globalVarName usingBlock:(void (^)(newtRef parentRef, newtRef keyRef, newtRef valueRef, BOOL *stop))block;

+ (void) enumerateFrameDescendantsOfGlobalVarNamed:(NSString *)globalVarName
                             withRequiredSlotNames:(NSArray *)requiredSlotNames
                                 optionalSlotNames:(NSArray *)optionalSlotNames
                                        usingBlock:(void (^)(newtRef parentRef, newtRef keyRef, newtRef valueRef, BOOL *stop))block;

+ (NSDictionary *) allFrameDescendantsOfGlobalVarNamed:(NSString *)globalVarName
                                 withRequiredSlotNames:(NSArray *)requiredSlotNames
                                     optionalSlotNames:(NSArray *)optionalSlotNames;

@end
