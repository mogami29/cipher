//app.cとappspeci.cの共通ヘッダー
#define FONTSIZE 18
#define LINEHEIGHT (FONTSIZE*3/2)
#define LEFTMARGIN 50
#define colWidth 450
//#define colWidth 200
#define colSep 30
#define nCols 1
extern WindowPtr currWindow;
extern int viewHeight;
extern float baseLine;
extern NSMutableAttributedString* theStr;
#import "MyView.h"
extern MyView* caller;
extern bool nowSelected;

void draw_integer(long i);
void drawSeparator(int length);
void scroll();			// in app.c
void myPrintf(char *fmt,...);
void print_str(char*s);
int getKey(int mode);

#if __cplusplus
extern "C" {
#endif
void addStringToText(char* string);
void initLines();
void newLine();
void HandleTyping(char c);
void HandleShifted(char c);
void HandleContentClick(NSPoint pt);
void HandleDragTo(NSPoint pt);
void DoUpdate(WindowPtr targetWindow);
void DoUndo();
NSString* copySelected();
void DoHide();
NSString* DoCut();
void insertCString(const char* str);
void setCString(const char *);
NSString* serializedString();
void DoLatex();
void DoPrint();
void ShowCaret();
void HideCaret();
void Redraw();
#if __cplusplus
}   // Extern C
#endif


#define NUL 0
#define BS	0x7F
#define CR 13

#define arrowLeft 	28
#define arrowRight 	29
#define arrowUp 		30
#define arrowDown 	31

#define balancedCR 0	// normal
#define shiftCR 	1	// DoOpen, edit
#define onlyCR 	2	// readline
