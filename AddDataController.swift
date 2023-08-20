//
//  AddDataController.swift
//  MyCNNApp
//
//  Created by 吉田成秀 on 2023/08/13.
//

import Foundation
import UIKit


protocol AddDataControllerDelegate: AnyObject {
    func addDataControllerDidDismiss(_ controller: AddDataController)
}

class AddDataController: UIViewController, UITextFieldDelegate {
    var dataArray: [String] = []
    weak var delegate: AddDataControllerDelegate?
    
    @IBOutlet weak var inputText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
        inputText.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // キーボードを閉じる
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        if let input = inputText.text, !input.isEmpty {
            saveData()
        }
        
        // モーダルを閉じるアクション
        self.dismiss(animated: true) { [weak self] in
            // Delegate メソッドを呼び出して通知を行う
            self?.delegate?.addDataControllerDidDismiss(self!)
        }
    }
    
    func saveData() {
        dataArray.append(String(inputText.text!))
        UserDefaults.standard.set(dataArray, forKey: "dataArrayKey")
        loadData()
    }
    
    func loadData() {
        if let savedData = UserDefaults.standard.array(forKey: "dataArrayKey") as? [String] {
            dataArray = savedData
            print(savedData)
        }
    }
}
