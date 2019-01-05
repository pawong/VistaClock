//
//  MZStatusItemView.h
//  VistaClock
//
//  Created by Paul Wong on 9/27/11.
//  Copyright 2011 Mazookie, LLC. All rights reserved.
//

#import <AppKit/AppKit.h>

#define StatusItemViewPaddingWidth  6
#define StatusItemViewPaddingHeight 3
#define StatusItemViewSecondaryPaddingHeight 1
#define StatusItemIconWidth 22

@interface MZStatusItemView : NSView
{
    NSStatusItem* statusItem;
    NSString* title;
    int titleWidth;
    NSString* subTitle1;
    NSString* subTitle2;

    NSImage* image;
    BOOL useDarkTheme;
    BOOL useInverseTitle;
    
    //id target;
    SEL action;
    BOOL isMenuVisible;
    int currentWidth;

    NSColor* foregroundColor;
    NSColor* backgroundColor;
}

-(void) setImage:(NSImage*) newImage;
-(void) setTitle:(NSString*) newTitle;
-(void) setTitles:(NSString*) newTitle subTitle1:(NSString*) newSubTitle1 subTitle2:(NSString*) newSubTitle2;
-(void) setDarkTheme:(BOOL) use;
-(void) setUseInverseTitle:(BOOL) use;

@property (retain, nonatomic) NSStatusItem* statusItem;
@property (assign) id target;
@property (assign) SEL action;

@end
