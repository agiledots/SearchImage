//
//  RootViewController.swift
//  SearchImage
//
//  Created by LU XIAOQUAN on 2017/06/30.
//  Copyright © 2017年 PM001192. All rights reserved.
//

import Foundation
import UIKit
import AssetsPickerViewController
import Photos
import PhotosUI
import SQLite
import TesseractOCR

class RootViewController: UICollectionViewController {

    // MARK: - Properties
    fileprivate let reuseIdentifier = "PhotoCell"
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 5.0, left: 1.0, bottom: 5.0, right: 1.0)
    
    fileprivate let itemsPerRow: CGFloat = 4

    fileprivate var items:[URL] = []
    fileprivate var rows:[Row] = []
    
    fileprivate var tesseract: G8Tesseract!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tesseract = G8Tesseract(language: "eng")
//        tesseract.delegate = self
//        tesseract.charWhitelist = "01234567890"

        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add
            , target: self, action: #selector(RootViewController.addPhotos))
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh
            , target: self, action: #selector(RootViewController.loadData))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadData()
    }
    
    func loadData() {
        // get all images
        self.items = []
        
        let rootPath = getImageDirectory()!
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: (rootPath.path))
            files.forEach({ (file) in
                let file = rootPath.appendingPathComponent(file)
                self.items.append(file)
            })
        } catch {
        
        }
        
        self.collectionView?.reloadData()
        
        print(" item: \(self.items)")
        
        ImageModel.shared.selectAll()?.forEach({ (row) in
            print(row)
            self.rows.append(row)
        })
    }
}

extension RootViewController: AssetsPickerViewControllerDelegate{

    func addPhotos() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picker = AssetsPickerViewController()
            picker.pickerDelegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    func assetsPickerDidCancel(controller: AssetsPickerViewController) {
        
    }
    
    func assetsPickerCannotAccessPhotoLibrary(controller: AssetsPickerViewController) {
        
    }
    
    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset]) {
        
        if let imagePath = getImageDirectory(), let thumbnailPath = getThumbnailDirectory() {
            for asset in assets {
                let filename = "\(Date().timeIntervalSince1970).jpg"
                
                let imageFile = imagePath.appendingPathComponent(filename)
                let thumbnailFile = thumbnailPath.appendingPathComponent(filename)
                
                saveImage(asset: asset, path: imageFile)
                saveThumbnail(asset: asset, path: thumbnailFile)
                
                ImageModel.shared.insert(data: ["filename": filename, "date": "\(Date())", "memo": ""])
            }
        }
        
        if !controller.isBeingDismissed {
            controller.dismiss(animated: true, completion: nil)
        }
    }
    
    func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    func assetsPicker(controller: AssetsPickerViewController, didSelect asset: PHAsset, at indexPath: IndexPath) {
    
    }
    
    func assetsPicker(controller: AssetsPickerViewController, shouldDeselect asset: PHAsset, at indexPath: IndexPath) -> Bool {
        return true
    }
    
    func assetsPicker(controller: AssetsPickerViewController, didDeselect asset: PHAsset, at indexPath: IndexPath) {
        
    }
    
    func getDirectory(folder: String) -> URL? {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            print("get path error.")
            return nil
        }
        
        let imageUrl = NSURL(fileURLWithPath: path).appendingPathComponent(folder)
        
        if(!FileManager.default.fileExists(atPath: (imageUrl?.path)!)) {
            do {
                try FileManager.default.createDirectory(at: imageUrl!, withIntermediateDirectories: false, attributes: nil)
            }catch{
                print("create directory error: \(error)")
                return nil
            }
        }
        
        return imageUrl
    }
    
    
    func getImageDirectory() -> URL? {
        return getDirectory(folder: "IMAGES")
    }

    func getThumbnailDirectory() -> URL? {
        return getDirectory(folder: "Thumbnail")
    }

    func saveThumbnail(asset: PHAsset, path: URL) {
        let manager = PHImageManager.default()
        
        let option = PHImageRequestOptions()
        option.isSynchronous = true
        
        manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            if let data = UIImageJPEGRepresentation(result!, 1) {
                do {
                    try data.write(to: path)
                } catch {
                    print("write file error: \(error)")
                }
            }
        })
    }
    
    func saveImage(asset: PHAsset, path: URL){
        let manager = PHImageManager.default()
        
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        
        manager.requestImageData(for: asset, options: options) { data, _, _, _ in
            if let data = data {
                do {
                    try data.write(to: path)
                } catch {
                    print("write file error: \(error)")
                }
           }
        }
    }

}



// UICollectionViewDelegate
extension RootViewController {
    override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        print("click item")
    }
}

// MARK: - UICollectionViewDataSource
extension RootViewController {
    //1
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1 //searches.count
    }
    
    //2
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return items.count //searches[section].searchResults.count
    }
    
    //3
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath) as! PhotoCell
        
        cell.imageView.image = UIImage(contentsOfFile: self.items[indexPath.row].path)
        
        return cell
    }
}


extension RootViewController : UICollectionViewDelegateFlowLayout {
    //1
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //2
        let paddingSpace = (sectionInsets.left + sectionInsets.right) * itemsPerRow * 4
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = Int(availableWidth / itemsPerRow)
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    //3
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // 4
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}
