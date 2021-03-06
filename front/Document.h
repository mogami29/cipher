//
//  Document.h
//  front
//
//  Created by 最上嗣生 on 2013/09/21.
//  Copyright (c) 2013年 最上嗣生. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Document : NSDocument
{
    NSData* loadedData;
    IBOutlet id myView;
}
@end

typedef enum {  // copied to Document.h
    session,
    editor
} CRmode;
