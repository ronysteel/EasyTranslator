//
//  LocalizedString.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 11.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "LocalizedString.h"
#import "LocalizationEntry.h"

@implementation LocalizedString

@dynamic language;
@dynamic translatedString;
@dynamic modified;
@dynamic localizationEntry;

+ (instancetype)newLocalizedStringInContext:(NSManagedObjectContext *)context {
    if (!context) {
        return nil;
    }
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"LocalizedString" inManagedObjectContext:context];
    LocalizedString *string = [[LocalizedString alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    return string;
}

+ (instancetype)localizedStringInEntry:(LocalizationEntry *)entry
                           withElement:(NSXMLElement *)element
                        sourceLanguage:(Language *)sourceLanguage
                        targetLanguage:(Language *)targetLanguage {
    
    if (!entry.managedObjectContext || !element) {
        return nil;
    }
    
    if (!sourceLanguage || !targetLanguage) {
        NSLog(@"Source language code and target language code must have valid values.");
        return nil;
    }
    
    NSString *sourceString = nil;
    NSString *targetString = nil;
    
    for (NSXMLNode *child in element.children) {
        if ([child.name isEqualToString:@"source"]) {
            sourceString = child.stringValue;
        } else if ([child.name isEqualToString:@"target"]) {
            targetString = child.stringValue;
        }
    }
    
    if (!sourceString.length) {
        NSLog(@"Invalid entry node: %@", element.XMLString);
        entry = nil;
        return nil;
    }
    
    __block LocalizedString *string = nil;
    NSManagedObjectContext *context = entry.managedObjectContext;
    [context performBlockAndWait:^{
        NSPredicate *sourcePredicate = [NSPredicate predicateWithFormat:@"language = %@", sourceLanguage];
        LocalizedString *sourceLocalizedString = [entry.localizedStrings filteredOrderedSetUsingPredicate:sourcePredicate].firstObject;
        if (!sourceLocalizedString) {
            sourceLocalizedString = [self newLocalizedStringInContext:context];
            sourceLocalizedString.language = sourceLanguage;
            sourceLocalizedString.localizationEntry = entry;
        }
        sourceLocalizedString.translatedString = sourceString;
        
        NSPredicate *targetPredicate = [NSPredicate predicateWithFormat:@"language = %@", targetLanguage];
        LocalizedString *targetLocalizedString = [entry.localizedStrings filteredOrderedSetUsingPredicate:targetPredicate].firstObject;
        if (!targetLocalizedString) {
            targetLocalizedString = [self newLocalizedStringInContext:context];
            targetLocalizedString.language = targetLanguage;
            targetLocalizedString.localizationEntry = entry;
        }
        targetLocalizedString.translatedString = targetString;
        string = targetLocalizedString;
    }];
    return string;
}

@end
