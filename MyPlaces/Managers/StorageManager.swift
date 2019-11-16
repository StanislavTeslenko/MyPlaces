//
//  StorageManager.swift
//  MyPlaces
//
//  Created by Stanislav Teslenko on 15.11.2019.
//  Copyright © 2019 Stanislav Teslenko. All rights reserved.
//

import RealmSwift

let realm = try! Realm()

class StorageManager {
    
    static func saveObject(_ place: Place) {
        
        try! realm.write {
            realm.add(place)
        }
    }
    
    static func deleteObject(_ place: Place) {
        
        try! realm.write {
            realm.delete(place)
        }     
    }
    
    
    
}
