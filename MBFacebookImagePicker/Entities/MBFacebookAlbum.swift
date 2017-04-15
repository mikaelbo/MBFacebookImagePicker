//
//  MBFacebookAlbum.swift
//  FacebookImagePicker
//
//  Copyright © 2017 Mikaelbo. All rights reserved.
//

import UIKit

class MBFacebookAlbum: NSObject {
    
    let name : String
    let albumId : String
    let coverPhotoURL: URL
    let photoCount : Int
    
    init(name: String, albumId: String, coverPhotoURL: URL, photoCount: Int){
        self.name = name
        self.albumId = albumId
        self.coverPhotoURL = coverPhotoURL
        self.photoCount = photoCount
        super.init()
    }
    
    override var description: String {
        return "\(name) -> \(photoCount)"
    }
}
