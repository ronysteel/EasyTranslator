//
//  LocalizedStringsTableViewController.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 05.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "LocalizedStringsTableViewController.h"
#import "LocalizationEntryTableViewCell.h"
#import "LocalizedStringsTableView.h"

@interface LocalizedStringsTableViewController () <NSTableViewDelegate, NSTableViewDataSource>
@property(nonatomic, strong) IBOutlet LocalizedStringsTableView *tableView;
@property(nonatomic, strong) NSMutableArray *datasource;
@property(nonatomic, strong) NSMutableDictionary *tableColumns;
@property(nonatomic, assign) NSUInteger editedRow;
@property(nonatomic, strong) LocalizationEntryTableViewCell *prototypeCell;
@end

@implementation LocalizedStringsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"TranslationCells" bundle:nil];
    [self.tableView registerNib:nib forIdentifier:@"TranslationEntryTableCellView"];
    [self.tableView setAutosaveName:@"SingleFileTableView"];
    [self.tableView setAutosaveTableColumns:YES];
    self.editedRow = NSNotFound;
}

- (void)viewWillAppear {
    [super viewWillAppear];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadData:)
                                                 name:kLocalizationEntriesDidChangeNotification
                                               object:self.storageManager];
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLocalizationEntriesDidChangeNotification
                                                  object:self.storageManager];
}




- (IBAction)copy:(id)sender {
    
}

- (id)objectValueForColumn:(NSUInteger)column row:(NSUInteger)row {
    NSString *identifier = [[self.tableView.tableColumns objectAtIndex:column] identifier];
    NSDictionary *dict = self.datasource[row];
    return dict[identifier];
}


- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    if (row == self.editedRow) {
        return 120.0f;
    }
    return 25.0f;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return YES;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.datasource.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary *dataDictionary = self.datasource[row];
    return dataDictionary[tableColumn.identifier];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {

    LocalizationEntryTableViewCell *cell = [tableView makeViewWithIdentifier:@"TranslationEntryTableCellView" owner:self];
    
    NSDictionary *dataDict = self.datasource[row];
    
    id object = dataDict[tableColumn.identifier];
    cell.objectValue = object;
    NSUInteger column = [self.tableView.tableColumns indexOfObject:tableColumn];
    cell.selected = [self.tableView.selectedIndexPath isEqual:[NSIndexPath indexPathForRow:row inColumn:column]];
    cell.cellEditingEndBlock = nil;
    cell.cellEditingBeginBlock = nil;
    if ([object isKindOfClass:[LocalizedString class]]) {
        LocalizedString *string = (LocalizedString *)object;
        cell.editable = !string.language.isSourceLanguage;
        cell.cellEditingBeginBlock = ^(LocalizationEntryTableViewCell *cell){
            self.editedRow = [self.tableView rowForView:cell];
            [NSAnimationContext beginGrouping];
            [NSAnimationContext currentContext].duration = 0.0;
            [self.tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:self.editedRow]];
            [NSAnimationContext endGrouping];
        };
        cell.cellEditingEndBlock = ^(LocalizationEntryTableViewCell *cell, BOOL returned){
            NSUInteger row = [self.tableView rowForView:cell];
            self.editedRow = NSNotFound;
            [NSAnimationContext beginGrouping];
            [NSAnimationContext currentContext].duration = 0.0;
            [self.tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:row]];
            [NSAnimationContext endGrouping];
            if (returned && [self.tableView selectNextRowsCell]) {
                LocalizationEntryTableViewCell *cell
                = [self.tableView viewAtColumn:self.tableView.selectedIndexPath.column
                                           row:self.tableView.selectedIndexPath.row
                               makeIfNecessary:YES];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cell beginEditing];
                });
            }
        };
    } else {
        cell.editable = NO;
    }
    
    return cell;
}

- (IBAction)reloadData:(id)sender {
    if (!self.viewLoaded || !self.storageManager) {
        return;
    }
    
    NSArray *selectedTargetLanguages = [self.storageManager selectedTargetLanguages];
    Language *sourceLanguage = [self.storageManager sourceLanguage];
    
    CGFloat minColumnWidth = 120.0f;
    CGFloat columnWidth = MAX(minColumnWidth, floorf(self.tableView.bounds.size.width / (selectedTargetLanguages.count + 3)) - 3);
    
    if (!self.tableColumns) {
        NSArray *columns = [self.tableView.tableColumns copy];
        for (NSTableColumn *column in columns) {
            [self.tableView removeTableColumn:column];
        }
        
        NSArray *allLanguages = [self.storageManager availableTargetLanguages];
        self.tableColumns = [NSMutableDictionary dictionary];
        
        NSString *columnID = @"identifier";
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:columnID];
        [column.headerCell setStringValue:@"Identifier"];
        column.width = columnWidth;
        column.minWidth = minColumnWidth;
        [self.tableColumns setObject:column forKey:columnID];
        
        columnID = @"note";
        column = [[NSTableColumn alloc] initWithIdentifier:columnID];
        [column.headerCell setStringValue:@"Note"];
        column.width = columnWidth;
        column.minWidth = minColumnWidth;
        [self.tableColumns setObject:column forKey:columnID];
        
        columnID = sourceLanguage.languageCode;
        column = [[NSTableColumn alloc] initWithIdentifier:sourceLanguage.languageCode];
        [column.headerCell setStringValue:[NSString stringWithFormat:@"%@ (Source)", sourceLanguage.localizedLanguageName]];
        column.width = columnWidth;
        column.minWidth = minColumnWidth;
        [self.tableColumns setObject:column forKey:columnID];
        
        for (Language *language in allLanguages) {
            columnID = language.languageCode;
            column = [[NSTableColumn alloc] initWithIdentifier:columnID];
            [column.headerCell setStringValue:language.localizedLanguageName];
            column.width = columnWidth;
            column.minWidth = minColumnWidth;
            [self.tableColumns setObject:column forKey:columnID];
        }
    }

    NSMutableArray *visibleColumnIDs = [NSMutableArray array];
    [visibleColumnIDs addObject:@"identifier"];
    [visibleColumnIDs addObject:@"note"];
    [visibleColumnIDs addObject:sourceLanguage.languageCode];
    for (Language *language in selectedTargetLanguages) {
        [visibleColumnIDs addObject:language.languageCode];
    }

    NSMutableArray *currentColumnIDs = [NSMutableArray array];
    //Remove invisible columns
    for (NSTableColumn *column in [self.tableView.tableColumns copy]) {
        if (![visibleColumnIDs containsObject:column.identifier]) {
            [self.tableView removeTableColumn:column];
        } else {
            [currentColumnIDs addObject:column.identifier];
        }
    }
    
    //Add missing columns
    for (NSString *columnID in visibleColumnIDs) {
        if (![currentColumnIDs containsObject:columnID]) {
            [self.tableView addTableColumn:self.tableColumns[columnID]];
        }
    }
    
    NSArray *entries = [self.storageManager.localizationEntries copy];
    self.datasource = [NSMutableArray arrayWithCapacity:[entries count]];
    for (LocalizationEntry *entry in entries) {
        NSMutableDictionary *dictionary = [@{
                                     @"identifier": entry.identifier,
                                     @"note": entry.note ? entry.note : @"",
                                     } mutableCopy];
        
        for (LocalizedString *string in entry.localizedStrings) {
            [dictionary setObject:string forKey:string.language.languageCode];
        }
        [self.datasource addObject:dictionary];
    }
    
    [self.tableView reloadData];
    NSLog(@"Reloading");
}

- (IBAction)refetch:(id)sender {
}


@end
