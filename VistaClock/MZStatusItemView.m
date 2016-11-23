//
//  MZStatusItemView.m
//  VistaClock
//
//  Created by Paul Wong on 9/27/11.
//  Copyright 2011 Mazookie, LLC. All rights reserved.
//

#import "MZStatusItemView.h"


@implementation MZStatusItemView

@synthesize statusItem, target, action;

-(id) initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) {
        statusItem = nil;
        image = nil;
        title = @"";
        subTitle1 = @"";
        subTitle2 = @"";
        currentWidth = titleWidth = 0;
        isMenuVisible = NO;
    }
    return self;
}

-(void) rightMouseDown:(NSEvent *)event 
{
    [[self menu] setDelegate:(id <NSMenuDelegate>)self];
    [statusItem popUpStatusItemMenu:[self menu]];
    [self setNeedsDisplay:YES];
}

-(void) mouseDown:(NSEvent *)event 
{
    [NSApp sendAction:self.action to:self.target from:self];
}

-(void) menuWillOpen:(NSMenu *)menu 
{
    isMenuVisible = YES;
    [self setNeedsDisplay:YES];
}

-(void) menuDidClose:(NSMenu *)menu 
{
    isMenuVisible = NO;
    [menu setDelegate:nil];    
    [self setNeedsDisplay:YES];
}

// set status item color
-(NSColor*) titleForegroundColor
{
    if (isMenuVisible || useDarkTheme)
    {
        return [NSColor whiteColor];
    }
    else 
    {
        return [NSColor blackColor];
    }
} // end of titleForegroundColor

// set status item color
-(void) setTitleColors
{
    if (isMenuVisible)
    {
        foregroundColor = [NSColor whiteColor];
        backgroundColor = [NSColor selectedMenuItemColor];
    }
    else
    {
        if (useDarkTheme)
        {
            if (useInverseTitle)
            {
                foregroundColor = [NSColor blackColor];
                backgroundColor = [NSColor whiteColor];
            }
            else
            {
                foregroundColor = [NSColor whiteColor];
                backgroundColor = [NSColor blackColor];
            }
        }
        else
        {
            if (useInverseTitle)
            {
                foregroundColor = [NSColor whiteColor];
                backgroundColor = [NSColor blackColor];
            }
            else
            {
                foregroundColor = [NSColor blackColor];
                backgroundColor = [NSColor whiteColor];
            }
        }
    }
} // end of setTitleColors

// style of status item
// subTitle1
-(NSDictionary*) topTitleAttributes
{
    // Use default menu bar font size
    NSFont *font = [NSFont fontWithName:@"Helvetica Neue" size:8];
    
    NSColor *fColor = [self titleForegroundColor];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName
        , fColor, NSForegroundColorAttributeName, nil];
} // end of topTitleAttributes

// subtitle2
-(NSDictionary*) bottomTitleAttributes
{
    // Use default menu bar font size
    NSFont *font = [NSFont fontWithName:@"Helvetica Neue" size:10];
    
    NSColor *fColor = [self titleForegroundColor];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName
            , fColor, NSForegroundColorAttributeName, nil];
} // end of bottomTitleAttributes

// main title
-(NSDictionary*) titleAttributes
{
    // Use default menu bar font size
    NSFont *font = [NSFont fontWithName:@"Helvetica Neue" size:[[NSFont menuBarFontOfSize:-1] pointSize]];
    
    [self setTitleColors];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName
        , foregroundColor, NSForegroundColorAttributeName, nil];
} // end of titleAttributes


// status title rect
-(NSRect) titleBoundingRect 
{
    NSRect retval = [title boundingRectWithSize:NSMakeSize((int32_t)1e100
    , (int32_t)1e100) options:(int32_t)0 attributes:[self titleAttributes]];
    return retval;
} // end of titleBoundingRect


// status subtitle rect
-(NSRect) subTitleBoundingRect
{
    NSRect retval;
    NSRect top = [subTitle1 boundingRectWithSize:NSMakeSize((int32_t)1e100
        , (int32_t)1e100) options:(int32_t)0 attributes:[self topTitleAttributes]];
    NSRect bottom = [subTitle2 boundingRectWithSize:NSMakeSize((int32_t)1e100
        , (int32_t)1e100) options:(int32_t)0 attributes:[self bottomTitleAttributes]];
    retval = (top.size.width > bottom.size.width) ? top : bottom;
    return retval;
} // end of subTitleBoundingRect


// sets the status items title
-(void) setTitle:(NSString*)newTitle
{
    title = [newTitle copy];
        
    // Update status item size (which will also update this view's bounds)
    NSRect titleBounds = [self titleBoundingRect];
    currentWidth = (int)titleBounds.size.width + (int)(StatusItemViewPaddingWidth);
    if ((int)titleBounds.size.width)
        currentWidth = currentWidth + (int)(StatusItemViewPaddingWidth);
    titleWidth = currentWidth;
    if (image != nil)
    {
        // room for the icon
        [statusItem setLength:currentWidth + StatusItemIconWidth 
            + StatusItemViewPaddingWidth];
    }
    else
    {
        [statusItem setLength:currentWidth];
    }
    
    // force draw the status
    [self setNeedsDisplay:YES];
} // end of setTitle


// sets the status items title and subtitles
-(void) setTitles:(NSString*)newTitle subTitle1:(NSString*) newSubTitle1
    subTitle2:(NSString*) newSubTitle2
{
    title = [newTitle copy];
    subTitle1 = [newSubTitle1 copy];
    subTitle2 = [newSubTitle2 copy];
    
    // Update status item size (which will also update this view's bounds)
    NSRect titleBounds = [self titleBoundingRect];
    currentWidth = (int)titleBounds.size.width + (int)(2*StatusItemViewPaddingWidth);
    titleWidth = currentWidth;
    
    // add subtitles?
    if (subTitle1 != nil && subTitle2 != nil)
    {
        NSRect subTitleBounds = [self subTitleBoundingRect];
        currentWidth = currentWidth + (int)subTitleBounds.size.width
            + StatusItemViewPaddingWidth;
    }
    
    // use icon?
    if (image != nil)
    {
        // room for the icon
        [statusItem setLength:currentWidth + image.size.width + StatusItemViewPaddingWidth];
    }
    else
    {
        [statusItem setLength:currentWidth];
    }
    
    // force draw the status
    [self setNeedsDisplay:YES];
} // end of setTitles


// set the status items icon
-(void) setImage:(NSImage*)newImage
{
    image = [newImage copy];
} // end of setImage


// get the title
- (NSString*) title
{
    return title;
} // end of title


// get the subTitle1
-(NSString*) subTitle1
{
    return subTitle1;
} // end of subTitle1


// get the subTitle2
-(NSString*) subTitle2
{
    return subTitle2;
} // end of subTitle2


// must do the drawing
-(void) drawRect:(NSRect)rect 
{
    // Draw status bar background, highlighted if menu is showing
    [statusItem drawStatusBarBackgroundInRect:[self bounds] withHighlight:isMenuVisible];

    // set text origin
    NSPoint textOrigin = NSMakePoint(StatusItemViewPaddingWidth, StatusItemViewPaddingHeight);

    // Draw boarder
    if (useInverseTitle && !isMenuVisible && [title length] != 0)
    {
        NSRect titleRect = [self titleBoundingRect];
        NSRect newRect = NSMakeRect(textOrigin.x-2, textOrigin.y-1, titleRect.size.width+4, titleRect.size.height-2);
        [NSBezierPath setDefaultLineWidth:1.0];
        NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:newRect xRadius:5.0 yRadius:5.0];
        [path setLineJoinStyle:NSRoundLineJoinStyle];
        [backgroundColor set];
        [path fill];
    }

    // Draw title string
    [title drawAtPoint:textOrigin withAttributes:[self titleAttributes]];
    
    // use icon?
    if (image != nil)
    {
        NSPoint p = {titleWidth, 1};
        [image drawAtPoint:p fromRect:[self bounds] operation:NSCompositeSourceOver fraction:1.0];
    }
    
    // add subtitles?
    if (subTitle1 != nil && subTitle2 != nil)
    {
        int padWidth = ((image != nil)?(StatusItemViewPaddingWidth +
            StatusItemIconWidth + titleWidth):(titleWidth));
        NSPoint originTop= NSMakePoint(padWidth, StatusItemViewSecondaryPaddingHeight +10);
        NSPoint originBottom = NSMakePoint(padWidth, StatusItemViewSecondaryPaddingHeight);
        [subTitle1 drawAtPoint:originTop withAttributes:[self topTitleAttributes]];
        [subTitle2 drawAtPoint:originBottom withAttributes:[self bottomTitleAttributes]];
    }
} // end of drawRect


-(void) setDarkTheme:(BOOL) use
{
    useDarkTheme = use;
} // end of setDarkTheme

-(void) setUseInverseTitle:(BOOL) use
{
    useInverseTitle = use;
} // end of setInverseColors

@end






