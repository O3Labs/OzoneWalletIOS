//
//  QRScannerController.swift
//  O3
//
//  Created by Andrei Terentiev on 9/16/17.
//  Copyright © 2017 drei. All rights reserved.
//

import UIKit
import AVFoundation

protocol QRScanDelegate: class {
    func qrScanned(data: String)
}

class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var qrCodeFrameView: UIView?
    weak var delegate: QRScanDelegate?
    var noScanYet = true
    let supportedCodeTypes = [
                              AVMetadataObject.ObjectType.qr]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.hideHairline()
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        if captureDevice == nil {
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)

            captureSession = AVCaptureSession()
            captureSession.addInput(input)

            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes

            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer.frame = self.view.layer.bounds
            self.view.layer.insertSublayer(videoPreviewLayer!, at: 0)

            captureSession!.startRunning()
            qrCodeFrameView = UIView(frame: CGRect.zero)

            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubviewToFront(qrCodeFrameView)
            }
        } catch {
            return
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }

        guard let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject else {
            return
        }

        if supportedCodeTypes.contains(metadataObj.type) {
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds

            if let dataString = metadataObj.stringValue {
                if noScanYet {
                    noScanYet = false
                    DispatchQueue.main.async {
                        self.delegate?.qrScanned(data: dataString)
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }

    @IBAction func dissmissTapped(_ sender: Any) {
        DispatchQueue.main.async { self.dismiss(animated: true) }
    }
}
