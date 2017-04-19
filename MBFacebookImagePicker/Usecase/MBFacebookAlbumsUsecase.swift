//
//  MBFacebookAlbumsUsecase.swift
//  FacebookImagePicker
//
//  Copyright © 2017 Mikaelbo. All rights reserved.
//

import UIKit
import FBSDKCoreKit

enum MBFacebookAlbumResult {
    case success([MBFacebookAlbum])
    case failure(MBFacebookImagePickerError)
}

class MBFacebookAlbumsUsecase: NSObject {

    let loadLimit: Int

    var canLoadMoreAlbums: Bool {
        return self.nextRequestString != nil
    }

    fileprivate(set) var isLoading = false
    fileprivate var nextRequestString: String?

    init(loadLimit: Int) {
        self.loadLimit = loadLimit
        super.init()
    }

    func refreshAlbums(_ completion:@escaping (_ result: MBFacebookAlbumResult) -> Void) {
        if FBSDKAccessToken.current() == nil {
            completion(.failure(.noFacebookAccessToken))
            return
        }

        let graphPath = "me/albums?limit=\(loadLimit)&fields=name,count,id"
        let request = FBSDKGraphRequest(graphPath: graphPath, parameters: nil)
        isLoading = true
        _ = request?.start(completionHandler: { [weak self] (_, result, error) in
            DispatchQueue.main.async {
                if let actualSelf = self {
                    actualSelf.isLoading = false
                    actualSelf.handleFacebookAlbumResponse(withResult: result, error: error, completion: completion)
                }
            }
        })
    }

    func loadMoreAlbums(_ completion:@escaping (_ result: MBFacebookAlbumResult) -> Void) {
        guard let nextRequestString = nextRequestString, FBSDKAccessToken.current() != nil else {
            let tokenIsNil = FBSDKAccessToken.current() == nil
            let error: MBFacebookImagePickerError =  tokenIsNil ? .noFacebookAccessToken : .unknown
            completion(.failure(error))
            return
        }

        let graphPath = "me/albums?limit=\(loadLimit)&fields=name,count,id&after=\(nextRequestString)"
        let request = FBSDKGraphRequest(graphPath: graphPath, parameters: nil)
        isLoading = true
        _ = request?.start(completionHandler: { [weak self] (_, result, error) in
            DispatchQueue.main.async {
                if let actualSelf = self {
                    actualSelf.isLoading = false
                    actualSelf.handleFacebookAlbumResponse(withResult: result, error: error, completion: completion)
                }
            }
        })
    }

    fileprivate func handleFacebookAlbumResponse(withResult result: Any?,
                                                 error: Error?,
                                                 completion: (_ result: MBFacebookAlbumResult) -> Void) {
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

        var albums = [MBFacebookAlbum]()

        for albumDict in data {
            if let album = album(forDictionary: albumDict) {
                albums.append(album)
            }
        }

        var nextRequestString: String? = nil
        if let paging = result["paging"] as? [String: Any] {
            nextRequestString = self.nextRequestString(forDictionary: paging)
        }
        self.nextRequestString = nextRequestString

        completion(.success(albums))
    }

    fileprivate func album(forDictionary dictionary: [String: Any]) -> MBFacebookAlbum? {
        if let name = dictionary["name"] as? String,
            let photoCount = dictionary["count"] as? Int,
            let albumId = dictionary["id"] as? String,
            let token = FBSDKAccessToken.current().tokenString,
            let cover = URL(string: "https://graph.facebook.com/\(albumId)/picture?type=album&access_token=\(token)") {
            return MBFacebookAlbum(name: name, albumId: albumId, coverPhotoURL: cover, photoCount: photoCount)
        }
        return nil
    }

    fileprivate func nextRequestString(forDictionary dictionary: [String: Any]) -> String? {
        if let cursors = dictionary["cursors"] as? [String: Any],
            let after = cursors["after"] as? String,
            dictionary["next"] != nil {
            return after
        }
        return nil
    }
}
