//
//  OpenCVWapper.m
//  OpenCVDemo
//
//  Created by mac on 2017/11/15.
//  Copyright © 2017年 程维. All rights reserved.
//

#import "OpenCVWapper.h"
#import <opencv2/opencv.hpp>
#import "MMCropView.h"
using namespace cv;
using namespace std;

@implementation OpenCVWapper

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

cv::Point2f computeIntersect(cv::Vec4i a, cv::Vec4i b) {
    int x1 = a[0], y1 = a[1], x2 = a[2], y2 = a[3], x3 = b[0], y3 = b[1], x4 = b[2], y4 = b[3];
    
    if (float d = ((float)(x1 - x2) * (y3 - y4)) - ((y1 - y2) * (x3 - x4))) {
        cv::Point2f pt;
        pt.x = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / d;
        pt.y = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / d;
        return pt;
    }
    else
        return cv::Point2f(-1, -1);
}

void sortCorners(std::vector<cv::Point2f>& corners, cv::Point2f center) {
    std::vector<cv::Point2f> top, bot;
    
    for (int i = 0; i < corners.size(); i++) {
        if (corners[i].y < center.y)
            top.push_back(corners[i]);
        else
            bot.push_back(corners[i]);
    }
    corners.clear();
    
    if (top.size() == 2 && bot.size() == 2){
        cv::Point2f tl = top[0].x > top[1].x ? top[1] : top[0];
        cv::Point2f tr = top[0].x > top[1].x ? top[0] : top[1];
        cv::Point2f bl = bot[0].x > bot[1].x ? bot[1] : bot[0];
        cv::Point2f br = bot[0].x > bot[1].x ? bot[0] : bot[1];
        
        
        corners.push_back(tl);
        corners.push_back(tr);
        corners.push_back(br);
        corners.push_back(bl);
    }
}
+ (UIImage *)transform:(UIImage *)originImage {
    UIImage *img;
    Mat wrapSrc = [self cvMatFromUIImage:originImage];
    //默认转为4通道 所以下面Scalar也得是4通道，否则不能正确实现颜色
    
    NSLog(@"wrapSrc cols%d rows%d channels%d type%d depth%d elemSize%zu",wrapSrc.cols,wrapSrc.rows,wrapSrc.channels(),wrapSrc.type(),wrapSrc.depth(),wrapSrc.elemSize());
    
    //灰度
    Mat graymat;
    cvtColor(wrapSrc, graymat,CV_BGR2GRAY);
    blur(graymat, graymat, cv::Size(3,3));
    
    Canny(graymat, graymat, 10, 30, 3);
    
    img = [self UIImageFromCVMat:graymat];
    
    std::vector<cv::Vec4i> lines;
    HoughLinesP(graymat, lines, 1, CV_PI/180, 70, 100, 10);
    
    // Expand the lines
    for (int i = 0; i < lines.size(); i++) {
        cv::Vec4i v = lines[i];
        lines[i][0] = 0;
        lines[i][1] = ((float)v[1] - v[3]) / (v[0] - v[2]) * -v[0] + v[1];
        lines[i][2] = wrapSrc.cols;
        lines[i][3] = ((float)v[1] - v[3]) / (v[0] - v[2]) * (wrapSrc.cols - v[2]) + v[3];
    }
    
    
    
    std::vector<cv::Point2f> corners;
    for (int i = 0; i < lines.size(); i++) {
        for (int j = i+1; j < lines.size(); j++) {
            cv::Point2f pt = computeIntersect(lines[i], lines[j]);
            
//            cv::circle(wrapSrc, pt, 3, CV_RGB(255,0,0), 2);
            
            if (pt.x >= 0 && pt.y >= 0)
                corners.push_back(pt);
        }
    }
    
    img = [self UIImageFromCVMat:wrapSrc];
    
    std::vector<cv::Point2f> approx;
    cv::approxPolyDP(cv::Mat(corners), approx, cv::arcLength(cv::Mat(corners), true) * 0.02, true);
    
    for (int i = 0; i < approx.size(); i++) {
        Point2f pt = approx[i];
        
        circle(wrapSrc, pt, 3, CV_RGB(255, 0, 0), 2);
    }
    img = [self UIImageFromCVMat:wrapSrc];
    
    if (approx.size() != 4) {
        std::cout << "The object is not quadrilateral!" << std::endl;
        return originImage;
    }
    
    cv::Point2f center(0,0);
    // Get mass center
    for (int i = 0; i < corners.size(); i++) {
        center += corners[i];
    }
    center *= (1. / corners.size());
    
    sortCorners(corners, center);
    if (corners.size() == 0) {
        std::cout << "The corners were not sorted correctly!" << std::endl;
        return originImage;
    }
    cv::Mat dst = wrapSrc.clone();
    
    // Draw lines
    for (int i = 0; i < lines.size(); i++)
    {
        cv::Vec4i v = lines[i];
        cv::line(dst, cv::Point(v[0], v[1]), cv::Point(v[2], v[3]), CV_RGB(0,255,0));
    }
    
    // Draw corner points
    cv::circle(dst, corners[0], 3, CV_RGB(255,0,0), 2);
    cv::circle(dst, corners[1], 3, CV_RGB(0,255,0), 2);
    cv::circle(dst, corners[2], 3, CV_RGB(0,0,255), 2);
    cv::circle(dst, corners[3], 3, CV_RGB(255,255,255), 2);
    
    // Draw mass center
    cv::circle(dst, center, 3, CV_RGB(255,255,0), 2);
    
    cv::Mat quad = cv::Mat::zeros(300, 220, CV_8UC3);
    
    std::vector<cv::Point2f> quad_pts;
    quad_pts.push_back(cv::Point2f(0, 0));
    quad_pts.push_back(cv::Point2f(quad.cols, 0));
    quad_pts.push_back(cv::Point2f(quad.cols, quad.rows));
    quad_pts.push_back(cv::Point2f(0, quad.rows));
    
    cv::Mat transmtx = cv::getPerspectiveTransform(corners, quad_pts);
    cv::warpPerspective(wrapSrc, quad, transmtx, quad.size());
    
    //Shi-Tomas
    UIImage *result = [self UIImageFromCVMat:quad];
    return result;
}


+ (UIImage *)wrapImg:(UIImage *)originImage {
    UIImage *img;
    Mat wrapSrc = [self cvMatFromUIImage:originImage];
    //默认转为4通道 所以下面Scalar也得是4通道，否则不能正确实现颜色
    
    NSLog(@"wrapSrc cols%d rows%d channels%d type%d depth%d elemSize%zu",wrapSrc.cols,wrapSrc.rows,wrapSrc.channels(),wrapSrc.type(),wrapSrc.depth(),wrapSrc.elemSize());
    
    //灰度
    Mat graymat;
    cvtColor(wrapSrc ,graymat, COLOR_BGR2GRAY);
    blur(graymat, graymat, Size2d(1,1));
    Canny(graymat, graymat, 100, 100, 3);
    //二值化，灰度大于14的为白色 需要多调整 直至出现白色大梯形
    img = [self UIImageFromCVMat:graymat];
    
//    graymat = graymat > 7;
//
//    img = [self UIImageFromCVMat:graymat];
    
    //Shi-Tomasi 角点算法参数
    int maxCorners = 100;
    vector<Point2f> corners;
    double qualityLevel = 0.01;
    double minDistance = 100;//角点之间最小距离
    int blockSize = 3;//轮廓越明显，取值越大
    bool useHarrisDetector=false;
    double k = 0.04;
    //Shi-Tomasi 角点检测
    goodFeaturesToTrack(graymat,corners,maxCorners,qualityLevel,minDistance,Mat(),blockSize,useHarrisDetector,k);
    
    NSLog(@"检测到角点数:%lu",corners.size());
    
    int r = 10;
    //画出来看看 找到的是不是四个顶点 另外角点检测出来的点顺序每次不一定相同
//    if(corners.size() == 4){
//        circle(wrapSrc,corners[0],r,Scalar(255,0,0,255),2,8,0);//红
//        circle(wrapSrc,corners[1],r,Scalar(0,255,0,255),2,8,0);//绿
//        circle(wrapSrc,corners[2],r,Scalar(0,0,255,255),2,8,0);//蓝
//        circle(wrapSrc,corners[3],r,Scalar(255,255,0,255),2,8,0);//黄
//    }
    
    for (int i = 0; i < corners.size(); i++) {
        int r = arc4random() % 255;
        int b = arc4random() % 255;
        int g = arc4random() % 255;
        int y = arc4random() % 255;
        circle(graymat, corners[i], r, Scalar(r, b, g, y), 2, 8, 0);
    }
    
    img = [self UIImageFromCVMat:graymat];
    
    
    std::vector<std::vector<cv::Point>> contoursOutLine;
    findContours(graymat,contoursOutLine,CV_RETR_LIST,CV_CHAIN_APPROX_SIMPLE);
    // 对轮廓计算其凸包//
    // 边界框
    cv::Rect boudRect;
    vector<Point2i>  poly ;
    for( int i = 0; i < contoursOutLine.size();  i++)
    {
        // 边界框
        boudRect=  boundingRect(contoursOutLine[i] );
        //面积过滤
        int tmpArea=boudRect.area();
        if(tmpArea>= 50000 )
        {
            rectangle(wrapSrc,cvPoint(boudRect.x,boudRect.y),cvPoint(boudRect.br().x ,boudRect.br().y ),Scalar(128),2);
        }
    }
    //src=wrapSrc(boudRect); 用这种方式截屏有时候会出错 不知咋回事
    //用IOS的 quartz api来截图
    UIImage *image=[UIImage imageWithCGImage:CGImageCreateWithImageInRect([originImage CGImage], CGRectMake(boudRect.x,boudRect.y,boudRect.width,boudRect.height))];
    
    Mat src = [self cvMatFromUIImage:image];
    Mat warp_dst = Mat::zeros( src.rows, src.cols, src.type() );
    
    //从梯形srcTri[4] 变换成 外包矩形dstTri[4]
    Point2f srcTri[4];
    Point2f dstTri[4];
    
    Point2f aRect1=boudRect.tl();
    // 梯形四个顶点 顺序为 左上  右上  左下  右下
    Point2f srcTri0 = Point2f(corners[0].x-aRect1.x  ,corners[0].y-aRect1.y );
    Point2f srcTri1 = Point2f(corners[2].x-aRect1.x  ,corners[2].y-aRect1.y );
    Point2f srcTri2 = Point2f(corners[1].x-aRect1.x  , corners[1].y-aRect1.y );
    Point2f srcTri3 = Point2f(corners[3].x-aRect1.x  , corners[3].y-aRect1.y );
    //查找左上点 取出外包矩形的中点，然后把梯形四个顶点与中点进行大小比较，如x，y都小于中点的是左上，x大于中点，y小于中点 则为右上
    Point2f boudRectCenter=Point2f(src.cols/2,src.rows/2);
    if(srcTri0.x>boudRectCenter.x){
        if(srcTri0.y>boudRectCenter.y){//右下
            srcTri[3]=srcTri0;
        }else{//右上
            srcTri[1]=srcTri0;
        }
    }else{
        if(srcTri0.y>boudRectCenter.y){//左下
            srcTri[2]=srcTri0;
        }else{//左上
            srcTri[0]=srcTri0;
        }
    }
    if(srcTri1.x>boudRectCenter.x){
        if(srcTri1.y>boudRectCenter.y){//右下
            srcTri[3]=srcTri1;
        }else{//右上
            srcTri[1]=srcTri1;
        }
    }else{
        if(srcTri1.y>boudRectCenter.y){//左下
            srcTri[2]=srcTri1;
        }else{//左上
            srcTri[0]=srcTri1;
        }
    }
    
    if(srcTri2.x>boudRectCenter.x){
        if(srcTri2.y>boudRectCenter.y){//右下
            srcTri[3]=srcTri2;
        }else{//右上
            srcTri[1]=srcTri2;
        }
    }else{
        if(srcTri2.y>boudRectCenter.y){//左下
            srcTri[2]=srcTri2;
        }else{//左上
            srcTri[0]=srcTri2;
        }
    }
    
    if(srcTri3.x>boudRectCenter.x){
        if(srcTri3.y>boudRectCenter.y){//右下
            srcTri[3]=srcTri3;
        }else{//右上
            srcTri[1]=srcTri3;
        }
    }else{
        if(srcTri3.y>boudRectCenter.y){//左下
            srcTri[2]=srcTri3;
        }else{//左上
            srcTri[0]=srcTri3;
        }
    }
    // 画出来 看看顺序对不对
    circle(src,srcTri[0],r,Scalar(255,0,0,255),-1,8,0);//红 左上
    circle(src,srcTri[1],r,Scalar(0,255,0,255),-1,8,0);//绿 右上
    circle(src,srcTri[2],r,Scalar(0,0,255,255),-1,8,0);//蓝 左下
    circle(src,srcTri[3],r,Scalar(255,255,0,255),-1,8,0);//黄 右下
    
    //  return;
    
    // 外包矩形的四个顶点， 顺序为 左上  右上  左下  右下
    dstTri[0] = Point2f( 0,0 );
    dstTri[1] = Point2f( src.cols - 1, 0 );
    dstTri[2] = Point2f( 0, src.rows - 1 );
    dstTri[3] = Point2f( src.cols - 1, src.rows - 1 );
    //自由变换 透视变换矩阵3*3
    Mat warp_matrix( 3, 3, CV_32FC1 );
    warp_matrix=getPerspectiveTransform(srcTri  ,dstTri  );
    warpPerspective( src, warp_dst, warp_matrix, warp_dst.size(),WARP_FILL_OUTLIERS);
    
//    _imageView.image= MatToUIImage(warp_dst) ;
    UIImage *result = [self UIImageFromCVMat:warp_dst];
    return result;
}


+ (void)detectEdgesFor:(UIImageView *)sourceImageView cropView:(MMCropView *)cropView {
    cv::Mat original = [self cvMatFromUIImage:sourceImageView.image];
    
    CGSize imageSize = sourceImageView.image.size;
    CGFloat imageScale = fminf(CGRectGetWidth(sourceImageView.bounds)/imageSize.width, CGRectGetHeight(sourceImageView.bounds)/imageSize.height);
    CGSize targetSize = CGSizeMake(imageSize.width*imageScale, imageSize.height*imageScale);
    
    cv::resize(original, original, cvSize(targetSize.width, targetSize.height));
    
    
    
    std::vector<std::vector<cv::Point>>squares;
    std::vector<cv::Point> largest_square;
    
    find_squares(original, squares);
    find_largest_square(squares, largest_square);
    
    if (largest_square.size() == 4)
    {
        
        // Manually sorting points, needs major improvement. Sorry.
        
        NSMutableArray *points = [NSMutableArray array];
        NSMutableDictionary *sortedPoints = [NSMutableDictionary dictionary];
        
        for (int i = 0; i < 4; i++)
        {
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGPoint:CGPointMake(largest_square[i].x, largest_square[i].y)], @"point" , [NSNumber numberWithInt:(largest_square[i].x + largest_square[i].y)], @"value", nil];
            [points addObject:dict];
        }
        
        int min = [[points valueForKeyPath:@"@min.value"] intValue];
        int max = [[points valueForKeyPath:@"@max.value"] intValue];
        
        int minIndex = 0;
        int maxIndex = 0;
        
        int missingIndexOne = 0;
        int missingIndexTwo = 0;
        
        for (int i = 0; i < 4; i++)
        {
            NSDictionary *dict = [points objectAtIndex:i];
            
            if ([[dict objectForKey:@"value"] intValue] == min)
            {
                [sortedPoints setObject:[dict objectForKey:@"point"] forKey:@"0"];
                minIndex = i;
                continue;
            }
            
            if ([[dict objectForKey:@"value"] intValue] == max)
            {
                [sortedPoints setObject:[dict objectForKey:@"point"] forKey:@"2"];
                maxIndex = i;
                continue;
            }
            
            NSLog(@"MSSSING %i", i);
            
            missingIndexOne = i;
        }
        
        for (int i = 0; i < 4; i++)
        {
            if (missingIndexOne != i && minIndex != i && maxIndex != i)
            {
                missingIndexTwo = i;
            }
        }
        
        
        if (largest_square[missingIndexOne].x < largest_square[missingIndexTwo].x)
        {
            //2nd Point Found
            [sortedPoints setObject:[[points objectAtIndex:missingIndexOne] objectForKey:@"point"] forKey:@"3"];
            [sortedPoints setObject:[[points objectAtIndex:missingIndexTwo] objectForKey:@"point"] forKey:@"1"];
        }
        else
        {
            //4rd Point Found
            [sortedPoints setObject:[[points objectAtIndex:missingIndexOne] objectForKey:@"point"] forKey:@"1"];
            [sortedPoints setObject:[[points objectAtIndex:missingIndexTwo] objectForKey:@"point"] forKey:@"3"];
        }
        
        [cropView topLeftCornerToCGPoint:[(NSValue *)[sortedPoints objectForKey:@"0"] CGPointValue]];
        [cropView topRightCornerToCGPoint:[(NSValue *)[sortedPoints objectForKey:@"1"] CGPointValue]];
        [cropView bottomRightCornerToCGPoint:[(NSValue *)[sortedPoints objectForKey:@"2"] CGPointValue]];
        [cropView bottomLeftCornerToCGPoint:[(NSValue *)[sortedPoints objectForKey:@"3"] CGPointValue]];
        
        NSLog(@"%@ Sorted Points",sortedPoints);
        
        
        
    }
    else{
        
    }
    
    original.release();
}

+ (UIImage *)imageCropedFromSourceImageView:(UIImageView *)sourceImageView cropView:(MMCropView *)cropView {
    CGSize imageSize = sourceImageView.image.size;
    CGFloat scaleFactor = fminf(CGRectGetWidth(sourceImageView.bounds)/imageSize.width, CGRectGetHeight(sourceImageView.bounds)/imageSize.height);
    CGPoint ptBottomLeft = [cropView coordinatesForPoint:1 withScaleFactor:scaleFactor];
    CGPoint ptBottomRight = [cropView coordinatesForPoint:2 withScaleFactor:scaleFactor];
    CGPoint ptTopRight = [cropView coordinatesForPoint:3 withScaleFactor:scaleFactor];
    CGPoint ptTopLeft = [cropView coordinatesForPoint:4 withScaleFactor:scaleFactor];
    
    
    
    CGFloat w1 = sqrt( pow(ptBottomRight.x - ptBottomLeft.x , 2) + pow(ptBottomRight.x - ptBottomLeft.x, 2));
    CGFloat w2 = sqrt( pow(ptTopRight.x - ptTopLeft.x , 2) + pow(ptTopRight.x - ptTopLeft.x, 2));
    
    CGFloat h1 = sqrt( pow(ptTopRight.y - ptBottomRight.y , 2) + pow(ptTopRight.y - ptBottomRight.y, 2));
    CGFloat h2 = sqrt( pow(ptTopLeft.y - ptBottomLeft.y , 2) + pow(ptTopLeft.y - ptBottomLeft.y, 2));
    
    CGFloat maxWidth = (w1 < w2) ? w1 : w2;
    CGFloat maxHeight = (h1 < h2) ? h1 : h2;
    
    
    
    cv::Point2f src[4], dst[4];
    src[0].x = ptTopLeft.x;
    src[0].y = ptTopLeft.y;
    src[1].x = ptTopRight.x;
    src[1].y = ptTopRight.y;
    src[2].x = ptBottomRight.x;
    src[2].y = ptBottomRight.y;
    src[3].x = ptBottomLeft.x;
    src[3].y = ptBottomLeft.y;
    
    dst[0].x = 0;
    dst[0].y = 0;
    dst[1].x = maxWidth - 1;
    dst[1].y = 0;
    dst[2].x = maxWidth - 1;
    dst[2].y = maxHeight - 1;
    dst[3].x = 0;
    dst[3].y = maxHeight - 1;
    
    cv::Mat undistorted = cv::Mat( cvSize(maxWidth,maxHeight), CV_8UC4);
    cv::Mat original = [self cvMatFromUIImage:sourceImageView.image];
    
    NSLog(@"%f %f %f %f",ptBottomLeft.x,ptBottomRight.x,ptTopRight.x,ptTopLeft.x);
    cv::warpPerspective(original, undistorted, cv::getPerspectiveTransform(src, dst), cvSize(maxWidth, maxHeight));
    
    UIImage *resImg = [self UIImageFromCVMat:undistorted];
    return resImg;
}


void find_squares(cv::Mat& image, std::vector<std::vector<cv::Point>>&squares) {
    
    // blur will enhance edge detection
    
    cv::Mat blurred(image);
    //    medianBlur(image, blurred, 9);
    GaussianBlur(image, blurred, cvSize(11,11), 0);//change from median blur to gaussian for more accuracy of square detection
    
    cv::Mat gray0(blurred.size(), CV_8U), gray;
    std::vector<std::vector<cv::Point> > contours;
    
    // find squares in every color plane of the image
    for (int c = 0; c < 3; c++)
    {
        int ch[] = {c, 0};
        mixChannels(&blurred, 1, &gray0, 1, ch, 1);
        
        // try several threshold levels
        const int threshold_level = 2;
        for (int l = 0; l < threshold_level; l++)
        {
            // Use Canny instead of zero threshold level!
            // Canny helps to catch squares with gradient shading
            if (l == 0)
            {
                Canny(gray0, gray, 10, 20, 3); //
                //                Canny(gray0, gray, 0, 50, 5);
                
                // Dilate helps to remove potential holes between edge segments
                dilate(gray, gray, cv::Mat(), cv::Point(-1,-1));
            }
            else
            {
                gray = gray0 >= (l+1) * 255 / threshold_level;
            }
            
            // Find contours and store them in a list
            findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
            
            // Test contours
            std::vector<cv::Point> approx;
            for (size_t i = 0; i < contours.size(); i++)
            {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                approxPolyDP(cv::Mat(contours[i]), approx, arcLength(cv::Mat(contours[i]), true)*0.02, true);
                
                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if (approx.size() == 4 &&
                    fabs(contourArea(cv::Mat(approx))) > 1000 &&
                    isContourConvex(cv::Mat(approx)))
                {
                    double maxCosine = 0;
                    
                    for (int j = 2; j < 5; j++)
                    {
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    if (maxCosine < 0.3)
                        squares.push_back(approx);
                }
            }
        }
    }
}

void find_largest_square(const std::vector<std::vector<cv::Point> >& squares, std::vector<cv::Point>& biggest_square)
{
    if (!squares.size())
    {
        // no squares detected
        return;
    }
    
    int max_width = 0;
    int max_height = 0;
    int max_square_idx = 0;
    
    for (size_t i = 0; i < squares.size(); i++)
    {
        // Convert a set of 4 unordered Points into a meaningful cv::Rect structure.
        cv::Rect rectangle = boundingRect(cv::Mat(squares[i]));
        
        //        cout << "find_largest_square: #" << i << " rectangle x:" << rectangle.x << " y:" << rectangle.y << " " << rectangle.width << "x" << rectangle.height << endl;
        
        // Store the index position of the biggest square found
        if ((rectangle.width >= max_width) && (rectangle.height >= max_height))
        {
            max_width = rectangle.width;
            max_height = rectangle.height;
            max_square_idx = i;
        }
    }
    
    biggest_square = squares[max_square_idx];
}


double angle( cv::Point pt1, cv::Point pt2, cv::Point pt0 ) {
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

cv::Mat debugSquares( std::vector<std::vector<cv::Point> > squares, cv::Mat image ){
    
    NSLog(@"DEBUG!/?!");
    for ( unsigned int i = 0; i< squares.size(); i++ ) {
        // draw contour
        
        NSLog(@"LOOP!");
        
        cv::drawContours(image, squares, i, cv::Scalar(255,0,0), 1, 8, std::vector<cv::Vec4i>(), 0, cv::Point());
        
        // draw bounding rect
        cv::Rect rect = boundingRect(cv::Mat(squares[i]));
        cv::rectangle(image, rect.tl(), rect.br(), cv::Scalar(0,255,0), 2, 8, 0);
        
        // draw rotated rect
        cv::RotatedRect minRect = minAreaRect(cv::Mat(squares[i]));
        cv::Point2f rect_points[4];
        minRect.points( rect_points );
        for ( int j = 0; j < 4; j++ ) {
            cv::line( image, rect_points[j], rect_points[(j+1)%4], cv::Scalar(0,0,255), 1, 8 ); // blue
        }
    }
    
    return image;
}

@end
