//
//  Language.h
//  EasyLocalize
//
//  Created by Sebastian Husche on 11.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LocalizedString, LocalizableProject;

@interface Language : NSManagedObject

@property(nonatomic, retain) NSString *languageCode;
@property(nonatomic) BOOL selected;
@property(nonatomic) BOOL isSourceLanguage;
@property(nonatomic, retain) NSOrderedSet *localizedStrings;
@property(nonatomic, retain) LocalizableProject *localizableProject;

@property(nonatomic, readonly) NSString *localizedLanguageName;

+ (instancetype)languageWithLanguageCode:(NSString *)languageCode inProject:(LocalizableProject *)project;

@end
