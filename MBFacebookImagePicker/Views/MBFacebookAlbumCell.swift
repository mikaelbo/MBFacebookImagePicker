//
//  MBFacebookAlbumCell.swift
//  FacebookImagePicker
//
//  Copyright © 2017 Mikaelbo. All rights reserved.
//

import UIKit

class MBFacebookAlbumCell: UITableViewCell {
    
    class var wantedRowHeight : CGFloat {
        return 86
    }
    
    fileprivate let coverImageView = MBAsyncImageView()
    fileprivate let nameLabel = UILabel()
    fileprivate let countLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        coverImageView.frame = CGRect(x: 8, y: 8, width: 70, height: 70)
        nameLabel.frame = CGRect(x: 86, y: 24, width: frame.size.width - 86 - 20, height: 20)
        countLabel.frame = CGRect(x: 86, y: 44, width: frame.size.width - 86 - 20, height: 20)
    }
    
    func configure(withAlbum album: MBFacebookAlbum) {
        nameLabel.text = album.name
        countLabel.text = String(album.photoCount)
        coverImageView.imageURL = album.coverPhotoURL
    }
    
    fileprivate func configureView() {
        accessoryType = .disclosureIndicator
        separatorInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        configureImageView()
        configureNameLabel()
        configureCountLabel()
    }
    
    fileprivate func configureImageView() {
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        contentView.addSubview(coverImageView)
    }
    
    fileprivate func configureNameLabel() {
        nameLabel.font = UIFont.systemFont(ofSize: 17)
        nameLabel.textColor = UIColor.black
        contentView.addSubview(nameLabel)
    }
    
    fileprivate func configureCountLabel() {
        countLabel.font = UIFont.systemFont(ofSize: 12)
        countLabel.textColor = UIColor.black
        contentView.addSubview(countLabel)
    }
}
