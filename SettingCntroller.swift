//
//  SettingCntroller.swift
//  MyCNNApp
//
//  Created by 吉田成秀 on 2023/08/16.
//

import Foundation
import UIKit

class SettingCntroller: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var lastmessage: UITextView!
    @IBOutlet weak var epochtxt: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let savedData = UserDefaults.standard.object(forKey: "lastmessage") {
            print(savedData)
            lastmessage.text = "\(savedData)"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func epochbutton(_ sender: Any) {
        UserDefaults.standard.set(epochtxt.text, forKey: "epoch")
        lastmessage.endEditing(true)
    }
    
    @IBAction func alldeletebutton(_ sender: Any) {
        let appDomain = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: appDomain!)
    }
    
    @IBAction func developerbutton(_ sender: Any) {
        
    }
    
    @IBAction func kiyaku(_ sender: Any) {
        
    }
}
