//
//  FetchResultsController.h
//  EasyLocalize
//
//  Created by Sebastian Husche on 07.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FetchResultsController;

@protocol FetchResultsControllerDelegate <NSObject>
@optional
- (NSUInteger)numberOfVisibleRecordsForController:(FetchResultsController *)controller;
- (void)controllerDidChangeContents:(FetchResultsController *)controller;

@end

@interface FetchResultsController : NSArrayController

@property(nonatomic, weak) id<FetchResultsControllerDelegate>delegate;

@end
