//
//  ViewController.m
//  BibleSearch2
//
//  Created by Hisai Toru on 2017/06/25.
//  Copyright © 2017年 Kronecker's Delta Studio. All rights reserved.
//

#import "ViewController.h"

#import "lua.h"
#import "lualib.h"
#import "lauxlib.h"
#import "LuaBridge.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)startLua {
    lua_State *L = [[LuaBridge instance] L];
    NSString *filename = [[NSBundle mainBundle] pathForResource:@"biblesearch2" ofType:@"lua"];
    if (luaL_dofile(L, [filename UTF8String])) {
        NSLog(@"Failed to load: %@: %s", filename, lua_tostring(L, -1));
    } else {
        lua_getglobal(L, "init");
        luabridge_push_object(L, self);
        if (lua_pcall(L, 1, 0, 0)) {
            NSLog(@"Failed to call init: %s", lua_tostring(L, -1));
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self performSelectorOnMainThread:@selector(startLua) withObject:NULL waitUntilDone:NO];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
