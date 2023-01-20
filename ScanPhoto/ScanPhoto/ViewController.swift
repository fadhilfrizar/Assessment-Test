//
//  ViewController.swift
//  ScanPhoto
//
//  Created by USER-MAC-GLIT-007 on 17/01/23.
//

import UIKit
import Vision
import AVFoundation

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!

    
    lazy var takePhotoButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .black
        button.setTitle("Take Photo", for: .normal)
        button.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        return button
    }()
    
    lazy var customViews: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemPink
        return view
    }()
    
    lazy var customViewBottom: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .blue
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure capture session
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium

        // Define the device and input
        guard let backCamera = AVCaptureDevice.default(for: .video) else {
            print("Unable to access back camera")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            captureSession.addInput(input)
        } catch {
            print("Error adding input to capture session: \(error)")
            return
        }

        // Define the output
        stillImageOutput = AVCapturePhotoOutput()
        captureSession.addOutput(stillImageOutput)

        // Configure the video preview layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.addSubview(customViews)
        
        customViews.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        customViews.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        customViews.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        customViews.heightAnchor.constraint(equalToConstant: view.frame.height / 2).isActive = true
        
        customViews.layer.addSublayer(videoPreviewLayer)
        
        view.addSubview(takePhotoButton)
        
        takePhotoButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        takePhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        // Start the capture session
        DispatchQueue.global(qos: .default).async {
            self.captureSession.startRunning()
        }
    }

    // Function to handle taking a photo
    @objc func takePhoto(_ sender: UIButton) {
        
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        stillImageOutput.capturePhoto(with: settings, delegate: self)
    }

    // Function to handle processing the photo and analyzing the text
    func processImage(_ image: UIImage) {
        // Convert the image to a CIImage
        guard let ciImage = CIImage(image: image) else {
            print("Unable to convert UIImage to CIImage")
            return
        }

        // Create a text recognition request
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                print("Error recognizing text: \(error)")
                return
            }

            // Iterate over the recognized text in the image
            request.results?.forEach({ (result) in
                guard let textResult = result as? VNRecognizedTextObservation else { return }
                let topCandidate = textResult.topCandidates(1)
                if topCandidate.isEmpty { return }
                let recognizedText = topCandidate[0].string
                
                self.showToast(message: recognizedText, font: UIFont.systemFont(ofSize: 12))
//                // check if the text is "1+1"
//                if recognizedText == "1+1" {
//                    let result = 1 + 1
//                    print("Result: \(result)")
//                }
            })
        }

        // Perform the text recognition
        let handler = VNImageRequestHandler(ciImage: ciImage)
        do {
            try handler.perform([request])
        } catch {
            print("Error performing text recognition: \(error)")
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }

        // Get the image data
        guard let imageData = photo.fileDataRepresentation() else {
            print("Unable to get image data")
            return
        }

        // Create a UIImage from the image data
        guard let image = UIImage(data: imageData) else {
            print("Unable to create UIImage")
            return
        }

        // Process the image
        processImage(image)
    }

}


extension UIViewController {

func showToast(message : String, font: UIFont) {

    let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
    toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    toastLabel.textColor = UIColor.white
    toastLabel.font = font
    toastLabel.textAlignment = .center;
    toastLabel.text = message
    toastLabel.alpha = 1.0
    toastLabel.layer.cornerRadius = 10;
    toastLabel.clipsToBounds  =  true
    self.view.addSubview(toastLabel)
    UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
         toastLabel.alpha = 0.0
    }, completion: {(isCompleted) in
        toastLabel.removeFromSuperview()
    })
} }
