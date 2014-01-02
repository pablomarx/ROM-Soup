//
//  NWTSoundsExtractor.m
//  NEWT
//
//  Created by Steve White on 2/10/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTSoundsExtractor.h"

#include "NewtEnv.h"
#include "NewtFns.h"
#include "NewtObj.h"
#include "NewtType.h"

@implementation NWTSoundsExtractor

- (NSData *) aiffDataFromSoundRef:(newtRef)soundRef
                            error:(NSError *__autoreleasing *)error
{
  if (NewtRefIsFrame(soundRef) == NO) {
    return nil;
  }

  newtRef samplesRef = NcGetSlot(soundRef, NSSYM(samples));
  if (NewtRefIsNIL(samplesRef) == YES) {
    NSLog(@"no 'samples slot in frame %i", soundRef);
    return nil;
  }
  
  newtRef compressionType = NcGetSlot(soundRef, NSSYM(compressionType));
  if (NewtRefIsNIL(compressionType) == false && NewtRefIsInt30(compressionType) && NewtRefToInt30(compressionType) != 0) {
    NSLog(@"Unsupported compression type: %i", NewtRefToInt30(compressionType));
    return nil;
  }

  /*
   * The sound frame that this function returns has the following slots.
   * sndFrameType
   *        The format of this sound frame. Currently, Newton
   *        sound frames always have the symbol 'simpleSound
   *        in this slot; future Newton devices may store other
   *        values here.
   * samples
   *        A frame of class 'samples containing the binary sound
   *        data. The sound data must have been sampled at 11Khz
   *        or 22KHz
   * samplingRate
   *        A ﬂoating-point value specifying the rate at which the
   *        sample data is to be played back
   * dataType
   *        A code that reﬂects the data type. Currently, the value of
   *        this slot is always 1, indicating 8-bit samples.
   * compressionType
   *        Optional. Integer. Encoding format of samples. If present, 
   *        it must be kSampleStandard (0), kSampleLinear (6), or 
   *        kSampleMuLaw (1). If missing, kSampleStandard is assumed.  
   */
  const uint32_t *rawData = NewtRefToData(samplesRef);
  uint32_t dataLength = NewtLength(samplesRef);
  
  uint8_t aiffHeaderBlob[] = {
    'F', 'O', 'R', 'M',
    0xff, 0xff, 0xff, 0xff, // fileSize - 8
    'A', 'I', 'F', 'C',

    // Version chunk
    'F', 'V', 'E', 'R',
    0x00, 0x00, 0x00, 0x04, // chunk size
    0xA2, 0x80, 0x51, 0x40,

    // Common chunk
    'C', 'O', 'M', 'M',
    0x00, 0x00, 0x00, 0x18, // chunk size
    0x00, 0x01,             // number of channels
    0xff, 0xff, 0xff, 0xff, // number of sample frames
    0x00, 0x08,             // sample size
    // sample rate, extended 80-bit floating-point format
    0x40, 0x0C, 0xAC, 0x44, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,

    'r', 'a', 'w', ' ',
    0x00, 0x00,
    
    // Sound Data Chunk
    'S', 'S', 'N', 'D',
    0xff, 0xff, 0xff, 0xff, // chunk size
    0x00, 0x00, 0x00, 0x00, // offset
    0x00, 0x00, 0x00, 0x00, // block size
  };

  uint32_t fileSize = dataLength + sizeof(aiffHeaderBlob);

  *((uint32_t *)(aiffHeaderBlob +  4)) = htonl(fileSize - 8);
  *((uint32_t *)(aiffHeaderBlob + 34)) = htonl(dataLength);
  *((uint32_t *)(aiffHeaderBlob + 60)) = htonl(dataLength + 8);
  
  NSMutableData *data = [NSMutableData dataWithCapacity:fileSize];
  [data appendBytes:aiffHeaderBlob length:sizeof(aiffHeaderBlob)];
  [data appendBytes:rawData length:dataLength];
  return data;
}

@end
