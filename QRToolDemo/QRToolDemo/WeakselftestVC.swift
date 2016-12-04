//
//  WeakselftestVC.swift
//  QRToolDemo
//
//  Created by targetcloud on 2016/12/5.
//  Copyright © 2016年 targetcloud. All rights reserved.
//

import UIKit

class WeakselftestVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title="--weakself test--"
        let nextItem=UIBarButtonItem(title:"QRTool",style:.plain,target:self,action:#selector(WeakselftestVC.toQRTool));
        self.navigationItem.rightBarButtonItem = nextItem
    }

    func toQRTool(){
        let toQRToolVC = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
        self.navigationController?.pushViewController(toQRToolVC,animated:true);
    }

}
