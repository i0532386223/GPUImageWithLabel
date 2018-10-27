//
//  ViewController.swift
//  GPUImageWithLabel
//
//  Created by Ivan Kramarchuk on 27/10/2018.
//  Copyright © 2018 Ivan Kramarchuk. All rights reserved.
//

import UIKit
import GPUImage
import Photos

class ViewController: UIViewController {

    
    @IBOutlet weak var btnRecord: UIButton!
    
    var filterView: GPUImageView!
    var videoCamera: GPUImageVideoCamera!
    var uiElement: GPUImageUIElement!
    var filter: GPUImageBrightnessFilter!
    var blendFilter: GPUImageAlphaBlendFilter!
    var uiElementInput: GPUImageUIElement!
    
    var catImageView: UIImageView!
    
    var movieWriter: GPUImageMovieWriter?
    var isRecording = false
    
    var fileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterView = GPUImageView(frame: self.view.bounds)
        self.view.addSubview(filterView)
        self.view.bringSubviewToFront(btnRecord)
        
        videoCamera = GPUImageVideoCamera(
            sessionPreset: AVCaptureSession.Preset.vga640x480.rawValue,
            cameraPosition: AVCaptureDevice.Position.back)
        videoCamera.outputImageOrientation = .portrait
        videoCamera.horizontallyMirrorFrontFacingCamera = false
        videoCamera.horizontallyMirrorRearFacingCamera = false
        
        filter = GPUImageBrightnessFilter()
        blendFilter = GPUImageAlphaBlendFilter()
        blendFilter.mix = 1.0
        
        videoCamera.addTarget(filter)
        
        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: 640, height: 480))
        self.catImageView = UIImageView(image: UIImage(named: "mycat")!)
        contentView.addSubview(catImageView)

        let label = UILabel(frame: CGRect(x: 20, y: 200, width: 300, height: 50))
        label.text = "Black cat"
        label.font = UIFont(name: label.font.fontName, size: 30)
        contentView.addSubview(label)
        
        uiElementInput = GPUImageUIElement(view: contentView)
        
        filter.addTarget(blendFilter)
        uiElementInput.addTarget(blendFilter)
        blendFilter.addTarget(filterView)
        
        filter.frameProcessingCompletionBlock = { filter, time in
            self.uiElementInput.update()
        }
        
        videoCamera.startCapture()
        
    }

    @IBAction func actRecord(_ sender: Any) {
        
        if (!isRecording) {
            do {
                self.isRecording = true
                let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
                fileURL = URL(string:"test.mp4", relativeTo:documentsDir)!
                do {
                    try FileManager.default.removeItem(at:fileURL!)
                } catch {
                }
                
                movieWriter = GPUImageMovieWriter(movieURL: fileURL!, size: CGSize(width: 480, height: 800))
                movieWriter?.shouldPassthroughAudio = true
                blendFilter.addTarget(movieWriter)
                movieWriter?.startRecording()
                
                DispatchQueue.main.async {
                    (sender as! UIButton).titleLabel!.text = "Stop"
                }
            } catch {
                fatalError("Couldn't initialize movie, error: \(error)")
            }
        } else {
            movieWriter?.finishRecording {
                self.isRecording = false
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.fileURL!)
                }) { saved, error in
                    if saved {
                        let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(defaultAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
                    print("error: \(error)")
                }
                
                DispatchQueue.main.async {
                    (sender as! UIButton).titleLabel!.text = "Record"
                }
                self.movieWriter = nil
            }
        }
        
    }
    

}

