//
//  MBAsyncImageView.swift
//  FacebookImagePicker
//
//  Copyright © 2017 Mikaelbo. All rights reserved.
//

import UIKit

fileprivate let imageCache = NSCache<AnyObject, AnyObject>()

class MBAsyncImageView: UIImageView {

    fileprivate lazy var placeholderImage: UIImage? = {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIColor.lightGray.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: UIEdgeInsets.zero,
                                                                                resizingMode: .stretch)
        UIGraphicsEndImageContext()
        return image
    }()

    var imageURL: URL? {
        didSet {
            guard let url = imageURL else {
                self.image = nil
                return
            }

            if let cachedImage = imageCache.object(forKey:url.absoluteString as AnyObject) as? UIImage {
                self.image = cachedImage
                return
            }

            self.image = self.placeholderImage

            URLSession.shared.dataTask(with: url as URL) { [weak self] data, _, error in
                guard let imageData = data, let actualSelf = self, error == nil else { return }
                DispatchQueue.main.async {
                    if let image = UIImage(data: imageData), actualSelf.imageURL == url {
                        actualSelf.layer.add(CATransition(), forKey: "fade")
                        actualSelf.image = image
                        imageCache.setObject(image, forKey: url.absoluteString as AnyObject)
                    }
                }
            }.resume()
        }
    }
}
