//
//  PlaceModel.swift
//  MyPlaces
//
//  Created by Stanislav Teslenko on 14.11.2019.
//  Copyright © 2019 Stanislav Teslenko. All rights reserved.
//

import UIKit
import RealmSwift

class Place: Object {
    
    @objc dynamic var name = ""
    @objc dynamic var location: String?
    @objc dynamic var type: String?
    @objc dynamic var imageData: Data?
    @objc dynamic var date = Date()
     
    
    convenience init (name: String, location: String?, type: String?, imageData: Data?) {
        
        self.init()
        
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
        
    }
}