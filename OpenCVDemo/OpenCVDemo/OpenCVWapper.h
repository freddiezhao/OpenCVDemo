//
//  OpenCVWapper.h
//  OpenCVDemo
//
//  Created by mac on 2017/11/15.
//  Copyright © 2017年 程维. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MMCropView;
@interface OpenCVWapper : NSObject

+ (UIImage *)transform:(UIImage *)originImage;

+ (UIImage *)wrapImg:(UIImage *)originImage;

+ (void)detectEdgesFor:(UIImageView *)sourceImageView cropView:(MMCropView *)cropView;

+ (UIImage *)imageCropedFromSourceImageView:(UIImageView *)sourceImageView cropView:(MMCropView *)cropView;

@end
