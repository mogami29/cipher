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
- (IBAction)startAnimation:(id)sender;
- (IBAction)stopAnimation:(id)sender;
- (IBAction)toggleAnimation:(id)sender;

- (void)performAnimation:(NSTimer *)aTimer;

@end
