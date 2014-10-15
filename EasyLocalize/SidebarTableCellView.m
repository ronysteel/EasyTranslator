//
//  SidebarTableCellView.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 05.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "SidebarTableCellView.h"
#import "LocalizableFile.h"

@interface SidebarTableCellView ()
@property(nonatomic, weak) IBOutlet NSButton *checkBox;
@property(nonatomic, weak) IBOutlet NSTextField *labelTotal;
@property(nonatomic, weak) IBOutlet NSTextField *labelMissing;
@property(nonatomic, weak) IBOutlet NSTextField *labelTotalNo;
@property(nonatomic, weak) IBOutlet NSTextField *labelMissingNo;
@property(nonatomic, readonly) LocalizableFile* file;

@end

@implementation SidebarTableCellView

- (BOOL)allowsVibrancy {
    return YES;
}

- (NSDictionary *)titleAttributes {
    static dispatch_once_t onceToken;
    static NSDictionary *attributes;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingHead;
        paragraphStyle.tighteningFactorForTruncation = 0.0f;
        attributes = @{
                       NSFontAttributeName : [NSFont fontWithName:@"HelveticaNeue" size:13],
                       NSForegroundColorAttributeName : [NSColor labelColor],
                       NSParagraphStyleAttributeName: paragraphStyle
                       };
    });
    return attributes;
}

- (NSDictionary *)disabledTitleAttributes {
    static dispatch_once_t onceToken;
    static NSDictionary *disabledAttributes;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingHead;
        paragraphStyle.tighteningFactorForTruncation = 0.0f;
        disabledAttributes = @{
                               NSFontAttributeName : [NSFont fontWithName:@"HelveticaNeue" size:13],
                               NSForegroundColorAttributeName : [NSColor tertiaryLabelColor],
                               NSParagraphStyleAttributeName: paragraphStyle
                               };
    });
    return disabledAttributes;
}

- (LocalizableFile *)file {
    return (LocalizableFile *)self.objectValue;
}

- (void)updateContents {
    
    BOOL selected = self.file.selected;
    
    NSDictionary *attributes = selected ? [self titleAttributes] : [self disabledTitleAttributes];
    
    NSString *title = [NSString stringWithFormat:@"%@", self.file.original];
    self.checkBox.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attributes];

    self.labelTotalNo.stringValue = [NSString stringWithFormat:@"%lu", self.file.numberOfLocalizedStrings];
    self.labelMissingNo.stringValue = [NSString stringWithFormat:@"%lu", self.file.numberOfIncompleteLocalizedStrings];
}

- (void)setObjectValue:(id)objectValue {
    [super setObjectValue:objectValue];
    [self.checkBox unbind:@"value"];
    [self updateContents];
    [self.checkBox bind:@"value" toObject:self.file withKeyPath:@"selected" options:nil];
}

- (IBAction)checkboxClicked:(id)sender {
    [self updateContents];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSBezierPath *linePath = [[NSBezierPath alloc] init];
    [linePath moveToPoint:(NSPoint){NSMinX(self.bounds) + 20, NSMaxY(self.bounds) - 1.0f}];
    [linePath lineToPoint:(NSPoint){NSMaxX(self.bounds)     , NSMaxY(self.bounds) - 1.0f}];
    
    [[NSColor gridColor] set];
    linePath.lineWidth = 1.0f;
    [linePath stroke];
    
}

@end
