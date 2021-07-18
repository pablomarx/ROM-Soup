//
//  NWTConsoleBackend.m
//  ROM Soup
//
//  Created by Steve White on 12/24/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTConsoleBackend.h"
#import "NSString+JSON.h"

#include "NewtEnv.h"
#include "NewtErrs.h"
#include "NewtFns.h"
#include "NewtObj.h"
#include "NewtVM.h"

#define USE_DECOMPILER TARGET_CPU_X86

@implementation NWTConsoleBackend

/* This method is called by the WebView when it is deciding what
 methods on this object can be called by JavaScript.  The method
 should return NO the methods we would like to be able to call from
 JavaScript, and YES for all of the methods that cannot be called
 from JavaScript.
 */
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
  return NO;
}

/* This method is called by the WebView to decide what instance
 variables should be shared with JavaScript.  The method should
 return NO for all of the instance variables that should be shared
 between JavaScript and Objective-C, and YES for all others.
 */
+ (BOOL)isKeyExcludedFromWebScript:(const char *)property {
  return NO;
}

/* This method converts a selector value into the name we'll be using
 to refer to it in JavaScript.  here, we are providing the following
 Objective-C to JavaScript name mappings:
 'doOutputToLog:' => 'log'
 'changeJavaScriptText:' => 'setscript'
 With these mappings in place, a JavaScript call to 'console.log' will
 call through to the doOutputToLog: Objective-C method, and a JavaScript call
 to console.setscript will call through to the changeJavaScriptText:
 Objective-C method.
 
 Comments for the webScriptNameForSelector: method in WebScriptObject.h talk more
 about the default name conversions performed from Objective-C to JavaScript names.
 You can overrride those defaults by providing your own translations in your
 webScriptNameForSelector: method.
 */
+ (NSString *) webScriptNameForSelector:(SEL)sel {
  return nil;
}

#pragma mark -
#pragma mark
- (NSString *) descriptionForNewtRef:(newtRef)ref {
  int refType = NewtGetRefType(ref, YES);
  
  newtRef classRef = NcClassOf(ref);
  newtSymDataRef classData = kNewtUnknownType;
  if (NewtRefIsSymbol(classRef)) {
    classData = NewtRefToData(classRef);
  }
  
  switch(refType) {
    case kNewtUnknownType:
      return [NSString stringWithFormat:@"Unknown <0x%08x>", ref];
    case kNewtPointer:
      return [NSString stringWithFormat:@"Pointer <0x%08x>", ref];
    case kNewtCharacter:
      //return [NSString stringWithFormat:@"Character <%@>", [NSString stringWithCharacters:NewtRefToCharacter(ref) length:1]];
      return [NSString stringWithFormat:@"Character <0x%08x>", ref];
    case kNewtSpecial:
      return [NSString stringWithFormat:@"Special <0x%08x>", ref];
    case kNewtNil:
      return [NSString stringWithFormat:@"NIL"];
    case kNewtTrue:
      return [NSString stringWithFormat:@"TRUE"];
    case kNewtUnbind:
      return [NSString stringWithFormat:@"#UNBIND"];
    case kNewtMagicPointer: {
      newtRef resolvedRef = NcResolveMagicPointer(ref);
      if (NewtRefIsMagicPointer(resolvedRef) == NO) {
        return [NSString stringWithFormat:@"@%d <%@>", NewtMPToIndex(ref), [self descriptionForNewtRef:resolvedRef]];
      }
      else {
        return [NSString stringWithFormat:@"@%d", NewtMPToIndex(ref)];
      }
    }
    case kNewtBinary: {
      NSMutableString *result = [NSMutableString stringWithString:@"Binary"];
      if (classRef != kNewtUnknownType) {
        [result appendFormat:@", class \"%s\"", classData->name];
      }
      [result appendFormat:@", length %i", NewtBinaryLength(ref)];
      return result;
    }
    case kNewtArray: {
      NSMutableString *result = [NSMutableString stringWithString:@"Array"];
      if (classRef != kNewtUnknownType && classData != NULL) {
        [result appendFormat:@", class \"%s\"", classData->name];
      }
      [result appendFormat:@", length %i", NewtLength(ref)];
      return result;
    }

    case kNewtFrame: {
      NSMutableString *result = [NSMutableString string];
      if (NewtRefIsCodeBlock(ref)) {
        int numArgs = NewtRefToInteger(NcGetSlot(ref, NSSYM0(numArgs)));
        newtRef indefinite = NcGetSlot(ref, NSSYM0(indefinite));
        char *indefiniteStr = "";
        if (NewtRefIsNotNIL(indefinite))
          indefiniteStr = "...";
        
        [result appendFormat:@"function, %d arg(s)%s #%08x", numArgs, indefiniteStr, ref];
      }
      else {
        [result appendString:@"Frame"];
        if (classData != NULL && classRef != kNewtUnknownType && classRef != kNewtObjFrame) {
          [result appendFormat:@", class \"%s\"", classData->name];
        }
        [result appendFormat:@", length %i", NewtLength(ref)];
      }
      return result;
    }
    case kNewtInt62:
    case kNewtInt64:
      return [@(NewtRefToInteger(ref)) stringValue];
    case kNewtReal:
      return [@(NewtRefToReal(ref)) stringValue];
    case kNewtSymbol: {
      newtSymDataRef symbolRef = NewtRefToData(ref);
      return [NSString stringWithFormat:@"'%s", symbolRef->name];
    }
    case kNewtString:
      return [[NSString stringWithCString:NewtRefToString(ref)
                                 encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
  }
  return nil;
}

- (NSDictionary *) remoteObjectRepresentationOfNewtRef:(newtRef)ref {
  int refType = NewtGetRefType(ref, YES);
  if (refType == kNewtMagicPointer) {
    ref = NcResolveMagicPointer(ref);
    refType = NewtGetRefType(ref, YES);
  }

  NSString *type = nil;
  NSString *description = [self descriptionForNewtRef:ref];
  BOOL hasChildren = NO;
  
  switch(refType) {
    case kNewtUnknownType:
    case kNewtPointer:
    case kNewtCharacter:
    case kNewtSpecial:
    case kNewtNil:
    case kNewtTrue:
    case kNewtUnbind:
      type = @"unknown";
      break;
    case kNewtMagicPointer:
      type = @"magic";
      break;
    case kNewtBinary:
      type = @"binary";
      break;
    case kNewtArray:
      hasChildren = (NewtLength(ref) > 0);
      // This is a lie, but I don't like how WebKit inspector
      // represents arrays :(
      type = @"object";
      break;
    case kNewtFrame:
      hasChildren = (NewtLength(ref) > 0);
      type = @"object";
      break;
    case kNewtInt62:
    case kNewtInt64:
    case kNewtReal:
      type = @"number";
      break;
    case kNewtSymbol:
      type = @"symbol";
      break;
    case kNewtString:
      type = @"string";
      break;
  }

#if USE_DECOMPILER
  if (NewtRefIsFunction(ref) == YES) {
    newtRef decompiler = NcGetSlot(NcGetGlobals(), NSSYM(decompiler));
    if (NewtRefIsNotNIL(decompiler)) {
      newtRef decompiledString = NcSend(decompiler, NSSYM(decompile), false, 1, ref);
      if (NewtRefIsString(decompiledString) == true) {
        description = [[NSString stringWithCString:NewtRefToString(decompiledString)
                                   encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
        type = @"string";
      }
      else {
        NSLog(@"Decompiler failed. Returned %i (type %i)", decompiledString, NewtGetRefType(decompiledString, true));
      }
    }
  }
#endif
  
  NSDictionary *remoteObject = @{ @"objectId"    : @(ref),
                                  @"hasChildren" : @(hasChildren),
                                  @"description" : description ? description : @"unknown",
                                  @"type"        : type ? type : @"unknown",
                                };
  return remoteObject;
}

- (NSString *) evaluate:(NSString *)expression
            objectGroup:(NSString *)objectGroup
  includeCommandLineAPI:(BOOL)includeCommandLineAPI
{
  newtErr err = kNErrNone;
  NSString *tryBlock = [NSString stringWithFormat:@"global cli() begin %@ end; try cli(); onexception |evt.ex| do return CurrentException();", expression];
  
  newtRef resultRef = NVMInterpretStr([tryBlock UTF8String], &err);
  if (err == kNErrNone) {
    NSString *result = [[self remoteObjectRepresentationOfNewtRef:resultRef] JSONString];
    return result;
  }
  // Would've preferred to use the following, but the resultRef is always nil :(
#if 0
  newtRef functionRef = NsCompile(kNewtRefUnbind, NewtMakeString([expression UTF8String], false));
  if (functionRef == kNewtNil) {
    NSLog(@"1");
  }
  else {
    newtRef resultRef = NsApply(kNewtRefUnbind, functionRef, kNewtRefNIL);
    NSString *result = [[self remoteObjectRepresentationOfNewtRef:resultRef] JSONString];
    NSLog(@"result=%@", result);
    return result;
  }
#endif
  return nil;
}

- (NSString *) propertiesForObjectWithId:(NSNumber *)objectId
                  ignoringHasOwnProperty:(BOOL)ignoreHasOwnProperty
                              abbreviate:(BOOL)abbreviate
{
  newtRef itemRef = [objectId unsignedIntegerValue];
  int refType = NewtGetRefType(itemRef, YES);
  if (refType != kNewtFrame && refType != kNewtArray) {
    return nil;
  }

  NSMutableArray *slots = [NSMutableArray array];
  int length = NewtLength(itemRef);
  for (int i=0; i<length; i++) {
    NSString *name = nil;
    if (refType == kNewtArray) {
      name = [@(i) stringValue];
    }
    else {
      newtRef frameKey = NewtGetFrameKey(itemRef, i);
      newtSymDataRef frameKeyRef = NewtRefToData(frameKey);
      name = [NSString stringWithCString:frameKeyRef->name encoding:NSUTF8StringEncoding];
    }
    
    newtRef slotRef = NewtGetArraySlot(itemRef, i);
    
    NSDictionary *remoteObject = [self remoteObjectRepresentationOfNewtRef:slotRef];
    NSDictionary *slot = @{ @"name"  : name,
                            @"value" : remoteObject,
                            };
    [slots addObject:slot];
  }
  
  NSString *result = [slots JSONString];
  return result;
}

- (NSString *) setValue:(id)value forKey:(NSString *)key ofPropertyWithId:(id)propertyId {
  return @"false";
}

- (NSString *) completionsForExpression:(NSString *)expression
                  includeCommandLineAPI:(BOOL)includeCommandLineAPI
{
  return @"";
}


@end

