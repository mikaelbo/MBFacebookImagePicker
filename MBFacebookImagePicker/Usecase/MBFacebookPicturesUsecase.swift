//
//  MBFacebookPicturesUsecase.swift
//  FacebookImagePicker
//
//  Copyright © 2017 Mikaelbo. All rights reserved.
//

import UIKit
import FBSDKCoreKit

enum MBFacebookPictureResult {
    case success([MBFacebookPicture])
    case failure(MBFacebookImagePickerError)
}

class MBFacebookPicturesUsecase: NSObject {
    
    let loadLimit : Int
    let album : MBFacebookAlbum
    
    var canLoadMorePictures : Bool {
        return self.nextRequestString != nil
    }
    
    fileprivate(set) var isLoading = false
    fileprivate var nextRequestString : String?
    
    init(album: MBFacebookAlbum, loadLimit: Int){
        self.album = album
        self.loadLimit = loadLimit
        super.init()
    }

    func refreshPictures(_ completion:@escaping (_ result: MBFacebookPictureResult) -> ()) {
        if FBSDKAccessToken.current() == nil {
            completion(.failure(.noFacebookAccessToken))
            return
        }
        
        let graphPath = "\(album.albumId)/photos?fields=picture,source,images,id&limit=\(loadLimit)"
        let request = FBSDKGraphRequest(graphPath: graphPath, parameters: nil)
        isLoading = true
        _ = request?.start(completionHandler: { [weak self] (connection, result, error) in
            DispatchQueue.main.async {
                if let actualSelf = self {
                    actualSelf.isLoading = false
                    actualSelf.handleFacebookPictureResponse(withResult: result, error: error, completion: completion)
                }
            }
        })
    }
    
    func loadMorePictures(_ completion:@escaping (_ result: MBFacebookPictureResult) -> ()) {
        guard let nextRequestString = nextRequestString, FBSDKAccessToken.current() != nil else {
            let error : MBFacebookImagePickerError = FBSDKAccessToken.current() == nil ? .noFacebookAccessToken : .unknown
            completion(.failure(error))
            return
        }
        
        let graphPath = "\(album.albumId)/photos?fields=picture,source,images,id&limit=\(loadLimit)&after=\(nextRequestString)"
        let request = FBSDKGraphRequest(graphPath: graphPath, parameters: nil)
        isLoading = true
        _ = request?.start(completionHandler: { [weak self] (connection, result, error) in
            DispatchQueue.main.async {
                if let actualSelf = self {
                    actualSelf.isLoading = false
                    actualSelf.handleFacebookPictureResponse(withResult: result, error: error, completion: completion)
                }
            }
        })
    }
    
    fileprivate func handleFacebookPictureResponse(withResult result: Any?, error: Error?,completion: (_ result: MBFacebookPictureResult) -> ()) {
        guard let result = result as? [String: Any], let data = result["data"] as? [[String: Any]], error == nil else {
            if let error = error {
                let err = error as NSError
                if err.code == NSURLErrorNotConnectedToInternet {
                    completion(.failure(.noConnection))
                } else {
                    completion(.failure(.unknown))
                }
            } else {
                completion(.failure(.invalidData))
            }
            return
        }
        
        var pictures = [MBFacebookPicture]()
        
        for pictureDict in data {
            if let picture = picture(forDictionary: pictureDict) {
                pictures.append(picture)
            }
        }
        
        var nextRequestString : String? = nil
        if let paging = result["paging"] as? [String: Any] {
            nextRequestString = self.nextRequestString(forDictionary: paging)
        }
        self.nextRequestString = nextRequestString
        
        completion(.success(pictures))
    }
    
    fileprivate func picture(forDictionary dictionary: [String: Any]) -> MBFacebookPicture? {
        if let images = dictionary["images"] as? [[String: Any]] {
            
            var sourceImages = [MBFacebookImageURL]()
            
            for imageDict in images {
                if let source = imageDict["source"] as? String,
                    let width = imageDict["width"] as? Int,
                    let height = imageDict["height"] as? Int,
                    let url = URL(string: source) {
                    sourceImages.append(MBFacebookImageURL(url: url, imageSize: CGSize(width: width, height: height)))
                }
            }
            
            if let thumbURLString = dictionary["picture"] as? String,
                let fullURLString = dictionary["source"] as? String,
                let thumbURL = URL(string: thumbURLString),
                let fullURL = URL(string: fullURLString) {
                let uid = dictionary["id"] as? String
                return MBFacebookPicture(thumbURL: thumbURL, fullURL: fullURL, albumId: album.albumId, uid: uid, sourceImages: sourceImages)
            }
        }
        return nil
    }
    
    fileprivate func nextRequestString(forDictionary dictionary: [String: Any]) -> String? {
        if let cursors = dictionary["cursors"] as? [String: Any],
            let after = cursors["after"] as? String,
            let _ = dictionary["next"] {
            return after
        }
        return nil
    }
}
