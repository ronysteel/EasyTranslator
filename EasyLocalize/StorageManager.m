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

@end

@implementation StorageManager
@synthesize persistentStoreURL = _persistentStoreURL;


#pragma mark - Init and Dealloc

- (instancetype)initWithError:(NSError **)error {
    self = [super init];
    if (self) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
        self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        if (self.managedObjectModel) {
            self.storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
            if (self.storeCoordinator) {
                
                NSPersistentStore *store = [self.storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType
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

                self.mainUIContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                self.mainUIContext.persistentStoreCoordinator = self.storeCoordinator;
                self.mainUIContext.undoManager = [[NSUndoManager alloc] init];

                self.workContext = [self newChildContext];

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
    }
    
    self.localizationEntriesFetchController = [FetchResultsController new];
    NSArray *sortDescriptors = @[
                                 [NSSortDescriptor sortDescriptorWithKey:@"localizableFile.original" ascending:YES],
                                 [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]
                                 ];
    self.localizationEntriesFetchController.entityName = @"LocalizationEntry";
    self.localizationEntriesFetchController.fetchPredicate = [NSPredicate predicateWithFormat:@"localizableFile.selected = YES"];
    self.localizationEntriesFetchController.sortDescriptors = sortDescriptors;
    self.localizationEntriesFetchController.managedObjectContext = _mainUIContext;
    self.localizationEntriesFetchController.delegate = self;
    [self.localizationEntriesFetchController fetch:nil];
    
    
    self.localizableFilesFetchController = [FetchResultsController new];
    sortDescriptors = @[
                        [NSSortDescriptor sortDescriptorWithKey:@"original" ascending:YES],
                        ];
    self.localizableFilesFetchController.entityName = @"LocalizableFile";
    self.localizableFilesFetchController.sortDescriptors = sortDescriptors;
    self.localizableFilesFetchController.managedObjectContext = _mainUIContext;
    self.localizableFilesFetchController.delegate = self;
    [self.localizableFilesFetchController fetch:nil];
    
    self.selectedFilesFetchController = [FetchResultsController new];
    sortDescriptors = @[
                        [NSSortDescriptor sortDescriptorWithKey:@"original" ascending:YES],
                        ];
    self.selectedFilesFetchController.entityName = @"LocalizableFile";
    self.selectedFilesFetchController.fetchPredicate = [NSPredicate predicateWithFormat:@"selected = YES"];
    self.selectedFilesFetchController.sortDescriptors = sortDescriptors;
    self.selectedFilesFetchController.managedObjectContext = _mainUIContext;
    self.selectedFilesFetchController.delegate = self;
    [self.selectedFilesFetchController fetch:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedObjectContextDidSave:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
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
        
        _persistentStoreURL = [appSupportURL URLByAppendingPathComponent:[NSString stringWithFormat:@"db_%@", [NSUUID UUID].UUIDString]];
        
    }
    return _persistentStoreURL;
}

- (NSArray *)localizationEntries {
    return self.localizationEntriesFetchController.arrangedObjects;
}

- (NSArray *)localizableFiles {
    return self.localizableFilesFetchController.arrangedObjects;
}

- (NSArray *)selectedLocalizableFiles {
    return self.selectedFilesFetchController.arrangedObjects;
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
        context.undoManager = nil;
        
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
        context.undoManager = undoManager;
    }];
    if (outError) {
        *outError = error;
    }
    
    return success;
}


#pragma mark - Managed Object Context Handling

- (void)managedObjectContextDidSave:(NSNotification *)notification {
    NSManagedObjectContext *context = notification.object;
    if (context == self.workContext) {
        [self.mainUIContext performBlockAndWait:^{
            [self.mainUIContext mergeChangesFromContextDidSaveNotification:notification];
            [self.mainUIContext save:nil];
        }];
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
