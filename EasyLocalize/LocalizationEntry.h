//
//  LocalizationEntry.h
//  EasyLocalize
//
//  Created by Sebastian Husche on 11.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LocalizableFile, LocalizedString;

@interface LocalizationEntry : NSManagedObject

@property(nonatomic, retain) NSString * identifier;
@property(nonatomic, retain) NSString * note;
@property(nonatomic, retain) NSOrderedSet *localizedStrings;
@property(nonatomic, retain) LocalizableFile *localizableFile;

+ (instancetype)localizationEntryInFile:(LocalizableFile *)file withElement:(NSXMLElement *)element;

@end
