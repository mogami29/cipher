//app.cÇ∆appspeci.cÇÃã§í ÉwÉbÉ_Å[
extern float FONTSIZE;
#define LINEHEIGHT (FONTSIZE*3/2)
#define LEFTMARGIN 20
#define COLWIDTH 450
extern float colWidth;
#define colSep 30
#define nCols 1
#define viewWidth 500
/*extern WindowPtr currWindow;
extern int viewHeight;
extern float baseLine;
extern NSMutableAttributedString* theStr;
#import "MyView.h"
extern MyView* caller;
extern bool nowSelected;*/

void draw_integer(long i);
void drawSeparator(int length);
void scroll();			// in app.c
void myPrintf(char *fmt,...);
void print_str(char*s);
int getKey(int mode);

typedef enum {  // copied to Document.h
    session,
    editor
} CRmode;
#if __cplusplus
extern "C" {
#endif
/*void setMode(CRmode m);
void addStringToText(char* string);
void initLines();
void newLine();
void removeSelected();
void HandleTyping(unichar c);
void HandleShifted(unichar c);
void HandleContentClick(NSPoint pt);
void HandleDragTo(NSPoint pt);
void DoUpdate(WindowPtr targetWindow);
void DoUndo();
NSString* copySelected();
void DoHide();
NSString* DoCut();
void pasteCString(const char* str);
void setCString(const char *);
NSString* serializedString();
void DoLatex();
void DoPrint();
void ShowCaret();
void HideCaret();
void Redraw(NSRect rect);
void setCursorBeforeVertMove();*/
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

struct insp {
	int pos;            // position in curstr
	list *curstr;       // current string
	list *lpos;         // pos-th of curstr. アクセサ関数の中からのみ変更されている。
    char* curcstr;
    
	inline void moveInto(list *l){
		curstr = l;
		lpos = l;
		pos = 0;
        curcstr = nil; }
	inline void moveRightmost(list *l){
		curstr = l;
		pos = length(*l);
		lpos = rest(l, pos);
        curcstr = nil; }    // cstr until here
	inline insp(list *curstr, list* l, int i):curstr(curstr), lpos(l), pos(i) {}
	inline insp(list* l, int i):curstr(l), pos(i) {lpos = rest(l,i);}
	inline insp():curstr(nil), pos(0), lpos(nil), curcstr(nil){};
	inline void setpos(int p){
		if(curstr){
            lpos = rest(curstr, p);
            pos = p;
            curcstr = nil;
        } else {
            lpos = nil;
            pos = p;
        }
    }
	inline list* list_point(){
        assert(lpos);   // not implemented for curCstr != nil
        return lpos;
		return rest(curstr, pos);
	}
};


struct MathText { public:

int viewPosition;
// list lines;
//---------current line with insertion point object---------------------------

list line;
int startOfThisLine;	//絶対座標, multiple lineのときの始め。

NSPoint cursorPosition;
float baseLine;// ほかに使っているのはplot()
                // baseLine ~ カーソル位置。描画なしでの予測と解釈できる
                // line編集中はcursorPositionと同時に変更を行う。

list drawList;
list insList;// insertion point のスタック（先頭の要素が、一番内側の方。） (list of "Int")
                        // insと合わせてinsertion pointを表す
                        // ins.posは実質insListの先頭。
list	beginSelList;
insp beginOfSel, ins;		//insは現在のinsertion point

inline bool equalsToCursor(list* curline, list l, int pos){
    if(!ins.curstr) return false;
    // assert((curline==ins.curstr && l == *ins.lpos) == (equal(insList, drawList) && pos == ins.pos));
    return(curline==ins.curstr && l == *ins.lpos);
}
inline bool equalsToCursor(char* curline, int pos){
    if(!ins.curcstr) return false;
    return(curline==ins.curcstr && pos == ins.pos);
}


    NSPoint curPt;
    NSMutableDictionary *dicAttr;
    NSFont *fontAttr;
    void GetPen(NSPoint * pt);
    void MoveTo(float h, float v);
    void Line(float h, float v);
    void Move(float h, float v);
    void TextSize(float s);
    float StringWidth(NSString* s1);
    void DrawString(NSString *s1);
    float StringWidth(const char * str);
    void DrawString(const char * str);
    void drawFraction(list_* f, bool draw);
    void drawSuperScript(obj v, bool draw);
    void drawSubScript(obj v, bool draw);
    bool crossed;
    void drawACharOrABox(list& l, int& pos, bool draw);
    inline int getInsertionCloseTo0(list& l, int &pos, float h, int& curr_mark);
    void findInsertionCloseTo(float h, int &next, int &prev);
    NSMutableAttributedString* theStr;
    MyView* caller;
    insp click;
    NSPoint clickpnt;
    NSPoint curclick;
    bool drawFragment0(insp& ip, bool draw);
    void drawFragment(obj line, bool draw);
    int viewHeight = 100;
    NSRect updateRect;
    node<int>* yposOfLines = nil;
    node<insp>* pointerToLines = nil;
    node<int>** il;
    node<insp>** ll;
    void startLineWith(insp i);
    insp toUpperLevel(insp ip);
    void drawLine(list*line, bool draw);
    void drawLine0(list*line, bool draw);
    void invalidateLayoutCache();
    float getWidth(obj str);
    void showPlot(obj y);
    //void drawObj(obj line);
    void Redraw(NSRect rect);
    //----------
    inline void set_insp(int pos);
    int findPreviousLetter();
    int findPreviousLine();
    int findBeginOfThisLine();
    list deleteALetter0();
    void putinUndobuf(list l);
    void deleteALetter();
    int peekPreviousLetter();
    inline void insert0(obj v);
    void insert(obj v);
    void pushInsertion();
    int popInsertion();
    void moveIntoNum(list_* fr);
    void moveIntoDenom(list_* fr);
    void insertFraction(list num, list denom);
    list* curr_str(list l);
    list ins_list(list*scan, list*cstr);	// finding insList from curstr
    list isInFracRecur();
    bool isInFrac();
    void moveToUpperLevel();
    int getNLine(list l);
    void insertSuperScriptAndMoveInto();
    void insertSubScriptAndMoveInto();
    obj peekPrevious();
    obj peekNext();
    void moveToLast();
    bool isAtLast();

NSPoint cursorBeforeVertMove;

NSPoint selectionCursorPosition;
bool nowSelected;

// didBufのデータ形式の定義
// 	list of insert_string("hoge"), move_to(list ins), delete(int n)
// undoBufのデータ形式の定義
//		delete(int n), move_to(list ins), insert_string("hoge")

//いまのところundobufをつかい1-levelのundoだけ
list didBuf;
list undoBuf;
obj undobuf;

    obj editline(obj v);
    obj edit(obj fn);
    void DoLatex();
    NSString* serializedString();
    void setCString(const char* str);
    void pasteCString(const char* str);
    NSString* DoCut();
    void DoHide();
    NSString* copySelected();
    void DoUndo();
    void HandleDragTo(NSPoint pt);
    void HandleContentClick(NSPoint pt);
    void getClickPosition(NSPoint pt);
    void HandleShifted(unichar c);
    void highlightSelected();
    void HandleTyping(unichar c);
    void setMode(CRmode m);
    CRmode mode;
    void handleCR();
    Interpreter	interpreter;
    void setCursorBeforeVertMove();
    int halfchar = 0;
    void HandleTyping0(unichar c);
    void removeSelected();
    void updateAround(bool erase);
    void print_str(char*s);
    void addStringToText(char* string);
    void addLineToText(obj line);
    void addObjToText(obj v);
    void initLines();
    void newLine0();
    void newLine();
    void scroll();
    void scrollBy(int points);
    void HideCaret();
    void ShowCaret();
    int caretState;	//==0 if hidden, ==1 if shown
    void moveLeft();
    void moveRight();
    list cutSelected();
    void moveUp();
    void moveDown();
//------
}; // MathText::
