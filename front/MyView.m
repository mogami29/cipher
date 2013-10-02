#import "MyView.h"@implementation MyView- (void) drawRect : (NSRect) rect{//    [[NSColor whiteColor] set];//    NSRectFill([self bounds]);   // Equiv to [[NSBezierPath bezierPathWithRect:[self bounds]] fill]	NSMutableDictionary *dicAttr = [ NSMutableDictionary dictionary ];    NSFont *fontAttr;    [ dicAttr setObject : [ NSColor blueColor ]                forKey  : NSForegroundColorAttributeName ];                    fontAttr = [ NSFont fontWithName : @"Futura Condensed ExtraBold"                                size : 24 ];    [ dicAttr setObject : fontAttr                forKey  : NSFontAttributeName];    [line   drawAtPoint : NSMakePoint( 10, 10 )		 withAttributes : dicAttr ];        //NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];    CGFloat w = [[[NSAttributedString alloc] initWithString:line attributes:dicAttr] size].width;        NSPoint	point0 = {w + 10, 10 - [fontAttr descender]};    NSPoint	point1 = {w + 10, 10 - [fontAttr descender] + [fontAttr ascender]};    [NSBezierPath strokeLineFromPoint:point0 toPoint:point1];}- (void) awakeFromNib{    NSLog( @"awakeFromNib" );    [ [ self window ] makeFirstResponder : self ];    line = [[NSMutableString alloc] init];}- (void) keyDown : (NSEvent *) theEvent{    NSString* hoge = [theEvent characters];	BOOL bar = [hoge isEqualToString: @"\n"];//	bar;    [line appendString: hoge];    [self display];}- (void) mouseDown:(NSEvent *)theEvent{    [line setString: @"hoge"];    [self display];}// taken from Circleview but not understood yet.100407- (IBAction)startAnimation:(id)sender {    [self stopAnimation:sender];        // We schedule a timer for a desired 30fps animation rate.    // In performAnimation: we determine exactly    // how much time has elapsed and animate accordingly.//    timer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/30.0) target:self selector:@selector(performAnimation:) userInfo:nil repeats:YES] retain];        // The next two lines make sure that animation will continue to occur    // while modal panels are displayed and while event tracking is taking    // place (for example, while a slider is being dragged).    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];    //    lastTime = [NSDate timeIntervalSinceReferenceDate];}- (IBAction)stopAnimation:(id)sender {    [timer invalidate];//    [timer release];    timer = nil;}- (IBAction)toggleAnimation:(id)sender {    if (timer != nil) {        [self stopAnimation:sender];    } else {        [self startAnimation:sender];    }}- (void)performAnimation:(NSTimer *)aTimer {    // We determine how much time has elapsed since the last animation,    // and we advance the angle accordingly.//    NSTimeInterval thisTime = [NSDate timeIntervalSinceReferenceDate];//    [self setStartingAngle:startingAngle + angularVelocity * (thisTime - lastTime)];//    lastTime = thisTime;}@end