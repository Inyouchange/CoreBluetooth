//
//  InputValueViewController.swift
//  bluetooth1107
//
//  Created by Betty on 2018/11/7.
//  Copyright © 2018 Betty. All rights reserved.
//

import UIKit

class InputValueViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    
    var inputValueBlock:((_ sendStr:String)->Void)!
    
    @IBAction func sendAction(_ sender: Any) {
        if((inputValueBlock) != nil) {
            inputValueBlock(textField.text!)
        }
        
        
        dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
