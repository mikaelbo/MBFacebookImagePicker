//
//  MBFacebookImagePickerController.swift
//  FacebookImagePicker
//
//  Copyright © 2017 Mikaelbo. All rights reserved.
//

import UIKit

public enum MBFacebookImagePickerError : CustomNSError {
    case noFacebookAccessToken
    case unknown
    case invalidData
    case noConnection
    
    public static var errorDomain: String {
        return "MBFacebookImagePickerError"
    }
    
    public var errorCode: Int {
        switch self {
        case .noFacebookAccessToken: return 0
        case .unknown: return 1
        case .invalidData: return 2
        case .noConnection: return 3
        }
    }
    
}

public enum MBFacebookImagePickerResult {
    case completed(UIImage)
    case failed(Error)
    case cancelled
}

public class MBFacebookImagePickerController: UINavigationController {
    
    public var finishedCompletion : ((MBFacebookImagePickerResult) -> ())?
    
    public init() {
        super.init(navigationBarClass: nil, toolbarClass: nil)
        viewControllers = [MBFacebookAlbumsViewController()]
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        viewControllers = [MBFacebookAlbumsViewController()]
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
       super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.barTintColor = UIColor(red: 0.129995, green: 0.273324, blue: 0.549711, alpha: 1)
        navigationBar.tintColor = UIColor.white
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
