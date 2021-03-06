/*	AppSpeci 2002-06, 2013- Tsuguo Mogami  */
#include "ciph.h"
#include "value.h"
#include "list.h"
#import "MyView.h"
#include "appSpeci.h"
#include <string.h>
//#include "lib.h"
#include "vector.h"

#import <Cocoa/Cocoa.h>




struct MathText* icaller;
char* cacheForUnitTest = nil;


void showPlot(obj y);
void drawLine(list*line, bool draw);
float getWidth(obj string);
void drawFragment(obj line, bool draw);
int findPreviousLine();
list CStringToLine(obj str);
void serialize(string*rs, list l, list end);
char* listToCString(list l);
//-----
inline int_* create(ValueType t, int i){
	int_* r = (int_*)alloc();
	r->type = t;
	uint(r) = i;
	return r;
}
class frac: public list_ {
public:
	frac();
	~frac() {}
};


#include <setjmp.h>
jmp_buf jmpEnv;

void assert_func(const char* file, int line){
	NSLog(@"assertion failure line %d in %s.", line, file);
	//longjmp(jmpEnv, 1);
}

void error_func(const char *str, const char* file, int line){
	myPrintf("error: %s occured in line %d of file %s\n", str, line, file+43);
	longjmp(jmpEnv, 1);
}

void exit2shell(){
    NSLog(@"exit requested (but not done)");
    longjmp(jmpEnv, 1);
}


typedef node<int>* intlist;
typedef node<list*>* listlist;
template <class T> node<T>** rest(node<T>** l){return &((*l)->d);}

node<int>* cons(int v, node<int>* l){
	node<int>* nn = (node<int>*)node_alloc<obj>();  //platform dependent: cast may cause trouble with the position of refcount
    //	L nn = new node<T>();
	nn->a = v;
	nn->d = l;
	return nn;
}
node<insp>* cons(insp v, node<insp>* l){
	node<insp>* nn = (node<insp>*)malloc(sizeof(node<insp>));  //platform dependent: cast may cause trouble with the position of refcount
    //	L nn = new node<T>();
	nn->a = v;
	nn->d = l;
	return nn;
}/*/
template <class T> node<T>* cons(T v, node<T>* l){       // don't know why it does not work
 node<T>* nn = (node<T>*)node_alloc<obj>();
 //	L nn = new node<T>();
 nn->a = v;
 nn->d = l;
 return nn;
 }//*/
/*template <class T> void surface_free(node<T>* p){
	node<T>* next;
	for( ; p; p=next){
		next = p->d;
		assert(p->refcount);
		node_free((node<obj>*)p);
	}
}*/
void surface_free(node<int>* p){
	node<int>* next;
	for( ; p; p=next){
		next = p->d;
		assert(p->refcount==1);
		node_free((node<obj>*)p);
	}
}
void surface_free(node<insp>* p){
	node<insp>* next;
	for( ; p; p=next){
		next = p->d;
		free(p);
	}
}

template <class T> T& first(node<T>* l){ return l->a;}

void rememberYPos(int y, obj v){     // v want to be either obj or list*
}

int find(list l, list line){
    int p = 0;
    for (; line; line=rest(line), p++) if(l==line) return p;
    if(l!=nil) assert(0);
    return p;
}



//-----------draw functions----------

void MathText::GetPen(NSPoint * pt){
    *pt = curPt;
}
void MathText::MoveTo(float h, float v){
    curPt.x = h;
    curPt.y = v;
}
void MathText::Line(float h, float v){
    const float w = 0.5;
    NSPoint	point0 = {(float)curPt.x, (int)curPt.y + w/2};
    NSPoint	point1 = {(float)curPt.x + h, (int)curPt.y + v + w/2};
    //[NSBezierPath strokeLineFromPoint:point0 toPoint:point1];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineWidth:w];
    [path moveToPoint:point0];
    [path lineToPoint:point1];
    [path stroke];
    curPt.x += h;
    curPt.y += v;
}
void MathText::Move(float h, float v){
    curPt.x += h;
    curPt.y += v;
}
void MathText::TextSize(float s){
    // setting text font size
    fontAttr = [ NSFont fontWithName : font size : s ];
    [ dicAttr setObject : fontAttr
                forKey  : NSFontAttributeName];
}
float MathText::StringWidth(NSString* s1){
    NSAttributedString* attStr = [[NSAttributedString alloc] initWithString:s1 attributes:dicAttr];
    CGFloat w = [attStr size].width;
    return w;
}
void MathText::DrawString(NSString *s1){
    NSAttributedString* attStr = [[NSAttributedString alloc] initWithString:s1 attributes:dicAttr];
    [attStr drawAtPoint : NSMakePoint( curPt.x, curPt.y - [fontAttr ascender] + [fontAttr descender])];
    CGFloat w = [attStr size].width;
    curPt.x += w;
}
/*/
void MathText::DrawString(NSString *s1){
    NSAttributedString* attrStr = [[NSAttributedString alloc] initWithString:s1 attributes:dicAttr];
    // from "Common Text Layout Operations"
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attrStr);
    // Set text position and draw the line into the graphics context
    CGContextSetTextPosition(context, curPt.x, curPt.y);
    CTLineDraw(line, context);
    CFRelease(line);
    // c.f. note 131117
    curPt = CGContextGetTextPosition(context);
}//*/
float MathText::StringWidth(const char * str){
    NSString* s1 = [[NSString alloc] initWithCString:(char*)str encoding:NSUTF8StringEncoding];
    assert(s1);
    return StringWidth(s1);
}
void MathText::DrawString(const char * str){
    NSString* s1 = [[NSString alloc] initWithCString:(char*)str encoding:NSUTF8StringEncoding];
    assert(s1);
    DrawString(s1);
}

//the lowest 2 bits
// 00: others
// 01: direct integer
// 10: not used
// 11: a character
#define dVal	3	// mask
#define idInt	1
#define idStr	2
//#define idChar	3
void setType(obj v, ValueType t){
	v->type = t;
}
inline obj dInt(long i){return (obj)((i<<2)+1);}
inline long rInt(obj v){return (long)v>>2;}
ValueType typeD(obj v){
    if(((long)v & dVal) == 0) return type(v);
    if(((long)v & dVal) == idInt) return INT;
    return (ValueType)-((long)v & dVal);
}
#define type typeD
obj retainD(obj v){
    if(((long)v & dVal) == 0) return retain(v);
    else return v;
}
//#define retain retainD
/*void releaseD(obj v){
    if((long)v & dVal) return;
    else release(v);
}
void releaseD(L p){
	L next;
	for( ; p; p=next){
		next = rest(p);
		if((p->refcount)-1) {--(p->refcount); return;}
		releaseD(p->a);
		node_free(p);
	}
}
#define release releaseD*/
long vrIntD(obj v){
    if(((long)v & dVal) == 0) return vrInt(v);
    else return (long)v >>2;
}
#define vrInt vrIntD

#define uint(v) ((long)v & dVal ? (int)rInt(v) : ((int_*)v)->intv)
//#define Int dInt
//*/

void MathText::drawFraction(list_* f, bool draw){
	NSPoint pt;
	GetPen(&pt);
	assert(type(f)==FRACTION);
	float numerWidth = getWidth(em0(f));
	float denomWidth = getWidth(em1(f));
	float width = 2 + larger(numerWidth, denomWidth) +2;
	MoveTo(pt.x, pt.y-FONTSIZE/3);
	if(draw) Line(width,0);
	MoveTo(pt.x+width/2-numerWidth/2, pt.y-FONTSIZE*2/3);
	drawList = cons(Int(1), drawList);
        drawFragment(em0(f), draw);
    vrInt(pop(&drawList));
	MoveTo(pt.x+width/2-denomWidth/2, pt.y+FONTSIZE);
	drawList = cons(Int(2), drawList);
        drawFragment(em1(f), draw);
    vrInt(pop(&drawList));
	MoveTo(pt.x+width+2, pt.y);
}
void MathText::drawSuperScript(obj v, bool draw){
	Move(0,-FONTSIZE*1/2);
	TextSize(FONTSIZE*3/4);
	assert(type(v)==SuperScript);
	drawFragment(v, draw);
	TextSize(FONTSIZE);
	Move(0,FONTSIZE*1/2);
}
void MathText::drawSubScript(obj v, bool draw){
	Move(0,+FONTSIZE/4);
	TextSize(FONTSIZE*3/4);
	assert(type(v)==SubScript);
	drawFragment(v, draw);
	TextSize(FONTSIZE);
	Move(0,-FONTSIZE/4);
}
// CRは行末に付属すると考える。

bool isWide(unichar c){return (c & 0xF800) == 0xD800;}

NSString* read(list& l){
	obj v = first(l);
    assert(type(v)==INT);
    unichar buf[3];
    // read
    int c = uint(v);
    int len = 1;
    buf[0] = c;
    //buf[1] = NULL;
    if(isWide(c)){
        if(! rest(l)) return nil;
        if(type(second(l)) != INT) return nil;
        buf[1] = uint(second(l));
        //buf[2] = NULL;
        len = 2;
    }
    return [[NSString alloc] initWithCharacters:buf length:len];
}
void MathText::drawACharOrABox(list& l, int& pos, bool draw){
	NSPoint pt;
	obj v = first(l);
    /*if(((long)v&dVal)==idStr) {
        char* s = ((char*)v) -idStr;
        DrawString(s);
        return;
     }*/
    if (type(v)==INT) {
        int c = uint(v);
        NSString* s = read(l);
		//draw:
		if(c=='\t') {
			if(draw) DrawString("    "); else Move(StringWidth("    "), 0);
			return;
		}
		if(!draw || pt.y < -FONTSIZE) Move(StringWidth(s), 0);
        else	DrawString(s);
		return;
    }
    drawList = cons(Int(pos+1), drawList);
	switch(type(v)){
    case FRACTION:
		drawFraction((list_*)v, draw);
		break;
	case SuperScript:
		drawSuperScript(v, draw);
		break;
	case SubScript:
		drawSubScript(v, draw);
		break;
	case tShow:
		DrawString("▽");
		drawLine0(&ul(v), draw);
		DrawString("▽");
		break;
    case tHide:
		DrawString("△");
		break;
    case STRING:
        if(draw) DrawString(ustr(v)); else Move(StringWidth(ustr(v)), 0);
        break;
    case IMAGE:
    case tCImg:
        if(draw) show_image(v);
        break;
    case tPlot:
        Move(0, 200);
        if(draw) showPlot(v);
        break;
	case tCanvas:		// if(typeid(*v)==typeid(canvas)) {
		Move(0, 400);
		if(draw) drawCanvas((canvas*)v);
		break;
	default:
		assert(0);
	}
    vrInt(pop(&drawList));
	return;
}

void step(list& l, int& pos){
    obj v = first(l);
    if(type(v)==INT && isWide(uint(v)) && rest(l) && type(second(l))==INT){
        pos++; l=rest(l);
    }
    pos++, l=rest(l);
}
void step(insp& ip){
    obj v = first(*ip.lpos);
    if(type(v)==INT && isWide(uint(v)) && rest(*ip.lpos) && type(second(*ip.lpos))==INT){
        ip.pos++; ip.lpos=rest(ip.lpos);
    }
    ip.pos++, ip.lpos=rest(ip.lpos);
}
void step(list& l){
    obj v = first(l);
    if(type(v)==INT && isWide(uint(v)) && rest(l) && type(second(l))==INT){
        l=rest(l);
    }
    l=rest(l);
}

/*inline int MathText::getInsertionCloseTo0(list& l, int &pos, float h, int& curr_mark){
	NSPoint pt;
	for(; ;){
		GetPen(&pt);
		if(pt.x <= h) curr_mark = pos;
		if(! l) goto endline;
		if(equalsToCursor(&line, l, pos)) crossed = true;
        
		obj v = first(l);
		if(type(v)==INT && uint(v)=='\n') {pos++, l=rest(l);goto newline;};	//newlineifneccesary
		drawACharOrABox(l, pos, false);
        step(l, pos);

		GetPen(&pt);
		if(pt.x > LEFTMARGIN+colWidth) goto newline; //wrap
 	}
newline:
	return 1;
endline:
	return 0;
}

void MathText::findInsertionCloseTo(float h, int &next, int &prev){
	int pos = findPreviousLine();
	int curr_mark=0; 
	if(pos<0) pos=0;
	list l=rest(line, pos);
	next=-1;
	prev=-1;
	crossed = false;
	bool metend = false;
	MoveTo(LEFTMARGIN,0);
	for(; l;){
		if(getInsertionCloseTo0(l, pos, h, curr_mark)==1) goto newline;
			else goto endline;
newline:
        NSPoint pt;
		GetPen(&pt);
		MoveTo(LEFTMARGIN, pt.y+LINEHEIGHT);
		if(! crossed) prev = curr_mark;
endline:
        if(metend) {next = curr_mark; return;}
		if(crossed) metend = true;
	}
}*/
void MathText::toDosOnCursor(insp ip, bool draw){
    if(equalsToCursor(ip)){
        GetPen(&cursorPosition);
        crossed = true;
		baseLine = cursorPosition.y;
        
        if(draw) [theStr drawAtPoint:NSMakePoint( curPt.x, curPt.y - [fontAttr ascender] + [fontAttr descender])];
        CGFloat w = [theStr size].width;
        if(draw) [caller drawCaretAt:curPt];
        Move(w, 0);
    }
}

NSString* preread(list l, int* length){
	const int buf_max = 100;
	unichar buf[buf_max];
	int len = 0;
	for(; l && len < buf_max -1;) {
		obj v = first(l);
		if(type(v)!=INT) break;
		int c = uint(v);
		if(c=='\n') break;
		buf[len++] = c;
		if(isWide(c)){
			if(! rest(l)) {assert(0);break;}
			l = rest(l);
			if(type(first(l)) != INT) {assert(0);break;}
			buf[len++] = uint(second(l));
		}
		l = rest(l);
	}
	*length = len;
	return [[NSString alloc] initWithCharacters:buf length:len];
}

void drawAChar(MathText* text, list l, bool draw){
	static CTTypesetterRef typesetter = nil;
	static NSString *s = nil;
	static int len = 0;
	static int p = 0;
	obj v = first(l);
	if(p == len || uint(v) != [s characterAtIndex:p]) {
		if(typesetter) CFRelease(typesetter);
		s = preread(l, &len);
		NSAttributedString* str = [[NSAttributedString alloc] initWithString:s attributes:text->dicAttr];
		typesetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(str));
		p = 0;
	}
	int count = isWide(uint(v)) ? 2 : 1;
	CTLineRef aline = CTTypesetterCreateLine(typesetter, CFRangeMake(p, count));
	if(draw){
		CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
		CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1, -1));
		CGContextSetTextPosition(context, text->curPt.x, text->curPt.y);
		CTLineDraw(aline, context);
	}
	text->curPt.x += CTLineGetTypographicBounds(aline, nil, nil, nil);
	CFRelease(aline);
	//text->curPt = CGContextGetTextPosition(context);
	p += count;
}

bool MathText::drawFragment0(insp& ip, bool draw){    //改行すべきか返る
	NSPoint pt;
	for(; ; ){	// chars
    continue_drawing:
        GetPen(&pt);
        toDosOnCursor(ip, draw);
		if(!draw && pt.y < clickpnt.y + FONTSIZE && pt.x < clickpnt.x){
            click = ip;
			curclick = pt;
		}
		if(! *ip) goto endofline;

		obj v = *ip;
		if(type(v)==INT && uint(v)=='\n') {step(ip); goto newline;};
		switch(type(v)){
		default:
            drawACharOrABox(*ip.lpos, ip.pos, draw);
			break;
		case INT:
			drawAChar(this, *ip.lpos, draw);
			break;
		case tShow:
            DrawString("▽");
            ip.moveInto(&(ul(v)));
            goto continue_drawing;
        }
        step(ip);
        
		GetPen(&pt);
		if(pt.x > LEFTMARGIN+colWidth){
            if(! *ip) goto endofline;
            obj v = *ip;
            if(type(v)==INT && uint(v)=='\n') {step(ip); goto newline;};
            goto newline;    //wrap
        }
	}
endofline:
    if(&(this->line) != ip.curstr) {    // end of tShow
        ip = toUpperLevel(ip);          // (moving into step possible?)
        DrawString("▽");
        goto continue_drawing;
    }
	return 0;
newline:
	return 1;
}


void MathText::drawFragment(obj line, bool draw){
    insp ip = insp(&ul(line), 0);
	NSPoint pt;
    GetPen(&pt);
	for(; ; ){	// chars
        toDosOnCursor(ip, draw);
		if(!draw && pt.y < clickpnt.y + FONTSIZE && pt.x < clickpnt.x){
            click = ip;
			curclick = pt;
		}
		if(! *ip) goto endofline;
        
		obj v = *ip;
		if(type(v)==INT && uint(v)=='\n') {step(ip); goto newline;};
        if(type(v) != tShow){
            drawACharOrABox(*ip.lpos, ip.pos, draw);
        } else {
            goto endofline;
        }
        step(ip);
        
		GetPen(&pt);
		if(pt.x > LEFTMARGIN+colWidth){
            if(! *ip) goto endofline;
            obj v= *ip;
            if(type(v)==INT && uint(v)=='\n') {step(ip); goto newline;};
            goto newline;    //wrap
        }
	}
endofline:
newline:
    ;
}

//static int getNLine(list line);
void MathText::drawLine(list*line, bool draw){
    drawList = phi();
    il = &yposOfLines;
    ll = &pointerToLines;
    drawLine0(line, draw);
}
void MathText::startLineWith(insp ip){      // or checkCache()
	NSPoint pt;
	GetPen(&pt);
    if(*il==nil) {
        *il = cons(pt.y, nil);
        *ll = cons(ip, nil);
    } else if(first(*ll).lpos != ip.lpos || first(*ll).pos != ip.pos){  //first(*il) != (int)vv ||
        // invalidate
        surface_free(*il);
        surface_free(*ll);    //releaseに変えた方がよい、freeされたnodeが再利用されているとまずい
        *il = cons(pt.y, nil);
        *ll = cons(ip, nil);
    }
}

insp MathText::toUpperLevel(insp ip){
    list insl = ins_list(&line, ip.curstr);
    long pos = vrInt(pop(&insl));
    list* str = curr_str(insl);
    release(insl);
    return insp(str, pos);
}

void MathText::drawLine0(list*line, bool draw){
    insp ip = insp(line, 0);
	NSPoint pt;
	GetPen(&pt);
    NSRect clip = draw ? updateRect : NSMakeRect(clickpnt.x, clickpnt.y, 0, 0);
	float vv = pt.y;
    for(; ;){			// lines (either soft or hard)
		if(!draw && vv < clickpnt.y + FONTSIZE){
            click = ip;
			curclick = pt;
		}
        if(*il && first(*il) - FONTSIZE < clip.origin.y){  //今の行の下端 ~ 次の行の上端
            ip = first(*ll);
            vv = first(*il);
            MoveTo(LEFTMARGIN, vv);
            goto start_line;
        }
        //NSLog(@"%i", (int)vv);
        if(drawFragment0(ip, draw)){
            GetPen(&pt);
            vv = pt.y + LINEHEIGHT;
            MoveTo(LEFTMARGIN, vv);
            if(equalsToCursor(ip)) continue;   // to do onCursor todos
        }
        if(! *ip.lpos) {    // end of tShow
            if(&(this->line) == ip.curstr) return;   // break ?
            assert(0);
        }
    start_line:
        if(! *ip.lpos) {    // necessary ?
            if(&(this->line) == ip.curstr) return;   // break ?
            assert(0);
        }
        if(vv > clip.origin.y + clip.size.height + FONTSIZE) break;
        startLineWith(ip);      // cacheは２番目から始まる   // excessive check if skipped
        il=rest(il), ll=rest(ll);
    }
    MoveTo(LEFTMARGIN, vv);
    viewHeight = larger(viewHeight, vv + FONTSIZE*3 + LINEHEIGHT*getNLine(*ip.lpos));
    if(! *ip.lpos) viewHeight = vv + FONTSIZE*3;
}

void MathText::invalidateLayoutCache(){
    yposOfLines = nil;
    pointerToLines = nil;
}

float MathText::getWidth(obj str){
	NSPoint pt, np;
	GetPen(&pt);
	drawFragment(str, false);
	GetPen(&np);
	return np.x - pt.x;
}

void MathText::show_image(obj v){
    NSPoint pt;
	GetPen(&pt);
    if(type(v)==IMAGE){
        int h = uar(v).size;
        int w = udar(uar(v).v[0]).size;
        NSBitmapImageRep* bm = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil pixelsWide:w pixelsHigh:h bitsPerSample:16 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSCalibratedWhiteColorSpace bytesPerRow:w*2 bitsPerPixel:0];
        unsigned short * bp = (unsigned short *)[bm bitmapData];
		for(int i=0; i< h; i++){
			obj row = uar(v).v[i];
			assert(type(row)==tDblArray);
			for(int j=0; j < udar(row).size; j++){
				bp[i*w + j] = smaller(0xFFFF, 0x10000 * udar(row).v[j]);
			}
		}
        [bm drawAtPoint:NSMakePoint(LEFTMARGIN, pt.y)];
        Move(0, h);
	} else if(type(v)==tCImg){
		assert(type(uar(v).v[0])==tArray);
        int h = uar(uar(v).v[0]).size;
        obj rowr = uar(uar(v).v[0]).v[0];
        int w = udar(rowr).size;
        NSBitmapImageRep* bm = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil pixelsWide:w pixelsHigh:h bitsPerSample:16 samplesPerPixel:3 hasAlpha:NO isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:w*6 bitsPerPixel:0];
        unsigned short * bp = (unsigned short *)[bm bitmapData];
		for(int i=0; i< h; i++){
			obj rowr = uar(uar(v).v[0]).v[i];
			obj rowg = uar(uar(v).v[1]).v[i];
			obj rowb = uar(uar(v).v[2]).v[i];
			assert(type(rowr)==tDblArray);
			for(int j=0; j< w; j++){
				bp[(i*w + j)*3 + 0] = 0xE000*(udar(rowr).v[j]);
				bp[(i*w + j)*3 + 1] = 0xE000*(udar(rowg).v[j]);
				bp[(i*w + j)*3 + 2] = 0xE000*(udar(rowb).v[j]);
//              [bm setColor:[NSColor colorWithCalibratedRed:udar(rowr).v[j] green:udar(rowg).v[j] blue:udar(rowb).v[j] alpha:1] atX:j y:i];
			}
		}
        [bm drawAtPoint:NSMakePoint(LEFTMARGIN, pt.y)];
        Move(0, h);
	} else assert(0);
}

void MathText::showPlot(obj y){           // plotting
    NSPoint pt;
    GetPen(&pt);
    int baseLine = pt.y;
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(10, baseLine - udar(y).v[0])];
    for(int i=1; i< udar(y).size; i++) [path lineToPoint:NSMakePoint(10+i*3, baseLine - udar(y).v[i])];
    [path stroke];
}
void gr_line::drawAt(float x, float y){
    NSBezierPath *path = [NSBezierPath bezierPath];
	double* pt = udar((*pts)[0]).v;
	assert(isfinite(pt[0]) && isfinite(pt[1]));
    [path moveToPoint:NSMakePoint(x + pt[0], y - pt[1])];
    for(int i=1; i< size(pts); i++){
		pt = udar((*pts)[i]).v;
		assert(isfinite(pt[0]) && isfinite(pt[1]));
		[path lineToPoint:NSMakePoint(x + pt[0], y - pt[1])];
	}
    [path stroke];
}
void MathText::drawCanvas(canvas* cv){
    NSPoint pt;
    GetPen(&pt);
    int baseLine = pt.y;
	for(int i=0; i < cv->grs.size; i++){
		(cv->grs.a[i])->drawAt(10, baseLine);
	}
}
/*
void MathText::drawObj(obj line){		//set cursorPosition at the same time
	if(type(line) ==STRING){
		DrawString(ustr(line));
		return;
	} else if(type(line)==IMAGE || type(line)==tCImg){
		print_image(line);
		return;
	} else if(type(line)==tPlot){
		showPlot(line);
		return;
	}
	assert(type(line)==LIST);
	drawLine(&ul(line), true);
}
*/
//static void highlightSelected();

void MathText::Redraw(NSRect rect){
	if(printing_canvas){
		MoveTo(0, 400);
		drawCanvas(cur_canvas);
		return;
	}
    updateRect = rect;
    /*	for(list l=lines; l; l=rest(l)){
		assert(type(first(l))==LIST);
		list aLine = ul(first(l));
		int position = uint(second(aLine));
		int h;
		if(rest(rest(aLine))) h = uint(third(aLine)); else h = LEFTMARGIN;;
		MoveTo(h, position-viewPosition);
        rememberYPos(position-viewPosition, first(aLine));
		drawObj(first(aLine));
	}*/
    TextSize(FONTSIZE);
	MoveTo(LEFTMARGIN, startOfThisLine-viewPosition);
	drawLine(&line, true);
	viewHeight = larger(viewHeight, larger(startOfThisLine + FONTSIZE*2 + LINEHEIGHT*getNLine(line), cursorPosition.y) + 3*FONTSIZE);// too inacurate
    /*if(caretState){
     MoveTo(cursorPosition.x, cursorPosition.y);
     Line(0,-FONTSIZE);
     Move(0, FONTSIZE);
     }*/
    //[NSBezierPath strokeRect:NSMakeRect(clickpnt.x - 0.5, clickpnt.y -0.5, 1, 1)];
    highlightSelected();
    //baseLine = cursorPosition.y;
}

//------accessors of the current line -----------------

inline void MathText::set_insp(int pos){	// <-> move insertion
	release(insList);
	insList = nil;
	ins = insp(&line, pos);
}
int MathText::findPreviousLetter(){
	int p = 0;
	int i = 0;
	for(list l=*(ins.curstr); l && i<ins.pos; l=rest(l), i++) {
		p = i;
		if(type(first(l))==INT && isWide(uint(first(l)))) {
			l=rest(l); i++;
		}
	}
	return p;
}
int MathText::findPreviousLine(){//returns -1 if none
	int pp = -1, p = 0, curr_pos;
	if(insList) curr_pos = uint(*last(insList));
	else curr_pos = ins.pos;
	int i = 0;
	for(list l=line; l && i<curr_pos; l=rest(l), i++) 
		if(type(first(l))==INT && uint(first(l))=='\n') {
			pp = p;
			p = i+1;
		}
	return pp;
}
int MathText::findBeginOfThisLine(){
	int p = 0, curr_pos;
	if(insList) curr_pos = uint(*last(insList));
	else curr_pos = ins.pos;
	int i = 0;
	for(list l=line; l && i<curr_pos; l=rest(l), i++)
		if(type(first(l))==INT && uint(first(l))=='\n') {
			p = i+1;
		}
	return p;
}
list MathText::deleteALetter0(){
	int p = findPreviousLetter();
	list* lpp = rest(ins.curstr, p);
	list l = *lpp;
	*lpp = rest(l, ins.pos-p);
	*rest(&l, ins.pos-p) = nil;
	ins.setpos(p);
	return l;
}
void MathText::putinUndobuf(list l){
	if(!undobuf) undobuf = (obj)create(tIns, phi());
	else if(type(undobuf)!=tIns){
		release(undobuf);
		undobuf = (obj)create(tIns, phi());
	}
	ul(undobuf) = merge(l, ul(undobuf));
}
void MathText::deleteALetter(){
	list l = deleteALetter0();
	putinUndobuf(l);
}

int MathText::peekPreviousLetter(){	// not good for 2-bytes
	if(ins.pos==0) return NUL;
	int p = findPreviousLetter();
	obj vp = first(rest(*ins.curstr, p));
	if(type(vp)!=INT) return NUL;
	return uint(vp);
}
inline void MathText::insert0(obj v){
	list* inspp = ins.list_point();
	*inspp = cons(v, *inspp);
	ins.setpos(ins.pos+1);
}
void MathText::insert(obj v){
	insert0(v);
	if(!undobuf) undobuf = create(tDel, 1);
	else if(undobuf && type(undobuf)==tDel){
		(((int_*)undobuf)->intv)++;
	} else {
		release(undobuf);
		undobuf = create(tDel, 1);
	}
}
void MathText::pushInsertion(){
	insList = cons(Int(ins.pos), insList);
}
int MathText::popInsertion(){
	return vrInt(pop(&insList));
}
void MathText::moveIntoNum(list_* fr){
	pushInsertion();
    //	ins.pos = 2;
    //	pushInsertion();
	insList = cons(Int(1), insList);
	ins.moveInto(&ul(em0(fr)));
}
void MathText::moveIntoDenom(list_* fr){
	pushInsertion();
//	ins.pos = 2;
//	pushInsertion();
	insList = cons(Int(2), insList);
	ins.moveInto(&ul(em1(fr)));
}
void MathText::insertFraction(list num, list denom){
	list_* v = render(FRACTION, list2(List2v(num), List2v(denom)));
	insert(v);
	moveIntoDenom(v);
}
list* MathText::curr_str(list l){
	if(! l) return &line;
	obj v = first(rest(*curr_str(rest(l)), uint(first(l))-1));
	assert(type(v)==FRACTION || type(v)==SubScript || type(v)==SuperScript || type(v)==LIST);
	return &ul(v);
}
list MathText::ins_list(list*scan, list*cstr){	// finding insList from curstr
	if(scan == cstr) return nil;
	list l = *scan;
	for(int i=0; l; l=rest(l), i++) {
		obj v=first(l);
		if(type(v)==INT) continue;
		if( &ul(v)==cstr) return list1(Int(i+1));
		else if (list ll = ins_list(&ul(v), cstr)) return merge(ll, list1(Int(i+1)));
	}
	return nil;
}
/*list* upper_str(list*scan){
	if(scan == ins.curstr) assert(0);
	List l = *scan;
	for(; l; l=rest(l)) {
		obj v=first(l);
		if(type(v)==INT) continue;
		if( &ul(v)==ins.curstr) return scan;
		if(list*ll = upper_str(&ul(v))) return ll;
	}
	return nil;
}*/

list MathText::isInFracRecur(){
	list l = insList;
	if(! l) return nil;
	for(;; l=rest(l)){
		if(! rest(l)) return nil;
		obj v = first(rest(*curr_str(rest(rest(l))), uint(second(l))-1));
		if(type(v)==FRACTION) return l;
	}
}
bool MathText::isInFrac(){
	if(! insList) return false;
	obj v = first(rest(*curr_str(rest((insList))), uint(first(insList))-1));
	if(type(v)!=FRACTION) return false;
	return true;
}
void MathText::moveToUpperLevel(){
	int pos = popInsertion();
	if(isInFrac()) pos = popInsertion();
	ins = insp(curr_str(insList), pos);
}
int MathText::getNLine(list l){//line数-1, newlineの数を数える
	int i=0;
	for(; l; l=rest(l)) if(type(first(l))==INT && uint(first(l))=='\n') i++;
	return i;
}
void MathText::insertSuperScriptAndMoveInto(){
	obj vp = render(SuperScript, nil);
	insert(vp);
	pushInsertion();		//insertion pointはみぎで待っていてもらうことにする。
	ins.moveInto(&ul(vp));
}

void MathText::insertSubScriptAndMoveInto(){
	obj vp = render(SubScript, phi());
	insert(vp);
	pushInsertion();
	ins.moveInto(&ul(vp));
}
obj MathText::peekPrevious(){
    if(ins.pos-1 < 0) return nil;
    return first(rest(*(ins.curstr), ins.pos-1));
}
obj MathText::peekNext(){
    list* l =ins.list_point();
    if(*l) return first(*l);
    else return nil;
}
void MathText::moveToLast(){
    ins.setpos(length(*ins.curstr));
}
bool MathText::isAtLast(){
    assert(ins.pos <= length(*ins.curstr));
    return ins.pos==length(*ins.curstr);
}
// -------------- controllers ------------
void MathText::moveLeft(){
	if(insList && ins.pos==0) {
		moveToUpperLevel();
		ins.setpos(ins.pos-1);
		return;
	}
	if(ins.pos==0) return;
	obj c = peekPrevious();
	if(type(c)==SuperScript || type(c)==SubScript || type(c)==tShow){
		pushInsertion();
		ins.moveRightmost(&ul(c));
		return;
	} if(type(c)==FRACTION){
		moveIntoDenom((list_*)c);
		moveToLast();
		return;
	}
	ins.setpos(findPreviousLetter());
}
void MathText::moveRight(){
	if(insList && isAtLast()) {
		moveToUpperLevel();
		return;
	}
	if(isAtLast()) return;
	obj c = first(*ins.list_point());
	if(type(c)==SuperScript || type(c)==SubScript || type(c)==tShow){
		ins.setpos(ins.pos+1);
		pushInsertion();
		ins.moveInto(&ul(c));
		return;
	} if(type(c)==FRACTION){
		ins.setpos(ins.pos+1);
		moveIntoDenom((list_*)c);
		return;
	}
	if(type(c)==INT && isWide(uint(c))) ins.setpos(ins.pos+1);
	//if(type(c)==INT && uint(c)=='\n') scrollBy(+LINEHEIGHT);
	ins.setpos(ins.pos+1);
}
list MathText::cutSelected(){
	if(beginSelList != insList){
		//SysBeep(1);
		return nil;
	}
	int b = smaller(beginOfSel.pos, ins.pos);
	int e = larger(beginOfSel.pos, ins.pos);
	if(b==e) return nil;

	ins.setpos(b);
	list*bp = rest(ins.curstr, b);
	list*ep = rest(ins.curstr, e);
	list l= *bp;
	*bp = *ep;
	*ep = nil;
	return l;
}
void MathText::moveUp(){
	if(list l = isInFracRecur()) {
		 if(uint(first(l))==2){	// in donominator?
			l = rest(l);
			retain(l);
			release(insList);
			l = cons(Int(1), l);	// moveToNumerator
			insList = l;
			ins.moveRightmost(curr_str(l));
			return;
		}
	}
    obj c = peekNext();
    if(c && type(c)==FRACTION){
        ins.setpos(ins.pos+1);
        moveIntoNum((list_*)c);
        return;
    }
	c = peekPrevious();
    if(c && type(c)==FRACTION){
        ins.setpos(ins.pos);
        moveIntoNum((list_*)c);
        moveToLast();
        return;
    }
    getClickPosition(NSMakePoint(cursorBeforeVertMove.x, cursorPosition.y - LINEHEIGHT));
	/*int nx,pv;
	findInsertionCloseTo(cursorBeforeVertMove.x, nx, pv);
	if(pv == -1) return;
	set_insp(pv);
	baseLine += -LINEHEIGHT;*/
}
void MathText::moveDown(){
	if(list l = isInFracRecur()) {
		 if(uint(first(l))==1){	// in numerator?
			l = rest(l);
			retain(l);
			release(insList);
			l = cons(Int(2), l);	// moveToDenominator
			insList = l;
			ins.moveRightmost(curr_str(l));
			return;
		}
	}
	obj c = peekNext();
    if(c && type(c)==FRACTION){
        ins.setpos(ins.pos+1);
        moveIntoDenom((list_*)c);
        return;
    }
	c = peekPrevious();
    if(c && type(c)==FRACTION){
        ins.setpos(ins.pos);
        moveIntoDenom((list_*)c);
        moveToLast();
        return;
    }
    getClickPosition(NSMakePoint(cursorBeforeVertMove.x, cursorPosition.y + LINEHEIGHT));
	/*int nx,pv;
	findInsertionCloseTo(cursorBeforeVertMove.x, nx, pv);
	if(nx==-1) return;
	set_insp(nx);
	baseLine += +LINEHEIGHT;*/
}

//--------------------
// unsigned long caretLastChanged;

void MathText::ShowCaret(){
//	caretLastChanged = TickCount();
	caretState = 1;
}

void MathText::HideCaret(){
	MoveTo(cursorPosition.x, cursorPosition.y);
//	PenPat(&qd.white);  // change color here
//	Line(0,-FONTSIZE);
//	Move(0, FONTSIZE);
//	PenPat(&qd.black);
//	caretLastChanged = TickCount();
	caretState = 0;
}

/*void updateCaret(){
	if(TickCount() - caretLastChanged >= GetCaretTime() ){
		if(caretState == 0) ShowCaret();
		else HideCaret();
	}
}*/

#define upboundby(b,x) ((x)<(b)?(x):(b))

void MathText::scrollBy(int points){
	baseLine += points;
	//win_normalize();
//	[caller updateFrame];
    insert(Int('\n'));
}

void MathText::scroll(){
	scrollBy(LINEHEIGHT);
}

//-----------------

list csparse(const char* str, size_t len);

void MathText::newLine(){}
void MathText::newLine0(){
	line = phi();
	ins.moveInto(&line);
	insList = nil;
    
	startOfThisLine = baseLine+viewPosition;
	//cursorPosition.x = LEFTMARGIN;
	//cursorPosition.y = baseLine;
	//MoveTo(LEFTMARGIN, baseLine);
    
	cursorBeforeVertMove = cursorPosition;
    
    //	beginOfSel.pos = 0;
	beginOfSel = insp();
	beginSelList = nil;
	selectionCursorPosition = cursorPosition;
	nowSelected = false;
	
	release(didBuf);
	release(undoBuf);
	didBuf = nil;
	undoBuf = nil;
}

void MathText::initLines(){
//	lines = phi();
    viewPosition = 0;
    baseLine = 20;
    insList = nil;
    nowSelected = false;
    didBuf = nil;
    undoBuf = nil;
    undobuf = nil;
    mode = session;

	ins = insp(&line, 0);
    dicAttr = [ NSMutableDictionary dictionary ];
    [ dicAttr setObject : [ NSColor blackColor ]
                forKey  : NSForegroundColorAttributeName ];
    fontAttr = [ NSFont fontWithName : font size : FONTSIZE ];
    [ dicAttr setObject : fontAttr
                forKey  : NSFontAttributeName];

    interpreter = create_interpreter();

    newLine0();
    beginOfContinuedLine = insp();  // invalid point
}

void MathText::addObjToText(obj v){	//taking line
//	list aLine = list2(v, Int(baseLine+viewPosition));
//	append(&lines, List2v(aLine));
    insert(v);
}

void MathText::addLineToText(obj line){	//taking line
    return;     // used in edit and readline, needs repair of those functions
//	list aLine = list2(line, Int(startOfThisLine));
//	append(&lines, List2v(aLine));
}

void MathText::addStringToText(char* string){
    obj str = cval(copyString(string));
    insert(str);
    cacheForUnitTest = ustr(str);
/*
    char* str = copyString(string);
    assert(((long)str & dVal)==0);
    insert((obj)((long)str | idStr));
    cacheForUnitTest = ustr(str);//*/
}

#include <stdarg.h>
#include <stdio.h>

void MathText::print_str(char*s){
	char str[256];
	NSPoint pt;
	GetPen(&pt);
	if(pt.x > LEFTMARGIN+colWidth) return;
	addStringToText(str);
//	for(char* s=str; *s; s++) if(*s=='\n') *s=' ';
	int p=0;
	for(; s[p] && p<250; p++) str[p] = s[p];
	s[p] = NUL;
//	DrawString(str);
}

int imbalanced(list line){
	int paren=0,brace=0;
	for(list l=line; l; l=rest(l)){
		switch(type(first(l))){
        case INT:{
			unichar c = uint(first(l));
			if(c=='(') paren++;
			if(c==')') paren--;
			if(c=='{') brace++;
			if(c=='}') brace--;
			break;
		}
        case FRACTION:
		case SuperScript:
		case SubScript:
		case STRING:
			break;
		default:
            assert(0);
		}
	}
	return abs(paren)+abs(brace);
}
void MathText::updateAround(bool erase){
	Rect r;
	r.left = LEFTMARGIN;
	r.right= LEFTMARGIN+colWidth+50;
	r.top 	= baseLine-FONTSIZE*2;
	r.bottom = baseLine+FONTSIZE;
	if(erase){
		r.top 	= baseLine-FONTSIZE*2;
	//	r.bottom = windowHeight;
	}	
    // need repair here 131013
    //if(erase) EraseRect(&r);
	//InvalRect(&r);
//	DoUpdate(currWindow);
}
void MathText::removeSelected(){
    if(nowSelected) putinUndobuf(cutSelected());
	nowSelected = false;
}
void MathText::HandleTyping0(unichar c){
	HideCaret();
	if(c=='\n'){
		if(! insList){
			insert(Int('\n'));
			//baseLine+=LINEHEIGHT;
		} else moveToUpperLevel();
		goto sho;
	} else if(c==BS){
		if(nowSelected) putinUndobuf(cutSelected());
		else deleteALetter();
		goto sho;
	} else if(c==arrowLeft){
		moveLeft();
		goto sho;
	} else if(c==arrowRight){
		moveRight();
		goto sho;
	} else if(c==arrowUp){
		moveUp();
		goto sho;
	} else if(c==arrowDown){
		moveDown();
		goto sho;
	}

	if(c=='^' && ! halfchar){
		insertSuperScriptAndMoveInto();
	} else if(c=='_' && ! halfchar){
		insertSubScriptAndMoveInto();
	} else if(c=='/' && peekPreviousLetter() =='/') {
		deleteALetter();	// delete '/'
		list l = deleteALetter0();
		insertFraction(l, nil);
	} else {
		removeSelected();
		insert(Int(c));
		if(isWide(c)) halfchar = c;     // 1311 possibly no need
		else halfchar = 0;
	}
	
sho:if(c==arrowLeft||c==arrowRight||c==arrowUp||c==arrowDown){
		if(undobuf && type(undobuf) !=tMove){
			undoBuf = cons(undobuf, undoBuf);
			undobuf = create(tMove, cons(Int(ins.pos), retain(insList)));
		}
	}
//	updateAround(!(c==arrowLeft||c==arrowRight||c==arrowUp||c==arrowDown));
//	baseLine = cursorPosition.y;
	ShowCaret();
	
	nowSelected = false;
}
void MathText::setCursorBeforeVertMove(){
    cursorBeforeVertMove = cursorPosition;
}
void MathText::handleCR(){
    list l = beginOfContinuedLine.lpos ? *beginOfContinuedLine.lpos : rest(line, findBeginOfThisLine());
	obj tl = cval(listToCString(l));
	scroll();	// newline
    if(setjmp(jmpEnv)==0){	//try
        icaller = this;
        interpret(interpreter, ustr(tl));
    } else {				//catch
    }
    release(tl);
	newLine();
}

void MathText::setMode(CRmode m){
    mode = m;
}

void MathText::HandleTyping(unichar c){
	if(mode==session && c=='\n' && !insList){
        if(! beginOfContinuedLine.lpos){
            int bp = findBeginOfThisLine();
            if(imbalanced(rest(line, bp))){
                beginOfContinuedLine = insp(&line, bp);
                HandleTyping0(c);
            } else {
                HideCaret();
                handleCR();
                ShowCaret();
            }
        } else {
            if(imbalanced(*beginOfContinuedLine.lpos)){
                HandleTyping0(c);
            } else {
                HideCaret();
                handleCR();
                ShowCaret();
                beginOfContinuedLine = insp();  // invalid
            }
        }
        return;
    }
    HandleTyping0(c);
}

void MathText::highlightSelected(){
    if(!nowSelected) return;
    //[[[NSColor selectedControlColor] colorWithAlphaComponent:0.5] set];   was not useful
    [[NSColor selectedControlColor] set];
    [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositePlusDarker];
    NSBezierPath* path = [NSBezierPath bezierPath];
    NSPoint s = selectionCursorPosition, e = cursorPosition;
    if(abs(s.y - e.y) < FONTSIZE){
        Rect r;
        r.left = smaller(s.x, e.x);
        r.right= larger(s.x, e.x);
        //r.top  = smaller(s.y, e.y) - FONTSIZE;
        //r.bottom=larger(s.y, e.y);
        [path appendBezierPathWithRect:NSMakeRect(r.left, s.y - FONTSIZE, r.right - r.left, LINEHEIGHT)];
    } else {
        if(s.y > e.y) {s=cursorPosition; e=selectionCursorPosition;}
        [path appendBezierPathWithRect:NSMakeRect(s.x, s.y - FONTSIZE, LEFTMARGIN + COLWIDTH + FONTSIZE  - s.x, LINEHEIGHT)];
        [path appendBezierPathWithRect:NSMakeRect(LEFTMARGIN - 1, s.y - FONTSIZE + LINEHEIGHT,
            LEFTMARGIN + COLWIDTH + FONTSIZE - (LEFTMARGIN - 1), e.y - s.y - LINEHEIGHT)];
        [path appendBezierPathWithRect:NSMakeRect(LEFTMARGIN - 1, e.y - FONTSIZE, e.x - (LEFTMARGIN - 1), LINEHEIGHT)];
    }
    [path fill];
    [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositeSourceOver];
}
void MathText::HandleShifted(unichar c){
    if(!nowSelected){
        beginOfSel = ins;	//for text selection
        //release(beginSelList);       possibly no need 131018
        beginSelList = retain(insList);
        selectionCursorPosition = cursorPosition;
    }
    if(!nowSelected && beginSelList != insList) return;
	HideCaret();
	if(c==arrowLeft){
		moveLeft();
	} else if(c==arrowRight){
		moveRight();
	} else if(c==arrowUp){
		moveUp();
	} else if(c==arrowDown){
		moveDown();
	}
	//updateAround(true);
	MoveTo(cursorPosition.x, cursorPosition.y);
	nowSelected = true;
}
void MathText::getClickPosition(NSPoint pt){
	clickpnt = pt;
	MoveTo(LEFTMARGIN, startOfThisLine - viewPosition);
	click = insp(nil, 0);
	drawLine(&line, false);
	if(!click.curstr) return;

	ins = click;
	release(insList);
	insList = ins_list(&line, click.curstr);
	cursorPosition = curclick;
}
void MathText::HandleContentClick(NSPoint pt){
	getClickPosition(pt);
    obj v = peekNext();
    if(v && (type(v)==tHide || type(v)==tShow)){ // cursor move should be suppressed in the future
        if(type(v)==tHide) setType(v, tShow);
        else setType(v, tHide);
    }//*/
    nowSelected = false;
    ShowCaret();
}
void MathText::HandleDragTo(NSPoint pt){  // combined getClockPosition and HandleShifted
	clickpnt = pt;
	MoveTo(LEFTMARGIN, startOfThisLine - viewPosition);
	click = insp(nil, 0);
	drawLine(&line, false);
	if(!click.curstr) return;

    if(!nowSelected){
        beginOfSel = ins;       //for text selection
        //release(beginSelList);       possibly no need 131018
        beginSelList = retain(insList);
        selectionCursorPosition = cursorPosition;
    }
    if(!nowSelected && beginSelList != insList) return;
//	HideCaret();

	ins = click;
	release(insList);
	insList = ins_list(&line, click.curstr);
	cursorPosition = curclick;

	//updateAround(true);
	MoveTo(cursorPosition.x, cursorPosition.y);
	nowSelected = true;
}
/*void DoUpdate(WindowPtr targetWindow) {
//	SetPortWindowPort(targetWindow);
//	BeginUpdate(targetWindow);
//	EraseRect(&targetWindow->portRect);
	Redraw();
//	DrawGrowIcon(targetWindow);
//	DrawControls(targetWindow);
//	EndUpdate(targetWindow);
}*/
void MathText::DoUndo(){
	obj doit=retainD(undobuf);
	if(type(doit)==tDel){
		int n = uint(doit);
		for(int i=0; i<n; i++) deleteALetter();
	} else if(type(doit)==tIns){
		for(list l=ul(doit); l; l=rest(l)) insert(retainD(first(l)));
	} else if(type(doit)==tMove) {
		release(insList);
		insList = rest(ul(doit));
		ins = insp(curr_str(insList), uint(em0(doit)));	// fuan
	}
	release(doit);
	updateAround(true);
}
NSString* MathText::copySelected(){
	if(beginSelList != insList) {
		//SysBeep(1);
		return nil;
	}
	int b = smaller(beginOfSel.pos, ins.pos);
	int e = larger(beginOfSel.pos, ins.pos);
	if(b==e) return nil;

	string rs = nullstr();
	serialize(&rs, rest(*ins.curstr,b), rest(*ins.curstr,e));
    NSString* str = [[NSString alloc] initWithCString:rs.s encoding:NSUTF8StringEncoding];
	freestr(&rs);
    return str;
}

void MathText::DoHide(){
	insert(create(tShow, cutSelected()));
	//updateAround(true);
	// next, make switch possible, then make it Hide not Show
}

NSString* MathText::DoCut(){
	NSString* str = copySelected();
	putinUndobuf(cutSelected());
	updateAround(true);
	MoveTo(cursorPosition.x, cursorPosition.y);
    return str;
}

void MathText::pasteCString(const char* str){    // assumes UTF16
    list tt = csparse(str, strlen(str));
    removeSelected();
    for(list l=tt; l; l=rest(l)){
        obj v = first(l);
        if(mode==session && type(v)==INT && (uint(v)==CR || uint(v)==LF)){
			HandleTyping('\n');
			[caller updateFrame];
        } else insert(retainD(v));
    }
    release(tt);
    MoveTo(cursorPosition.x, cursorPosition.y);
}

void MathText::setCString(const char* str){   // UTF8
	newLine();
	line = csparse(str, strlen(str));
/*	MoveTo(LEFTMARGIN, startOfThisLine - viewPosition);
	drawLine(&line, true);
	MoveTo(cursorPosition.x, cursorPosition.y);*/
}

NSString* MathText::serializedString(){
	char* st = listToCString(line);
    NSString* str = [[NSString alloc] initWithCString:st encoding:NSUTF8StringEncoding];
    free(st);
    return str;
}

void MathText::DoLatex(){
	assert(0);
}

obj MathText::edit(obj fn){	// open edit save
	//long bytes;
	obj rr = nil;//val(read(&bytes, (fn)));     // restore needed 131014
	newLine();
	line = CStringToLine(rr);
	MoveTo(LEFTMARGIN, startOfThisLine-viewPosition);	
	drawLine(&line, true);
	MoveTo(cursorPosition.x, cursorPosition.y);

	while(! getKey(shiftCR)) ;
	addLineToText(List2v(line));

	char* st = listToCString(line);
	//write(st, strlen(st)+1, fn);    // restore needed 131014
	free(st);
	return nil;
}

obj MathText::editline(obj v){
	newLine();
	line = CStringToLine(v);
	MoveTo(LEFTMARGIN, startOfThisLine-viewPosition);	
	drawLine(&line, true);
	MoveTo(cursorPosition.x, cursorPosition.y);
	while(! getKey(onlyCR)) ;
	addLineToText(List2v(line));
	//baseLine = startOfThisLine-viewPosition;      // 131118 in question
	scrollBy(FONTSIZE*2+getNLine(line)*LINEHEIGHT);	// newline
	obj lin = cval(listToCString(line));
	newLine();
	return lin;
}

static void append(string*rs, const char*s){
	for(; *s; s++) appendS(rs, *(unsigned char*)s);
}

void serialize(string*rs, list l, list end){
	for(; l != end; step(l)){
		obj v = first(l);
		switch(type(v)){
        case INT: {
            NSString* s = read(l);
            append(rs, [s UTF8String]);
            break; }
		case SuperScript:
			appendS(rs, '^');
			appendS(rs, '(');
			serialize(rs, ul(v), nil);
			appendS(rs, ')');
			break;
		case SubScript:
			appendS(rs, '_');
			appendS(rs, '(');
			serialize(rs, ul(v), nil);
			appendS(rs, ')');
			break;
		case FRACTION:
			append(rs, "//{");
			serialize(rs, ul(first(ul(v))), nil);
			append(rs, "}{");
			serialize(rs, ul(second(ul(v))), nil);
			append(rs, "}");
			break;
		case STRING:
			break;
		default:
			assert(0);
		}
	}
}

char* listToCString(list l){
	string rs = nullstr();
	serialize(&rs, l, nil);
	return rs.s;
}

char* clp;	//
char* clpe;	// end
list csparse0();

list putchar(int c, list l){
	if(c <= 0xFFFF) {
		l = cons(dInt(c), l);
	} else {
		l = cons(Int(0xD8 | ((c >> 10) - 0x40)), l);
		l = cons(Int(0xDC | (c & 0x03FF)), l);
	}
	return l;
}
list csparen(){
	if(*clp != '{' && *clp != '(') {
		list l=putchar(readchar(clp), nil);
		clp = next(clp);
		return l;
	}
	clp++;
	list l = csparse0();
	if(*clp != '}' && *clp != ')') ;//assert(0);
	else clp++;
	return l;
}
bool getchar(char**pp, int c){  // UTF8?
	if(readchar(*pp)!=c) return false;
	*pp = next(*pp);
	return true;
}
int readchar2(char* st){    // UTF8
    if(!(*st & 0x80)) return *st;
    int c = *st & 0x3F;
    for(int i = 0x20; c-i >= 0; i = i>>1) c -= i;
    for(st++; (*st & 0xC0) == 0x80; st++) c = c<<6 | (*st & 0x3F);
	return c;
}
char* next2(char* st){    // UTF8
    if(!(*st & 0x80)) return st+1;
    for(st++; (*st & 0xC0) == 0x80; st++);
	return st;
}
list csparse0(){
	list l = nil;
	int bracelevel = 0;
	for(; *clp && clp!=clpe; ){
		if(getchar(&clp, '^')){
			assert(*clp);
			//if(readchar(clp) != '{') continue;
			l = cons(render(SuperScript, csparen()), l);
		} else if(getchar(&clp, '_')){
			assert(*clp);
			//if(readchar(clp) != '{') continue;
			l = cons(render(SubScript, csparen()), l);
		} else if(get_pat((unsigned char**)&clp, "//")){
			//if(readchar(clp) != '{') continue;
			list nu = csparen();
			list de = csparen();
			l = cons(render(FRACTION, list2(List2v(nu), List2v(de))) ,l);
		} else {
			int c = readchar2(clp);
			if( c =='{' || c =='(') bracelevel++;
			if( c =='}' || c ==')') {bracelevel--; if(bracelevel < 0) break;}
			if( c==CR || c==LF) c='\n';
			l = putchar(c, l);
			clp = next2(clp);
		}
	}
	return reverse(l);
}
list csparse(const char* str, size_t len){  //UTF8
	clp = (char*)str;
	clpe = clp + len;
	return csparse0();
}
list CStringToLine(obj str){
	assert(type(str)==STRING);
	return csparse(ustr(str), strlen(ustr(str)));
}



void scroll(){          icaller -> scroll();}
void scrollBy(int i){   icaller -> scrollBy(i);}

void myPrintf(const char *fmt,...){
	va_list	ap;
	char str[256];
	NSPoint pt;
//	GetPen(&pt);
	if(pt.x > LEFTMARGIN+colWidth) return;
    //	if(pt.x > LEFTMARGIN+colWidth) scroll();
	va_start(ap,fmt);
	if (fmt) {
		vsprintf(str,fmt,ap);
	}
	va_end(ap);
	if(strlen(str)>255) assert_func("app.c", __LINE__);
	icaller->addStringToText(str);
    //append_string(&ks, str); write string merge
	for(char* s=str; *s; s++) if(*s=='\n') scroll();
//	Move(StringWidth(str), 0);
}

void addObjToText(struct value* ob){icaller -> addObjToText(ob);}

void addGrObj(gr* gr_obj){
	if(! icaller->cur_canvas) {
		icaller->cur_canvas = new canvas();
		icaller -> addObjToText(icaller->cur_canvas);
		scroll();
	}
	icaller->cur_canvas->grs.append(gr_obj);
}

char* canvas2eps(size_t* n){
	icaller->printing_canvas = true;
	NSData* d = [icaller->caller dataWithEPSInsideRect:NSMakeRect(0,0, 400, 400)];
	icaller->printing_canvas = false;
	*n = [d length];
	char* eps = (char*)malloc(*n);
	[d getBytes:eps length:*n];
	return eps;
}

void new_canvas(){
	icaller->cur_canvas = nil;
}

