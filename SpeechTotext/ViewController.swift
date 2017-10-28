//
//  ViewController.swift
//  SpeechTotext
//
//  Created by Zachary King on 10/27/17.
//  Copyright © 2017 Zachary King. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
//Hello
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    
    @IBAction func microphoneTapped(_ sender: Any) {
    }
    
}


