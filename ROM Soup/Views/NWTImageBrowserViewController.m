//
//  NWTImageBrowserViewController.m
//  ROM Soup
//
//  Created by Steve White on 12/26/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTImageBrowserViewController.h"

#import "NWTBitmapExtractor.h"
#import "NWTImageViewWindowController.h"
#import "NWTPICTExtractor.h"

#include "NewtEnv.h"
#include "NewtErrs.h"
#include "NewtFns.h"
#include "NewtObj.h"
#include "NewtType.h"
#include "NewtVM.h"

#import "NWTObjectEnumerator.h"

@implementation NWTImageBrowserViewController

@synthesize imageBrowser = _imageBrowser;
@synthesize romGlobalVarName = _romGlobalVarName;

- (id) init {
  self = [super init];
  if (self != nil) {
    _images = [[NSMutableArray alloc] init];
    _imageWindows = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *) title {
  return NSLocalizedString(@"Images", @"Images");
}

- (NSString *) nibName {
  return NSStringFromClass([self class]);
}

- (void) awakeFromNib {
  [super awakeFromNib];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(windowWillClose:)
                                               name:NSWindowWillCloseNotification
                                             object:nil];
}

- (void) viewDidAppear {
    [super viewDidAppear];
    if (_firstAppearance == NO) {
        _firstAppearance = YES;
        [self reloadData];
        [self.imageBrowser scrollIndexToVisible:0];
    }
}

- (void) windowWillClose:(NSNotification *)aNotification {
  NSWindowController *controller = [[aNotification object] windowController];
  if (controller != nil) {
    if ([_imageWindows containsObject:controller]) {
      [_imageWindows removeObject:controller];
    }
  }
}

- (void) loadBitmaps {
  /* Would've preferred to use the following, but it doesn't
   * match everything
   */
/*
  NSString *newtScript = @"local f := [];\n" \
  "foreach slot, val deeply in %@ do\n" \
  "  if classof(val) = 'frame and \n" \
  "     val.bits exists and \n" \
  "     val.bounds exists  \n" \
  "   then AddArraySlot(f, val);\n" \
  "f;";
  
  newtErr err = kNErrNone;
  newtRef resultRef = NVMInterpretStr([[NSString stringWithFormat:newtScript, self.romGlobalVarName] UTF8String], &err);
*/

  NSDictionary *bitmaps = [NWTObjectEnumerator allFrameDescendantsOfGlobalVarNamed:self.romGlobalVarName
                                                                     withSlotNames:@[ @"bits", @"bounds" ]];
  NSDictionary *colorBitmaps = [NWTObjectEnumerator allFrameDescendantsOfGlobalVarNamed:self.romGlobalVarName
                                                                          withSlotNames:@[ @"colordata", @"bounds" ]];

  NSMutableDictionary *allImages = [NSMutableDictionary dictionaryWithDictionary:bitmaps];
  [allImages addEntriesFromDictionary:colorBitmaps];
  
  for (NSNumber *aBoxedRef in allImages) {
    newtRef bitmapRef = [aBoxedRef unsignedIntegerValue];
    newtRef bits = NcGetSlot(bitmapRef, NSSYM(bits));
    newtRef colordata = NcGetSlot(bitmapRef, NSSYM(colordata));
    if (NewtRefIsNIL(bits) == YES && NewtRefIsNIL(colordata) == YES) {
      continue;
    }

    NWTImageBrowserItem *item = [[NWTImageBrowserItem alloc] init];
    NSString *imageTitle = [bitmaps objectForKey:aBoxedRef];
    if ((id)imageTitle == [NSNull null]) {
      imageTitle = @"Unknown";
    }
    item.imageTitle = imageTitle;
    item.imageUID = [aBoxedRef stringValue];
    [_images addObject:item];
  }
}

- (void) loadPICTs {
  NSMutableDictionary *picts = [NSMutableDictionary dictionary];
  [NWTObjectEnumerator enumerateGlobalVarNamed:self.romGlobalVarName
                                    usingBlock:^(newtRef parentRef, newtRef keyRef, newtRef valueRef, BOOL *stop) {
                                      if (NewtRefIsBinary(valueRef) == NO || NcClassOf(valueRef) != NSSYM(picture)) {
                                        return;
                                      }

                                      NSNumber *boxedRef = @(valueRef);
                                      id existingValue = [picts objectForKey:boxedRef];
                                      if (existingValue == nil || existingValue == [NSNull null]) {
                                        NSString *name = nil;
                                        if (NewtGetRefType(keyRef, true) == kNewtSymbol || NewtGetRefType(keyRef, true) == kNewtString) {
                                          newtSymDataRef nameData = NewtRefToData(keyRef);
                                          if (nameData->name != NULL) {
                                            name = [NSString stringWithCString:nameData->name
                                                                      encoding:NSUTF8StringEncoding];
                                          }
                                        }
                                        
                                        [picts setObject:name ? name : [NSNull null]
                                                    forKey:@(valueRef)];
                                      }
                                    }];

  for (NSNumber *aBoxedRef in picts) {
    NWTImageBrowserItem *item = [[NWTImageBrowserItem alloc] init];
    NSString *imageTitle = [picts objectForKey:aBoxedRef];
    if ((id)imageTitle == [NSNull null]) {
      imageTitle = @"Unknown";
    }
    item.imageTitle = imageTitle;
    item.imageUID = [aBoxedRef stringValue];
    item.pict = YES;
    [_images addObject:item];
  }
}

- (void) reloadData {
  [_images removeAllObjects];
  
  [self loadBitmaps];
  [self loadPICTs];
  
  NSSortDescriptor *titleSort = [NSSortDescriptor sortDescriptorWithKey:@"imageTitle"
                                                              ascending:YES
                                                               selector:@selector(localizedCaseInsensitiveCompare:)];
  [_images sortUsingDescriptors:@[titleSort]];

  [self.imageBrowser reloadData];
}

- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *) aBrowser {
  return [_images count];
}

- (NWTImageBrowserItem *) imageBrowserItemAtIndex:(NSUInteger)index {
  NWTImageBrowserItem *item = [_images objectAtIndex:index];
  if (item.imageRepresentation == nil) {
    NSData *imageData = nil;
    if (item.pict == YES) {
      NWTPICTExtractor *extractor = [[NWTPICTExtractor alloc] init];
      imageData = [extractor pngRepresentationOfPICT:[item.imageUID integerValue]
                                               error:nil];
    }
    else {
      NWTBitmapExtractor *extractor = [[NWTBitmapExtractor alloc] init];
      imageData = [extractor pngRepresentationOfBitmap:[item.imageUID integerValue]
                                                 error:nil];
    }
    item.imageRepresentation = imageData;
    item.imageRepresentationType = IKImageBrowserNSDataRepresentationType;
  }
  return item;
}

- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index {
  return [self imageBrowserItemAtIndex:index];
}

#if 0
// This doesn't end up working :(
- (NSUInteger) imageBrowser:(IKImageBrowserView *) aBrowser
        writeItemsAtIndexes:(NSIndexSet *) itemIndexes
               toPasteboard:(NSPasteboard *)pasteboard
{
  NSMutableArray *items = [NSMutableArray array];
  [itemIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    NSData *pngData = [[self imageBrowserItemAtIndex:idx] imageRepresentation];

    NSPasteboardItem *anItem = [[[NSPasteboardItem alloc] init] autorelease];
    [anItem setData:pngData
            forType:NSPasteboardTypePNG];
    [items addObject:anItem];
  }];
  [pasteboard clearContents];
  [pasteboard writeObjects:items];
  return [items count];
}
#endif

- (void) imageBrowser:(IKImageBrowserView *) aBrowser cellWasDoubleClickedAtIndex:(NSUInteger) index {
  NWTImageBrowserItem *imageItem = [self imageBrowserItemAtIndex:index];
  NWTImageViewWindowController *imageController = nil;
  for (NWTImageViewWindowController *aController in _imageWindows) {
    if (aController.imageItem == imageItem) {
      imageController = aController;
      break;
    }
  }
  if (imageController == nil) {
    imageController = [[NWTImageViewWindowController alloc] initWithImageItem:imageItem];
    [_imageWindows addObject:imageController];
  }
  [imageController showWindow:self];
}

- (void) imageBrowser:(IKImageBrowserView *) aBrowser cellWasRightClickedAtIndex:(NSUInteger) index withEvent:(NSEvent *) event {
  NSMenu *menu = [[NSMenu alloc] initWithTitle:@"menu"];
  [menu setAutoenablesItems:NO];

  NSMenuItem *item = nil;
  NSIndexSet *browserSelection = [aBrowser selectionIndexes];
  if ([browserSelection containsIndex:index] == YES && [browserSelection count] > 1) {
    item = [menu addItemWithTitle:NSLocalizedString(@"Save Images As...", @"Save Images As...")
                           action:@selector(exportImages:)
                    keyEquivalent:@""];
  }
  else {
    item = [menu addItemWithTitle:NSLocalizedString(@"Save Image As...", @"Save Image As...")
                           action:@selector(exportImage:)
                    keyEquivalent:@""];

    [item setRepresentedObject: [self imageBrowserItemAtIndex:index]];
  }
  
  [item setTarget:self];
  [NSMenu popUpContextMenu:menu withEvent:event forView:aBrowser];
}

- (IBAction) exportImage:(id)sender {
  if ([sender isKindOfClass:[NSMenuItem class]] == NO) {
    return;
  }
  
  NWTImageBrowserItem *item = [sender representedObject];
  
  NSSavePanel *savePanel = [NSSavePanel savePanel];
  [savePanel setCanCreateDirectories:YES];
  [savePanel setTitle:NSLocalizedString(@"Save Image As...", @"Save Image As...")];
  NSString *filename = [item imageTitle];
  if (filename == nil) {
    filename = @"unknown";
  }
  [savePanel setNameFieldStringValue:[filename stringByAppendingPathExtension:@"png"]];
  
  NSInteger result = [savePanel runModal];
  if (result != NSFileHandlingPanelOKButton) {
    return;
  }
  
  NSURL *selectedURL = [savePanel URL];
  if (selectedURL == nil) {
    return;
  }
  
  [item.imageRepresentation writeToURL:selectedURL atomically:YES];
}

- (IBAction) exportImages:(id)sender {
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  [openPanel setCanChooseFiles:NO];
  [openPanel setCanChooseDirectories:YES];
  [openPanel setCanCreateDirectories:YES];
  [openPanel setResolvesAliases:YES];
  [openPanel setAllowsMultipleSelection:NO];
  [openPanel setTitle:NSLocalizedString(@"Save images to...", @"Save images to...")];
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

  NSIndexSet *browserSelection = [self.imageBrowser selectionIndexes];
  [browserSelection enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    NWTImageBrowserItem *item = [self imageBrowserItemAtIndex:idx];

    NSString *imageTitle = [item imageTitle];
    if (imageTitle == nil) {
      imageTitle = @"unknown";
    }

    NSString *fileName = [imageTitle stringByAppendingPathExtension:@"png"];
    NSString *filePath = [basePath stringByAppendingPathComponent:fileName];
    int count=0;
    while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
      fileName = [[imageTitle stringByAppendingFormat:@" %i", ++count] stringByAppendingPathExtension:@"png"];
      filePath = [basePath stringByAppendingPathComponent:fileName];
    }
    
    [item.imageRepresentation writeToFile:filePath
                               atomically:YES];
  }];
}

@end

@implementation NWTImageBrowserItem

@synthesize imageTitle = _imageTitle;
@synthesize imageUID = _imageUID;
@synthesize imageRepresentationType = _imageRepresentationType;
@synthesize imageRepresentation = _imageRepresentation;
@synthesize pict = _pict;

@end
