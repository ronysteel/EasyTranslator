//
//  SingleFileSidebarController.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 05.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "SingleFileSidebarController.h"
#import "SidebarTableCellView.h"
#import "LanguageValueTransformer.h"

@interface SingleFileSidebarController () <NSTableViewDelegate, NSTableViewDataSource>

@property(nonatomic, weak) IBOutlet NSTableView *tableView;
@property(nonatomic, strong) SidebarTableCellView *prototypeCell;
@property(nonatomic, weak) IBOutlet NSTextField *titleTextField;
@end


@implementation SingleFileSidebarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"SidebarCells" bundle:nil];
    [self.tableView registerNib:nib forIdentifier:@"SidebarTableCellView"];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadData:)
                                                 name:kLocalizableFilesDidChangeNotification
                                               object:self.storageManager];
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLocalizableFilesDidChangeNotification
                                                  object:self.storageManager];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"SidebarTableCellView" owner:self];
    return cellView;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    if (!self.prototypeCell) {
        self.prototypeCell = [tableView makeViewWithIdentifier:@"SidebarTableCellView" owner:nil];
    }
    self.prototypeCell.objectValue = [self.storageManager.localizableFiles objectAtIndex:row];
    [self.prototypeCell layoutSubtreeIfNeeded];
    return self.prototypeCell.bounds.size.height;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn {
    return NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.storageManager.localizableFiles.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return self.storageManager.localizableFiles[row];
}

- (IBAction)reloadData:(id)sender {
    if (!self.storageManager) {
        return;
    }
    LanguageValueTransformer *transformer = [[LanguageValueTransformer alloc] init];
    NSArray *languages = self.storageManager.availableLanguages;
    NSMutableArray *languageStrings = [NSMutableArray arrayWithCapacity:languages.count];
    for (Language *language in languages) {
        [languageStrings addObject:[transformer transformedValue:language.languageCode]];
    }
    NSString *title = [languageStrings componentsJoinedByString:@", "];
    self.titleTextField.stringValue = title;
    [self.tableView reloadData];
}

@end
