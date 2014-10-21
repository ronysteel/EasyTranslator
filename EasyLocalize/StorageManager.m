//
//  StorageManager.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 05.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "StorageManager.h"
#import "Errors.h"
#import "FetchResultsController.h"

@interface StorageManager () <FetchResultsControllerDelegate>

@property(nonatomic, strong) NSManagedObjectContext *workContext;
@property(nonatomic, strong) NSManagedObjectContext *mainUIContext;
@property(nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property(nonatomic, strong) NSPersistentStoreCoordinator *storeCoordinator;
@property(nonatomic, readonly) NSURL *persistentStoreURL;

@property(nonatomic, strong) FetchResultsController *localizableFilesFetchController;
@property(nonatomic, strong) FetchResultsController *selectedFilesFetchController;
@property(nonatomic, strong) FetchResultsController *localizationEntriesFetchController;

@property(nonatomic, readonly) NSPredicate *fulltextSearchPredicate;
@property(nonatomic, strong) NSArray *objectIDsFromSearchResults;
@property(nonatomic, assign) NSInteger numActiveSearches;

@end

@implementation StorageManager
@synthesize persistentStoreURL = _persistentStoreURL;
@synthesize fulltextSearchPredicate = _fulltextSearchPredicate;

#pragma mark - Init and Dealloc

- (instancetype)initWithError:(NSError **)error {
    self = [super init];
    if (self) {
        _fulltextSearchMode = FulltextSearchModeContains;
        _fulltextSearchOptions = FulltextSearchOptionCaseInsensitive | FulltextSearchOptionDiacriticInsensitive;
        
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        if (_managedObjectModel) {
            _storeCoordinator
            = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
            if (_storeCoordinator) {
                
                NSPersistentStore *store = [_storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                               configuration:nil
                                                                                         URL:self.persistentStoreURL
                                                                                     options:nil
                                                                                       error:error];
                
                //                NSPersistentStore *store = [self.storeCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                //                                                                               configuration:nil
                //                                                                                         URL:nil
                //                                                                                     options:nil
                //                                                                                       error:error];
                if (!store) {
                    if (error) {
                        *error = errorWithCode(EasyLocalizeStorageInternalError, YES);
                    }
                    return nil;
                }
                
                _mainUIContext
                = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                
                _mainUIContext.persistentStoreCoordinator = _storeCoordinator;
                _mainUIContext.undoManager = [[NSUndoManager alloc] init];
                
                _workContext = [self newChildContext];
                
            } else {
                if (error) {
                    *error = errorWithCode(EasyLocalizeStorageInternalError, YES);
                }
                return nil;
            }
        } else {
            if (error) {
                *error = errorWithCode(EasyLocalizeStorageNoMOMDError, YES);
            }
            return nil;
        }
        
        _localizationEntriesFetchController = [FetchResultsController new];
        
        NSArray *sortDescriptors = @[
                                     [NSSortDescriptor sortDescriptorWithKey:@"localizableFile.original" ascending:YES],
                                     [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]
                                     ];
        
        _localizationEntriesFetchController.entityName = @"LocalizationEntry";
        
        _localizationEntriesFetchController.fetchPredicate
        = [NSPredicate predicateWithFormat:@"localizableFile.selected = YES"];
        
        _localizationEntriesFetchController.sortDescriptors = sortDescriptors;
        _localizationEntriesFetchController.managedObjectContext = _mainUIContext;
        _localizationEntriesFetchController.delegate = self;
        [_localizationEntriesFetchController fetch:nil];
        
        
        _localizableFilesFetchController = [FetchResultsController new];
        
        sortDescriptors = @[
                            [NSSortDescriptor sortDescriptorWithKey:@"original" ascending:YES],
                            ];
        
        _localizableFilesFetchController.entityName = @"LocalizableFile";
        _localizableFilesFetchController.sortDescriptors = sortDescriptors;
        _localizableFilesFetchController.managedObjectContext = _mainUIContext;
        _localizableFilesFetchController.delegate = self;
        [_localizableFilesFetchController fetch:nil];
        
        
        _selectedFilesFetchController = [FetchResultsController new];
        
        sortDescriptors = @[
                            [NSSortDescriptor sortDescriptorWithKey:@"original" ascending:YES],
                            ];
        
        _selectedFilesFetchController.entityName = @"LocalizableFile";
        _selectedFilesFetchController.fetchPredicate = [NSPredicate predicateWithFormat:@"selected = YES"];
        _selectedFilesFetchController.sortDescriptors = sortDescriptors;
        _selectedFilesFetchController.managedObjectContext = _mainUIContext;
        _selectedFilesFetchController.delegate = self;
        [_selectedFilesFetchController fetch:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextWillSave:)
                                                     name:NSManagedObjectContextWillSaveNotification
                                                   object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSFileManager defaultManager] removeItemAtURL:self.persistentStoreURL error:nil];
    
}


#pragma mark - Computed properties

- (NSURL *)persistentStoreURL {
    if (!_persistentStoreURL) {
        NSURL *appSupportURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                                      inDomain:NSUserDomainMask
                                                             appropriateForURL:nil
                                                                        create:YES
                                                                         error:nil];
        
        _persistentStoreURL = [appSupportURL URLByAppendingPathComponent:[NSString stringWithFormat:@"db_%@",
                                                                          [NSUUID UUID].UUIDString]];
        
    }
    return _persistentStoreURL;
}

- (NSArray *)localizationEntries {
    if (self.fulltextSearchstring.length == 0) {
        return self.localizationEntriesFetchController.arrangedObjects;
    } else {
        NSArray *results = [self.localizationEntriesFetchController.arrangedObjects copy];
        return [results filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"objectID IN %@", self.objectIDsFromSearchResults]];
    }
}

- (NSArray *)localizableFiles {
    return self.localizableFilesFetchController.arrangedObjects;
}

- (NSArray *)selectedLocalizableFiles {
    return self.selectedFilesFetchController.arrangedObjects;
}

- (void)setFulltextSearchMode:(FulltextSearchMode)fulltextSearchMode {
    if (_fulltextSearchMode != fulltextSearchMode) {
        _fulltextSearchMode = fulltextSearchMode;
        _fulltextSearchPredicate = nil;
        [self performSearchIfNeeded];
    }
}

- (void)setFulltextSearchOptions:(FulltextSearchOptions)fulltextSearchOptions {
    if (_fulltextSearchOptions != fulltextSearchOptions) {
        _fulltextSearchOptions = fulltextSearchOptions;
        _fulltextSearchPredicate = nil;
        [self performSearchIfNeeded];
    }
}

- (void)setFulltextSearchstring:(NSString *)fulltextSearchstring {
    if (![_fulltextSearchstring isEqualToString:fulltextSearchstring]) {
        _fulltextSearchstring = [fulltextSearchstring copy];
        _fulltextSearchPredicate = nil;
        [self performSearchIfNeeded];
    }
}

- (NSPredicate *)fulltextSearchPredicate {
    if (!self.fulltextSearchstring.length) {
        return nil;
    }
    
    if (!_fulltextSearchPredicate) {
        NSString *modeString;
        switch (self.fulltextSearchMode) {
            case FulltextSearchModeBegins:
                modeString = @"BEGINSWITH";
                break;
            case FulltextSearchModeEnds:
                modeString = @"ENDSWITH";
                break;
            default:
                modeString = @"CONTAINS";
                break;
        }
        
        NSString *optionsString = @"";
        
        if (self.fulltextSearchOptions & FulltextSearchOptionCaseInsensitive) {
            optionsString = [optionsString stringByAppendingString:@"c"];
        }
        
        if (self.fulltextSearchOptions & FulltextSearchOptionDiacriticInsensitive) {
            optionsString = [optionsString stringByAppendingString:@"d"];
        }
        
        if (optionsString.length > 0) {
            modeString = [modeString stringByAppendingFormat:@"[%@]", optionsString];
        }
        
        NSString *predicateString
        = [NSString stringWithFormat:@"identifier %@ '%@' OR note %@ '%@' OR ANY localizedStrings.translatedString %@ '%@'",
           modeString,
           self.fulltextSearchstring,
           modeString,
           self.fulltextSearchstring,
           modeString,
           self.fulltextSearchstring
           ];

        _fulltextSearchPredicate = [NSPredicate predicateWithFormat:predicateString];
    }
    return _fulltextSearchPredicate;
}


- (void)performSearchIfNeeded {
    NSManagedObjectContext *searchContext = [self newChildContext];
    NSPredicate *predicate = self.fulltextSearchPredicate;
    if (!predicate) {
        if (self.objectIDsFromSearchResults) {
            self.objectIDsFromSearchResults = nil;
            [self controllerDidChangeContents:self.localizationEntriesFetchController];
        }
        return;
    }
    
    self.numActiveSearches ++;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [searchContext performBlock:^{
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"LocalizationEntry"];
            fetchRequest.resultType = NSManagedObjectIDResultType;
            fetchRequest.predicate = predicate;
            NSError *error = nil;
            NSArray *objectIDs = [searchContext executeFetchRequest:fetchRequest error:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!objectIDs) {
                    NSLog(@"Error while searching: %@", error.localizedDescription);
                }
                self.objectIDsFromSearchResults = [objectIDs copy];
                [self controllerDidChangeContents:self.localizationEntriesFetchController];
                self.numActiveSearches --;
            });
        }];
    });
}


#pragma mark - Import

- (BOOL)importXLIFFDocument:(NSXMLDocument *)xliffDocument error:(NSError **)outError {
    
    if (!xliffDocument) {
        if (outError) {
            *outError = errorWithCode(EasyLocalizeFileNotReadError, YES);
        }
        return NO;
    }
    
    NSManagedObjectContext *context = self.workContext;
    
    __block BOOL success;
    __block NSError *error;
    [context performBlockAndWait:^{
        
        NSUndoManager *undoManager = context.undoManager;
        [context.undoManager disableUndoRegistration];
        
        LocalizableProject *project = [LocalizableProject localizableProjectWithElement:xliffDocument.rootElement
                                                                 inManagedObjectContext:context];
        
        if (!project) {
            error = errorWithCode(EasyLocalizeStorageInternalError, YES);
            return;
        }
        
        NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"Language"];
        NSArray *languages = [context executeFetchRequest:fr error:nil];
        Language *sourceLanguage = languages.firstObject;
        
        NSArray *fileElements = [xliffDocument.rootElement elementsForName:@"file"];
        if (fileElements.count == 0) {
            error = errorWithCode(EasyLocalizeFileInvalidError, YES);
            [context reset];
            success = NO;
            return;
        }
        
        for (NSXMLElement *fileElement in fileElements) {
            LocalizableFile *file = [LocalizableFile localizableFileInProject:project withElement:fileElement];
            if (!file) {
                error = errorWithCode(EasyLocalizeFileInvalidError, YES);
                [context reset];
                success = NO;
                return;
            }
            
            NSString *targetLanguageCode = [fileElement attributeForName:@"target-language"].stringValue;
            Language *targetLanguage = [Language languageWithLanguageCode:targetLanguageCode
                                                                inProject:project];
            
            if (!targetLanguage) {
                error = errorWithCode(EasyLocalizeStorageInternalError, YES);
                [context reset];
                success = NO;
                return;
            }
            
            NSXMLElement *body = [fileElement elementsForName:@"body"].firstObject;
            NSArray *transUnitElements = [body elementsForName:@"trans-unit"];
            
            for (NSXMLElement *transUnitElement in transUnitElements) {
                LocalizationEntry *entry = [LocalizationEntry localizationEntryInFile:file withElement:transUnitElement];
                if (!entry) {
                    error = errorWithCode(EasyLocalizeFileInvalidError, YES);
                    [context reset];
                    success = NO;
                    return;
                }
                
                LocalizedString *localizedString = [LocalizedString localizedStringInEntry:entry
                                                                               withElement:transUnitElement
                                                                            sourceLanguage:sourceLanguage
                                                                            targetLanguage:targetLanguage];
                if (!localizedString) {
                    error = errorWithCode(EasyLocalizeFileInvalidError, YES);
                    [context reset];
                    success = NO;
                    return;
                }
            }
        }
        success = [context save:&error];
        [undoManager enableUndoRegistration];
    }];
    if (outError) {
        *outError = error;
    }
    
    return success;
}

- (NSXMLDocument *)exportXLIFFDocument:(NSError **)outError {
    if (self.mainUIContext.hasChanges) {
        if (![self.mainUIContext save:outError]) {
            return nil;
        }
    }
    
    NSXMLElement *rootElement = [[NSXMLElement alloc] initWithName:@"xliff"];
    NSXMLElement *namespace = [NSXMLElement namespaceWithName:@"" stringValue:@"urn:oasis:names:tc:xliff:document:1.2"];
    [rootElement addNamespace:namespace];
    
    NSString *schemaURL = @"http://www.w3.org/2001/XMLSchema-instance";
    
    NSXMLElement *xsiNamespace = [NSXMLElement namespaceWithName:@"xsi" stringValue:schemaURL];
    [rootElement addNamespace:xsiNamespace];
    
    NSXMLNode *schemaLocationAttributeXmlNode =
    [NSXMLNode attributeWithName:@"xsi:schemaLocation"
                             URI:schemaURL
                     stringValue:@"urn:oasis:names:tc:xliff:document:1.2 http://docs.oasis-open.org/xliff/v1.2/os/xliff-core-1.2-strict.xsd"];
    
    [rootElement addAttribute:schemaLocationAttributeXmlNode];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"LocalizableProject"];
    LocalizableProject *project = [[self.mainUIContext executeFetchRequest:fetchRequest error:outError] firstObject];
    if (!project) {
        return nil;
    }
    
    Language *sourceLanguage = nil;
    Language *targetLanguage = nil;
    
    for (Language *language in project.languages) {
        if (language.isSourceLanguage) {
            sourceLanguage = language;
        } else {
            targetLanguage = language;
        }
        if (sourceLanguage && targetLanguage) {
            break;
        }
    }
    
    if (!sourceLanguage) {
        NSLog(@"Did not find source language");
        return nil;
    }
    
    if (!targetLanguage) {
        NSLog(@"Did not find target language");
        return nil;
    }
    
    NSArray *childNodes = [project xmlNodesForSourceLanguage:sourceLanguage target:targetLanguage];
    if (!childNodes) {
        NSLog(@"No child nodes for export found.");
        return nil;
    }
    
    for (NSXMLNode *child in childNodes) {
        [rootElement addChild:child];
    }
    
    NSXMLDocument *xliffDocument = [[NSXMLDocument alloc] initWithRootElement:rootElement];
    if (xliffDocument) {
        [xliffDocument setVersion:@"1.2"];
        [xliffDocument setCharacterEncoding:@"UTF-8"];
        [xliffDocument setStandalone:NO];
    }
    
    return xliffDocument;
}


#pragma mark - Managed Object Context Handling

- (void)managedObjectContextWillSave:(NSNotification *)notification {
    NSManagedObjectContext *context = notification.object;
    if (context == self.mainUIContext) {
        if ([context hasChanges]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kWillSaveChangesNotification object:self];
        }
    }
}

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    NSManagedObjectContext *context = notification.object;
    if (context == self.workContext) {
        [self.mainUIContext performBlockAndWait:^{
            [self.mainUIContext mergeChangesFromContextDidSaveNotification:notification];
            if ([self.mainUIContext hasChanges]) {
                [self.mainUIContext save:nil];
            }
        }];
    } else if (context == self.mainUIContext) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDidSaveChangesNotification object:self];
        [self performSearchIfNeeded];
    }
}

- (NSManagedObjectContext *)newChildContext {
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = self.storeCoordinator;
    return context;
}

#pragma mark - FetchResultsController delegate

- (void)controllerDidChangeContents:(FetchResultsController *)controller {
    if (controller == self.localizationEntriesFetchController) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocalizationEntriesDidChangeNotification object:self];
    } else if (controller == self.selectedFilesFetchController) {
        [self.localizationEntriesFetchController fetch:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kSelectedLocalizableFilesDidChangeNotification object:self];
    } else if (controller == self.localizableFilesFetchController) {
        [self.selectedFilesFetchController fetch:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocalizableFilesDidChangeNotification object:self];
    }
}


#pragma mark - Convenience fetches

- (NSArray *)availableLanguages {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Language"];
    NSError *error = nil;
    NSArray *results = [self.mainUIContext executeFetchRequest:fetchRequest error:&error];
    if (!results) {
        NSLog(@"Error fetching languages: %@", error);
    }
    return results;
}

- (NSArray *)selectedLanguages {
    return [self.availableLanguages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"selected = YES"]];
}

- (Language *)sourceLanguage {
    NSArray *sourceLanguages = [[self availableLanguages] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isSourceLanguage = YES"]];
    return sourceLanguages.firstObject;
}

- (NSArray *)availableTargetLanguages {
    NSMutableArray *languages = [[self availableLanguages] mutableCopy];
    [languages removeObject:self.sourceLanguage];
    return languages;
}

- (NSArray *)selectedTargetLanguages {
    NSMutableArray *languages = [[self selectedLanguages] mutableCopy];
    [languages removeObject:self.sourceLanguage];
    return languages;
}

@end
