//
//  SidebarCheckboxCell.m
//  EasyLocalize
//
//  Created by Sebastian Husche on 06.10.14.
//  Copyright (c) 2014 Sebastian Husche. All rights reserved.
//

#import "SidebarCheckboxCell.h"

@implementation SidebarCheckboxCell

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView {
    frame.origin.y -= 1.0f;
    frame.origin.x += 3.0f;
    frame.size.width -= 3.0f;
    return [super drawTitle:title withFrame:frame inView:controlView];
}

@end
