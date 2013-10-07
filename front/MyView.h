#import <Cocoa/Cocoa.h>
@interface MyView : NSView
{
    NSMutableString* line;
	int cursorOn;
	NSTimer *timer;
}
- (void) drawRect : (NSRect) rect;
- (void) awakeFromNib;
- (void) keyDown : (NSEvent *) theEvent;
- (void) mouseDown:(NSEvent *)theEvent;
// introduced from CircleView for test
- (void) startAnimation;
- (void) stopAnimation;
- (void) toggleAnimation;
- (void)performAnimation:(NSTimer *)aTimer;
@end
