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

@interface CropViewController () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIImageView *sourceImageView;
@property (strong, nonatomic) MMCropView *cropRect;

@end

@implementation CropViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *image = [UIImage imageNamed:@"Smartisan"];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:scrollView];
    
    _sourceImageView = [[UIImageView alloc] initWithImage:image];
    [scrollView addSubview:_sourceImageView];
    
//    CGRect frame = CGRect{CGPointZero, image.size};
    scrollView.contentSize = image.size;
    
    _cropRect = [[MMCropView alloc] initWithFrame:_sourceImageView.bounds];
    [scrollView addSubview:_cropRect];
    
    
//    UIPanGestureRecognizer *singlePan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(singlePan:)];
//    singlePan.maximumNumberOfTouches = 1;
//    [_cropRect addGestureRecognizer:singlePan];
    
    UIButton *cropBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cropBtn.frame = CGRectMake(120, CGRectGetMaxY(self.view.bounds)-80, (CGRectGetWidth(self.view.bounds)-240)*0.5, 40);
    [self.view addSubview:cropBtn];
    [cropBtn setTitle:@"Crop" forState:UIControlStateNormal];
    cropBtn.backgroundColor = [UIColor redColor];
    [cropBtn addTarget:self action:@selector(onCropBtnClick) forControlEvents:UIControlEventTouchUpInside];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [OpenCVWapper detectEdgesFor:self.sourceImageView cropView:self.cropRect];
}

- (void)singlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint posInStretch = [gesture locationInView:_cropRect];
    if(gesture.state == UIGestureRecognizerStateBegan){
        [_cropRect findPointAtLocation:posInStretch];
    }
    if(gesture.state == UIGestureRecognizerStateEnded){
        _cropRect.activePoint.backgroundColor = [UIColor grayColor];
        _cropRect.activePoint = nil;
        [_cropRect checkangle:0];
    }
    [_cropRect moveActivePointToLocation:posInStretch];
    
}

- (void)onCropBtnClick {
    UIImage *image = [OpenCVWapper imageCropedFromSourceImageView:self.sourceImageView cropView:self.cropRect];
    return;
}



@end
