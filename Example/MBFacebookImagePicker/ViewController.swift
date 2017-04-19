//
//  ViewController.swift
//  MBFacebookImagePicker
//
//  Copyright (c) 2017 mikaelbo. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import MBFacebookImagePicker

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var choosePhotoButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        choosePhotoButton.backgroundColor = UIColor.clear
        choosePhotoButton.layer.cornerRadius = 30
        choosePhotoButton.layer.masksToBounds = true
        let buttonColor = UIColor(red: 0.129995, green: 0.273324, blue: 0.549711, alpha: 1)
        choosePhotoButton.setBackgroundImage(resizableImage(withColor: buttonColor), for: .normal)
    }

    @IBAction func choosePhotoButtonPressed(_ sender: UIButton) {
        if FBSDKAccessToken.current() != nil {
            showImagePicker()
        } else {
            let login = FBSDKLoginManager()
            login.logIn(withReadPermissions: ["user_photos"], from: self, handler: { [weak self] (result, error) in
                if let error = error {
                    self?.showAlertFromFacebookError(error: error as NSError)
                } else if let result = result {
                    if result.isCancelled {
                        // Do nothing
                    } else if !result.declinedPermissions.isEmpty {
                        self?.showPermissionsAlert()
                    } else if result.token != nil {
                        self?.showImagePicker()
                    } else {
                        self?.showUnknownError()
                    }
                }
            })
        }
    }

    func showImagePicker() {
        let imagePicker = MBFacebookImagePickerController()
        imagePicker.finishedCompletion = { [weak self] (result) in
            self?.dismiss(animated: true, completion: nil)
            switch result {
            case .completed(let image): self?.imageView.image = image
            case .failed(let error): print("failed with error: \(error)")
            case .cancelled: print("Cancelled!")
            }
        }
        present(imagePicker, animated: true, completion: nil)
    }

    func showAlertFromFacebookError(error: NSError) {
        let title = error.userInfo[FBSDKErrorLocalizedTitleKey] as? String
        let description = error.userInfo[FBSDKErrorLocalizedDescriptionKey] as? String
        if title != nil || description != nil {
            showErrorAlert(withTitle: title, message: description)
        } else {
            showUnknownError()
        }
    }

    func showPermissionsAlert() {
        showErrorAlert(withTitle: "Facebook permissions",
                       message: "To be able to use this app, we need permission to access your Facebook photos")
    }

    func showUnknownError() {
        showErrorAlert(withTitle: nil, message: "Whoops, something went wrong.")
    }

    func showErrorAlert(withTitle title: String?, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    fileprivate func resizableImage(withColor color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        color.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let context = UIGraphicsGetImageFromCurrentImageContext()
        let image = context?.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: .stretch)
        UIGraphicsEndImageContext()
        return image
    }
}
