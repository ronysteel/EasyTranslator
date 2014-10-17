//
//  LocalizableFile.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 11.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "LocalizableFile.h"
#import "LocalizableProject.h"
#import "LocalizationEntry.h"
#import "Language.h"

@implementation LocalizableFile

@dynamic localizableProject;
@dynamic dataType;
@dynamic headerString;
@dynamic original;
@dynamic selected;
@dynamic localisationEntries;

+ (instancetype)newLocalizableFileInContext:(NSManagedObjectContext *)context {
    if (!context) {
        return nil;
    }
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"LocalizableFile" inManagedObjectContext:context];
    LocalizableFile *file = [[LocalizableFile alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    return file;
}

+ (instancetype)localizableFileInProject:(LocalizableProject *)project withElement:(NSXMLElement *)element {
    if (!project.managedObjectContext || !element) {
        return nil;
    }
    
    NSString *originalName = [element attributeForName:@"original"].stringValue;
    if (!originalName.length) {
        NSLog(@"Invalid file node: %@", element.XMLString);
        return nil;
    }
    
    __block LocalizableFile *file = nil;
    NSManagedObjectContext *context = project.managedObjectContext;
    [context performBlockAndWait:^{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"original = %@", originalName];
        NSOrderedSet *files = [project.localizableFiles filteredOrderedSetUsingPredicate:predicate];
        file = files.firstObject;
        if (!file) {
            file = [self newLocalizableFileInContext:context];
            file.selected = YES;
            file.original = [element attributeForName:@"original"].stringValue;
            file.dataType = [element attributeForName:@"datatype"].stringValue;
            file.localisationEntries = [NSOrderedSet orderedSet];
            for (NSXMLNode *child in element.children) {
                if ([child.name isEqualToString:@"header"]) {
                    file.headerString = child.XMLString;
                    break;
                }
            }
            
            if (!file.original.length || !file.headerString.length) {
                NSLog(@"Invalid file node: %@", element.XMLString);
                file = nil;
                return;
            }
            file.localizableProject = project;
        }
    }];
    return file;
}

- (NSXMLNode *)xmlNodeForSourceLanguage:(Language *)sourceLanguage target:(Language *)targetLanguage {
    
    NSXMLElement *fileNode = [NSXMLNode elementWithName:@"file"];
    [fileNode addAttribute:[NSXMLNode attributeWithName:@"original" stringValue:self.original]];
    [fileNode addAttribute:[NSXMLNode attributeWithName:@"source-language" stringValue:sourceLanguage.languageCode]];
    [fileNode addAttribute:[NSXMLNode attributeWithName:@"datatype" stringValue:self.dataType]];
    [fileNode addAttribute:[NSXMLNode attributeWithName:@"target-language" stringValue:targetLanguage.languageCode]];
    
    NSError *error = nil;
    
    NSXMLElement *header = [[NSXMLElement alloc] initWithXMLString:self.headerString error:&error];
    if (!header) {
        NSLog(@"Could not create header node from header string: %@", error.localizedDescription);
    }
    [fileNode addChild:header];
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    for (LocalizationEntry *entry in self.localisationEntries) {
        NSXMLNode *entryNode = [entry xmlNodeForSourceLanguage:sourceLanguage target:targetLanguage];
        if (entryNode) {
            [body addChild:entryNode];
        } else {
            NSLog(@"Could not create node for entry.");
            return nil;
        }
    }
    [fileNode addChild:body];
    return fileNode;
}

- (NSUInteger)numberOfLocalizedStrings {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"LocalizedString"];
    fetchRequest.predicate
    = [NSPredicate predicateWithFormat:@"localizationEntry.localizableFile == %@ AND language.isSourceLanguage = NO",
       self];
    
    NSError *error = nil;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];

    if (count == NSNotFound) {
        NSLog(@"Could not count localized strings: %@", error.localizedDescription);
    }
    return count;
}

- (NSUInteger)numberOfIncompleteLocalizedStrings {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"LocalizedString"];
    fetchRequest.predicate
    = [NSPredicate predicateWithFormat:@"translatedString = NIL AND localizationEntry.localizableFile == %@ AND language.isSourceLanguage = NO",
       self];
    
    NSError *error = nil;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
    if (count == NSNotFound) {
        NSLog(@"Could not count localized strings: %@", error.localizedDescription);
    }
    return count;
}

@end
