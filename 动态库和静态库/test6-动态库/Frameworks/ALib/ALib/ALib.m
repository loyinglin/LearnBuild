//
//  ALib.c
//  testLib
//
//  Created by linjiansheng on 12/19/16.
//  Copyright © 2016 youshixiu. All rights reserved.
//

#include "ALib.h"

void foo()
{
    printf("foo in ALib.\n");
}

@implementation ALib


+ (void)load {
    NSLog(@"load Alib");
}


- (void)foo {
    NSLog(@"foo in NSALib.\n");
}

@end
