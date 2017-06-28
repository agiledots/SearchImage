//
//  ViewController.swift
//  SearchImage
//
//  Created by PM001192 on 2017/06/14.
//  Copyright © 2017年 PM001192. All rights reserved.
//

import UIKit
import AssetsPickerViewController
import Photos
import PhotosUI
import SQLite
import TesseractOCR



class ViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var loadingAlert: UIAlertController!
    
    var filenames:[URL]!
    var data:[Row]!
    
    var assets: [PHAsset] = []
    
    var tesseract: G8Tesseract!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        loadData()
        
        tesseract = G8Tesseract(language: "jpn")
        //tesseract.language = "eng+ita";
        tesseract.delegate = self
        tesseract.charWhitelist = "01234567890"
        
        searchBar.delegate = self
        
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.backgroundColor = UIColor.white
        
        self.view.addSubview(collectionView!)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add
            , target: self, action: #selector(ViewController.showActionSheet))

        //
        loadingAlert = UIAlertController(title: nil, message: "処理中...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        loadingAlert.view.addSubview(loadingIndicator)
    }

}

extension ViewController : UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
    }

    // 搜索触发事件，点击虚拟键盘上的search按钮时触发此方法
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // 书签按钮触发事件
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        print("搜索历史")
    }
    
    // 取消按钮触发事件
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // 搜索内容置空
        searchBar.text = ""
    }
}


extension ViewController {
    
    @objc fileprivate func showActionSheet() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let fromLibraryAction = UIAlertAction(title: "ライブラリから選択", style: .default, handler: { action in
            self.accessCameraroll()
        })
        let takePictureAction = UIAlertAction(title: "画像を撮る", style: .default, handler: { action in
            self.accessCamera()
        })
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        
        alert.addAction(fromLibraryAction)
        alert.addAction(takePictureAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func accessCameraroll() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let controller = UIImagePickerController()
            controller.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
            controller.sourceType = .photoLibrary
            self.present(controller, animated: true, completion: nil)
        }
        
        // AssetsPickerViewController
//        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
//            let picker = AssetsPickerViewController()
//            picker.pickerDelegate = self
//            present(picker, animated: true, completion: nil)
//        }
    }
    
    func accessCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let controller = UIImagePickerController()
            controller.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
            controller.sourceType = .camera
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func loadData() {
        // get all images
        self.filenames = []
        self.data = []
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: getDocumentsDirectory().path)

            self.filenames.removeAll()
            files.forEach({ (file) in
                let file = getDocumentsDirectory().appendingPathComponent(file)
                self.filenames.append(file)
            })
            print("get images count : \(filenames.count)")
        } catch {
            print("get images error: \(error)")
        }
    
        
        print("sqlite data : \n")
        ImageModel.shared.selectAll()?.forEach({ (row) in
            print(row)
            self.data.append(row)
        })
        
    }
}


//extension ViewController: AssetsPickerViewControllerDelegate {
//
//    func assetsPickerCannotAccessPhotoLibrary(controller: AssetsPickerViewController) {
//    
//    }
//    
//    func assetsPickerDidCancel(controller: AssetsPickerViewController) {
//    
//    }
//
//    func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset]) {
//
//        self.assets.removeAll()
//        self.assets.append(contentsOf: assets)
//        
//        self.collectionView.reloadData()
//        
//        if !controller.isBeingDismissed {
//            controller.dismiss(animated: true, completion: nil)
//        }
//    }
//    func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool {
//        
//        return true
//    }
//    
//    func assetsPicker(controller: AssetsPickerViewController, didSelect asset: PHAsset, at indexPath: IndexPath) {
//    
//    }
//    
//    func assetsPicker(controller: AssetsPickerViewController, shouldDeselect asset: PHAsset, at indexPath: IndexPath) -> Bool {
//        return true
//    }
//    
//    func assetsPicker(controller: AssetsPickerViewController, didDeselect asset: PHAsset, at indexPath: IndexPath) {
//    
//    }
//    
//    func getAssetThumbnail(asset: PHAsset) -> UIImage? {
//        let manager = PHImageManager.default()
//        let option = PHImageRequestOptions()
//        var thumbnail:UIImage?
//        option.isSynchronous = true
//        
//        manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
//            
//            thumbnail = result!
//            
//            print("thumbnail: \(thumbnail!)")
//        })
//        return thumbnail
//    }
//    
//}


extension ViewController: UIImagePickerControllerDelegate {

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        
        // create directory if not exsits
        let path = getDocumentsDirectory().path
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("create directory error: \(error)")
            }
        }
        
        // save image to directory
        let filename = "\(Date().timeIntervalSince1970).jpg"
        if let data = UIImagePNGRepresentation(image) {
            let fullpath = getDocumentsDirectory().appendingPathComponent(filename)
            do{
                try data.write(to: fullpath)
            } catch {
                print("save image error : \(error)")
            }
        }
        
        ImageModel.shared.insert(data: ["filename": filename, "date": "\(Date())", "memo": ""])
        
        //
        self.loadData()
        self.collectionView.reloadData()

        
        
        tesseract.image = image
        tesseract.recognize()
        
        print("ocr:  \(tesseract.recognizedText)")
        
        
        if !picker.isBeingDismissed {
            picker.dismiss(animated: true, completion: nil)
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if !picker.isBeingDismissed {
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
}

extension ViewController: G8TesseractDelegate {
    
    public func progressImageRecognition(for tesseract: G8Tesseract!) {
        print("progressImageRecognition:  \(tesseract.recognizedText)")
    }

    public func shouldCancelImageRecognition(for tesseract: G8Tesseract!) -> Bool {
        return true;
    }

//    public func preprocessedImage(for tesseract: G8Tesseract!, sourceImage: UIImage!) -> UIImage!{
//        print("preprocessedImage:  \(tesseract.recognizedText)")
//        
//    }
}


extension ViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){

    }
}

extension ViewController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.data.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        print("collectionview cellForItemAt")
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ImageCollectionViewCell
        
        if let filename = self.data[indexPath.row].get(Expression<String?>("filename")) {
            
            let path = getDocumentsDirectory().appendingPathComponent(filename).path
            
            if let image = UIImage(contentsOfFile: path) {
                cell.imageView?.image = image
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        print("collectionview willDisplay")
        
//        guard let cell = cell as? ImageCollectionViewCell else {
//            return
//        }
//        
//        let manager = PHImageManager.default()
//        let option = PHImageRequestOptions()
//        option.isSynchronous = true
//        
//        manager.requestImage(for: self.assets[indexPath.row], targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
//            
////            print("thumbnail: \(thumbnail!)")
//            cell.imageView.image = result!
//            
//            // save image to directory
//
//            let filename = self.getDocumentsDirectory().appendingPathComponent("\(Date().timeIntervalSince1970).jpg")
//            
//            self.filenames.append(filename)
//            
//            if let data = UIImageJPEGRepresentation(result!, 1) {
//                do{
//                    try data.write(to: filename)
//                } catch {
//                    print("save image error : \(error)")
//                }
//            }
//            
//        })
        
    }
}



extension ViewController: UINavigationControllerDelegate {

}










