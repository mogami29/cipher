//
//  frontTests.m
//  frontTests
//
//  Created by 最上嗣生 on 2013/09/21.
//  Copyright (c) 2013年 最上嗣生. All rights reserved.
//

#import <XCTest/XCTest.h>
//#import "ciph.h"
//#import "value.h"
typedef struct Interpreter_* Interpreter;
Interpreter create_interpreter(void);
void interpret(Interpreter interpreter, char* line);
void dispose_interpreter(Interpreter interpreter);
void newLine();

@interface frontTests : XCTestCase
{
    Interpreter ip;
}
@end

@implementation frontTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    ip = create_interpreter();
    newLine();
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

bool equal(const char* v1, const char* v2){ return !strcmp(v1, v2);}
extern char* cacheForUnitTest;

- (void)testExample
{
    interpret(ip, "4+3");
    XCTAssert(equal(cacheForUnitTest, "7"));

    //        XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
