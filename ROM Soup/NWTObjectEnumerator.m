//
//  NWTObjectEnumerator.m
//  ROM Soup
//
//  Created by Steve White on 12/26/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTObjectEnumerator.h"

#include "NewtErrs.h"
#include "NewtFns.h"
#include "NewtObj.h"
#include "NewtType.h"
#include "NewtVM.h"

@implementation NWTObjectEnumerator

+ (BOOL) enumerateNewtRef:(newtRef)itemRef
               usingBlock:(void (^)(newtRef parentRef, newtRef keyRef, newtRef valueRef, BOOL *stop))block
              visitedRefs:(NSMutableSet *)visitedRefs
{
  NSNumber *boxedRef = [NSNumber numberWithUnsignedInteger:itemRef];
  if ([visitedRefs containsObject:boxedRef] == YES) {
    return YES;
  }
  
  BOOL shouldContinue = YES;
  [visitedRefs addObject:boxedRef];
  
  int refType = NewtGetRefType(itemRef, YES);
  if (refType != kNewtArray && refType != kNewtFrame) {
    goto out;
  }
  
  int length = NewtLength(itemRef);
  for (int i=0; i<length; i++) {
    newtRef keyRef;
    if (refType == kNewtArray) {
      keyRef = NewtMakeInt32(i);
    }
    else {
      keyRef = NewtGetFrameKey(itemRef, i);
    }
    
    newtRef valueRef = NewtGetArraySlot(itemRef, i);
    BOOL stop = NO;
    block(itemRef, keyRef, valueRef, &stop);
    if (stop == YES) {
      shouldContinue = NO;
      goto out;
    }
    
    int valueType = NewtGetRefType(valueRef, YES);
    if (valueType == kNewtArray || valueType == kNewtFrame) {
      shouldContinue = [[self class] enumerateNewtRef:valueRef usingBlock:block visitedRefs:visitedRefs];
      if (shouldContinue == NO) {
        goto out;
      }
    }
  }
  out:
  return shouldContinue;
}

+ (void) enumerateNewtRef:(newtRef)itemRef usingBlock:(void (^)(newtRef parentRef, newtRef keyRef, newtRef valueRef, BOOL *stop))block {
  NSMutableSet *visitedRefs = [NSMutableSet set];
  [self enumerateNewtRef:itemRef
              usingBlock:block
             visitedRefs:visitedRefs];
}

+ (void) enumerateGlobalVarNamed:(NSString *)globalVarName usingBlock:(void (^)(newtRef parentRef, newtRef keyRef, newtRef valueRef, BOOL *stop))block {
  if (globalVarName == nil) {
    return;
  }
  
  newtRef romRef = NcGetSlot(newt_env.globals, NewtMakeSymbol([globalVarName UTF8String]));
  [[self class] enumerateNewtRef:romRef usingBlock:block];
}

+ (void) enumerateFrameDescendantsOfGlobalVarNamed:(NSString *)globalVarName
                             withRequiredSlotNames:(NSArray *)requiredSlotNames
                                 optionalSlotNames:(NSArray *)optionalSlotNames
                                        usingBlock:(void (^)(newtRef parentRef, newtRef keyRef, newtRef valueRef, BOOL *stop))block
{
  int minSlotLength = [requiredSlotNames count];
  int maxSlotLength = [requiredSlotNames count] + [optionalSlotNames count];
  NSMutableArray *allSlotNames = [NSMutableArray arrayWithArray:requiredSlotNames];
  if (optionalSlotNames != nil) {
    [allSlotNames addObjectsFromArray:optionalSlotNames];
  }
  
  [NWTObjectEnumerator enumerateGlobalVarNamed:globalVarName
                                    usingBlock:^(newtRef parentRef, newtRef keyRef, newtRef valueRef, BOOL *stop)
  {
    int valueType = NewtGetRefType(valueRef, YES);
    if (valueType != kNewtFrame) {
      return;
    }
    
    int matches = 0;
    int valueLength = NewtLength(valueRef);
    if (valueLength > maxSlotLength || valueLength < minSlotLength) {
      return;
    }
    
    for (int i=0; i<valueLength; i++) {
      newtRef nameRef = NewtGetFrameKey(valueRef, i);
      newtSymDataRef classData = NewtRefToData(nameRef);
      for (NSString *aSlotName in allSlotNames) {
        if (strcasecmp([aSlotName UTF8String], classData->name) == 0) {
          matches++;
          break;
        }
      }
    }
    
    if (matches >= [requiredSlotNames count]) {
      block(parentRef, keyRef, valueRef, stop);
    }
  }];
  
}

+ (NSDictionary *) allFrameDescendantsOfGlobalVarNamed:(NSString *)globalVarName
                                 withRequiredSlotNames:(NSArray *)requiredSlotNames
                                     optionalSlotNames:(NSArray *)optionalSlotNames
{
  NSMutableDictionary *results = [NSMutableDictionary dictionary];
  
  [[self class] enumerateFrameDescendantsOfGlobalVarNamed:globalVarName
                                    withRequiredSlotNames:requiredSlotNames
                                        optionalSlotNames:optionalSlotNames
                                               usingBlock:^(newtRef parentRef, newtRef keyRef, newtRef valueRef, BOOL *stop)
   {
     NSNumber *boxedRef = @(valueRef);
     id existingValue = [results objectForKey:boxedRef];
     if (existingValue == nil || existingValue == [NSNull null]) {
       NSString *name = nil;
       if (NewtGetRefType(keyRef, true) == kNewtSymbol || NewtGetRefType(keyRef, true) == kNewtString) {
         newtSymDataRef nameData = NewtRefToData(keyRef);
         if (nameData->name != NULL) {
           name = [NSString stringWithCString:nameData->name
                                     encoding:NSUTF8StringEncoding];
         }
       }
       
       [results setObject:name ? name : [NSNull null]
                   forKey:@(valueRef)];
     }
   }];
  
  
  return [NSDictionary dictionaryWithDictionary:results];
}

@end
