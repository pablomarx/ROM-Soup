//
//  NWTROMImporter.m
//  NEWT
//
//  Created by Steve White on 4/21/12.
//  Copyright (c) 2012 Steve White. All rights reserved.
//

#import "NWTROMImporter.h"

#include <sys/mman.h>

#include "NewtEnv.h"
#include "NewtFns.h"
#include "NewtGC.h"
#include "NewtNSOF.h"
#include "NewtObj.h"
#include "NewtPkg.h"

#define AIF_HEADER_SIZE 128
#define ROUND_UP(a,b)              (((a) + (b) - 1) & ~((b) - 1))

#define RECORD_TYPE_DATA  0
#define RECORD_TYPE_ARRAY 1
#define RECORD_TYPE_FRAME 3

#define VPUM_TYPE(v)        ((v)&0x03)
#define VPUM_TYPE_VALUE     0
#define VPUM_TYPE_POINTER   1
#define VPUM_TYPE_UNUSUAL   2
#define VPUM_TYPE_MAGIC     3

#define VPUM_TYPE_UNUSUAL_CODEBLOCK  0x032
#define VPUM_TYPE_UNUSUAL_CFUNCTION 0x132

#define VPUM_AS_VALUE(v)    (((long) (v)) >> 2)
#define VPUM_AS_POINTER(v)  ((v) & 0xFFFFFFFC)
#define VPUM_AS_UNICODE(v)  ((unichar) ((v) >> 4))
#define VPUM_AS_MAGIC(v)    ((v) >> 2)

#define VPUM_NIL            0x00000002
#define VPUM_TRUE           0x0000001A
#define VPUM_SYMBOL_CLASS   0x00055552

typedef struct {
	unsigned char size[3];
	unsigned char type;
	unsigned int flags;
	unsigned int class;
} entry_header;


#define DUMP_FRAME_OBJECTS 0

NSString * const NWTROMImporterErrorDomain = @"NWTROMImporterErrorDomain";


@interface NWTROMImporter () 
- (newtRef) newtRefForRecordAtOffset:(uint32_t)offset;
@end

@implementation NWTROMImporter

@synthesize romGlobalVarName = _romGlobalVarName;

- (id) initWithContentsOfFile:(NSString *)romFile
                        error:(NSError *__autoreleasing *)error
{
  self = [super init];
  if (self != nil) {
    _romFp = -1;
    
    BOOL isValidROM = [self _openFile:romFile
                                error:error];
    if (isValidROM == NO) {
      [self release];
      return nil;
    }
    _pointerMap = [[NSMutableDictionary alloc] init];
    _magicPointers = [[NSMutableSet alloc] init];
  }
  return self;
}

- (void) dealloc {
  if (_romImage != NULL) {
    munmap(_romImage, _romSize);
  }
  if (_romFp != -1) {
    close(_romFp);
  }

  [_romPackages release];
  [_pointerMap release];
  [_magicPointers release];
  [_romGlobalVarName release];
  [super dealloc];
}

- (NSArray *) packagesFromRexBlockAtOffset:(uint32_t)offset {
  uint32_t *cursor = (unsigned int *)_romImage + ((offset + 8) / 4);
#if DUMP_REX_BLOCK
  NSLog(@"checksum=0x%08x", htonl(*cursor++));
  NSLog(@"headerVersion=0x%08x", htonl(*cursor++));
  NSLog(@"manufacturer=0x%08x", htonl(*cursor++));
  NSLog(@"version=0x%08x", htonl(*cursor++));
  NSLog(@"length=0x%08x", htonl(*cursor++));
  NSLog(@"id=0x%08x", htonl(*cursor++));
  NSLog(@"start=0x%08x", htonl(*cursor));
#else
  cursor += 6;
#endif
  if (htonl(*cursor) != offset) {
    NSLog(@"Bailing out of RExBlock scan because the start:0x%08x doesn't match the offset:0x%08x", htonl(*cursor), offset);
    return nil;
  }
  cursor++;
  
  NSMutableArray *packages = [NSMutableArray array];
  uint32_t numOfRexBlocks = htonl(*cursor++);
  for (int i=0; i<numOfRexBlocks; i++) {
    uint32_t blockTag = htonl(*cursor++);
    uint32_t blockOffset = htonl(*cursor++);
    uint32_t blockLength = htonl(*cursor++);
#if DUMP_REX_BLOCK
    NSLog(@"RExBlock #%i", i);
    NSLog(@"tag    = %c%c%c%c", (blockTag>>24 & 0xff), (blockTag>>16 & 0xff), (blockTag>>8 & 0xff), (blockTag & 0xff));
    NSLog(@"offset = 0x%08x", blockOffset);
    NSLog(@"length = 0x%08x", blockLength);
#endif
    if (blockTag != 'pkgl') {
      continue;
    }
    
    uint32_t blockEnd = offset + blockOffset + blockLength;
    if (blockEnd > _romSize) {
      NSLog(@"package block ends at 0x%08x, which is outside of rom size:0x%08x", blockEnd, (uint32_t)_romSize);
      continue;
    }
    
    uint32_t pkgOffset = (offset + blockOffset);
    do {
      const char *package = (const char *)(_romImage + pkgOffset);
      if (strncasecmp(package, "package1", 8) != 0 && strncasecmp(package, "package0", 8) != 0) {
        NSLog(@"Didn't find valid package?xxx header at offset: 0x%08x", pkgOffset);
        break;
      }
      
      uint32_t pkgLength = htonl(*((uint32_t *)(_romImage +  pkgOffset + 28)));
      if (pkgOffset + pkgLength > blockEnd) {
        break;
      }
      
      [packages addObject:@{ @"offset" : @(pkgOffset),
                             @"length" : @(pkgLength)}];
      pkgOffset += pkgLength;
    } while (pkgOffset < blockEnd);
  }

  return packages;
}

- (BOOL) _openFile:(NSString *)romFile
             error:(NSError *__autoreleasing *)outError
{
  BOOL success = NO;
  NSError *error = nil;
  
	_romFp = open([romFile fileSystemRepresentation], 0666);
  
  if (_romFp == -1) {
    error = [NSError errorWithDomain:NWTROMImporterErrorDomain
                                code:0
                            userInfo:@{ NSLocalizedFailureReasonErrorKey : @"Couldn't open the file",
                                        NSLocalizedDescriptionKey        : [NSString stringWithCString:strerror(errno)
                                                                                              encoding:NSUTF8StringEncoding],
                                        }];
    goto out;
  }
  
	_romSize = (size_t)lseek(_romFp, 0, SEEK_END);
	lseek(_romFp, 0, SEEK_SET);
	_romImage = mmap(0, _romSize, PROT_READ | PROT_WRITE, MAP_SHARED, _romFp, 0);
  
	uint32_t *cursor = (unsigned int *)_romImage;
  
  //
  // Does this file start with an AIF header?
  //
  if (htonl(*cursor) == 0xE1A00000) { // NOP, aka mov r0, r0
    if (htonl(*(cursor + 16)) == 0xE1A00000) { // NOP, aka mov r0, r0
      // fReadOnlySize + fReadWriteSize + fDebugSize + AIF_HEADER_SIZE
      if (htonl(*(cursor + 5)) + htonl(*(cursor + 6)) + htonl(*(cursor + 7)) + AIF_HEADER_SIZE == _romSize) {
        _addressOffset = AIF_HEADER_SIZE;
      }
    }
  }
  
  //
  // Check for the expected DataAreaTable
  //
  if (htonl(*(cursor + ((_addressOffset + 0x40) / 4))) != 'data') {
    if (_addressOffset != 0x00) {
      NSLog(@"image appeared to be AIF, couldn't find DataAreaTable, trying as a flat image");
      _addressOffset = 0x0;
    }
    
    if (htonl(*(cursor + ((_addressOffset + 0x40) / 4))) != 'data') {
      error = [NSError errorWithDomain:NWTROMImporterErrorDomain
                                  code:0
                              userInfo:@{ NSLocalizedFailureReasonErrorKey : @"Couldn't find expected DataAreaTable",
                                          NSLocalizedDescriptionKey        : [NSString stringWithFormat:@"Expected word at offset 0x%08x to equal 'data'", _addressOffset + 0x40],
                                          }];
      goto out;
    }
  }
  
  _dataEnd = htonl(*(cursor + ((_addressOffset + 0x44) / 4)));
  if (_dataEnd > _romSize) {
    error = [NSError errorWithDomain:NWTROMImporterErrorDomain
                                code:0
                            userInfo:@{ NSLocalizedFailureReasonErrorKey : @"Word after DataAreaTable exceeds file length",
                                        NSLocalizedDescriptionKey        : [NSString stringWithFormat:@"dataEnd=0x%08x, romSize=0x%08x", _dataEnd, (uint32_t)_romSize],
                                        }];
    goto out;
  }
  
  //
  // Figure out ROM versions / etc
  //
  uint32_t romManufacturer = htonl(*(cursor + ((_addressOffset + 0x13f0) / 4)));
  // Apple, Sharp, Motorola
  if (romManufacturer == 0x01000000 || romManufacturer == 0x01000100 || romManufacturer == 0x01000200) {
//    uint32_t hardwareType = htonl(*(cursor + ((_addressOffset + 0x13ec) / 4)));
    _romVersion = htonl(*(cursor + ((_addressOffset + 0x13dc) / 4)));
  }
  else if (romManufacturer == 1) {
    uint32_t oldCheckSumC = htonl(*(cursor + ((_addressOffset + 0x13e4) / 4)));
    uint32_t oldCheckSumD = htonl(*(cursor + ((_addressOffset + 0x13e8) / 4)));
    if (oldCheckSumC == 0x00000000 || oldCheckSumC == 0xffffffff || oldCheckSumD == 0x00000000 || oldCheckSumD == 0xffffffff) {
      error = [NSError errorWithDomain:NWTROMImporterErrorDomain
                                  code:0
                              userInfo:@{ NSLocalizedFailureReasonErrorKey : @"Couldn't determine the manufacturer",
                                          NSLocalizedDescriptionKey        : [NSString stringWithFormat:@"Word at offset 0x%08x was: 0x%08x", _addressOffset + 0x13f0, romManufacturer],
                                          }];
      goto out;
    }
    _romVersion = romManufacturer;
  }
  else {
    error = [NSError errorWithDomain:NWTROMImporterErrorDomain
                                code:0
                            userInfo:@{ NSLocalizedFailureReasonErrorKey : @"Couldn't determine the manufacturer",
                                        NSLocalizedDescriptionKey        : [NSString stringWithFormat:@"Word at offset 0x%08x was: 0x%08x", _addressOffset + 0x13f0, romManufacturer],
                                        }];
    goto out;
  }
  
  _romMajor = (_romVersion >> 16);
  if (_romMajor != 2 && _romMajor != 1 && _romVersion != 0x06290000 && _romVersion != 0x00000001 /*Notepad 1.0b1 image*/) {
    error = [NSError errorWithDomain:NWTROMImporterErrorDomain
                                code:0
                            userInfo:@{ NSLocalizedFailureReasonErrorKey : @"Unsupported ROM Version",
                                        NSLocalizedDescriptionKey        : [NSString stringWithFormat:@"ROM Version 0x%08x is not supported", _romVersion],
                                        }];
    goto out;
  }
  
  if (_romMajor != 2) {
    _romMajor = 1; // fix the J1 & 1.0b1 images
  }
  
  //
  // Find soup start/end markers
  //
  unsigned char *haystack = _romImage;
  const char *needle = "Uriah Strings";
  size_t needleLength = strlen(needle);
  uint32_t offset = 0;
  do {
    haystack = memchr(haystack, needle[0], _romSize - offset);
    if (haystack == NULL) {
      break;
    }

    offset = (haystack - _romImage);
    if (bcmp((const char *)haystack, needle, needleLength) != 0) {
      haystack++;
      continue;
    }
    
    offset = ROUND_UP(offset + needleLength, 4);
    cursor = (unsigned int *)_romImage + (offset / 4);
    _soupStart = htonl(*cursor++);
    _soupEnd = htonl(*cursor);
    break;
  }
  while (offset < _romSize - needleLength);
  NSLog(@"_soupStart=0x%08x, _soupEnd=0x%08x", _soupStart, _soupEnd);
  
  if (_soupStart == 0 || _soupEnd == 0) {
    error = [NSError errorWithDomain:NWTROMImporterErrorDomain
                                code:0
                            userInfo:@{ NSLocalizedFailureReasonErrorKey : @"Couldn't find soup start or end markers",
                                        NSLocalizedDescriptionKey        : @"This means we failed to find 'Uriah Strings' in the file",
                                        }];
    goto out;
  }
  else if (_soupStart == _soupEnd) {
    error = [NSError errorWithDomain:NWTROMImporterErrorDomain
                                code:0
                            userInfo:@{ NSLocalizedFailureReasonErrorKey : @"Invalid soup start or end markers",
                                        NSLocalizedDescriptionKey        : @"This means my assumption about 'Uriah Strings' wasn't the best",
                                        }];
    goto out;
  }
  else if (_soupStart > _romSize || _soupEnd > _romSize) {
    error = [NSError errorWithDomain:NWTROMImporterErrorDomain
                                code:0
                            userInfo:@{ NSLocalizedFailureReasonErrorKey : @"Soup start or end markers exceed file's length",
                                        NSLocalizedDescriptionKey        : [NSString stringWithFormat:@"Soup start was: 0x%08x, Soup end was: 0x%08x, romSize is: 0x%08x", _soupStart, _soupEnd, (uint32_t)_romSize],
                                        }];
    goto out;
  }
  
  if (_romMajor == 2) {
    //
    // Find RExBlock
    //
    unsigned char *haystack = _romImage;
    const char *needle = "RExBlock";
    size_t needleLength = strlen(needle);
    uint32_t offset = 0;
    do {
      haystack = memchr(haystack, needle[0], _romSize - offset - needleLength);
      if (haystack == NULL) {
        break;
      }
      offset = (haystack - _romImage);
      
      if (bcmp((const char *)haystack, needle, needleLength) != 0) {
        haystack++;
        continue;
      }
      
      if (offset % 4 != 0 || *((uint32_t *)(haystack -  4)) != 0) {
        haystack += needleLength;
        continue;
      }
      
      NSLog(@"Found a RExBlock at 0x%08x", offset);
      _romPackages = [[self packagesFromRexBlockAtOffset:offset] retain];
      break;
    } while (offset < _romSize - needleLength);
    
  }
  
  success = YES;
  
  out:
  if (error != nil) {
    NSLog(@"An error occurred: %@", error);
    if (outError != nil) {
      *outError = error;
    }
  }
  return success;
}

#pragma mark -
#pragma mark
- (newtRef) newtRefForVPUM:(uint32_t)vpum {
  if (vpum == 0) {
    return NewtMakeInteger(0);
  }

  newtRef value = kNewtUnknownType;
  switch(VPUM_TYPE(vpum)) {
    case VPUM_TYPE_MAGIC:
      value = NewtMakeMagicPointer(0, VPUM_AS_MAGIC(vpum));
      [_magicPointers addObject:@(VPUM_AS_MAGIC(vpum))];
      break;
    case VPUM_TYPE_POINTER:
    {
      int offset = VPUM_AS_POINTER(vpum);
      value = [self newtRefForRecordAtOffset:offset];
    }
      break;
    case VPUM_TYPE_UNUSUAL:
      if (vpum == VPUM_NIL) {
        value = kNewtRefNIL;
      }
      else if (vpum == VPUM_TRUE) {
        value = kNewtRefTRUE;
      }
      else if ((vpum & 0xf) == 6){
        value = NewtMakeCharacter(vpum >> 4);
      }
      else {
        if (_romMajor != 2 || (vpum != VPUM_TYPE_UNUSUAL_CODEBLOCK && vpum != VPUM_TYPE_UNUSUAL_CFUNCTION)) {
          NSLog(@"BAD vpum=0x%08x", vpum);
        }
      }
      break;
    case VPUM_TYPE_VALUE:
      value = NewtMakeInteger(VPUM_AS_VALUE(vpum));
      break;
    default:
      NSAssert1(NO, @"Unhandled vpum type: %i", VPUM_TYPE(vpum));
  }
  return value;
}

- (NSArray *) frameKeysForArrayRecordAtOffset:(uint32_t)offset
                                        class:(newtRef *)outClass
{
    uint8_t *cursor = _romImage + offset + _addressOffset;

  entry_header header;
  int headerSize = sizeof(header);
  
  memcpy(&header, cursor, headerSize);
  
  cursor += headerSize;
  
  int recordSize = (header.size[0] << 16) | (header.size[1] << 8) | header.size[2];
  if (recordSize == 0) {
    return 0;
  }
  
  header.flags = htonl(header.flags);
  header.class = htonl(header.class);
  if (outClass != NULL) {
    *outClass = header.class;
  }
  
  int dataType = (header.type & 3);
  int dataFormat = (header.type >> 4);
  NSAssert2(dataType == RECORD_TYPE_ARRAY && (dataFormat == 0x4 || (_romMajor == 2 && dataFormat == 0xc)), @"Unexpected header type 0x%02x at offset 0x%08x", header.type, offset);
  
  NSMutableArray *results = [NSMutableArray array];
  
  int blobSize = recordSize - headerSize;
  int arrayLength = blobSize / 4;
  
  unsigned int hash = (cursor[0] << 24) | (cursor[1] << 16) | (cursor[2] << 8) | cursor[3];
  int type = VPUM_TYPE(hash);
  if (type == VPUM_TYPE_POINTER) {
    [results addObjectsFromArray:[self frameKeysForArrayRecordAtOffset:VPUM_AS_POINTER(hash)
                                                                 class:NULL]];
  }
  else if (type == VPUM_TYPE_VALUE && type != VPUM_NIL) {
    NSLog(@"%s: value as the first entry: %i", __PRETTY_FUNCTION__, (int)VPUM_AS_VALUE(type));
  }
  cursor += 4;
  
  for (int i=1; i<arrayLength; i++) {
    uint32_t hash = (cursor[0] << 24) | (cursor[1] << 16) | (cursor[2] << 8) | cursor[3];
    newtRef entry = [self newtRefForVPUM:hash];
    [results addObject:@(entry)];
    cursor += 4;
  }

  return results;
}

- (void) recordNewtRef:(newtRef)result
             forOffset:(uint32_t)offset
{
  [_pointerMap setObject:@(result)
                  forKey:@(offset)];
}

- (newtRef) newtRefForRecordAtOffset:(uint32_t)offset {
  NSNumber *mapped = [_pointerMap objectForKey:@(offset)];
  if (mapped != nil) {
    return (newtRef)[mapped unsignedLongValue];
  }
  
  uint8_t *cursor = _romImage + offset + _addressOffset;
  
  entry_header header;
  int headerSize = sizeof(header);

  memcpy(&header, cursor, headerSize);

  cursor += headerSize;
  
  int recordSize = (header.size[0] << 16) | (header.size[1] << 8) | header.size[2];
  if (recordSize == 0) {
    //NSAssert1(recordSize > 0, @"Invalid 0 length record at offset 0x%08x", offset);
    NSLog(@"bad record size!");
    return 0;
  }
  
  header.flags = htonl(header.flags);
  header.class = htonl(header.class);

  int headerClassType = VPUM_TYPE(header.class);
  
  int blobSize = recordSize - headerSize;

  newtRef result = kNewtUnknownType;
  int dataType = (header.type & 0xf);
  if (dataType != RECORD_TYPE_DATA && dataType != RECORD_TYPE_ARRAY && dataType != RECORD_TYPE_FRAME) {
    NSLog(@"Unexpected data type %i from header value: 0x%02x", dataType, header.type);
    return 0;
  }

  int dataFormat = (header.type >> 4);
  if (dataFormat !=4 && (_romMajor != 2 || dataFormat != 0xc)) {
    NSLog(@"Unexpected data format %i from header value: 0x%02x", dataType, header.type);
    return 0;
  }
  
  if (dataType == RECORD_TYPE_DATA) {
    if (header.class == _romStringSymbol) {
      NSString *unicodeStr = (NSString *)CFStringCreateWithBytes(NULL, cursor, blobSize-1, kCFStringEncodingUTF16BE, false);
        if (unicodeStr == nil) {
            result = NewtMakeInteger(-1);
            NSLog(@"Failed to make unicode string");
        }
        else {
            result = NewtMakeString([unicodeStr UTF8String], false);
            CFRelease(unicodeStr);

            _stats.strings++;
            [self recordNewtRef:result
                      forOffset:offset];
        }
    }
    else if (header.class == _romInstructionsSymbol) {
      result = NewtMakeBinary(NSSYM0(instructions), cursor, blobSize + 1, false);
      _stats.codeBlocks++;
      [self recordNewtRef:result
                forOffset:offset];
    }
    else if (header.class==VPUM_SYMBOL_CLASS) {
      // Compensation for symbol's hash entry
      cursor  += 4;
      //headerSize += 4;

      // strncasecmp as 2.0 uses 'string', 1.0 uses 'String'
      if (_romStringSymbol == 0 && strncasecmp((const char *)cursor, "String", 7) == 0) {
        _romStringSymbol = offset | VPUM_TYPE_POINTER;
      }
      else if (_romInstructionsSymbol == 0 && strncmp((const char *)cursor, "instructions", 13) == 0) {
        _romInstructionsSymbol = offset | VPUM_TYPE_POINTER;
      }
      
      result = NewtMakeSymbol((const char *)cursor);
      _stats.symbols++;
      [self recordNewtRef:result
                forOffset:offset];

      newtSymDataRef symbolRef = NewtRefToData(result);
      NSAssert2(strcasecmp((const char *)cursor, symbolRef->name)==0, @"cursor %s != symbolRef->name %s", cursor, symbolRef->name);
    }
    else if (headerClassType == VPUM_TYPE_POINTER) {
      newtRef dataClass = [self newtRefForRecordAtOffset:VPUM_AS_POINTER(header.class)];
      result = NewtMakeBinary(dataClass, cursor, blobSize, false);
      [self recordNewtRef:result
                forOffset:offset];
      _stats.data++;
    }
    else {
      NSAssert(NO, @"Unhandled data class type");
    }
  }
  else if (dataType == RECORD_TYPE_ARRAY) {
    _stats.arrays++;
    
    int arrayLength = blobSize / 4;

    // Magic pointer table??
    if (offset == 0x003bbcc0) { // XXX: J1 Armistice Image hack
      result = newt_env.magic_pointers;
    }
    else {
      newtRef dataClass = [self newtRefForVPUM:header.class];
      result = NewtMakeArray(dataClass, arrayLength);
      [self recordNewtRef:result
                forOffset:offset];
    }
    
    for (int i=0; i<arrayLength; i++, cursor+=4) {
      uint32_t vpum = (cursor[0] << 24) | (cursor[1] << 16) | (cursor[2] << 8) | cursor[3];

      newtRef slotEntry = [self newtRefForVPUM:vpum];
      if (offset == 0x003bbcc0) {
        NcAddArraySlot(result, slotEntry);
      }
      else {
        NewtSlotsSetSlot(result, i, slotEntry);
      }
    }
    
    if (offset != 0x003bbcc0) { // J1 armistice hack
      NSAssert2(arrayLength == NewtLength(result), @"arrayLength %i != NewtLength %i", arrayLength, NewtLength(result));
    }
    else {
      NSLog(@"Magic Pointers length: %i", NewtLength(result));
    }
  }
  else if (dataType == RECORD_TYPE_FRAME) {
    _stats.frames++;
    
    if (headerClassType != VPUM_TYPE_POINTER) {
      NSAssert(NO, @"Expected a pointer for a frame header class type");
    }

    int frameLength = blobSize / 4;
    
    newtRef frameKeysClass = kNewtUnknownType;
    int frameKeysOffset = VPUM_AS_POINTER(header.class);
    NSArray *frameKeys = [self frameKeysForArrayRecordAtOffset:frameKeysOffset
                                                         class:&frameKeysClass];

    BOOL frameLengthAssertion = YES;
    if (NewtRefIsInteger(frameKeysClass)) {
/*
      int classValue = NewtRefToInteger(frameKeysClass);
      if (classValue == 1) {
        result = newt_env.global_fns;
        frameLengthAssertion = NO;
      }
*/
      result = NsMakeFrame(kNewtRefUnbind);
    }
    else {
      result = NsMakeFrame(frameKeysClass);
    }
    [self recordNewtRef:result
              forOffset:offset];
    
    NSAssert2([frameKeys count] == frameLength, @"frameKeys count %i != frameLength %i", [frameKeys count], frameLength);
    
    for (int i=0; i<frameLength; cursor+=4, i+=1) {
      uint32_t vpum = (cursor[0] << 24) | (cursor[1] << 16) | (cursor[2] << 8) | cursor[3];
      newtRef frameKey = [[frameKeys objectAtIndex:i] unsignedLongValue];
      newtRef frameValue = [self newtRefForVPUM:vpum];
      if (frameValue == kNewtUnknownType) {
        if (_romMajor == 2) {
          if (vpum == VPUM_TYPE_UNUSUAL_CODEBLOCK) {
            frameValue = NSSYM(CodeBlock);
          }
          else if (vpum == VPUM_TYPE_UNUSUAL_CFUNCTION) {
            frameValue = NSSYM(CFunction);
          }
        }
      }
      
      if (NewtRefIsNIL(frameValue)) {
        frameValue = kNewtRefUnbind;
      }
      
      NsSetSlot(kNewtRefUnbind, result, frameKey, frameValue);
    }
    
    if (frameLengthAssertion == YES) {
      NSAssert2(frameLength == NewtLength(result), @"frameLength %i != NewtLength %i", frameLength, NewtLength(result));
    }
  }
  else {
    //NSAssert1(NO, @"unhandled header type: 0x%08x", header.type);
    NSLog(@"unhandled header type: 0x%08x", header.type);
  }
  if (result == kNewtUnknownType) {
    NSLog(@"unknown type at offset 0x%08x", offset);
  }
  
  //NSLog(@"offset 0x%08x, result 0x%08x", offset, result);
  return result;
}

- (void) dumpStats {
  NSLog(@"frames:%i, arrays:%i, symbols:%i, data:%i, strings:%i, codeBlocks:%i, magicPointers:%i", _stats.frames, _stats.arrays, _stats.symbols, _stats.data, _stats.strings, _stats.codeBlocks, [_magicPointers count]);
}

- (void) import {
  newtRef romObjects = NewtMakeArray(kNewtRefUnbind, 0);
  newtRef packagesRef = kNewtUnknownType;
  if (_romGlobalVarName != nil) {
    if ([_romPackages count] > 0) {
      newtRef romFrame = NsMakeFrame(kNewtRefUnbind);
      packagesRef = NewtMakeArray(kNewtRefUnbind, 0);
      
      NcSetSlot(romFrame, NSSYM(romSoup), romObjects);
      NcSetSlot(romFrame, NSSYM(packages), packagesRef);
      NcSetSlot(newt_env.globals, NewtMakeSymbol([_romGlobalVarName UTF8String]), romFrame);
    }
    else {
      NcSetSlot(newt_env.globals, NewtMakeSymbol([_romGlobalVarName UTF8String]), romObjects);
    }
  }

  newtRef ref;
  int tocObjects = 0, tocFrames = 0, tocSymbols = 0;
  int tocEntries = 0;

  uint32_t offset = _soupEnd + _addressOffset + 4;
  NSLog(@"Starting import at offset: 0x%08x", offset);

  uint32_t *cursor = (uint8_t *)(_romImage + offset);
  uint32_t lastPointer = 0;
  
  while(offset < _dataEnd) {
    int vpum = htonl(cursor[0]);
    if (vpum >> 24 != 0x00) {
      NSLog(@"Bailing due to vpum: 0x%08x", vpum);
      break;
    }
    
    switch (VPUM_TYPE(vpum)) {
      case VPUM_TYPE_POINTER:
        tocObjects++;
        // Notepad 1.0b1 seems to repeat items...
        if (lastPointer != VPUM_AS_POINTER(vpum)) {
          ref = [self newtRefForRecordAtOffset:VPUM_AS_POINTER(vpum)];
          lastPointer = VPUM_AS_POINTER(vpum);

          if (ref == 0) {
            NSLog(@"offset 0x%08x returned 0", offset);
          }
          else {
            if (NewtGetRefType(ref, true) != kNewtSymbol) {
              NcAddArraySlot(romObjects, ref);
            }
            
            if (NewtGetRefType(ref, true) == kNewtFrame) {
              tocFrames++;
            }
            else if (NewtGetRefType(ref, true) == kNewtSymbol) {
              tocSymbols++;
            }
          }
        }
        break;
      case VPUM_TYPE_MAGIC:
        //NSLog(@"Skipping MAGIC value");
        break;
      case VPUM_TYPE_UNUSUAL:
        NSLog(@"Skipping UNUSUAL value at offset: 0x%08x", offset);
        break;
      case VPUM_TYPE_VALUE:
        if (vpum != offset - 4) {
          // This holds true for the 1.3 and J1 images, but not
          // the 1.0b1 image
//          NSLog(@"Expected VALUE 0x%08x at offset: 0x%08x to be: 0x%08x", vpum, offset, offset - 4);
        }
        //NSLog(@"Skipping VALUE value at offset: 0x%08x", offset);
        break;
      default:
        NSLog(@"unknown vpum type: %i (%i) at offset: 0x%08x", VPUM_TYPE(vpum), vpum, offset);
        break;
    }

    cursor += 1;
    tocEntries += 1;
    offset = (uint8_t *)cursor - _romImage;
  }

  NSLog(@"Finished import at 0x%08x! tocEntries=%i, tocObjects=%i, tocFrames=%i, tocSymbols=%i", offset, tocEntries, tocObjects, tocFrames, tocSymbols);
  [self dumpStats];
#if 0
    // XXX: Fixme NEWT0/modern does not contain NewtReadPkgWithOffset
  if ([_romPackages count] > 0) {
    for (int i=0; i<[_romPackages count]; i++) {
      NSDictionary *aRomPackage = [_romPackages objectAtIndex:i];
      uint32_t offset = [[aRomPackage objectForKey:@"offset"] unsignedIntValue];
      uint32_t length = [[aRomPackage objectForKey:@"length"] unsignedIntValue];
      newtRef result = NewtReadPkgWithOffset((_romImage + offset), offset, length);
      NcAddArraySlot(packagesRef, result);
    }
  }
#endif
}

@end
