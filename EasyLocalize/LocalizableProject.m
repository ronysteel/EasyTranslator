//
//  LocalizableProject.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 11.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "LocalizableProject.h"
#import "LocalizableFile.h"
#import "Language.h"

@implementation LocalizableProject

@dynamic localizableFiles;
@dynamic languages;

+ (instancetype)newLocalizableProjectInContext:(NSManagedObjectContext *)context {
    if (!context) {
        return nil;
    }
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"LocalizableProject" inManagedObjectContext:context];
    LocalizableProject *project = [[LocalizableProject alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    return project;
}

+ (instancetype)localizableProjectWithElement:(NSXMLElement *)element
                       inManagedObjectContext:(NSManagedObjectContext *)context {
    
    if (!context || !element) {
        return nil;
    }
    
    
    __block LocalizableProject *project = nil;
    __block NSError *error = nil;

    [context performBlockAndWait:^{
        NSXMLElement *firstFile = [element elementsForName:@"file"].firstObject;
        NSString *sourceLanguageCode = [firstFile attributeForName:@"source-language"].stringValue;
        
        NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"LocalizableProject"];
        project = [context executeFetchRequest:fr error:&error].firstObject;
        if (error) {
            NSLog(@"Cannot fetch localizable project: %@", error.localizedDescription);
            project = nil;
            return;
        }

        if (!project) {
            project = [self newLocalizableProjectInContext:context];
            project.localizableFiles = [NSOrderedSet orderedSet];
            Language *sourceLanguage = [Language languageWithLanguageCode:sourceLanguageCode inProject:project];
            if (!sourceLanguage) {
                NSLog(@"Project contains no localizable files with valid source language.");
                project = nil;
                return;
            }
            sourceLanguage.isSourceLanguage = YES;
        }
    }];
    return project;
}

@end
