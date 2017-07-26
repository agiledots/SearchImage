//
//  RootViewController.swift
//  SearchImage
//

import Foundation
import UIKit
import AssetsPickerViewController
import Photos
import PhotosUI
import TesseractOCR
import Lightbox

class RootViewController: BaseViewController {

    // MARK: - Properties
    fileprivate let cellReuseIdentifier = "PhotoCell"
    fileprivate let headerReuseIdentifier = "PhotoHeader"
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 5.0, left: 1.0, bottom: 5.0, right: 1.0)
    
    fileprivate let itemsPerRow: CGFloat = 4

    var searchBar: UISearchBar!
    
    var collectionView: UICollectionView!
    
    fileprivate var items:[Photo] = [] {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    fileprivate var addBarButtonItem: UIBarButtonItem!
    fileprivate var orcButtonItem: UIBarButtonItem!
    fileprivate var deleteBarButtonItem: UIBarButtonItem!
    
    
    fileprivate let tesseract = G8Tesseract(language: "jpn+eng")
    
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
        searchBar.showsCancelButton = false
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
        self.addBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add
            , target: self, action: #selector(showActionSheet))
        
        self.deleteBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "delete"), style: .plain, target: self, action: #selector(deleteItems))
        
        self.orcButtonItem = UIBarButtonItem(barButtonSystemItem: .organize
            , target: self, action: #selector(orc))
        
        self.navigationItem.rightBarButtonItem = addBarButtonItem
        self.navigationItem.leftBarButtonItems = [self.orcButtonItem, self.editButtonItem]
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("viewWillAppear===> ")
        self.reloadData()
    }
    
    func orc() {
        
        if let data = PhotoManager.shared.queryNullMemo() {
            print("count: \(Array(data).count)")
            
            if data.count > 0 {
                self.present(self.loadingAlert, animated: false, completion: nil)
            }
            
            for (index, photo) in Array(data).enumerated() {
                print("photo: \(photo)")
                
                let imageData = try? Data(contentsOf: photo.imageUrl!)
                if let tesseract = G8Tesseract(language: "jpn+eng") {
                    
                    tesseract.image = UIImage(data: imageData!)
                    DispatchQueue(label: "backgroud").async {
                        tesseract.recognize()
                        
                        DispatchQueue.main.sync {
                            PhotoManager.shared.update(photo: photo, memo: (tesseract.recognizedText)!)

                            if index == data.count - 1 {
                                self.loadingAlert.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
        
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

        print("the newest data: \(self.items)")
        print("the count of data: \(self.items.count)")
    }
    
    func hiddenKeyBoard(recognizer: UITapGestureRecognizer) {
        self.searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        
        self.collectionView.allowsMultipleSelection = editing
        
        let indexPaths = self.collectionView.indexPathsForVisibleItems
        for path in indexPaths {
            self.collectionView.deselectItem(at: path, animated: false)
            if let cell = self.collectionView.cellForItem(at: path) as? PhotoCell {
                cell.editing = editing
            }
        }
        
        if editing {
            self.navigationItem.rightBarButtonItem = deleteBarButtonItem
        } else {
            self.navigationItem.rightBarButtonItem = addBarButtonItem
        }
    }
    
    func deleteItems() {
        if let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems {
            var newItems:[Photo] = []
            
            for (index, _) in self.items.enumerated() {
                var found:Bool = false
                for indexPath in selectedIndexPaths {
                    if index == indexPath.row {
                        found = true
                        break
                    }
                }
                
                if !found {
                    newItems.append(self.items[index])
                } else {
                    
                    let photo = self.items[index]
                    
                    if let url = photo.imageUrl {
                        try? FileManager.default.removeItem(at: url)
                    }
                    if let url = photo.thumbnailUrl {
                        try? FileManager.default.removeItem(at: url)
                    }
                    
                    PhotoManager.shared.delete(photo: photo)
                }
            }
            
            self.items = newItems
        }
    }
    
    func showActionSheet() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let fromLibraryAction = UIAlertAction(title: "ライブラリから選択", style: .default, handler: { action in
            self.addPhotos()
        })
        let takePictureAction = UIAlertAction(title: "画像を撮る", style: .default, handler: { action in
            self.accessCamera()
        })
        
        // iPad対応
        alert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        alert.popoverPresentationController?.permittedArrowDirections = .up
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        
        alert.addAction(takePictureAction)
        alert.addAction(fromLibraryAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true)
    }
    
    func accessCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let controller = UIImagePickerController()
            controller.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
            controller.sourceType = .camera
            self.present(controller, animated: true, completion: nil)
        }
    }
}

extension RootViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        
        guard let imagePath = getImageDirectory(), let thumbnailPath = getThumbnailDirectory() else {
            return
        }

        if !picker.isBeingDismissed {
            picker.dismiss(animated: true, completion: nil)
            //self.present(loadingAlert, animated: true, completion: nil)
        }
        
        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)

        let fetchOption = PHFetchOptions()
        fetchOption.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOption.fetchLimit = 1

        if let asset = PHAsset.fetchAssets(with: .image, options: fetchOption).firstObject {

            let filename = "\(Date().timeIntervalSince1970).jpg"
            let imageFile = imagePath.appendingPathComponent(filename)
            let thumbnailFile = thumbnailPath.appendingPathComponent(filename)
            
            saveImage(asset: asset, path: imageFile)
            saveThumbnail(asset: asset, path: thumbnailFile)
            
            // new model
            let photo = Photo()
            photo.filename = filename
            PhotoManager.shared.add(photo: photo)
            //self.reloadData()
            
            
//            DispatchQueue(label: "backgroud").async {
//                self.tesseract?.image = image
////                self.tesseract?.recognize()
//                DispatchQueue.main.sync {
//                    print("recognizedText: \(self.tesseract?.recognizedText)")
//                    PhotoManager.shared.update(photo: photo, memo: (self.tesseract?.recognizedText)!)
//                    self.loadingAlert.dismiss(animated: true, completion: nil)
//                }
//            }
            
            //self.loadingAlert.dismiss(animated: true, completion: nil)
            
        }
        


    }
    
}

extension RootViewController: UINavigationControllerDelegate {
    
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

                // new model
                let photo = Photo()
                photo.filename = filename
                PhotoManager.shared.add(photo: photo)
                self.reloadData()
                
            }
            
            self.loadingAlert.dismiss(animated: true, completion: nil)

        }
        
        if !controller.isBeingDismissed {
            controller.dismiss(animated: true, completion: nil)
            self.present(loadingAlert, animated: true, completion: nil)
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
        
        manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: nil, resultHandler: {(image, info)->Void in
            
            guard let _ = image else {
                return
            }
            
            if let data = UIImageJPEGRepresentation(image!, 1) {
                try? data.write(to: path)
                
            } else if let data = UIImagePNGRepresentation(image!) {
                try? data.write(to: path)
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
        if self.isEditing {
            return
        }
        
        self.searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false

        let photo = self.items[indexPath.row]
        let imageViewController = ImageViewController()
        imageViewController.photo = photo
        self.navigationController?.pushViewController(imageViewController, animated: true)
        
//        var images: [LightboxImage] = []
//        for item in self.items {
//            if let data = try? Data(contentsOf: item.imageUrl!) {
//                let image = LightboxImage(image: UIImage(data: data)!, text: item.memo, videoURL: nil)
//                images.append(image)
//            }
//        }
//
//        LightboxConfig.CloseButton.text = "閉じる";
//        LightboxConfig.loadImage = {
//                        imageView, URL, completion in
//                        imageView.contentMode = .scaleAspectFill
//                    }
//        
//        let controller = LightboxController(images: images, startIndex: indexPath.row)
//        controller.dynamicBackground = true
        
//        let photo = self.items[indexPath.row]
//        if let data = try? Data(contentsOf: photo.imageUrl!) {
//            let image = LightboxImage(image: UIImage(data: data)!, text: photo.memo, videoURL: nil)
//            images.append(image)
//        }
//        
//        let controller = LightboxController(images: images, startIndex: 0)
//
//        self.present(controller, animated: true, completion: nil)
    }
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
        cell.imageView.image = nil
        cell.editing = self.isEditing
        
        // cell
        if let imageUrl = self.items[indexPath.row].thumbnailUrl {
            
            if let data = try? Data(contentsOf: imageUrl) {
                cell.imageView.image = UIImage(data: data)
            }
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
    
    // called when text ends editing
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    }
    
    // called when text starts editing
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }

    // called when cancel button pressed
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }
    
}

extension RootViewController: G8TesseractDelegate{
    
    public func progressImageRecognition(for tesseract: G8Tesseract!) {
        print("---- progressImageRecognition ")
    }

    public func shouldCancelImageRecognition(for tesseract: G8Tesseract!) -> Bool {
        print("---- shouldCancelImageRecognition ")
        return false
    }
    
    public func preprocessedImage(for tesseract: G8Tesseract!, sourceImage: UIImage!) -> UIImage! {
        print("---- preprocessedImage ")
        return sourceImage
    }
}
