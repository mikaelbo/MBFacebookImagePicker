//
//  MBFacebookPickerEmptyView.swift
//  FacebookImagePicker
//
//  Copyright © 2017 Mikaelbo. All rights reserved.
//

import UIKit

class MBFacebookPickerEmptyView: UIView {
    
    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureLabel()
    }
    
    fileprivate func configureLabel() {
        titleLabel.numberOfLines = 2
        let wantedSize = CGSize(width: 205, height: 40)
        titleLabel.textAlignment = .center
        titleLabel.frame = CGRect(x: (bounds.size.width - wantedSize.width) / 2,
                                  y: (bounds.size.height - wantedSize.height) / 2,
                                  width: wantedSize.width,
                                  height: wantedSize.height)
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = UIColor(red: 85 / 255, green: 85 / 255, blue: 85 / 255, alpha: 0.5)
        titleLabel.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        addSubview(titleLabel)
    }
}
