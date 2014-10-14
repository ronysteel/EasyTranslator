//
//  LocalizationEntryTableViewCell.h
//  EasyLocalize
//
//  Created by Sebastian Husche on 08.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LocalizationEntryTableViewCell;

typedef void (^EntryTableCellBeginEditingBlock)(LocalizationEntryTableViewCell *cell);
typedef void (^EntryTableCellEndEditingBlock)(LocalizationEntryTableViewCell *cell, BOOL returned);

@interface LocalizationEntryTableViewCell : NSTableCellView

@property(nonatomic, assign, getter=isEditable) BOOL editable;
@property(nonatomic, assign, getter=isSelected) BOOL selected;
@property(nonatomic, readonly, getter=isEditing) BOOL editing;

@property(nonatomic, copy) EntryTableCellBeginEditingBlock cellEditingBeginBlock;
@property(nonatomic, copy) EntryTableCellEndEditingBlock cellEditingEndBlock;

- (void)beginEditing;

@end
