//
//  StorageManager.h
//  EasyLocalize
//
//  Created by Sebastian Husche on 05.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

@import Cocoa;

#import "LocalizableProject.h"
#import "LocalizableFile.h"
#import "LocalizationEntry.h"
#import "LocalizedString.h"
#import "Language.h"

static NSString * const kLocalizationEntriesDidChangeNotification = @"kLocalizaationEntriesDidChange";
static NSString * const kLocalizableFilesDidChangeNotification = @"kLocalizableFilesDidChange";
static NSString * const kSelectedLocalizableFilesDidChangeNotification = @"kSelectedLocalizableFilesDidChange";

@interface StorageManager : NSObject

@property(nonatomic, readonly) NSManagedObjectContext *mainUIContext;

@property(nonatomic, readonly) NSArray *localizationEntries;
@property(nonatomic, readonly) NSArray *localizableFiles;
@property(nonatomic, readonly) NSArray *selectedLocalizableFiles;

@property(nonatomic, readonly) NSArray *availableLanguages;
@property(nonatomic, readonly) NSArray *selectedLanguages;
@property(nonatomic, readonly) Language *sourceLanguage;
@property(nonatomic, readonly) NSArray *availableTargetLanguages;
@property(nonatomic, readonly) NSArray *selectedTargetLanguages;

- (instancetype)initWithError:(NSError **)error;

- (BOOL)importXLIFFDocument:(NSXMLDocument *)xliffDocument error:(NSError **)outError;

- (NSManagedObjectContext *)newChildContext;

@end
