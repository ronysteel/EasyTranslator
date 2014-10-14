//
//  LocalizedString.h
//  EasyLocalize
//
//  Created by Sebastian Husche on 11.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LocalizationEntry, Language;

@interface LocalizedString : NSManagedObject

@property(nonatomic, retain) Language *language;
@property(nonatomic, retain) LocalizationEntry *localizationEntry;
@property(nonatomic, retain) NSString *translatedString;
@property(nonatomic) BOOL modified;

+ (instancetype)localizedStringInEntry:(LocalizationEntry *)entry
                           withElement:(NSXMLElement *)element
                        sourceLanguage:(Language *)sourceLanguage
                        targetLanguage:(Language *)targetLanguage;


@end
