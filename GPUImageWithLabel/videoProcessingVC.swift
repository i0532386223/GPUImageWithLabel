//
//  videoProcessingVC.swift
//  GPUImageWithLabel
//
//  Created by Ivan Kramarchuk on 28/10/2018.
//  Copyright © 2018 Ivan Kramarchuk. All rights reserved.
//

import UIKit
import GPUImage
import Photos

class videoProcessingVC: UIViewController {

    var imagePickerController = UIImagePickerController()
    var videoURL: URL?
    var fileURL: URL?
    
    var movieFile: GPUImageMovie!
    
    var movieWriter: GPUImageMovieWriter?
    var isRecording = false
  
    var filterView: GPUImageView!
    var uiElement: GPUImageUIElement!
    var filter: GPUImageBrightnessFilter!
    var blendFilter: GPUImageAlphaBlendFilter!
    var uiElementInput: GPUImageUIElement!
    
    var catImageView: UIImageView!
    
    
    @IBOutlet weak var btnProcessing: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        filterView = GPUImageView(frame: self.view.bounds)
        self.view.addSubview(filterView)
        self.view.bringSubviewToFront(btnProcessing)
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func actProcessing(_ sender: Any) {
        
        imagePickerController.sourceType = .savedPhotosAlbum
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = ["public.movie"]
        present(imagePickerController, animated: true, completion: nil)
        
    }
    
    func doProcessing() {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        do {
            let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
            fileURL = URL(string:"test3.mov", relativeTo:documentsDir)!
            try FileManager.default.removeItem(at:fileURL!)
        } catch {
        }
        
        movieFile = GPUImageMovie.init(url: videoURL)
        movieFile.runBenchmark = false
        movieFile.playAtActualSpeed = false
        
        filter = GPUImageBrightnessFilter()
        filterView.setInputRotation(kGPUImageRotateRight, at: 90)
        filter.addTarget(filterView)
        movieFile.addTarget(filter)
        
        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: 640, height: 480))
        self.catImageView = UIImageView(image: UIImage(named: "mycat")!)
        contentView.addSubview(catImageView)

        let label = UILabel(frame: CGRect(x: 20, y: 200, width: 300, height: 50))
        label.text = "Black cat"
        label.font = UIFont(name: label.font.fontName, size: 30)
        contentView.addSubview(label)

        uiElementInput = GPUImageUIElement(view: contentView)

        blendFilter = GPUImageAlphaBlendFilter()
        blendFilter.mix = 1.0

        filter.addTarget(blendFilter)
        uiElementInput.addTarget(blendFilter)

        filter.frameProcessingCompletionBlock = { filter, time in
            self.uiElementInput.update()
        }
                
        let asset: AVURLAsset = AVURLAsset(url: videoURL!)
        let videoAssetTrack: AVAssetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        print("fileURL: \(fileURL)")
        movieWriter = GPUImageMovieWriter(movieURL: fileURL!, size: CGSize(width: videoAssetTrack.naturalSize.height, height: videoAssetTrack.naturalSize.width))
        movieWriter?.shouldPassthroughAudio = true
        movieWriter?.setInputRotation(kGPUImageRotateRight, at: 90)
        blendFilter.setInputRotation(kGPUImageRotateLeft, at: 90)
        blendFilter.addTarget(movieWriter)
        
        movieFile.audioEncodingTarget = movieWriter
        movieFile.enableSynchronizedEncoding(using: movieWriter)
        
        movieWriter?.startRecording()
        movieFile.startProcessing()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            print("End 1")
            self.movieWriter?.finishRecording {
                print("End 2")
                DispatchQueue.main.async {
                    self.movieFile.endProcessing()

                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.fileURL!)
                    }) { saved, error in
                        print("End 3")
                        if saved {
                            DispatchQueue.main.async {
                                let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alertController.addAction(defaultAction)
                                self.present(alertController, animated: true, completion: nil)
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            }
                        }
                        print("error PHPhotoLibrary: \(error) - \(self.fileURL!)")
                    }
                }
            }
        })

    }
    
}

extension videoProcessingVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL
        print("videoURL:\(String(describing: videoURL))")
        self.dismiss(animated: true, completion: nil)
        doProcessing()
    }
    
}


