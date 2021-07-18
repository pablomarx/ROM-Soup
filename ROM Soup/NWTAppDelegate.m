//
//  NWTAppDelegate.m
//  ROM Soup
//
//  Created by Steve White on 12/25/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTAppDelegate.h"

#import "NWTDefsImporter.h"

#include "NewtEnv.h"
#include "NewtFns.h"
#include "NewtObj.h"
#include "NewtPkg.h"
#include "NewtVM.h"

@implementation NWTAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  NewtInit(0, NULL, 0);
	NEWT_INDENT = -2;
  NEWT_DEBUG = 1;

  [self importNTKDefinitions];
  [self loadViewFrame];
}

- (void) importNTKDefinitions {
  NWTDefsImporter *defsImporter = [[NWTDefsImporter alloc] init];
  [defsImporter importNTKDefsFile:[[NSBundle mainBundle] pathForResource:@"MessagePad Defs" ofType:@""]];
}

- (void) loadViewFrame {
  NSBundle *bundle = [NSBundle mainBundle];
  NVMInterpretStr("global EnsureInternal(obj) begin return obj; end;\
                  global vars := {extras: []};\
                  vars.vars := vars;\
                  global Notify(obj) begin end;\
                  GetRoot().Notify := func(a,b,c) begin end;\
                  ", NULL);
  
  NSString *viewFrame = [bundle pathForResource:@"ViewFrame" ofType:@"pkg"];
  NSData *packageData = [NSData dataWithContentsOfFile:viewFrame];
  newtRef result = NewtReadPkg((unsigned char *)[packageData bytes], [packageData length]);
  if (NewtRefIsNIL(result) == YES) {
    NSLog(@"NewtReadPkg() failed to read: %@", viewFrame);
    return;
  }
  
  NsSetSlot(kNewtRefNIL, newt_env.globals, NSSYM(ViewFramePackage), result);
  NVMInterpretStr("global routing:=ViewFramePackage.parts[0].data;\
                  routing:InstallScript(routing);\
                  GetRoot().|ViewFrame:JRH| := routing.theForm;\
                  RemoveSlot(GetGlobals(), 'routing);\
                  RemoveSlot(GetGlobals(), 'ViewFramePackage);\
                  ", NULL);

  
  NSString *viewFrameDecompiler = [bundle pathForResource:@"VF+Function" ofType:@"pkg"];
  packageData = [NSData dataWithContentsOfFile:viewFrameDecompiler];
  result = NewtReadPkg((unsigned char *)[packageData bytes], [packageData length]);
  if (NewtRefIsNIL(result) == YES) {
    NSLog(@"NewtReadPkg() failed to read: %@", viewFrameDecompiler);
    return;
  }
  
  NsSetSlot(kNewtRefNIL, newt_env.globals, NSSYM(VFFunctionPackage), result);
  NVMInterpretStr(
                  "global routing:=VFFunctionPackage.parts[0].data;\
                  routing:InstallScript(routing);\
                  global decompiler:=|ViewFrame:JRH|.|VF+Function:JRH|[0].DisplayObject.literals[4];\
                  print(decompiler:nosemi(\"If you can see this, things are sort of working!;\") & \"\\n\");\
                  RemoveSlot(GetGlobals(), 'routing);\
                  RemoveSlot(GetGlobals(), 'VFFunctionPackage);\
                  ", NULL);
  
  NSString *initScript = [NSString stringWithContentsOfFile:[bundle pathForResource:@"ViewFrame-init" ofType:@"ns"]
                                               usedEncoding:NULL
                                                      error:NULL];
  NVMInterpretStr([initScript UTF8String], NULL);
}

@end
