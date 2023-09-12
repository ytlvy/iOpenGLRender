//
//  GLSLViewController.m
//  testOpenGLESRender
//
//  Created by Lyman on 2019/2/21.
//  Copyright © 2019 Lyman Li. All rights reserved.
//



#import "GLSLViewController.h"
#import "GLSLBox.h"


@interface GLSLViewController ()

@property(nonatomic, strong) GLSLBox *box;

@end

@implementation GLSLViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.box];
}

- (GLSLBox *) box {
    if(!_box) {
        _box = [[GLSLBox alloc] initWithFrame:CGRectMake(10, 10, 300, 300)];
    }
    return _box;
}

@end
