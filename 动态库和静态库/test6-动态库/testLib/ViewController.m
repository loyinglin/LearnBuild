//
//  ViewController.m
//  testLib
//
//  Created by linjiansheng on 12/19/16.
//  Copyright © 2016 youshixiu. All rights reserved.
//

#import "ViewController.h"
#include <dlfcn.h>

@interface ViewController ()

@end

@implementation ViewController

typedef void (*FOO_FUNC)(void);

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self testLib];
    });
}

- (void)testLib {
    NSLog(@"Test lib.");
    void *handle;
    char *error;
    handle = dlopen("ALib.framework/ALib", RTLD_LAZY);
    if (!handle) {
        fprintf(stderr, "%s\n", dlerror());
        return ;
    }
    dlerror();
    FOO_FUNC func = dlsym(handle, "foo");
    if ((error = dlerror()) != NULL)  {
        fprintf(stderr, "%s\n", error);
        return;
    }
    func();
    
    
    Class Alib = NSClassFromString(@"ALib");
    SEL foo = NSSelectorFromString(@"foo");
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (Alib && foo) {
        [[[Alib alloc] init] performSelector:foo withObject:nil];
    }
#pragma clang diagnostic pop
    
    
    
    dlclose(handle);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
