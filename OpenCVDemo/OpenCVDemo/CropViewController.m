//
//  CropViewController.m
//  OpenCVDemo
//
//  Created by mac on 2017/11/16.
//  Copyright © 2017年 程维. All rights reserved.
//

#import "CropViewController.h"
#import "MMCropView.h"
#import "OpenCVWapper.h"

@interface CropViewController ()

@property (strong, nonatomic) MMCropView *cropRect;

@end

@implementation CropViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *sourceImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Smartisan"]];
    sourceImage.center = self.view.center;
    [self.view addSubview:sourceImage];
    
}


@end
