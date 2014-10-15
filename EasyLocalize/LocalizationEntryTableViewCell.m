//
//  LocalizationEntryTableViewCell.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 08.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "LocalizationEntryTableViewCell.h"
#import "LocalizedString.h"

@interface LocalizationEntryTableViewCell () <NSTextFieldDelegate>

@property(nonatomic, readonly) LocalizedString *localizedString;
@property(nonatomic, assign, getter=isEditing) BOOL editing;
@property(nonatomic, assign) BOOL editingEndedWithReturnKey;

@end

@implementation LocalizationEntryTableViewCell

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [self setWantsLayer:YES];
    self.textField.editable = NO;
    self.textField.selectable = NO;
    _editable = NO;
    _selected = NO;
    _editing = NO;
}

- (void)awakeFromNib {
    [self commonInit];
}

- (LocalizedString *)localizedString {
    if ([self.objectValue isKindOfClass:[LocalizedString class]]) {
        return (LocalizedString *)self.objectValue;
    }
    return nil;
}

- (void)setObjectValue:(id)objectValue {
    if (self.objectValue != objectValue) {
        [super setObjectValue:objectValue];
        [self updateContents];
    }
}

- (void)setEditable:(BOOL)editable {
    if (_editable != editable) {
        _editable = editable;
        [self updateContents];
    }
}

- (void)setSelected:(BOOL)selected {
    if (selected != _selected) {
        _selected = selected;
        if (selected) {
            self.layer.borderColor = [NSColor alternateSelectedControlColor].CGColor;
            self.layer.borderWidth = 1.0f;
        } else {
            self.layer.borderColor = nil;
            self.layer.borderWidth = 0.0f;
        }
    }
}

- (void)setEditing:(BOOL)editing {
    if (_editing != editing) {
        _editing = editing;
        if (_editing && self.cellEditingBeginBlock) {
            self.cellEditingBeginBlock(self);
        } else if (!_editing && self.cellEditingEndBlock) {
            self.cellEditingEndBlock(self, self.editingEndedWithReturnKey);
            self.editingEndedWithReturnKey = NO;
        }
    }
}

- (void)beginEditing {
    self.textField.editable = self.editable;
    if (self.textField.editable) {
        self.editing = [self.window makeFirstResponder:self.textField];
    }
}

- (void)endEditing {
    self.textField.editable = NO;
    self.textField.selectable = NO;
    self.editing = NO;
}

- (void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];
    if (theEvent.clickCount == 2) {
        [self beginEditing];
    }
}

- (void)updateContents {
    NSString *title = nil;
    LocalizedString *stringValue = self.localizedString;
    if (stringValue) {
        title = stringValue.translatedString;
    } else {
        title = (NSString *)self.objectValue;
    }
   
    NSColor *textColor = self.editable ? [NSColor controlTextColor] : [NSColor disabledControlTextColor];
    [self.textField setTextColor:textColor];
    
    self.textField.stringValue = title ? title : @"";
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(insertNewline:)) {
        self.editingEndedWithReturnKey = YES;
        [textView insertNewline:nil];
        return YES;
    } else if (commandSelector == @selector(cancelOperation:)) {
        [self endEditing];
        return NO;
    }
    return NO;
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    if (notification.object == self.textField) {
        NSString *newTitle = self.textField.stringValue;
        if (newTitle.length == 0) {
            newTitle = nil;
        }
        self.localizedString.translatedString = newTitle;
        [self.localizedString.managedObjectContext save:nil];
        [self endEditing];
    }
}

@end
