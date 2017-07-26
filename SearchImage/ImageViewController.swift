//
//  ImageViewController.swift
//  SearchImage
//
//  Created by LU XIAOQUAN on 2017/07/21.
//  Copyright © 2017年 PM001192. All rights reserved.
//

import Foundation
import UIKit
import TesseractOCR

class ImageViewController : BaseViewController {
    
    var photo: Photo?
    
    var imageView: UIImageView!
    var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        guard let data = try? Data(contentsOf: (photo?.imageUrl!)!) else {
            return
        }
        
        imageView = UIImageView(frame: self.view.frame)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.image = UIImage(data: data)
        self.view.addSubview(imageView)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlerGesture))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(pan)
        
        let segment = UISegmentedControl(items: ["画像", "テキスト"])
        segment.selectedSegmentIndex = 0
        self.navigationItem.titleView = segment
        segment.sizeToFit()
        segment.addTarget(self, action: #selector(changed(segment:)), for: UIControlEvents.valueChanged)
        
        textView = UITextView(frame: self.view.frame)
        textView.isEditable = false
        self.view.addSubview(textView)
        textView.isHidden = true
        
        if photo?.memo == "" {
            
            if let tesseract = G8Tesseract(language: "jpn+eng") {
                tesseract.image = UIImage(data: data)?.adjust()
                tesseract.delegate = self
                DispatchQueue(label: "backgroud").async {
                    tesseract.recognize()
                    DispatchQueue.main.sync {
                        PhotoManager.shared.update(photo: self.photo!, memo: (tesseract.recognizedText)!)
                        
                        self.textView.text = tesseract.recognizedText
                    }
                }
            }
        } else {
            self.textView.text = photo?.memo
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
//        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
//        self.navigationController?.navigationBar.shadowImage = nil
    }
    
    func close(){
    }
    
    func changed(segment: UISegmentedControl){
        switch segment.selectedSegmentIndex {
        case 0:
            self.imageView.isHidden = false
            self.textView.isHidden = true
        case 1:
            self.imageView.isHidden = true
            self.textView.isHidden = false
        default:
            print("segment index default")
        }
    }
    
    func handlerGesture(recognizer: UIPanGestureRecognizer) {
        
        if(recognizer.state == .ended) {
            let velocity = recognizer.velocity(in: recognizer.view)
            
            if velocity.y > 500 {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}


extension ImageViewController: G8TesseractDelegate{
    
    public func progressImageRecognition(for tesseract: G8Tesseract!) {
        print("---- progressImageRecognition \(Date().timeIntervalSince1970)")
    }
    
    public func shouldCancelImageRecognition(for tesseract: G8Tesseract!) -> Bool {
        print("---- shouldCancelImageRecognition \(Date().timeIntervalSince1970)")
        return false
    }
    
    public func preprocessedImage(for tesseract: G8Tesseract!, sourceImage: UIImage!) -> UIImage! {
        print("---- preprocessedImage \(Date().timeIntervalSince1970)")
        return sourceImage
    }
}

