//
//  MBFacebookAlbumsViewController.swift
//  FacebookImagePicker
//
//  Copyright © 2017 Mikaelbo. All rights reserved.
//

import UIKit

class MBFacebookAlbumsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableView : UITableView!
    
    fileprivate let CellIdentifier = "FacebookAlbumCell"
    fileprivate let usecase = MBFacebookAlbumsUsecase(loadLimit: 100)
    fileprivate var albums = [MBFacebookAlbum]()
    
    fileprivate let loadingFooter = UIView()
    fileprivate let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    fileprivate lazy var emptyView : MBFacebookPickerEmptyView = {
        let emptyView = MBFacebookPickerEmptyView(frame: self.view.bounds)
        emptyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        emptyView.alpha = 0
        emptyView.titleLabel.text = NSLocalizedString("MBIMAGEPICKER_NO_ALBUMS_FOUND", comment: "")
        return emptyView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("MBIMAGEPICKER_ALBUMS", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("MBIMAGEPICKER_CANCEL", comment: ""),
                                                            style: .plain,
                                                            target: self, action: #selector(cancelButtonPressed))
        createTableView()
        
        loadingFooter.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 44)
        spinner.frame = CGRect(x: (loadingFooter.bounds.size.width - spinner.bounds.width) / 2,
                               y: (loadingFooter.frame.size.height - spinner.bounds.size.height) / 2,
                               width: spinner.bounds.width,
                               height: spinner.bounds.height)
        spinner.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        loadingFooter.addSubview(spinner)
        tableView.tableFooterView = loadingFooter
        view.backgroundColor = UIColor.white
        refreshAlbums()
        view.addSubview(emptyView)
    }
    
    func createTableView() {
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.delegate = self
        tableView.dataSource = self
        if #available(iOS 9, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.register(MBFacebookAlbumCell.classForCoder(), forCellReuseIdentifier: CellIdentifier)
        tableView.rowHeight = MBFacebookAlbumCell.wantedRowHeight
        
        view.addSubview(tableView)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (context) in
            
        }, completion: nil)
    }
    
    func cancelButtonPressed() {
        if let picker = self.navigationController as? MBFacebookImagePickerController {
            picker.finishedCompletion?(.cancelled)
        }
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath) as! MBFacebookAlbumCell
        if indexPath.row < albums.count {
            cell.configure(withAlbum: albums[indexPath.row])
        }
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row < albums.count {
            let album = albums[indexPath.row]
            let picturesController = MBFacebookPicturesViewController()
            picturesController.album = album
            navigationController?.pushViewController(picturesController, animated: true)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if shouldLoadMore() {
            loadMoreAlbums()
        }
    }
    
    //MARK: - Refresh & load more
    
    func refreshAlbums() {
        spinner.startAnimating()
        usecase.refreshAlbums { [weak self] (result) in
            self?.spinner.stopAnimating()
            switch result {
            case .success(let albums): self?.reload(withAlbums: albums)
            case .failure(let error): self?.showAlert(withError: error)
            }
        }
    }
    
    func loadMoreAlbums() {
        spinner.startAnimating()
        usecase.loadMoreAlbums({ [weak self] (result) in
            self?.spinner.stopAnimating()
            switch result {
            case .success(let albums): self?.insert(albums: albums)
            case .failure(let error): print(error)
            }
        })
    }
    
    func reload(withAlbums albums: [MBFacebookAlbum]) {
        self.albums = albums
        tableView.reloadData()
        tableView.tableFooterView = usecase.canLoadMoreAlbums ? loadingFooter : UIView(frame: CGRect.zero)
        showNoAlbumsViewIfNeeded()
    }
    
    func insert(albums: [MBFacebookAlbum]) {
        let oldCount = self.albums.count;
        
        if oldCount == 0 {
            reload(withAlbums: albums)
            return;
        }
        
        var paths = [IndexPath]()
        for i in 0 ..< albums.count {
            paths.append(IndexPath(row: self.albums.count + i, section: 0))
        }
        
        self.albums.append(contentsOf: albums)
        
        if self.albums.count == oldCount + albums.count {
            tableView.insertRows(at: paths, with: .fade)
        } else {
            tableView.reloadData()
        }
        
        tableView.tableFooterView = usecase.canLoadMoreAlbums ? loadingFooter : UIView(frame: CGRect.zero)
        showNoAlbumsViewIfNeeded()
    }
    
    //MARK: - Convenience
    
    func showAlert(withError error: MBFacebookImagePickerError) {
        var description = NSLocalizedString("MBIMAGEPICKER_UNKNOWN_ERROR", comment: "")
        if error == .noConnection {
            description = NSLocalizedString("MBIMAGEPICKER_NETWORK_ERROR", comment: "")
        }
        let title = NSLocalizedString("MBIMAGEPICKER_ERROR_ALERT_TITLE", comment: "")
        
        let alertController = UIAlertController(title: title, message: description, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("MBIMAGEPICKER_OK", comment: ""), style: .default, handler: { [weak self] (action) in
            if let imagePickerController = self?.navigationController as? MBFacebookImagePickerController {
                imagePickerController.finishedCompletion?(.failed(error))
            }
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    func shouldLoadMore() -> Bool {
        if !usecase.canLoadMoreAlbums || usecase.isLoading {
            return false
        }
        let visibleContentBottom = tableView.contentOffset.y + tableView.bounds.height;
        let lastPageTop = tableView.contentSize.height - 3 * tableView.bounds.height;
        return visibleContentBottom > lastPageTop;
    }
    
    //MARK: - Show & hide no albums view
    
    func showNoAlbumsViewIfNeeded() {
        self.albums.count > 0 ? hideNoAlbumsView() : showNoAlbumsView()
    }
    
    func showNoAlbumsView() {
        UIView.beginAnimations("fadeInEmptyView", context: nil)
        UIView.setAnimationDuration(0.5)
        emptyView.alpha = 1
        UIView.commitAnimations()
    }
    
    func hideNoAlbumsView() {
        UIView.beginAnimations("fadeOutEmptyView", context: nil)
        UIView.setAnimationDuration(0.5)
        emptyView.alpha = 0
        UIView.commitAnimations()
    }
}
