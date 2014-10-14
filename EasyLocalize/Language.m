//
//  Language.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 11.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "Language.h"
#import "LocalizedString.h"
#import "LocalizableProject.h"

@implementation Language

@dynamic languageCode;
@dynamic selected;
@dynamic localizedStrings;
@dynamic isSourceLanguage;
@dynamic localizableProject;

+ (instancetype)newLanguageInContext:(NSManagedObjectContext *)context {
    if (!context) {
        return nil;
    }
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Language" inManagedObjectContext:context];
    Language *language = [[Language alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    return language;
}



+ (instancetype)languageWithLanguageCode:(NSString *)languageCode
             inProject:(LocalizableProject *)project {
    
    if (!languageCode.length || !project.managedObjectContext) {
        return nil;
    }
    
    NSManagedObjectContext *context = project.managedObjectContext;

    __block NSError *error = nil;
    __block Language *language = nil;
    [context performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Language"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"languageCode = %@", languageCode];
        language = [context executeFetchRequest:fetchRequest error:&error].firstObject;
        if (error) {
            NSLog(@"Cannot fetch localizable project: %@", error.localizedDescription);
            language = nil;
            return;
        }
        if (!language) {
            language = [self newLanguageInContext:context];
            language.languageCode = languageCode;
            language.localizedStrings = [NSOrderedSet orderedSet];
            language.selected = YES;
            language.localizableProject = project;
        }
    }];
    
    return language;
}

- (NSString *)localizedLanguageName {
    return [[NSLocale currentLocale] displayNameForKey:NSLocaleLanguageCode value:self.languageCode];
}

@end
