//
//  LocalizationEntry.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 11.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "LocalizationEntry.h"
#import "LocalizableFile.h"
#import "LocalizedString.h"


@implementation LocalizationEntry

@dynamic identifier;
@dynamic note;
@dynamic localizableFile;
@dynamic localizedStrings;

+ (instancetype)newLocalizationEntryInContext:(NSManagedObjectContext *)context {
    if (!context) {
        return nil;
    }
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"LocalizationEntry" inManagedObjectContext:context];
    LocalizationEntry *entry = [[LocalizationEntry alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    return entry;
}

+ (instancetype)localizationEntryInFile:(LocalizableFile *)file withElement:(NSXMLElement *)element {
    if (!file.managedObjectContext || !element) {
        return nil;
    }
    
    NSString *identifier = [element attributeForName:@"id"].stringValue;
    if (!identifier.length) {
        NSLog(@"Invalid localization entry: %@", element.XMLString);
        return nil;
    }

    __block LocalizationEntry *entry = nil;
    NSManagedObjectContext *context = file.managedObjectContext;
    [context performBlockAndWait:^{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier = %@ AND localizableFile = %@", identifier, file];
        NSOrderedSet *entries = [file.localisationEntries filteredOrderedSetUsingPredicate:predicate];
        entry = entries.firstObject;
        if (!entry) {
            entry = [self newLocalizationEntryInContext:context];
            entry.identifier = identifier;
            for (NSXMLNode *child in element.children) {
                if ([child.name isEqualToString:@"note"]) {
                    entry.note = child.stringValue;
                    break;
                }
            }
            entry.localizedStrings = [NSOrderedSet orderedSet];
            if (!entry.identifier.length) {
                NSLog(@"Invalid entry node: %@", element.XMLString);
                entry = nil;
                return;
            }
            entry.localizableFile = file;
        }
    }];
    return entry;
}

@end
