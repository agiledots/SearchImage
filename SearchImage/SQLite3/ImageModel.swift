//
//  test.swift
//  SearchImage
//
//

// https://github.com/stephencelis/SQLite.swift

import Foundation
import SQLite


extension Connection {

    func tableExists(tableName: String) -> Bool {
        if let count = try? scalar(
            "SELECT EXISTS (SELECT * FROM sqlite_master WHERE type = 'table' AND name = ?)",
            tableName
            ) as! Int64 {
            return count > 0
        }
        return false
    }
}


class ImageModel {
    
    static let shared = ImageModel()
    
    fileprivate let DB_NAME = "db.sqlite3"
    fileprivate var db: Connection!
    
    let images = Table("images")

    let id = Expression<Int64>("id")
    let filename = Expression<String>("filename")
    let memo = Expression<String?>("memo")
    let date = Expression<String>("date")
    
    init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        let dbfile = documentsDirectory.appendingPathComponent(DB_NAME).path
        do {
            db = try Connection(dbfile)
        } catch {
            print("error")
        }
    }
    
    func createTable() {
        if !db.tableExists(tableName: "images") {
            do {
                try db.run(images.create { t in
                    t.column(id, primaryKey: true)
                    t.column(filename, unique: true)
                    t.column(memo)
                    t.column(date)
                })
            } catch {
                print(error)
            }
        }
    }
    
    func selectAll() -> [Row]? {
        var result:[Row] = []
        
        do {
            for image in try db.prepare(images) {
                result.append(image)
            }
            return result
        } catch {
            print(error)
            return nil
        }
    }
    
    func insert(data:[String : String])  {
        do {
            let insert = images.insert(filename <- data["filename"]!, memo <- data["memo"]!, date <- data["date"]!)
            try db.run(insert)
        } catch {
            print(error)
        }
    }
    
    func update(data:[String : String]) {
        do {
            let value = images.filter(id == data["id"] as! Int64)
            
            try db.run(value.update(memo <- memo.replace("", with: data["memo"]!)  ))
        } catch {
            print(error)
        }
    }
    
    func delete(rowid: Int64) {
        do {
            let value = images.filter(id == rowid)
            try db.run(value.delete())
        } catch {
            print(error)
        }
    }
}

