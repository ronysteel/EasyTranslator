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
@property (weak) IBOutlet NSTextField *labelFilepath;
@property(nonatomic, weak) IBOutlet NSTextField *labelTotal;
@property(nonatomic, weak) IBOutlet NSTextField *labelMissing;
@property(nonatomic, weak) IBOutlet NSTextField *labelTotalNo;
@property(nonatomic, weak) IBOutlet NSTextField *labelMissingNo;
@property(nonatomic, readonly) LocalizableFile* file;
@property(nonatomic, strong) NSMutableDictionary *currentTitleAttributes;


@end

@implementation SidebarTableCellView

- (BOOL)allowsVibrancy {
    return YES;
}

- (NSMutableDictionary *)currentTitleAttributes {
    if (!_currentTitleAttributes) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingHead;
        paragraphStyle.tighteningFactorForTruncation = 0.0f;
        _currentTitleAttributes = [@{
                                     NSFontAttributeName : [NSFont fontWithName:@"HelveticaNeue" size:14],
                                     NSForegroundColorAttributeName : [NSColor labelColor],
                                     NSParagraphStyleAttributeName: paragraphStyle
                                     } mutableCopy];
    }
    return _currentTitleAttributes;
}

- (NSDictionary *)titleAttributes {
    static dispatch_once_t onceToken;
    static NSDictionary *attributes;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingHead;
        paragraphStyle.tighteningFactorForTruncation = 0.0f;
        attributes = @{
                       NSFontAttributeName : [NSFont fontWithName:@"HelveticaNeue" size:14],
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
                               NSFontAttributeName : [NSFont fontWithName:@"HelveticaNeue" size:14],
                               NSForegroundColorAttributeName : [NSColor tertiaryLabelColor],
                               NSParagraphStyleAttributeName: paragraphStyle
                               };
    });
    return disabledAttributes;
}

- (LocalizableFile *)file {
    return (LocalizableFile *)self.objectValue;
}

- (void)updateUI {
    BOOL selected = self.file.selected;
    NSColor *textColor = selected ? [NSColor labelColor] : [NSColor tertiaryLabelColor];
    self.currentTitleAttributes[NSForegroundColorAttributeName] = textColor;
    self.labelFilepath.textColor = textColor;
    self.labelTotal.textColor = textColor;
    self.labelTotalNo.textColor = textColor;
    self.labelMissing.textColor = textColor;
    self.labelMissingNo.textColor = textColor;
    self.checkBox.state = self.file.selected ? NSOnState : NSOffState;
    
    NSString *filename = [self.file.original lastPathComponent];
    NSString *filepath = [self.file.original stringByDeletingLastPathComponent];
    filepath = [filepath stringByAppendingString:@"/"];
    self.checkBox.attributedTitle = [[NSAttributedString alloc] initWithString:filename attributes:self.currentTitleAttributes];
    self.labelFilepath.stringValue = filepath;
    self.labelTotalNo.stringValue = [NSString stringWithFormat:@"%lu", self.file.numberOfLocalizedStrings];
    self.labelMissingNo.stringValue = [NSString stringWithFormat:@"%lu", self.file.numberOfIncompleteLocalizedStrings];
}

- (void)setObjectValue:(id)objectValue {
    [super setObjectValue:objectValue];
    [self updateUI];
}

- (IBAction)checkboxClicked:(id)sender {
    self.file.selected = self.checkBox.state == NSOnState;
    [self updateUI];
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
