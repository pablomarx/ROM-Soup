//
//  NSString+JSON.h
//  ROM Soup
//
//  Created by Steve White on 12/25/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (JSONAdditions)
- (NSString *)JSONString;
- (id) JSONValue;
@end

@interface NSArray (JSONAdditions)
- (NSString *)JSONString;
@end

@interface NSDictionary (JSONAdditions)
- (NSString *)JSONString;
@end
