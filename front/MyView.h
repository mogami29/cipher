#import <Cocoa/Cocoa.h>
@interface MyView : NSView <NSTextInputClient>
{
    NSMutableString* line;
	int cursorOn;
	NSTimer *timer;

    NSMutableDictionary *dicAttr;
    NSFont *fontAttr;
    NSMutableAttributedString *backingStore;
    NSRange markedRange;
    NSRange selectedRange;
}
- (void) drawRect : (NSRect) rect;
- (void) keyDown : (NSEvent *) theEvent;
- (void) mouseDown:(NSEvent *) theEvent;
- (void) startAnimation;
- (void) stopAnimation;
- (void) toggleAnimation;
- (void)performAnimation:(NSTimer *)aTimer;
@end
