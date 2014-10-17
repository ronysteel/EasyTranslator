//
//  LocalizableProject.h
//  EasyLocalize
//
//  Created by Sebastian Husche on 11.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LocalizableFile, Language;

@interface LocalizableProject : NSManagedObject

@property(nonatomic, retain) NSOrderedSet *localizableFiles;
@property(nonatomic, retain) NSOrderedSet *languages;

+ (instancetype)localizableProjectWithElement:(NSXMLElement *)element
                       inManagedObjectContext:(NSManagedObjectContext *)context;

- (NSArray *)xmlNodesForSourceLanguage:(Language *)sourceLanguage target:(Language *)targetLanguage;

@end
