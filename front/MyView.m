#import "MyView.h"
@implementation MyView

- (void) drawRect : (NSRect) rect 
{
//    [[NSColor whiteColor] set];
//    NSRectFill([self bounds]);   // Equiv to [[NSBezierPath bezierPathWithRect:[self bounds]] fill]
	NSMutableDictionary *dicAttr = [ NSMutableDictionary dictionary ];
    NSFont *fontAttr;
    [ dicAttr setObject : [ NSColor blackColor ]
                forKey  : NSForegroundColorAttributeName ];
                
    fontAttr = [ NSFont fontWithName : @"Helvetica"
                                size : 24 ];
    [ dicAttr setObject : fontAttr
                forKey  : NSFontAttributeName];
    NSAttributedString* str = [[NSAttributedString alloc] initWithString:line attributes:dicAttr];
    //[str drawAtPoint : NSMakePoint( 10, 10 )];
    /*if (cursorOn){
        CGFloat w = [str size].width;
        
        NSPoint	point0 = {w + 10, 10 - [fontAttr descender]};
        NSPoint	point1 = {w + 10, 10 - [fontAttr descender] + [fontAttr ascender]};
        [NSBezierPath strokeLineFromPoint:point0 toPoint:point1];
    }*/
    
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
        
        // Move the index beyond the line break.
        start += count;
    }//*/

    if (cursorOn){
        CGFloat ascent, descent, leading;
        double w = 0.0;
        if(aline) w = CTLineGetTypographicBounds(aline, & ascent, & descent, & leading );
        if ((start && ([line characterAtIndex:(start - 1)]=='\r')) || ypos==0.0) {
            ypos = ypos - [fontAttr descender] + [fontAttr ascender]*1.5 + [fontAttr leading];
            w = 0;
        }
        NSPoint	point0 = {w + 10, 10 + ypos };
        NSPoint	point1 = {w + 10, 10 + ypos - [fontAttr ascender]};
        [NSBezierPath strokeLineFromPoint:point0 toPoint:point1];
    }
}

- (id) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    line = [[NSMutableString alloc] init];
    cursorOn = 1;
    [self startAnimation];
    [self setFrameSize:NSMakeSize(500, 1000)];
    return self;
}

- (void) dealloc
{
    [self stopAnimation];
}

/*- (void) awakeFromNib
{
    NSLog( @"awakeFromNib" );
    [ [ self window ] makeFirstResponder : self ];
    line = [[NSMutableString alloc] init];
    cursorOn = 1;
    [self startAnimation];
    [self setFrameSize:NSMakeSize(500, 1000)];
}*/

- (void) keyDown : (NSEvent *) theEvent
{
    NSString* hoge = [theEvent characters];
//	BOOL bar = [hoge isEqualToString: @"\n"];
//	bar;
    cursorOn = true;
    [line appendString: hoge];
    [self display];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void) mouseDown:(NSEvent *)theEvent
{
    [line setString: @"hoge"];
    [self display];
}

// taken from Circleview
- (void) startAnimation {
    [self stopAnimation];
    
    // We schedule a timer for a desired 30fps animation rate.
    // In performAnimation: we determine exactly
    // how much time has elapsed and animate accordingly.
    timer = [NSTimer scheduledTimerWithTimeInterval:(1.0/2.0) target:self selector:@selector(performAnimation:) userInfo:nil repeats:YES];
    
    // The next two lines make sure that animation will continue to occur
    // while modal panels are displayed and while event tracking is taking
    // place (for example, while a slider is being dragged).
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
    
//    lastTime = [NSDate timeIntervalSinceReferenceDate];
}

- (void) stopAnimation {
    [timer invalidate];
//    [timer release];
    timer = nil;
}

- (void) toggleAnimation {
    if (timer != nil) {
        [self stopAnimation];
    } else {
        [self startAnimation];
    }
}

- (void)performAnimation:(NSTimer *)aTimer {
    // We determine how much time has elapsed since the last animation,
    // and we advance the angle accordingly.
    //NSTimeInterval thisTime = [NSDate timeIntervalSinceReferenceDate];
    cursorOn = !cursorOn;
    //    lastTime = thisTime;
    [self setNeedsDisplay:YES];
    // use later: - (void)setNeedsDisplayInRect:(NSRect)invalidRect
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

@end
