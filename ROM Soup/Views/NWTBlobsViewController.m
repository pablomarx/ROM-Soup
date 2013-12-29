//
//  NWTBlobsViewController.m
//  ROM Soup
//
//  Created by Steve White on 12/28/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTBlobsViewController.h"

#import "NWTHexViewWindowController.h"
#import "NWTObjectEnumerator.h"

#include "NewtErrs.h"
#include "NewtFns.h"
#include "NewtObj.h"
#include "NewtType.h"
#include "NewtVM.h"

@implementation NWTBlobsViewController

@synthesize tableView = _tableView;
@synthesize romGlobalVarName = _romGlobalVarName;

- (id) init {
  self = [super init];
  if (self != nil) {
    _hexWindows = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_hexWindows release];
  [_tableView release];
  [_romGlobalVarName release];
  [_blobs release];
  [super dealloc];
}

- (NSString *) title {
  return NSLocalizedString(@"Blobs", @"Blobs");
}

- (NSString *) nibName {
  return NSStringFromClass([self class]);
}

- (void) awakeFromNib {
  [super awakeFromNib];

  [self.tableView setDoubleAction:@selector(tableViewRowWasDoubleClicked:)];
  [self.tableView setTarget:self];
  
  newtRef bitsRef = NSSYM(bits);
  newtRef maskRef = NSSYM(mask);
  newtRef pictureRef = NSSYM(picture);
  newtRef samplesRef = NSSYM(samples);
  newtRef patternRef = NSSYM(pattern);
  newtRef unicRef = NSSYM(UniC);
  
  NSMutableDictionary *blobData = [NSMutableDictionary dictionary];
  [NWTObjectEnumerator enumerateGlobalVarNamed:self.romGlobalVarName
                                    usingBlock:^(newtRef parentRef, newtRef keyRef, newtRef valueRef, BOOL *stop)
   {
     // We're only interested in binaries
     if (NewtRefIsBinary(valueRef) == false) {
       return;
     }
     
     // Too many things are binaries. We don't want
     // strings, symbols, numbers
     if (NewtRefIsString(valueRef) || NewtRefIsSymbol(valueRef) || NewtRefIsInteger(valueRef) || NewtRefIsReal(valueRef)) {
       return;
     }

     // Nor are we interested in functions
     if (NewtRefIsFunction(parentRef) == true) {
       return;
     }

     newtRef classRef = NcClassOf(valueRef);
     // Bits and pictures and sounds we display elsewhere
     // Patterns we don't display, but should!
     // UniC .. scares me
     if (classRef == bitsRef || classRef == pictureRef || classRef == samplesRef || classRef == maskRef || classRef == patternRef || classRef == unicRef) {
       return;
     }
     
     NWTBlobItem *blobItem = [blobData objectForKey:@(valueRef)];
     if (blobItem == nil) {
       blobItem = [[NWTBlobItem alloc] init];
       blobItem.itemRef = valueRef;
       blobItem.length = NewtBinaryLength(valueRef);
       [blobData setObject:blobItem forKey:@(valueRef)];
       [blobItem release];
     }

     if (blobItem.className == nil) {
       if (NewtRefIsSymbol(classRef)) {
         newtSymDataRef classData = NewtRefToData(classRef);
         blobItem.className = [NSString stringWithCString:classData->name
                                                 encoding:NSUTF8StringEncoding];
       }
     }

     if (blobItem.name == nil) {
       if (NewtRefIsSymbol(keyRef) == true) {
         newtSymDataRef symbolData = NewtRefToData(keyRef);
         blobItem.name = [NSString stringWithCString:symbolData->name
                                            encoding:NSUTF8StringEncoding];
       }
     }
   }];
  
  NSSortDescriptor *classSortDesc = [NSSortDescriptor sortDescriptorWithKey:@"className"
                                                                  ascending:YES
                                                                   selector:@selector(localizedCaseInsensitiveCompare:)];
  _blobs = [[[blobData allValues] sortedArrayUsingDescriptors:@[classSortDesc]] retain];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(windowWillClose:)
                                               name:NSWindowWillCloseNotification
                                             object:nil];
}

- (void) windowWillClose:(NSNotification *)aNotification {
  NSWindowController *controller = [[aNotification object] windowController];
  if (controller != nil) {
    if ([_hexWindows containsObject:controller]) {
      [_hexWindows removeObject:controller];
    }
  }
}

- (NWTBlobItem *) blobItemAtIndex:(NSInteger)index {
  return [_blobs objectAtIndex:index];
}

#pragma mark -
#pragma mark NSTableView data source
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [_blobs count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  NWTBlobItem *blobItem = [self blobItemAtIndex:rowIndex];
  id columnValue = [blobItem valueForKey:[aTableColumn identifier]];
  if ([columnValue isKindOfClass:[NSNumber class]] == YES) {
    return [columnValue stringValue];
  }
  return columnValue;
}

#pragma mark -
#pragma mark
- (IBAction)tableViewRowWasDoubleClicked:(id)sender {
  NWTBlobItem *blobItem = [self blobItemAtIndex:[self.tableView selectedRow]];
  NWTHexViewWindowController *windowController = nil;
  for (NWTHexViewWindowController *aWindowController in _hexWindows) {
    if (aWindowController.blobItem == blobItem) {
      windowController = aWindowController;
      break;
    }
  }
  
  if (windowController == nil) {
    windowController = [[NWTHexViewWindowController alloc] initWithBlobItem:blobItem];
    [_hexWindows addObject:windowController];
    [windowController release];
  }
  
  [windowController showWindow:self];
}

- (NSMenu*)tableView:(NSTableView*)aTableView menuForRows:(NSIndexSet*)rows {
  NSMenu *menu = [[NSMenu alloc] initWithTitle:@"menu"];
  [menu setAutoenablesItems:NO];
  
  NSMenuItem *item = nil;
  if ([rows count] > 1) {
    item = [menu addItemWithTitle:NSLocalizedString(@"Save Blobs As...", @"Save Blobs As...")
                           action:@selector(exportBlobs:)
                    keyEquivalent:@""];
  }
  else {
    item = [menu addItemWithTitle:NSLocalizedString(@"Save Blob As...", @"Save Blob As...")
                           action:@selector(exportBlob:)
                    keyEquivalent:@""];
    
    [item setRepresentedObject: @([rows firstIndex])];
  }
  
  [item setTarget:self];
  return menu;
}

- (NSString *) filenameForBlobItem:(NWTBlobItem *)blobItem {
  NSMutableString *filename = [NSMutableString string];
  if (blobItem.className != nil) {
    [filename appendString:blobItem.className];
  }
  if (blobItem.name != nil) {
    [filename appendString:@")"];
    [filename insertString:@" (" atIndex:0];
    [filename insertString:blobItem.name atIndex:0];
  }
  return [filename stringByAppendingPathExtension:@"bin"];
}

- (IBAction) exportBlob:(id)sender {
  if ([sender isKindOfClass:[NSMenuItem class]] == NO) {
    return;
  }
  
  NWTBlobItem *blobItem = [self blobItemAtIndex:[self.tableView selectedRow]];
  
  NSSavePanel *savePanel = [NSSavePanel savePanel];
  [savePanel setCanCreateDirectories:YES];
  [savePanel setTitle:NSLocalizedString(@"Save Blob As...", @"Save Blob As...")];
  [savePanel setNameFieldStringValue:[self filenameForBlobItem:blobItem]];
  
  NSInteger result = [savePanel runModal];
  if (result != NSFileHandlingPanelOKButton) {
    return;
  }
  
  NSURL *selectedURL = [savePanel URL];
  if (selectedURL == nil) {
    return;
  }
  
  [blobItem.data writeToURL:selectedURL atomically:YES];
}

- (IBAction) exportBlobs:(id)sender {
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  [openPanel setCanChooseFiles:NO];
  [openPanel setCanChooseDirectories:YES];
  [openPanel setCanCreateDirectories:YES];
  [openPanel setResolvesAliases:YES];
  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setTitle:NSLocalizedString(@"Save blobs to...", @"Save blobs to...")];
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
    NWTBlobItem *item = [self blobItemAtIndex:idx];
    NSString *proposedFilename = [self filenameForBlobItem:item];
    NSString *extension = [proposedFilename pathExtension];
    NSString *filePath = [basePath stringByAppendingPathComponent:proposedFilename];
    int count=0;
    while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
      NSString *filename = [[proposedFilename stringByDeletingPathExtension] stringByAppendingFormat:@" %i", ++count];
      filePath = [basePath stringByAppendingPathComponent:[filename stringByAppendingPathExtension:extension]];
    }
    
    [item.data writeToFile:filePath
                atomically:YES];
  }];
}

@end


@implementation NWTBlobItem

@synthesize itemRef = _itemRef;
@synthesize name = _name;
@synthesize className = _className;
@synthesize length = _length;
@dynamic data;

- (void) dealloc {
  [_className release];
  [_name release];
  [super dealloc];
}

- (NSData *) data {
  NSData *data = [NSData dataWithBytes:NewtRefToData(_itemRef)
                                length:NewtBinaryLength(_itemRef)];
  return data;
}

- (NSString *) description {
  NSMutableString *ms = [NSMutableString string];
  [ms appendString:@"<"];
  [ms appendString:NSStringFromClass([self class])];
  [ms appendFormat:@": %p;", self];
  [ms appendFormat:@" itemRef = %i;", self.itemRef];
  [ms appendFormat:@" name = %@;", self.name];
  [ms appendFormat:@" className = %@;", self.className];
  [ms appendFormat:@" length = %i;", self.length];
  [ms appendString:@">"];
  return ms;
}

@end