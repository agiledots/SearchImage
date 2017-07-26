//
//  PhotoModel.swift
//  SearchImage
//
//  Created by LU XIAOQUAN on 2017/07/12.
//  Copyright © 2017年 PM001192. All rights reserved.
//

import Foundation
import RealmSwift

class Photo: Object {
    
    dynamic var id = 0
    dynamic var filename = ""
    dynamic var memo = ""
    dynamic var createDate = Date()

    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["imageUrl"]
    }
    
    var imageUrl: URL? {
        get {
            if let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
                let imagePath = NSURL(fileURLWithPath: path).appendingPathComponent("IMAGES")
                return imagePath?.appendingPathComponent(self.filename)
            } else {
                return nil
            }
        }
    }
    
    var thumbnailUrl: URL? {
        if let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            let imagePath = NSURL(fileURLWithPath: path).appendingPathComponent("Thumbnail")
            return imagePath?.appendingPathComponent(self.filename)
        } else {
            return nil
        }
    }
    
}


class PhotoManager {
    
    static let shared = PhotoManager()
    
    let realm: Realm

    private init() {
        self.realm = try! Realm()
    }
    
    func add(photo: Photo) {
        do {
            if let max = realm.objects(Photo.self).max(ofProperty: "id") as Int? {
                photo.id = max + 1
            } else {
                photo.id = 1
            }
            
            realm.beginWrite()
            realm.add(photo)
            try realm.commitWrite()
        } catch {
            
        }
    }
    
    func update(photo: Photo, memo: String){
        do {
            print("update photo: \(memo)")
            realm.beginWrite()
            photo.memo = memo
            realm.add(photo, update: true)
            try realm.commitWrite()
        } catch {
            print("update photo error : \(error)")
        }
    }
    
    func delete(photo: Photo){
        
        do {
            realm.beginWrite()
            realm.delete(photo)
            try realm.commitWrite()
        } catch {
            print("delete photo error : \(error)")
        }
    }
    
    func queryAll() -> Results<Photo>? {
        var photos: Results<Photo>?
        
        do {
            photos = realm.objects(Photo.self).sorted(byKeyPath: "createDate", ascending: false)
        } catch {
            print("query all photo error : \(error)")
        }
        
        return photos
    }
    
    func query(by memo: String) -> Results<Photo>? {
        var photos: Results<Photo>?
        
        do {
            photos = realm.objects(Photo.self).filter("memo contains '\(memo)'").sorted(byKeyPath: "createDate", ascending: false)
        } catch {
            print("query photo by memo error : \(error)")
        }
        
        return photos
    }
    
    func queryNullMemo() -> Results<Photo>? {
        var photos: Results<Photo>?
        
        do {
            photos = realm.objects(Photo.self).filter("memo = '' ").sorted(byKeyPath: "createDate", ascending: false)
        } catch {
            print("query photo by memo error : \(error)")
        }
        
        return photos
    }

    
}

