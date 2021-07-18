//
//  NSString+JSON.m
//  ROM Soup
//
//  Created by Steve White on 12/25/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NSString+JSON.h"

@implementation NSString (JSONAdditions)

- (NSString *)JSONString {
  NSArray *stringArray = [NSArray arrayWithObject:self];
  NSString *jsonString = [stringArray JSONString];
  NSString *result = [jsonString substringWithRange:NSMakeRange(1, jsonString.length-2)];
  return result;
}

- (id) JSONValue {
  NSError *jsonError = nil;
  id result = [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding]
                                              options:NSJSONReadingAllowFragments
                                                error:&jsonError];
  if (result == nil) {
    NSLog(@"JSONStringWithOptions: returned error:%@", jsonError);
  }
  return result;
}

@end

@implementation NSArray (JSONAdditions)

- (NSString *)JSONString {
  NSError *jsonError = nil;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                     options:0
                                                       error:&jsonError];
  if (jsonData == nil) {
    NSLog(@"JSONStringWithOptions: returned error:%@", jsonError);
  }
  
  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end

@implementation NSDictionary (JSONAdditions)
- (NSString *)JSONString {
  NSError *jsonError = nil;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                     options:0
                                                       error:&jsonError];
  if (jsonData == nil) {
    NSLog(@"JSONStringWithOptions: returned error:%@", jsonError);
  }
  
  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
