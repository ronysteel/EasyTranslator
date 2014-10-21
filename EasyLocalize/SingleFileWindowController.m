//
//  SingleFileWindowController.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 05.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "SingleFileWindowController.h"
#import "SingleFileSidebarController.h"
#import "LocalizedStringsTableViewController.h"

@interface SingleFileWindowController ()

@property(nonatomic, strong) NSSplitViewController *splitViewController;
@property(nonatomic, strong) SingleFileSidebarController *sidebarViewController;
@property(nonatomic, strong) LocalizedStringsTableViewController *translationsViewController;
@property (weak) IBOutlet NSSearchField *searchField;

@end

@implementation SingleFileWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.titlebarAppearsTransparent = YES;
    self.splitViewController = (id)self.contentViewController;
    self.sidebarViewController = (id)[self.splitViewController.splitViewItems[0] viewController];
    self.translationsViewController = (id)[self.splitViewController.splitViewItems[1] viewController];
    [self updateSubviewControllers];
}

- (void)updateSubviewControllers {
    self.sidebarViewController.storageManager = self.storageManager;
    self.translationsViewController.storageManager = self.storageManager;
}

- (void)setStorageManager:(StorageManager *)storageManager {
    if (storageManager != _storageManager) {
        _storageManager = storageManager;
        [self updateSubviewControllers];
    }
}

- (IBAction)search:(id)sender {
    self.storageManager.fulltextSearchstring = self.searchField.stringValue;
}

- (IBAction)performFindPanelAction:(id)sender {
    [self.window makeFirstResponder:self.searchField];
}


@end
