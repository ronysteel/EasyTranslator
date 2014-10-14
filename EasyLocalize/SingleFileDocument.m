//
//  SingleFileDocument.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 05.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "SingleFileDocument.h"
#import "StorageManager.h"
#import "Errors.h"
#import "SingleFileWindowController.h"

@interface SingleFileDocument ()
@property(nonatomic, strong) NSXMLDocument *xliffDocument;
@property(nonatomic, strong) StorageManager *storageManager;
@end

@implementation SingleFileDocument

+ (BOOL)autosavesInPlace {
    return YES;
}

- (void)makeWindowControllers {
    // Override to return the Storyboard file name of the document.
    NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    SingleFileWindowController *windowController
    = [storyboard instantiateControllerWithIdentifier:@"Single File Window Controller"];
    windowController.storageManager = self.storageManager;
    [self addWindowController:windowController];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {

    NSXMLDocument *xliffDocument = [[NSXMLDocument alloc] initWithData:data options:0 error:outError];
    if (!xliffDocument) {
        if (outError) {
            *outError = errorWithCode(EasyLocalizeFileNotReadError, YES);
        }
        return NO;
    }
    
    if (![xliffDocument.rootElement.name isEqualToString:@"xliff"]) {
        if (outError) {
            *outError = errorWithCode(EasyLocalizeFileInvalidError, YES);
        }
        return NO;
    }
    
    StorageManager *storageManager = [[StorageManager alloc] initWithError:outError];
    if (!storageManager) {
        return NO;
    }
    
    BOOL result = [storageManager importXLIFFDocument:xliffDocument error:outError];
    if (result) {
        self.storageManager = storageManager;
        self.xliffDocument = xliffDocument;
    }
    
    return result;
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    return nil;
}


@end
