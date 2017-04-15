//
//  MBFacebookPicturesViewController.swift
//  FacebookImagePicker
//
//  Copyright © 2017 Mikaelbo. All rights reserved.
//

import UIKit

class MBFacebookPicturesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var album : MBFacebookAlbum?
    var collectionView : UICollectionView!
    
    fileprivate let CellIdentifier = "FacebookPictureCell"
    fileprivate let FooterIdentifier = "FacebookPicturesFooter"
    
    fileprivate var usecase : MBFacebookPicturesUsecase?
    fileprivate var pictures = [MBFacebookPicture]()
    
    fileprivate let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    fileprivate lazy var emptyView : MBFacebookPickerEmptyView = {
        let emptyView = MBFacebookPickerEmptyView(frame: self.view.bounds)
        emptyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        emptyView.alpha = 0
        emptyView.titleLabel.text = NSLocalizedString("MBIMAGEPICKER_NO_PICTURES_FOUND", comment: "")
        return emptyView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if let album = album {
            usecase = MBFacebookPicturesUsecase(album: album, loadLimit: 100)
            title = album.name
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("MBIMAGEPICKER_CANCEL", comment: ""),
                                                            style: .plain,
                                                            target: self, action: #selector(cancelButtonPressed))
        createCollectionView()
        refreshPictures()
        view.backgroundColor = UIColor.white
        view.addSubview(emptyView)
    }
    
    fileprivate func createCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.footerReferenceSize = CGSize(width: 0, height: 44);
        configureFlowLayout(layout)
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MBFacebookPictureCell.classForCoder(), forCellWithReuseIdentifier: CellIdentifier)
        collectionView.backgroundColor = UIColor.white
        collectionView.alwaysBounceVertical = true
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.register(UICollectionReusableView.classForCoder(),
                                forSupplementaryViewOfKind: UICollectionElementKindSectionFooter,
                                withReuseIdentifier: FooterIdentifier)
        view.addSubview(collectionView)
    }
    
    func configureFlowLayout(_ layout: UICollectionViewFlowLayout) {
        let spacing : CGFloat = 2
        let inset : CGFloat = 2
        let viewWidth = view.bounds.size.width
        
        var picturesPerRow : CGFloat = 3
        
        if viewWidth > 480 {
            picturesPerRow = 5
        } else if viewWidth >= 480 {
            picturesPerRow = 4
        }
        
        let padding = picturesPerRow - 1
        let size = (viewWidth - CGFloat(padding * spacing + padding * inset)) / picturesPerRow;
        
        layout.itemSize = CGSize(width: size, height: size)
        layout.sectionInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (context) in
            self.configureFlowLayout(self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout)
        }, completion: nil)
    }
    
    func cancelButtonPressed() {
        if let picker = self.navigationController as? MBFacebookImagePickerController {
            picker.finishedCompletion?(.cancelled)
        }
    }
    
    //MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pictures.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as! MBFacebookPictureCell
        if indexPath.item < pictures.count {
            let picture = pictures[indexPath.row]
            cell.imageView.imageURL = picture.bestURLForSize(size: cell.imageView.bounds.size)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                                         at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionFooter {
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FooterIdentifier, for: indexPath)
            if !spinner.isDescendant(of: footerView) {
                footerView.addSubview(spinner)
                let frame = footerView.frame
                spinner.frame = CGRect(x: (frame.size.width - spinner.bounds.size.width) / 2,
                                       y: (frame.size.height - spinner.bounds.size.height) / 2,
                                       width: spinner.bounds.size.width,
                                       height: spinner.bounds.size.width)
                spinner.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
            }
            return footerView
        }
        return UICollectionReusableView()
    }
    
    //MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if let cell = collectionView.cellForItem(at: indexPath) as? MBFacebookPictureCell {
            downloadFullImage(forCell: cell, at: indexPath)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if shouldLoadMore() {
            loadMorePictures()
        }
    }
    
    //MARK: - Refresh & load more pictures
    
    func refreshPictures() {
        guard let usecase = usecase else { return }
        spinner.startAnimating()
        usecase.refreshPictures({ [weak self] (result) in
            self?.spinner.stopAnimating()
            switch result {
            case .success(let pictures): self?.insert(pictures: pictures)
            case .failure(let error): self?.showAlert(withError: error, shouldDismiss: true)
            }
        })
    }
    
    func loadMorePictures() {
        guard let usecase = usecase else { return }
        spinner.startAnimating()
        usecase.loadMorePictures({ [weak self] (result) in
            self?.spinner.stopAnimating()
            switch result {
            case .success(let pictures): self?.insert(pictures: pictures)
            case .failure(let error): print(error)
            }
        })
    }
    
    func insert(pictures: [MBFacebookPicture]) {
        let oldCount = self.pictures.count;
        
        self.pictures.append(contentsOf: pictures)
        
        var paths = [IndexPath]()
        for i in oldCount ..< self.pictures.count {
            paths.append(IndexPath(item: i, section: 0))
        }

        collectionView.insertItems(at: paths)
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout, let usecase = usecase {
            layout.footerReferenceSize = CGSize(width: 0, height: usecase.canLoadMorePictures ? 44 : 0)
        }
        
        showNoPicturesViewIfNeeded()
    }
    
    //MARK: - Download Image
    
    func downloadFullImage(forCell cell: MBFacebookPictureCell, at indexPath: IndexPath) {
        guard let imagePickerController = navigationController as? MBFacebookImagePickerController,
            let indexPath = collectionView.indexPath(for: cell),
            indexPath.row < pictures.count else {
            return
        }
        
        let picture = pictures[indexPath.row]
        
        imagePickerController.view.isUserInteractionEnabled = false
        
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityView.center = cell.contentView.center
        activityView.color = UIColor.white
        activityView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        
        let overlayView = UIView(frame: cell.contentView.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        cell.contentView.addSubview(overlayView)
        cell.contentView.addSubview(activityView)
        
        activityView.startAnimating()
        
        downloadFullImage(forUrl: picture.fullURL) { [weak self, weak overlayView, weak activityView, weak imagePickerController] (image, error) in
            overlayView?.removeFromSuperview()
            activityView?.removeFromSuperview()
            imagePickerController?.view.isUserInteractionEnabled = true
            if let image = image {
                imagePickerController?.finishedCompletion?(.completed(image))
            } else {
                self?.showAlert(withError: error)
            }
        }
    }
    
    func downloadFullImage(forUrl url: URL, completion:@escaping (_ image: UIImage?, _ error: NSError?) -> ()) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 40
        URLSession(configuration: config).dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let imageData = data, let image = UIImage(data: imageData) {
                    completion(image, nil)
                } else if let error = error {
                    completion(nil, error as NSError)
                } else {
                    completion(nil, nil)
                }
            }
        }.resume()
    }
    
    //MARK: - Convenience
    
    func showAlert(withError error: Error?, shouldDismiss: Bool = false) {
        var descriptionString : String? = nil
        
        if let error = error as? MBFacebookImagePickerError, error == .noConnection {
            descriptionString = NSLocalizedString("MBIMAGEPICKER_NETWORK_ERROR", comment: "")
        } else if let error = error {
            let err = error as NSError
            if err.code == NSURLErrorNotConnectedToInternet {
                descriptionString = NSLocalizedString("MBIMAGEPICKER_NETWORK_ERROR", comment: "")
            }
        }
        if descriptionString == nil {
            descriptionString = NSLocalizedString("MBIMAGEPICKER_UNKNOWN_ERROR", comment: "")
        }
        
        let title = NSLocalizedString("MBIMAGEPICKER_ERROR_ALERT_TITLE", comment: "")
        
        let alertController = UIAlertController(title: title, message: descriptionString, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("MBIMAGEPICKER_OK", comment: ""), style: .default, handler: { [weak self] (action) in
            if shouldDismiss {
                self?.navigationController?.popViewController(animated: true)
            }
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    func shouldLoadMore() -> Bool {
        guard let usecase = usecase else { return false }
        if !usecase.canLoadMorePictures || usecase.isLoading {
            return false
        }
        let visibleContentBottom = collectionView.contentOffset.y + collectionView.bounds.height;
        let lastPageTop = collectionView.contentSize.height - 3 * collectionView.bounds.height;
        return visibleContentBottom > lastPageTop;
    }
    
    //MARK: - Show & hide no pictures view
    
    func showNoPicturesViewIfNeeded() {
        self.pictures.count > 0 ? hideNoPicturesView() : showNoPicturesView()
    }
    
    func showNoPicturesView() {
        UIView.beginAnimations("fadeInEmptyView", context: nil)
        UIView.setAnimationDuration(0.5)
        emptyView.alpha = 1
        UIView.commitAnimations()
    }
    
    func hideNoPicturesView() {
        UIView.beginAnimations("fadeOutEmptyView", context: nil)
        UIView.setAnimationDuration(0.5)
        emptyView.alpha = 0
        UIView.commitAnimations()
    }
}
