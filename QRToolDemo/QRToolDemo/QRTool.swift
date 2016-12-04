//
//  QRTool.swift
//
//  Created by targetcloud on 2016/12/4.
//  Copyright © 2016年 targetcloud. All rights reserved.
//  http://blog.csdn.net/callzjy

import UIKit
import AVFoundation

typealias ScanResultBlock = ([String]) -> ()

class QRTool: NSObject {
    static let shareInstance = QRTool()
    
    private lazy var input: AVCaptureDeviceInput? = {
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        var input: AVCaptureDeviceInput?
        do {
            input = try AVCaptureDeviceInput(device: device)
            return input
        }catch {
            return nil
        }
    }()
    private lazy var output: AVCaptureMetadataOutput = {
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        return output
    }()
    lazy var session: AVCaptureSession = AVCaptureSession()
    lazy var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
    fileprivate var scanResultBlock: ScanResultBlock?
    fileprivate var isDrawFrame: Bool = false
    fileprivate var drawLindWidth:CGFloat = 1
    fileprivate var drawStrokeColor:UIColor = UIColor.red
    
    func scanQRCode(_ inView: UIView, isDrawFrame: Bool = true,drawStrokeColor:UIColor = UIColor.red,drawLindWidth:CGFloat = 5, resultBlock: @escaping (_ resultStrs: [String])->()) {
        scanResultBlock = resultBlock
        self.isDrawFrame = isDrawFrame
        self.drawStrokeColor = drawStrokeColor
        self.drawLindWidth = drawLindWidth
        if session.inputs.count==0 && session.outputs.count==0{
            if session.canAddInput(input) && session.canAddOutput(output) {
                session.addInput(input)
                session.addOutput(output)
            }else {
                return
            }
        }
        output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        if inView.layer.sublayers == nil {
            previewLayer.frame = inView.layer.bounds
            inView.layer.insertSublayer(previewLayer, at: 0)
        }else {
            let subLayers = inView.layer.sublayers!
            if  !subLayers.contains(previewLayer) {
                previewLayer.frame = inView.layer.bounds
                inView.layer.insertSublayer(previewLayer, at: 0)
            }
        }
        session.startRunning()
    }
    
    func setRectInterest(_ orignRect: CGRect) {
        let bounds = UIScreen.main.bounds
        let x: CGFloat = orignRect.origin.x / bounds.size.width
        let y: CGFloat = orignRect.origin.y / bounds.size.height
        let width: CGFloat = orignRect.size.width / bounds.size.width
        let height: CGFloat = orignRect.size.height / bounds.size.height
        output.rectOfInterest = CGRect(x: y, y: x, width: height, height: width)
    }
    
    class func detectorQRCodeImage(_ image: UIImage, isDrawQRCodeFrame: Bool = true,drawLineWidth:CGFloat = 5) -> (resultStrs: [String]?, resultImage: UIImage) {
        let imageCI = CIImage(image: image)
        let dector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = dector?.features(in: imageCI!)
        var resultImage = image
        var resultStrings = [String]()
        for feature in features! {
            let qrFeature = feature as! CIQRCodeFeature
            resultStrings.append(qrFeature.messageString!)
            if isDrawQRCodeFrame {
                resultImage = drawFrame(resultImage, feature: qrFeature,drawLineWidth:drawLineWidth)
            }
        }
        return (resultStrings, resultImage)
    }
    
    class func generatorQRCode(_ inputStr: String, centerImage: UIImage?,scaleXY: CGFloat = 10,drawSize:CGSize = CGSize(width: 80, height: 80)) -> UIImage {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setDefaults()
        filter?.setValue(inputStr.data(using: String.Encoding.utf8), forKey: "inputMessage")
        filter?.setValue("M", forKey: "inputCorrectionLevel")
        var image = filter?.outputImage
        let transform = CGAffineTransform(scaleX: scaleXY, y: scaleXY)
        image = image?.applying(transform)
        var resultImage = UIImage(ciImage: image!)
        if centerImage != nil {
            resultImage = mergeImage(resultImage, centerImage: centerImage!,centerImageSize:drawSize)
        }
        return resultImage
    }
}

extension QRTool {
    class fileprivate func drawFrame(_ image: UIImage, feature: CIQRCodeFeature,drawLineWidth:CGFloat) -> UIImage {
        let size = image.size
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let context = UIGraphicsGetCurrentContext()
        context?.scaleBy(x: 1, y: -1)
        context?.translateBy(x: 0, y: -size.height)
        let bounds = feature.bounds
        let path = UIBezierPath(rect: bounds)
        UIColor.red.setStroke()
        path.lineWidth = drawLineWidth
        path.stroke()
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resultImage!
    }
    
    class fileprivate func mergeImage(_ sourceImage: UIImage, centerImage: UIImage,centerImageSize : CGSize = CGSize(width: 80, height: 80)) -> UIImage {
        let size = sourceImage.size
        UIGraphicsBeginImageContext(size)
        sourceImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        centerImage.draw(in: CGRect(x: (size.width - centerImageSize.width) * 0.5, y: (size.height - centerImageSize.height) * 0.5, width: centerImageSize.width, height: centerImageSize.height))
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resultImage!
    }
}

extension QRTool:  AVCaptureMetadataOutputObjectsDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        if isDrawFrame {
            removeFrameLayer()
        }
        var resultStrs = [String]()
        for obj in metadataObjects {
            if (obj as AnyObject).isKind(of: AVMetadataMachineReadableCodeObject.self){
                let resultObj = previewLayer.transformedMetadataObject(for: obj as! AVMetadataObject)
                let qrCodeObj = resultObj as! AVMetadataMachineReadableCodeObject
                if !resultStrs.contains(qrCodeObj.stringValue){
                    resultStrs.append(qrCodeObj.stringValue)
                }
                if isDrawFrame {
                    drawFrame(qrCodeObj)
                }
            }
        }
        if scanResultBlock != nil {
            removeFrameLayer()
            scanResultBlock!(resultStrs)//代理转闭包
        }
    }
    
    func drawFrame(_ qrCodeObj: AVMetadataMachineReadableCodeObject) {
        guard let corners = qrCodeObj.corners else { return }
        let shapLayer = CAShapeLayer()
        shapLayer.fillColor = UIColor.clear.cgColor
        shapLayer.strokeColor = drawStrokeColor.cgColor
        shapLayer.fillColor = UIColor.clear.cgColor
        shapLayer.lineWidth = drawLindWidth
        let path = UIBezierPath()
        var index = 0
        for corner in corners {
            let point = CGPoint(dictionaryRepresentation:corner as! CFDictionary)
            if index == 0 {
                path.move(to: point!)
            }else {
                path.addLine(to: point!)
            }
            index += 1
        }
        path.close()
        shapLayer.path = path.cgPath
        previewLayer.addSublayer(shapLayer)
    }
    
    func  removeFrameLayer() {
        guard let subLayers = previewLayer.sublayers else {return}
        for subLayer in subLayers {
            if subLayer.isKind(of: CAShapeLayer.self){
                subLayer.removeFromSuperlayer()
            }
        }
    }
}
