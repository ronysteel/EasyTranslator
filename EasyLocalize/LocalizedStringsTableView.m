//
//  LocalizedStringsTableView.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 08.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "LocalizedStringsTableView.h"

@implementation NSIndexPath (TableView)

+ (NSIndexPath *)indexPathForRow:(NSUInteger)row inColumn:(NSUInteger)column {
    NSUInteger path[] = { row, column };
    return [NSIndexPath indexPathWithIndexes:path length:2];
}

- (NSUInteger)row {
    return [self indexAtPosition:0];
}

- (NSUInteger)column {
    return [self indexAtPosition:1];
}

@end


@implementation LocalizedStringsTableView
@synthesize selectedIndexPath = _selectedIndexPath;

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath {
    if ([_selectedIndexPath isEqual:selectedIndexPath]) {
        return;
    }
    NSIndexPath *previouslySelectedIndexPath = _selectedIndexPath;
    _selectedIndexPath = selectedIndexPath;
    NSMutableIndexSet *rowIndexes = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *colIndexes = [NSMutableIndexSet indexSet];
    if (previouslySelectedIndexPath) {
        [rowIndexes addIndex:previouslySelectedIndexPath.row];
        [colIndexes addIndex:previouslySelectedIndexPath.column];
    }
    if (_selectedIndexPath) {
        [rowIndexes addIndex:_selectedIndexPath.row];
        [colIndexes addIndex:_selectedIndexPath.column];
    
        [self scrollRowToVisible:_selectedIndexPath.row];
        [self scrollColumnToVisible:_selectedIndexPath.column];
    }
    
    [self reloadDataForRowIndexes:rowIndexes columnIndexes:colIndexes];
}

- (BOOL)selectNextColumnsCell {
    if (!self.selectedIndexPath) {
        return NO;
    }
    NSUInteger row = self.selectedIndexPath.row;
    NSUInteger column = self.selectedIndexPath.column;
    if (column < self.numberOfColumns - 1) {
        column++;
    } else {
        if (row < self.numberOfRows - 1) {
            column = 0;
            row ++;
        } else {
            return NO;
        }
    }
    self.selectedIndexPath = [NSIndexPath indexPathForRow:row inColumn:column];
    return YES;
}

- (BOOL)selectPreviousColumnsCell {
    if (!self.selectedIndexPath) {
        return NO;
    }
    NSUInteger row = self.selectedIndexPath.row;
    NSUInteger column = self.selectedIndexPath.column;
    if (column > 0) {
        column --;
    } else {
        if (row > 0) {
            column = self.numberOfColumns -1 ;
            row --;
        } else {
            return NO;
        }
    }
    self.selectedIndexPath = [NSIndexPath indexPathForRow:row inColumn:column];
    return YES;
}

- (BOOL)selectNextRowsCell {
    if (!self.selectedIndexPath) {
        return NO;
    }
    NSUInteger row = self.selectedIndexPath.row;
    NSUInteger column = self.selectedIndexPath.column;
    if (row >= self.numberOfRows - 1) {
        return NO;
    }
    row ++;
    self.selectedIndexPath = [NSIndexPath indexPathForRow:row inColumn:column];
    return YES;
}

- (BOOL)selectPreviousRowsCell {
    if (!self.selectedIndexPath) {
        return NO;
    }
    NSUInteger row = self.selectedIndexPath.row;
    NSUInteger column = self.selectedIndexPath.column;
    if (row <= 0) {
        return NO;
    }
    row --;
    self.selectedIndexPath = [NSIndexPath indexPathForRow:row inColumn:column];
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];
    NSPoint clickPoint = [[self.window contentView] convertPoint:[theEvent locationInWindow] toView:self];
    NSInteger row = [self rowAtPoint:clickPoint];
    NSInteger column = [self columnAtPoint:clickPoint];
    if (row >= 0 && column >= 0) {
        self.selectedIndexPath = [NSIndexPath indexPathForRow:row inColumn:column];
    }
}

- (void)keyDown:(NSEvent *)theEvent {
    
    NSIndexPath *path = self.selectedIndexPath;
    if (!path) {
        [super keyDown:theEvent];
        return;
    }
    if ([theEvent type] == NSKeyDown) {
        switch ([theEvent keyCode]) {
            case 125:
                [self selectNextRowsCell];
                break;
            case 126:
                [self selectPreviousRowsCell];
                break;
            case 123:
                [self selectPreviousColumnsCell];
                break;
            case 124:
            case 48:
                [self selectNextColumnsCell];
                break;
            case 36:
            case 76:
                [self selectNextRowsCell];
                break;
            default:
                [super keyDown:theEvent];
                return;
        }
    } else {
        [super keyDown:theEvent];
    }
}

- (void)reloadData {
    [super reloadData];
    if (self.selectedIndexPath) {
        NSUInteger maxRow = MIN([self numberOfRows] - 1, self.selectedIndexPath.row);
        NSUInteger maxColumn = MIN([self numberOfColumns] - 1, self.selectedIndexPath.column);
        self.selectedIndexPath = [NSIndexPath indexPathForRow:maxRow inColumn:maxColumn];
    }
}

@end
