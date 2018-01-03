//
//  ViewController.swift
//  ReportCamera
//
//  Created by tanaka.takaaki on 2016/12/14.
//  Copyright © 2016年 tanaka.takaaki. All rights reserved.
//

import AWSS3
import AVFoundation
import UIKit

class CameraViewController: UIViewController {

    @IBOutlet weak var takePhotoButton: UIButton!
    
    var timeline: Timeline?
    
    var identityId = ""
    
    var device: AVCaptureDevice!
    var session: AVCaptureSession!
    var output: AVCaptureVideoDataOutput!
    
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        session = AVCaptureSession()
        
        for d in AVCaptureDevice.devices() {
            if (d as AnyObject).position == AVCaptureDevicePosition.back {
                device = d as? AVCaptureDevice
                print("\(device!.localizedName) found.")
            }
        }
        
        // バックカメラからキャプチャ入力生成
        let input: AVCaptureDeviceInput?
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            print("Caught exception!")
            return
        }
        session.addInput(input)
        //output = AVCaptureStillImageOutput()
        
        output = AVCaptureVideoDataOutput()
        // ピクセルフォーマットを 32bit BGR + A とする
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_32BGRA)]
        
        // フレームをキャプチャするためのサブスレッド用のシリアルキューを用意
        output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        output.alwaysDiscardsLateVideoFrames = true
        
        
        
        session.addOutput(output)
        session.sessionPreset = AVCaptureSessionPresetHigh
        // プレビューレイヤを生成
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.frame = view.bounds
        view.layer.addSublayer(previewLayer!)
        
        
        self.view.bringSubview(toFront: self.takePhotoButton)
        
        // セッションを開始
        session.startRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func takePhoto() {
        if let image = self.image {
            //UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)

            let data = UIImagePNGRepresentation(image)
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentsDirectory = paths[0]
            
            let filename = documentsDirectory.appendingPathComponent("copy.png")
            try? data?.write(to: filename)
            
            upload(imageURL: filename, createAt: Date()).continueWith(block: { task -> Any? in
                print(task)
            })
            
        }
    }
    
    
    func upload(imageURL: URL, createAt: Date) -> AWSTask<AnyObject> {
        let request = AWSS3TransferManagerUploadRequest()
        
        request?.bucket = "report-camera"
        request?.key = "images/original/\(createAt.timeIntervalSince1970)-\(imageURL.lastPathComponent)"
        request?.body = imageURL
        
        return AWSS3TransferManager.default().upload(request!)
    }

    func captureImage(sampleBuffer: CMSampleBuffer) -> UIImage {
        
        // Sampling Bufferから画像を取得
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        // pixel buffer のベースアドレスをロック
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)!
        
        let bytesPerRow:Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width:Int = CVPixelBufferGetWidth(imageBuffer)
        let height:Int = CVPixelBufferGetHeight(imageBuffer)
        
        
        // 色空間
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bitsPerCompornent:Int = 8
        // swift 2.0
        let newContext:CGContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace,  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue)!
        
        let imageRef: CGImage = newContext.makeImage()!
        let resultImage = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImageOrientation.right)
        
        return resultImage
    }
    
    @IBAction func takePhoto(_ sender: AnyObject) {
        takePhoto()
    }
    
    
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }

}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {

        let image: UIImage = self.captureImage(sampleBuffer: sampleBuffer)
        
        self.image = image
    }
}
