//
//  ViewController.m
//  testLib
//
//  Created by linjiansheng on 12/19/16.
//  Copyright © 2016 youshixiu. All rights reserved.
//

#import "ViewController.h"
#include "BLib.h"
#include "DLib.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self testLib];
    
}

- (void)testLib {
    NSLog(@"Test lib.");
    call_foo_b();
//    call_foo_d();
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
