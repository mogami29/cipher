#import "MyView.h"
#include "ciph.h"
#include "value.h"
#include "list.h"
#import "appSpeci.h"

float FONTSIZE = 12;
float colWidth = COLWIDTH;

@implementation MyView

#define larger(a, b) ((a) > (b) ? (a) : (b))

+ (BOOL)isCompatibleWithResponsiveScrolling{ return YES;}

- (void) drawRect : (NSRect) rect
{
    //[[NSColor whiteColor] set];
    //NSRectFill([self bounds]);   // Equiv to [[NSBezierPath bezierPathWithRect:[self bounds]] fill]
    NSAttributedString* str = [[NSAttributedString alloc] initWithString:line attributes:dicAttr];
    
    // taken from Core Text:Common Operations
    // Initialize a graphics context and set the text matrix to a known value.
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext]
                                          graphicsPort];
    CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1, -1));
    
    // Create a typesetter using the attributed string.
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(str));
    
    CFIndex start = 0;
    CTLineRef aline = nil;
    CGFloat ypos = 0.0;
    while (start < CFStringGetLength((__bridge CFStringRef)(str))){
        ypos = ypos - [fontAttr descender] + [fontAttr ascender]*1.5 + [fontAttr leading];
        // Find a break for line from the beginning of the string to the given width.
        CFIndex count = CTTypesetterSuggestLineBreak(typesetter, start, 200);
        
        // Use the returned character count (to the break) to create the line.
        aline = CTTypesetterCreateLine(typesetter, CFRangeMake(start, count));
        
        // Move the given text drawing position and draw the line.
        CGContextSetTextPosition(context, 10, 10 + ypos);
        CTLineDraw(aline, context);
        
        CFRelease(aline);
        // Move the index beyond the line break.
        start += count;
    }//*/
    CFRelease(typesetter);

    if (cursorOn){
        CGFloat ascent, descent, leading;
        double w = 0.0;
        if(aline) w = CTLineGetTypographicBounds(aline, & ascent, & descent, & leading );
        if ((start && ([line characterAtIndex:(start - 1)]=='\r')) || ypos==0.0) {
            ypos = ypos - [fontAttr descender] + [fontAttr ascender]*1.5 + [fontAttr leading];
            w = 0;
        }
/*        NSPoint	point0 = {w + 10, 10 + ypos };
        NSPoint	point1 = {w + 10, 10 + ypos - [fontAttr ascender]};
        [NSBezierPath strokeLineFromPoint:point0 toPoint:point1];*/
    }

/*    if (cursorOn) {
        ShowCaret();
    } else HideCaret();
*/
    text->theStr = backingStore;
    text->caller = self;
	if (![NSGraphicsContext currentContextDrawingToScreen]) {text->invalidateLayoutCache(); FONTSIZE = 12*0.8; colWidth = COLWIDTH*0.8;}// [self stopBlink];}
        text->Redraw(rect);
	if (![NSGraphicsContext currentContextDrawingToScreen]) {text->invalidateLayoutCache(); FONTSIZE = 12; colWidth = COLWIDTH;}// [self startBlink];}
    [self setFrameSize:NSMakeSize(500, larger(text->viewHeight, text->baseLine + FONTSIZE))];   // copy from updateFrame
}

- (void) drawCaretAt:(NSPoint)pt
{
    if (cursorOn && selectedRange.length==0) {
        CGFloat w = [backingStore attributedSubstringFromRange:NSMakeRange(0, selectedRange.location)].size.width;
        caretPosition = NSMakePoint((int)(pt.x + w), pt.y);
        NSPoint	point0 = {(int)(pt.x + w)+.5, pt.y };
        NSPoint	point1 = {(int)(pt.x + w)+.5, pt.y - FONTSIZE};
        [[NSColor blackColor] set];
        if ([NSGraphicsContext currentContextDrawingToScreen])
            [NSBezierPath strokeLineFromPoint:point0 toPoint:point1];
    }
}

- (void) setMode:(CRmode)m {
    text->setMode(m);
}

- (id) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    line = [[NSMutableString alloc] init];
    [self startBlink];
    text = new MathText;
    text->initLines();
    text->newLine();

    dicAttr = [ NSMutableDictionary dictionary ];
    [ dicAttr setObject : [ NSColor blackColor ]
                forKey  : NSForegroundColorAttributeName ];
    
    fontAttr = [ NSFont fontWithName : @"Helvetica"
                                size : FONTSIZE ];
    [ dicAttr setObject : fontAttr
                forKey  : NSFontAttributeName];
    backingStore = [[NSMutableAttributedString alloc] initWithString:@"" attributes:dicAttr];
    selectedRange = NSMakeRange(0, 0);
    markedRange = NSMakeRange(NSNotFound, 0);

    return self;
}

- (void) dealloc
{
    [self stopBlink];
}

- (void) updateFrame {
    NSRect clip = [[self superview] bounds];    // the clipview in the scrollview
    if(text->baseLine + FONTSIZE > clip.origin.y + clip.size.height) {     // we may expect size always positive
        NSPoint newScrollOrigin = NSMakePoint(0.0, text->baseLine + FONTSIZE - clip.size.height);
        [self scrollPoint:newScrollOrigin];
    }
    if(text->baseLine - FONTSIZE < clip.origin.y) {
        NSPoint newScrollOrigin = NSMakePoint(0.0, text->baseLine - FONTSIZE);
        [self scrollPoint:newScrollOrigin];
    }
    [self setFrameSize:NSMakeSize(500, larger(text->viewHeight, text->baseLine + FONTSIZE))];
}

// from Printing Programming Guide for Mac
- (IBAction)printDocument:(id)sender {
    NSPrintOperation *op;
    op = [NSPrintOperation printOperationWithView:self];
    if (op)
        [op runOperation];
    else
        ;// handle error here
}
/*
// from "Laying Out Page Content"
// Return the number of pages available for printing
- (BOOL)knowsPageRange:(NSRangePointer)range {
    NSRect bounds = [self bounds];
    float printHeight = [self calculatePrintHeight];
 
    range->location = 1;
    range->length = NSHeight(bounds) / printHeight + 1;
    return YES;
}

// Return the drawing rectangle for a particular page number
- (NSRect)rectForPage:(NSInteger)page {
    NSRect bounds = [self bounds];
    float pageHeight = [self calculatePrintHeight];
    return NSMakeRect( NSMinX(bounds), (page - 1) * pageHeight,
                        NSWidth(bounds), pageHeight );
}

// Calculate the vertical size of the view that fits on a single page
- (float)calculatePrintHeight {
    // Obtain the print info object for the current operation
    NSPrintInfo *pi = [[NSPrintOperation currentOperation] printInfo];
 
    // Calculate the page height in points
    NSSize paperSize = [pi paperSize];
    float pageHeight = paperSize.height - [pi topMargin] - [pi bottomMargin];
 
    // Convert height to the scaled view
    float scale = [[[pi dictionary] objectForKey:NSPrintScalingFactor]
                    floatValue];
    return pageHeight / scale;
}//*/

- (void) keyDown : (NSEvent *) theEvent
{
    NSString* str = [theEvent characters];
	//BOOL bar = [str isEqualToString: @"\n"];
    unichar key = 0;
    if ([str length]!=0) key = [str characterAtIndex:0];
    if ([str length] >= 2) NSLog(@"2 word char!");
    if (key == 0x7F || key >= 0xF700 ||1){  // 0x7F is delete
        //[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
        [[self inputContext] handleEvent:theEvent];
    } else {
        //[line appendString: str];
        text->HandleTyping(key);
    }
    cursorOn = true;
    [self updateFrame];
    NSRect clip = [[self superview] bounds];    // the clipview in the scrollview
	CGFloat top;
    CGFloat bottom;
    if(key==NSUpArrowFunctionKey || key==NSDownArrowFunctionKey || key==NSUpArrowFunctionKey || key==NSDownArrowFunctionKey) {
        top = caretPosition.y - LINEHEIGHT - FONTSIZE;
        bottom = caretPosition.y + LINEHEIGHT + FONTSIZE/2;
    } else {
        top = caretPosition.y - 2*LINEHEIGHT ;  // large enough for fractions
        bottom = clip.origin.y + clip.size.height;
    }
    [self displayRect:NSMakeRect(clip.origin.x, top, clip.size.width, bottom - top)];
	if(!(key==NSUpArrowFunctionKey || key==NSDownArrowFunctionKey)) text->setCursorBeforeVertMove();
}

- (void) insertText:(id)string
{
    //[line appendString: string];
    const char * s = [string cStringUsingEncoding:NSUTF16LittleEndianStringEncoding];
    if (!s) return;
    for(const unichar* p = (unichar*)s; *p; p++) text->HandleTyping(*p);
    // need update of framesize here
}

- (void)insertNewline:(id)sender
{
    text->HandleTyping(CR);
}

- (void) deleteBackward:(id)sender
{
    text->HandleTyping(BS);
}

- (void) deleteForward:(id)sender
{
    text->HandleTyping(arrowRight);     // There may be some trouble with this easy implementation.
    text->HandleTyping(BS);
}

- (void) insertTab:(id)sender
{
    text->HandleTyping('\t');
}

- (void) moveLeft:(id)sender    // what is moveBackward?
{
    text->HandleTyping(arrowLeft);
}

- (void) moveRight:(id)sender
{
    text->HandleTyping(arrowRight);
}

- (void) moveUp:(id)sender
{
    text->HandleTyping(arrowUp);
}

- (void) moveDown:(id)sender
{
    text->HandleTyping(arrowDown);
}

- (void)moveLeftAndModifySelection:(id)sender
{
    text->HandleShifted(arrowLeft);
}

- (void)moveRightAndModifySelection:(id)sender
{
    text->HandleShifted(arrowRight);
}

- (void)moveUpAndModifySelection:(id)sender
{
    text->HandleShifted(arrowUp);
}

- (void)moveDownAndModifySelection:(id)sender
{
    text->HandleShifted(arrowDown);
}


- (BOOL)isFlipped
{
    return YES;
}

// from "Creating Custom View"
- (void) mouseDown:(NSEvent *)event
{
    NSPoint clickLocation;
    
    // convert the mouse-down location into the view coords
    clickLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    text->HandleContentClick(clickLocation);
    
    /*
    BOOL itemHit = NO;
    // did the mouse-down occur in the item?
    itemHit = [self isPointInItem:clickLocation];
    
    // Yes it did, note that we're starting to drag
    if (itemHit) {
        // flag the instance variable that indicates
        // a drag was actually started
        dragging = YES;
        
        // store the starting mouse-down location;
        lastDragLocation = clickLocation;
    }*/
    text->setCursorBeforeVertMove();
    cursorOn = 1;
    [self setNeedsDisplay:YES];
}

- (void) mouseDragged:(NSEvent *)event
{
    NSPoint newDragLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    text->HandleDragTo(newDragLocation);
    /*
    // offset the item by the change in mouse movement
    // in the event
    [self offsetLocationByX:(newDragLocation.x-lastDragLocation.x)
                       andY:(newDragLocation.y-lastDragLocation.y)];
    
    // save the new drag location for the next drag event
    lastDragLocation = newDragLocation;
*/
    // support automatic scrolling during a drag
    // by calling NSView's autoscroll: method
    [self autoscroll:event];

    [self setNeedsDisplay:YES];
}

- (NSString *)string
{
    return text->serializedString();
}

- (void)setString:(NSString *)string
{
    text->setCString([string cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (void) undo:sender {
    text->DoUndo();
    [self setNeedsDisplay:YES];
}

- (void) redo:sender {
    NSLog(@"redo");
}

- (void) cut:sender {
    NSString *string = text->DoCut();
    if (string != nil) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        NSArray *copiedObjects = [NSArray arrayWithObject:string];
        [pasteboard writeObjects:copiedObjects];
    }
    [self updateFrame];
    [self setNeedsDisplay:YES];
}

// from Paste board Getting Started
- (void) copy:sender {
    NSString *string = text->copySelected();
    if (string != nil) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        NSArray *copiedObjects = [NSArray arrayWithObject:string];
        [pasteboard writeObjects:copiedObjects];
    }
}

- (void) paste:sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classArray = [NSArray arrayWithObject:[NSString class]];
    NSDictionary *options = [NSDictionary dictionary];
    
    BOOL ok = [pasteboard canReadObjectForClasses:classArray options:options];
    if (ok) {
        NSArray *objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        NSString *string = [objectsToPaste objectAtIndex:0];
        const char * s = [string cStringUsingEncoding:NSUTF8StringEncoding];
        assert(s);    // yen mark results in null pointer
        text->pasteCString(s);
    }
    [self updateFrame];
    [self setNeedsDisplay:YES];
}

- (void) hideText: sender{
    text->DoHide();
    [self setNeedsDisplay:YES];
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem {
    
    if ([anItem action] == @selector(cut:)) {
        return text->nowSelected;
    }
    if ([anItem action] == @selector(copy:)) {
        return text->nowSelected;
    }
    if ([anItem action] == @selector(undo:)) {
        return YES;
    }
    if ([anItem action] == @selector(redo:)) {
        return YES;
    }
    if ([anItem action] == @selector(hideText:)) {
        return text->nowSelected;
    }
    if ([anItem action] == @selector(paste:)) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        NSArray *classArray = [NSArray arrayWithObject:[NSString class]];
        NSDictionary *options = [NSDictionary dictionary];
        return [pasteboard canReadObjectForClasses:classArray options:options];
    }
    return [[self window] validateUserInterfaceItem:anItem];    // is asking to the window correct?
}

// taken from Circleview
- (void) startBlink {
    [self stopBlink];
    
    // We schedule a timer for a desired 30fps animation rate.
    // In performBlink: we determine exactly
    // how much time has elapsed and animate accordingly.
    timer = [NSTimer scheduledTimerWithTimeInterval:(1.0/2.0) target:self selector:@selector(performBlink:) userInfo:nil repeats:YES];
    
    // The next two lines make sure that animation will continue to occur
    // while modal panels are displayed and while event tracking is taking
    // place (for example, while a slider is being dragged).
    //[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
    //[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
    
    cursorOn = 1;
//    lastTime = [NSDate timeIntervalSinceReferenceDate];
}

- (void) stopBlink {
    [timer invalidate];
    timer = nil;
}

- (void) toggleBlink {
    if (timer != nil) {
        [self stopBlink];
    } else {
        [self startBlink];
    }
}

- (void)performBlink:(NSTimer *)aTimer {
    // We determine how much time has elapsed since the last animation,
    // and we advance the angle accordingly.
    //NSTimeInterval thisTime = [NSDate timeIntervalSinceReferenceDate];
    cursorOn = !cursorOn;
    //    lastTime = thisTime;
    if ([[self window] isKeyWindow])  // NSWindowDidResignKeyNotification notification may be useful too
        [self setNeedsDisplayInRect:NSMakeRect(caretPosition.x, caretPosition.y - FONTSIZE, 1, FONTSIZE)];
}

// From TextInputView
- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    return YES;
}

- (BOOL)resignFirstResponder {
    return YES;
}

#pragma mark -
/*
- (void)doCommandBySelector:(SEL)aSelector {
    [super doCommandBySelector:aSelector]; // NSResponder's implementation will do nicely
}*/

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange {
    // Get a valid range
    if (replacementRange.location == NSNotFound) {
        if (markedRange.location != NSNotFound) {
            replacementRange = markedRange;
        } else {
            replacementRange = selectedRange;
        }
    }
    
    // Add the text
    [backingStore beginEditing];
    // insert aString to backingstore and
    //[self insertText:[backingStore string]];
    [self insertText:aString ];
    text->removeSelected();
    [backingStore setAttributedString:[[NSAttributedString alloc] initWithString:@"" attributes:dicAttr]];
    [backingStore endEditing];
    
    // Redisplay
    [self unmarkText];
    selectedRange = NSMakeRange(0, 0);
    [[self inputContext] invalidateCharacterCoordinates]; // recentering
    [self setNeedsDisplay:YES];
}

- (void)setMarkedText:(id)aString selectedRange:(NSRange)newSelection replacementRange:(NSRange)replacementRange {
    // Get a valid range
    if (replacementRange.location == NSNotFound) {
        if (markedRange.location != NSNotFound) {
            replacementRange = markedRange;
        } else {
            replacementRange = selectedRange;
        }
    }
    
    // Add the text
    [backingStore beginEditing];
    if ([aString length] == 0) {
        [backingStore deleteCharactersInRange:replacementRange];
        [self unmarkText];
    } else {
        markedRange = NSMakeRange(replacementRange.location, [aString length]);
        if ([aString isKindOfClass:[NSAttributedString class]]) {
            [backingStore replaceCharactersInRange:replacementRange withAttributedString:aString];
        } else {
            [backingStore replaceCharactersInRange:replacementRange withString:aString];
        }
        [backingStore addAttributes:dicAttr range:markedRange];
    }
    [backingStore endEditing];
    text->removeSelected();
    
    // Redisplay
    selectedRange.location = replacementRange.location + newSelection.location; // Just for now, only select the marked text
    selectedRange.length = newSelection.length;
    [[self inputContext] invalidateCharacterCoordinates]; // recentering
    [self setNeedsDisplay:YES];
}

- (void)unmarkText {
    markedRange = NSMakeRange(NSNotFound, 0);
    [[self inputContext] discardMarkedText];
}

- (NSRange)selectedRange {
    return selectedRange;
}

- (NSRange)markedRange {
    return markedRange;
}

- (BOOL)hasMarkedText {
    return (markedRange.location == NSNotFound ? NO : YES);
}

- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange {
    // We choose not to adjust the range, though we have the option
    if (actualRange) {
        *actualRange = aRange;
    }
    return [backingStore attributedSubstringFromRange:aRange];
}

- (NSArray *)validAttributesForMarkedText {
    // We only allow these attributes to be set on our marked text (plus standard attributes)
    // NSMarkedClauseSegmentAttributeName is important for CJK input, among other uses
    // NSGlyphInfoAttributeName allows alternate forms of characters
    return [NSArray arrayWithObjects:NSMarkedClauseSegmentAttributeName, NSGlyphInfoAttributeName, nil];
}

- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange {
/*    // Ask the layout manager
    NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:aRange actualCharacterRange:actualRange];
    NSRect glyphRect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
    glyphRect.origin.x += centerOffset;
*/  NSRect glyphRect =  {caretPosition.x, caretPosition.y -FONTSIZE/2, 1, 1};

    // Convert the rect to screen coordinates
    glyphRect = [self convertRectToBase:glyphRect];
    glyphRect.origin = [[self window] convertBaseToScreen:glyphRect.origin];
    return glyphRect;
}

- (NSUInteger)characterIndexForPoint:(NSPoint)aPoint {
/*    // Convert the point from screen coordinates
    NSPoint localPoint = [self convertPointFromBase:[[self window] convertScreenToBase:aPoint]];
    localPoint.x -= centerOffset;
    
    // Ask the layout manager
    NSUInteger glyphIndex = [layoutManager glyphIndexForPoint:localPoint inTextContainer:textContainer fractionOfDistanceThroughGlyph:NULL];
    return [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
*/
    return 0;
}

- (NSAttributedString *)attributedString {
    // This method is optional, but our backing store is an attributed string anyway
    return backingStore;
}

- (NSInteger)windowLevel {
    // This method is optional but easy to implement
    return [[self window] level];
}
/*
- (CGFloat)fractionOfDistanceThroughGlyphForPoint:(NSPoint)aPoint {
    // This method is optional but would help with mouse-related activities, such as selection
    // Unfortunately we don't support selection
    
    // Convert the point from screen coordinates
    NSPoint localPoint = [self convertPointFromBase:[[self window] convertScreenToBase:aPoint]];
    localPoint.x -= centerOffset;
    
    // Ask the layout manager
    CGFloat fraction = 0.5;
    [layoutManager glyphIndexForPoint:localPoint inTextContainer:textContainer fractionOfDistanceThroughGlyph:&fraction];
    return fraction;
}

- (CGFloat)baselineDeltaForCharacterAtIndex:(NSUInteger)anIndex {
    // This method is optional but helps position other elements next to the characters, such as the box that allows you to choose which Chinese or Japanese characters you want to input.
    
    // Get the first glyph corresponding to this character
    NSUInteger glyphIndex = [layoutManager glyphIndexForCharacterAtIndex:anIndex];
    
    if (glyphIndex != NSNotFound) {
        // Ask the layout manager's typesetter
        return [[layoutManager typesetter] baselineOffsetInLayoutManager:layoutManager glyphIndex:glyphIndex];
    } else {
        // Fall back to the layout manager and font
        return [layoutManager defaultBaselineOffsetForFont:[defaultAttributes objectForKey:NSFontAttributeName]];
    }
}*/

// No implementation of -drawsVerticallyForCharacterAtIndex:, which means all characters are assumed to be drawn horizontally.
// This is consistent with the current behavior of NSLayoutManager.
// If you are drawing vertically, you should implement this method.

@end
