//
//  CustomPlaceHolderTextColorTextField.m
//  LiquorStoreApp
//
//  Created by Vanguard on 11/5/14.
//  Copyright (c) 2014 ParthPatel. All rights reserved.
//

#import "CustomPlaceHolderTextColorTextField.h"

@implementation CustomPlaceHolderTextColorTextField

-(void) drawPlaceholderInRect:(CGRect)rect  {
    if (self.placeholder)
    {
        // color of placeholder text
        UIColor *placeHolderTextColor = [UIColor whiteColor];

        CGSize drawSize = [self.placeholder sizeWithAttributes:[NSDictionary dictionaryWithObject:self.font forKey:NSFontAttributeName]];
        CGRect drawRect = CGRectMake(rect.origin.x, (rect.size.height- self.font.pointSize)/2, rect.size.width, self.font.pointSize);
        
        // verticially align text
        drawRect.origin.y = (rect.size.height - drawSize.height) * 0.5;
        
        // set alignment
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = self.textAlignment;
        
        // dictionary of attributes, font, paragraphstyle, and color
        NSDictionary *drawAttributes = @{NSFontAttributeName: self.font,
                                         NSParagraphStyleAttributeName : paragraphStyle,
                                         NSForegroundColorAttributeName : placeHolderTextColor};
        
        
        // draw
        [self.placeholder drawInRect:drawRect withAttributes:drawAttributes];
//        [self.placeholder drawInRect:drawRect withFont:self.font lineBreakMode:NSLineBreakByWordWrapping alignment:self.textAlignment];
    }
}

@end