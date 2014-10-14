//
//  LocalizedStringsTableView.h
//  EasyLocalize
//
//  Created by Sebastian Husche on 08.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSIndexPath (TableView)

+ (NSIndexPath *)indexPathForRow:(NSUInteger)row inColumn:(NSUInteger)column;

@property(nonatomic, readonly) NSUInteger row;
@property(nonatomic, readonly) NSUInteger column;

@end


@interface LocalizedStringsTableView : NSTableView

@property(nonatomic, strong) NSIndexPath *selectedIndexPath;

- (BOOL)selectNextColumnsCell;
- (BOOL)selectPreviousColumnsCell;
- (BOOL)selectNextRowsCell;
- (BOOL)selectPreviousRowsCell;


@end
