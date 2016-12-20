//
//  ViewController.m
//  testLib
//
//  Created by linjiansheng on 12/19/16.
//  Copyright © 2016 youshixiu. All rights reserved.
//

#import "ViewController.h"
#include "BLib.h"
#include "CLib.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self testLib];
    
}

- (void)testLib {
    NSLog(@"Test A.");
    call_foo_b();
    
    NSLog(@"Test B.");
    foo();
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
