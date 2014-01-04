#import <Cocoa/Cocoa.h>
@interface MyView : NSView <NSTextInputClient>
{
    NSMutableString* line;
	int cursorOn;
    NSPoint caretPosition;
	NSTimer *timer;

    NSMutableDictionary *dicAttr;
    NSFont *fontAttr;
    NSMutableAttributedString *backingStore;
    NSRange markedRange;
    NSRange selectedRange;
    
    struct MathText* text;
}
- (void) drawRect : (NSRect) rect;
- (void) drawCaretAt : (NSPoint) pt;
- (void) updateFrame;
- (void) keyDown : (NSEvent *) theEvent;
- (void) mouseDown:(NSEvent *) theEvent;
- (void) startBlink;
- (void) stopBlink;
- (void) toggleBlink;
- (void) performBlink:(NSTimer *)aTimer;
@end
