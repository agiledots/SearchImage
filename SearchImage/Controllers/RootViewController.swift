//
//  RootViewController.swift
//  SearchImage
//

import Foundation
import UIKit
import AssetsPickerViewController
import Photos
import PhotosUI
import SQLite
import TesseractOCR
import Lightbox

class RootViewController: UIViewController {

    // MARK: - Properties
    fileprivate let cellReuseIdentifier = "PhotoCell"
    fileprivate let headerReuseIdentifier = "PhotoHeader"
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 5.0, left: 1.0, bottom: 5.0, right: 1.0)
    
    fileprivate let itemsPerRow: CGFloat = 4

    fileprivate var items:[Photo] = [] {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
//    fileprivate var tesseract: G8Tesseract!
    
    var searchController: UISearchController!
    
    var collectionView: UICollectionView!
    
    var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        let navigationBarHeight = self.navigationController?.navigationBar.frame.size.height
        let spaceHeight = statusBarHeight + navigationBarHeight!
        
        // UISearchBar
        searchBar = UISearchBar(frame: CGRect(x: 0, y: spaceHeight, width: self.view.bounds.width, height: 50))
        searchBar.delegate = self
        searchBar.placeholder = "検索"
        searchBar.searchBarStyle = .default //なくてもいい
        searchBar.barStyle = .default //なくてもいい
        searchBar.sizeToFit()
        self.view.addSubview(searchBar)
        
        // UIColleciontView
        let layout = UICollectionViewFlowLayout()
        let frame = CGRect(x: 0, y: spaceHeight + 50, width: self.view.bounds.width, height: self.view.bounds.height - 50)
        collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.register(UINib(nibName: "PhotoCell", bundle: Bundle.main), forCellWithReuseIdentifier: cellReuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.white
        self.view.addSubview(collectionView)
        
        // UIBarButtonItem
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add
            , target: self, action: #selector(addPhotos))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh
            , target: self, action: #selector(reloadData))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.reloadData()
    }
    
    func reloadData() {
        // get all images
        self.items = []
        
        if self.searchBar.text != "" {
            if let photos = PhotoManager.shared.query(by: self.searchBar.text!) {
                self.items = Array(photos)
            }
        } else {
            //
            if let photos = PhotoManager.shared.queryAll() {
                self.items = Array(photos)
            }
        }

        print("new rows \(self.items)")
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
                
                DispatchQueue.global().async {
                    // ocr
                    let data = try? Data(contentsOf: imageFile)
                    
                    // ORC
                    let tesseract = G8Tesseract(language: "eng")
                    tesseract?.charWhitelist = "01234567890"
                    tesseract?.image = UIImage(data: data!)
                    tesseract?.recognize()
                    
                    // new model
                    let photo = Photo()
                    photo.filename = filename
                    photo.memo = (tesseract?.recognizedText)!
                    
                    print("new objects: \(photo)")
                    //
                    DispatchQueue.main.sync {
                        // insert to db
                        PhotoManager.shared.add(photo: photo)
                        
                        self.reloadData()
                    }
                }
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
    
    func saveImage(asset: PHAsset, path: URL) {
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
extension RootViewController : UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("click item")
        
        
        var images: [LightboxImage] = []
        for item in self.items {
            if let data = try? Data(contentsOf: item.imageUrl!) {
                let image = LightboxImage(image: UIImage(data: data)!, text: item.memo, videoURL: nil)
                    //LightboxImage(image: UIImage(data: data)!)
                images.append(image)
            }
        }
        
        LightboxConfig.CloseButton.text = "";
        LightboxConfig.loadImage = {
                        imageView, URL, completion in
                        imageView.contentMode = .scaleAspectFill
                    }
        
        let controller = LightboxController(images: images, startIndex: indexPath.row)
        controller.dynamicBackground = true

        self.present(controller, animated: true, completion: nil)
    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        
//        return CGSize(width: self.view.bounds.width, height: 50)
//    }
    
//  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        
//        let reuseView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "searchReuseIdentifier", for: indexPath)
//        if kind == UICollectionElementKindSectionHeader {
//            
//            
//        }
//        
//        return reuseView
//    }
}

// MARK: - UICollectionViewDataSource
extension RootViewController : UICollectionViewDataSource{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier,
                                                      for: indexPath) as! PhotoCell
        
        // cell
        if let imageUrl = self.items[indexPath.row].imageUrl {
            let data = try? Data(contentsOf: imageUrl)
            cell.imageView.image = UIImage(data: data!)
        }
        
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

// UISearchBarDelegate
extension RootViewController: UISearchBarDelegate {
    
    // called when text changes (including clear)
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText == "" {
            reloadData()
        } else {
            if let photos = PhotoManager.shared.query(by: searchText) {
                self.items = Array(photos)
            }
        }
    }
    
}

extension RootViewController: G8TesseractDelegate{
    
    public func progressImageRecognition(for tesseract: G8Tesseract!) {
        
    }

    public func shouldCancelImageRecognition(for tesseract: G8Tesseract!) -> Bool {
        return false
    }
    
    public func preprocessedImage(for tesseract: G8Tesseract!, sourceImage: UIImage!) -> UIImage! {
        return sourceImage
    }
}
