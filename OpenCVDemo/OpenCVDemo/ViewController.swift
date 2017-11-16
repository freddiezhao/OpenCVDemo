//
//  ViewController.swift
//  OpenCVDemo
//
//  Created by mac on 2017/11/15.
//  Copyright © 2017年 程维. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    let image = UIImage(named: "Smartisan")

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
//        if let touch = touches.first {
//            let pt: CGPoint = touch.location(in: self.view)
//            if pt.y < self.view.bounds.height * 0.5 {
//                let image_ = OpenCVWapper.wrapImg(image)
//                print(image_)
//            } else {
//                let image_ = OpenCVWapper.transform(image)
//                print(image_)
//            }
//        }
        
        self.show(CropViewController(), sender: nil)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

