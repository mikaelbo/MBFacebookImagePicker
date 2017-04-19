//
//  MBFacebookPicture.swift
//  FacebookImagePicker
//
//  Copyright © 2017 Mikaelbo. All rights reserved.
//

import UIKit

class MBFacebookImageURL: NSObject {
    let url: URL
    let imageSize: CGSize

    init(url: URL, imageSize: CGSize) {
        self.url = url
        self.imageSize = imageSize
        super.init()
    }
}

class MBFacebookPicture: NSObject {
    let thumbURL: URL
    let fullURL: URL
    let albumId: String
    let uid: String?
    let sourceImages: [MBFacebookImageURL]

    init(thumbURL: URL, fullURL: URL, albumId: String, uid: String?, sourceImages: [MBFacebookImageURL]) {
        self.thumbURL = thumbURL
        self.fullURL = fullURL
        self.albumId = albumId
        self.uid = uid
        self.sourceImages = sourceImages
        super.init()
    }

    func bestURLForSize(size: CGSize) -> URL {
        guard var bestImageURL = sourceImages.first else {
            return self.thumbURL
        }

        for imageURL in sourceImages {
            let currentFoundSize = bestImageURL.imageSize
            let sizeIsAcceptable = imageURL.imageSize.width >= size.width && imageURL.imageSize.height >= size.height
            let imageTotal = imageURL.imageSize.width * imageURL.imageSize.height
            let currentImageTotal = currentFoundSize.width * currentFoundSize.height
            if sizeIsAcceptable && imageTotal < currentImageTotal {
                bestImageURL = imageURL
            }
        }

        return bestImageURL.url
    }
}
