//
//  NWTDefsImporter.m
//  NEWT
//
//  Created by Steve White on 2/8/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTDefsImporter.h"
#include "NewtEnv.h"
#include "NewtFns.h"
#include "NewtObj.h"

@implementation NWTDefsImporter

- (void) importNTKDefsFile:(NSString *)file { 
  NSString *contents = [NSString stringWithContentsOfFile:file
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
  NSArray *lines = [contents componentsSeparatedByString:@"\n"];
  NSError *error = NULL;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^/\\* constant \\*/ (.*) := @([0-9]*);"
                                                                         options:NSRegularExpressionCaseInsensitive
                                                                           error:&error];

  int defsParsed = 0;
  for (NSString *aLine in lines) {
    NSArray *matches = [regex matchesInString:aLine
                                      options:0
                                        range:NSMakeRange(0, [aLine length])];
    if ([matches count] != 1) {
      continue;
    }
    
    defsParsed++;
    NSTextCheckingResult *result = [matches lastObject];
    NSString *name = [aLine substringWithRange:[result rangeAtIndex:1]];
    NSString *magic = [aLine substringWithRange:[result rangeAtIndex:2]];

    newtRef magicPointerRef = NewtMakeMagicPointer(0, [magic integerValue]);
    newtRef resolvedRef = NcResolveMagicPointer(magicPointerRef);
    newtRef nameRef = NewtMakeSymbol([name UTF8String]);
    
    NsSetSlot(kNewtRefNIL, newt_env.named_mps, nameRef, resolvedRef);
  }
  
  NSLog(@"Imported %i NTK definitions", defsParsed);
}

@end
