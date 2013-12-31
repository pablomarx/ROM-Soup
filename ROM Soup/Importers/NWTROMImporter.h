//
//  NWTROMImporter.h
//  NEWT
//
//  Created by Steve White on 1/27/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const NWTROMImporterErrorDomain;

@interface NWTROMImporter : NSObject {
  NSMutableDictionary *_pointerMap;
  NSMutableSet *_magicPointers;
  NSString *_romGlobalVarName;
  
  unsigned char *_romImage;
  int _romFp;
  size_t _romSize;
  
  struct {
    int symbols;
    int frames;
    int arrays;
    int data;
    int strings;
    int codeBlocks;
  } _stats;
  
  uint32_t _romStringSymbol;
  uint32_t _romInstructionsSymbol;
  uint32_t _romCFunctionSymbol;
  uint32_t _romFunctionSymbol;
  uint32_t _romCodeBlockSymbol;
  
  uint32_t _soupStart;
  uint32_t _soupEnd;
  uint32_t _dataEnd;
  uint32_t _addressOffset;
  uint32_t _romVersion;
  uint8_t _romMajor;
}

@property (strong, atomic) NSString *romGlobalVarName;

- (id) initWithContentsOfFile:(NSString *)romFile
                        error:(NSError *__autoreleasing *)error;

- (void) import;

@end
