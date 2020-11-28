//
//  ViewController.swift
//  MeMe
//
//  Created by Leela Krishna Chaitanya Koravi on 11/24/20.
//  Copyright © 2020 Leela Krishna Chaitanya Koravi. All rights reserved.
//

import UIKit

struct Meme {
    var topText1:String
    var bottomText1:String
    var originalImage = UIImage()
    var memedImage = UIImage()
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
    UITextFieldDelegate {

    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var topText: UITextField!
    @IBOutlet weak var bottomText: UITextField!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var bottomToolbar: UIToolbar!
    
    var uiBarButtonItem_Share: UIBarButtonItem!
    var uiBarButtonItem_Cancel: UIBarButtonItem!
    
    let memeTextAttributes: [NSAttributedString.Key: Any] =
    [
        NSAttributedString.Key.strokeColor: UIColor.black,
        NSAttributedString.Key.foregroundColor: UIColor.white,
        NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 20)!,
        NSAttributedString.Key.strokeWidth: 2.0
        //NSAttributedString.Key.backgroundColor: UIColor.white
    ]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //Add Share, Cancel button to UINavigationBar
        let navigationItem = UINavigationItem()
        uiBarButtonItem_Share = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.action, target: self, action: "shareMeme")
        uiBarButtonItem_Cancel = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action:"cancelMeme")
        navigationItem.leftBarButtonItem = uiBarButtonItem_Share
        navigationItem.rightBarButtonItem = uiBarButtonItem_Cancel
        navigationBar.setItems([navigationItem], animated: true)
        
        setLaunchStateConfiguration()
    }
    
    func setLaunchStateConfiguration(){
        imagePickerView.image = nil

        topText.text = "TOP"
        topText.delegate = self
        topText.defaultTextAttributes = memeTextAttributes
        topText.textAlignment = NSTextAlignment.center
        //topText.backgroundColor = UIColor(white: 1, alpha: 0.1)
        topText.isHidden = true
        
        bottomText.text = "BOTTOM"
        bottomText.delegate = self
        bottomText.defaultTextAttributes = memeTextAttributes
        bottomText.textAlignment = NSTextAlignment.center
        //bottomText.backgroundColor = UIColor(white: 1, alpha: 0.1)
        bottomText.isHidden = true
        
        //Disable share, cancel button as image is not set/selected yet.
        uiBarButtonItem_Share.isEnabled = false
        uiBarButtonItem_Cancel.isEnabled = false
    }
    
    func setMemeStateConfiguration(image: UIImage){
        imagePickerView.image = image
        
        //Enable share, cancel as image is set
        uiBarButtonItem_Share.isEnabled = true
        uiBarButtonItem_Cancel.isEnabled = true
        
        topText.isHidden = false
        bottomText.isHidden = false
        
        topText.text = "TOP"
        bottomText.text = "BOTTOM"
    }
    
    @objc func shareMeme(){
        //Share
        let image = generateMemedImage()
        let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        self.present(controller, animated: true, completion: nil)
        //Completion handler
        controller.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed:
            Bool, arrayReturnedItems: [Any]?, error: Error?) in
            if completed {
                print("share completed")
                self.save()
                self.setLaunchStateConfiguration()
                return
            } else {
                print("cancel")
            }
            if let shareError = error {
                print("error while sharing: \(shareError.localizedDescription)")
            }
        }
    }
    
    @objc func cancelMeme(){
        setLaunchStateConfiguration()
    }
    
    @IBAction func PickImageFromAlbum(_ sender: Any) {
        let controller = UIImagePickerController()
        controller.sourceType = .photoLibrary
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func PickImageFromCamera(_ sender: Any) {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = self
        present(controller, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            setMemeStateConfiguration(image: image)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("imagePickerControllerDidCancel")
        dismiss(animated: true, completion: nil)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if (textField.text == "TOP" || textField.text == "BOTTOM"){
            textField.text = ""
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
       textField.resignFirstResponder()
       return true
    }
    
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        //If bottom textfield is being edited.
        if(bottomText.isEditing){
            view.frame.origin.y -= getKeyboardHeight(notification)
        }
    }
    
    @objc func keyboardWillHide(_ notification:Notification){
        //If bottom textfield is being edited.
        if(bottomText.isEditing){
        view.frame.origin.y = 0
        }
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    func save() {
        // Create the meme
        let meme = Meme(topText1: topText.text!, bottomText1: bottomText.text!, originalImage: imagePickerView.image!, memedImage: generateMemedImage())
    }
    
    func generateMemedImage() -> UIImage {
        
        // TODO: Hide toolbar and navbar
        navigationBar.isHidden = true
        bottomToolbar.isHidden = true

        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // TODO: Show toolbar and navbar
        navigationBar.isHidden = false
        bottomToolbar.isHidden = false

        return memedImage
    }
    
}

