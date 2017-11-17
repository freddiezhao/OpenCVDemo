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
        
        self.show(CropViewController(), sender: nil)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

