//
//  ViewController.swift
//  QRToolDemo
//
//  Created by targetcloud on 2016/12/4.
//  Copyright © 2016年 targetcloud. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var QRCodeResultStrings: UITextField!
    @IBOutlet weak var scanline: UIImageView!
    @IBOutlet weak var scanBackView: UIView!
    @IBOutlet weak var scanlineBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var qrImg: UIImageView!
    
    deinit{
        print("demo deinit");
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        QRCodeResultStrings.resignFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scanBackView.backgroundColor = UIColor.clear
        scanBackView.clipsToBounds = true
        
        self.title="--QRTool Demo--";
        let leftItem=UIBarButtonItem(barButtonSystemItem:.action,target:self,action:#selector(ViewController.ItemClick));
        self.navigationItem.leftBarButtonItem=leftItem;
    }

    func ItemClick(){
        self.navigationController?.popViewController(animated: true);
    }
    
    //生成二维码图片
    @IBAction func generatorQRImage(_ sender: UIButton) {
        view.endEditing(true)
        let resultImage = QRTool.generatorQRCode(QRCodeResultStrings.text ?? "", centerImage: UIImage(named: "targetcloud.png"))
        qrImg.image = resultImage
    }
    
    //add NSPhotoLibraryUsageDescription key in your info.plist
    //从相册检测到二维码
    @IBAction func detectFromImagePickerController(_ sender: UIButton) {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary){
            return
        }
        let imagePickerVC = UIImagePickerController()
        imagePickerVC.delegate = self
        present(imagePickerVC, animated: true, completion: nil)
    }
    
    //add NSCameraUsageDescription key in your info.plist
    //从相机扫描二维码
    @IBAction func startScan(_ sender: UIButton) {
        startScanAnimation()
        QRTool.shareInstance.setRectInterest(scanBackView.frame)
        QRTool.shareInstance.scanQRCode(view) { [weak self] (resultStrs) in//需要加[weak self]
            guard let str = resultStrs.first else { return }
            self?.QRCodeResultStrings.text = str
            QRTool.shareInstance.session.stopRunning();
            QRTool.shareInstance.previewLayer.removeFromSuperlayer();
            self?.removeScanAnimation()
            //前往扫描结果
//            self?.go(str)
        }
    }
    
    fileprivate func startScanAnimation() {
        scanlineBottomConstraint.constant = -scanBackView.frame.size.height
        view.layoutIfNeeded()
        scanlineBottomConstraint.constant = scanBackView.frame.size.height
        UIView.animate(withDuration: 1, animations: {
            UIView.setAnimationRepeatCount(MAXFLOAT)
            self.view.layoutIfNeeded()
        })
    }
    
    fileprivate func removeScanAnimation() {
        scanline.layer.removeAllAnimations()
    }
    
    fileprivate func go(_ str : String){
        var msg:String
        var title:String
        if str.characters.count==0 {
            msg = "没有得到相关信息。。。"
            title = "OK"
        }else{
            msg = str.description
            title = "前往"
        }
        let alertVC = UIAlertController(title: "结果", message: msg, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: title, style: UIAlertActionStyle.default) { (action: UIAlertAction) in
            if str.characters.count>0{
                UIApplication.shared.open(URL(string: str)!, options: [:], completionHandler: nil)
            }
        }
        alertVC.addAction(action)
        present(alertVC, animated: true, completion: nil)
    }
}

extension ViewController:UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else{
            return
        }
        let result = QRTool.detectorQRCodeImage(image)
        QRCodeResultStrings.text = result.resultStrs?.last ?? ""
        picker.dismiss(animated: true, completion: nil)
        //前往检测结果
        go(QRCodeResultStrings.text!)
    }
}
