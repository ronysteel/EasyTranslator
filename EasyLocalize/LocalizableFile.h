//
//  LocalizableFile.h
//  EasyLocalize
//
//  Created by Sebastian Husche on 11.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LocalizationEntry, LocalizableProject, Language;

@interface LocalizableFile : NSManagedObject

@property(nonatomic, retain) NSString *dataType;
@property(nonatomic, retain) NSString *headerString;
@property(nonatomic, retain) NSString *original;
@property(nonatomic, assign) BOOL selected;
@property(nonatomic, retain) LocalizableProject *localizableProject;
@property(nonatomic, retain) NSOrderedSet *localisationEntries;

@property(nonatomic, readonly) NSUInteger numberOfLocalizedStrings;
@property(nonatomic, readonly) NSUInteger numberOfIncompleteLocalizedStrings;

+ (instancetype)localizableFileInProject:(LocalizableProject *)project withElement:(NSXMLElement *)element;

- (NSXMLNode *)xmlNodeForSourceLanguage:(Language *)sourceLanguage target:(Language *)targetLanguage;


@end
