//
//  NWTSoundsViewController.m
//  ROM Soup
//
//  Created by Steve White on 12/27/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTSoundsViewController.h"

#import "NWTObjectEnumerator.h"
#import "NWTSoundsExtractor.h"

#include "NewtFns.h"
#include "NewtObj.h"
#include "NewtType.h"

@implementation NWTSoundsViewController

@synthesize romGlobalVarName = _romGlobalVarName;
@synthesize tableView = _tableView;

- (id) init {
  self = [super init];
  if (self != nil) {
    _sounds = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void) dealloc {
  if (_player != nil) {
    [_player stop];
  }
}

- (NSString *) title {
  return NSLocalizedString(@"Sounds", @"Sounds");
}

- (NSString *) nibName {
  return NSStringFromClass([self class]);
}

- (void) awakeFromNib {
  [super awakeFromNib];

  [self.tableView setDoubleAction:@selector(tableViewRowWasDoubleClicked:)];
  [self.tableView setTarget:self];

  NSDictionary *soundFrames = [NWTObjectEnumerator allFrameDescendantsOfGlobalVarNamed:self.romGlobalVarName
                                                                         withSlotNames:@[@"sndFrameType", @"samples", @"samplingRate", @"compressionType"]];
  
  for (NSNumber *aSoundRef in soundFrames) {
    NSMutableDictionary *soundInfo = [NSMutableDictionary dictionary];
    [soundInfo setObject:aSoundRef forKey:@"itemRef"];
    
    id soundName = [soundFrames objectForKey:aSoundRef];
    if (soundName == [NSNull null]) {
      soundName = NSLocalizedString(@"Unknown", @"Unknown");
    }
    
    [soundInfo setObject:soundName forKey:@"name"];
    newtRef samplesRef = NcGetSlot([aSoundRef unsignedIntegerValue], NSSYM(samples));
    if (samplesRef != kNewtRefNIL) {
      [soundInfo setObject:@( NewtBinaryLength(samplesRef) )
                    forKey:@"length"];
    }
    [_sounds addObject:soundInfo];
  }
  
  NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"name"
                                                             ascending:YES
                                                              selector:@selector(localizedCaseInsensitiveCompare:)];
  [_sounds sortUsingDescriptors:@[nameSort]];
}

- (NSDictionary *) soundInfoAtIndex:(NSUInteger)index {
  return [_sounds objectAtIndex:index];
}

- (NSString *) filenameForSoundInfo:(NSDictionary *)soundInfo {
  return [[soundInfo objectForKey:@"name"] stringByAppendingPathExtension:@"aiff"];
}

- (NSData *) aiffDataForSoundInfo:(NSDictionary *)soundInfo {
  newtRef soundRef = [[soundInfo objectForKey:@"itemRef"] unsignedIntegerValue];
  NWTSoundsExtractor *soundExtractor = [[NWTSoundsExtractor alloc] init];
  NSData *aiffData = [soundExtractor aiffDataFromSoundRef:soundRef
                                                    error:nil];
  return aiffData;
}

- (void) playSoundAtIndex:(NSUInteger)index {
  if (_player != nil) {
    [_player stop];
  }
  
  NSDictionary *soundInfo = [self soundInfoAtIndex:index];
  _player = [[AVAudioPlayer alloc] initWithData:[self aiffDataForSoundInfo:soundInfo]
                                          error:nil];
  _player.delegate = self;
  [_player play];
}

#pragma mark -
#pragma mark NSTableView data source
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [_sounds count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  NSDictionary *soundInfo = [self soundInfoAtIndex:rowIndex];
  id columnValue = [soundInfo valueForKey:[aTableColumn identifier]];
  if ([columnValue isKindOfClass:[NSNumber class]] == YES) {
    return [columnValue stringValue];
  }
  return columnValue;
}

#pragma mark -
#pragma mark
- (IBAction)tableViewRowWasDoubleClicked:(id)sender {
  [self playSoundAtIndex:[self.tableView selectedRow]];
}

- (void) tableViewEnterKeyPressed:(NSTableView *)tableView {
  [self playSoundAtIndex:[self.tableView selectedRow]];
}

- (NSMenu*)tableView:(NSTableView*)aTableView menuForRows:(NSIndexSet*)rows {
  NSMenu *menu = [[NSMenu alloc] initWithTitle:@"menu"];
  [menu setAutoenablesItems:NO];
  
  NSMenuItem *item = nil;
  if ([rows count] > 1) {
    item = [menu addItemWithTitle:NSLocalizedString(@"Save Sounds As...", @"Save Sounds As...")
                           action:@selector(exportSounds:)
                    keyEquivalent:@""];
  }
  else {
    item = [menu addItemWithTitle:NSLocalizedString(@"Save Sound As...", @"Save Sound As...")
                           action:@selector(exportSound:)
                    keyEquivalent:@""];
    
    [item setRepresentedObject: @([rows firstIndex])];
  }
  
  [item setTarget:self];
  return menu;
}

- (IBAction) exportSound:(id)sender {
  if ([sender isKindOfClass:[NSMenuItem class]] == NO) {
    return;
  }
  
  NSDictionary *soundInfo = [self soundInfoAtIndex:[self.tableView selectedRow]];
  
  NSSavePanel *savePanel = [NSSavePanel savePanel];
  [savePanel setCanCreateDirectories:YES];
  [savePanel setTitle:NSLocalizedString(@"Save Sound As...", @"Save Sound As...")];
  [savePanel setNameFieldStringValue:[self filenameForSoundInfo:soundInfo]];
  
  NSInteger result = [savePanel runModal];
  if (result != NSFileHandlingPanelOKButton) {
    return;
  }
  
  NSURL *selectedURL = [savePanel URL];
  if (selectedURL == nil) {
    return;
  }
  
  [[self aiffDataForSoundInfo:soundInfo] writeToURL:selectedURL atomically:YES];
}

- (IBAction) exportSounds:(id)sender {
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  [openPanel setCanChooseFiles:NO];
  [openPanel setCanChooseDirectories:YES];
  [openPanel setCanCreateDirectories:YES];
  [openPanel setResolvesAliases:YES];
  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setTitle:NSLocalizedString(@"Save Sounds to...", @"Save Sounds to...")];
  [openPanel setPrompt:NSLocalizedString(@"Select", @"Select")];
  
  NSInteger result = [openPanel runModal];
  if (result != NSFileHandlingPanelOKButton) {
    return;
  }
  
  NSArray *openURLs = [openPanel URLs];
  if ([openURLs count] != 1) {
    return;
  }
  
  NSString *basePath = [[openURLs lastObject] path];
  
  NSIndexSet *tableViewSelection = [self.tableView selectedRowIndexes];
  [tableViewSelection enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    NSDictionary *soundInfo = [self soundInfoAtIndex:idx];

    NSString *proposedFilename = [self filenameForSoundInfo:soundInfo];
    NSString *extension = [proposedFilename pathExtension];
    NSString *filePath = [basePath stringByAppendingPathComponent:proposedFilename];
    int count=0;
    while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
      NSString *filename = [[proposedFilename stringByDeletingPathExtension] stringByAppendingFormat:@" %i", ++count];
      filePath = [basePath stringByAppendingPathComponent:[filename stringByAppendingPathExtension:extension]];
    }
    
    [[self aiffDataForSoundInfo:soundInfo] writeToFile:filePath atomically:YES];
  }];
}

#pragma mark -
#pragma mark
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  _player = nil;
}

@end
