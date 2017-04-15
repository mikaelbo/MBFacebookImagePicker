//
//  MBFacebookPictureCell.swift
//  FacebookImagePicker
//
//  Copyright © 2017 Mikaelbo. All rights reserved.
//

import UIKit

class MBFacebookPictureCell: UICollectionViewCell {
    
    let imageView = MBAsyncImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }
    
    fileprivate func configureView() {
        imageView.frame = self.bounds
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.isUserInteractionEnabled = true
        self.contentView.addSubview(imageView)
    }
}
