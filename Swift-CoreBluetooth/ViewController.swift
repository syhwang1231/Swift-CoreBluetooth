//
//  ViewController.swift
//  Swift-CoreBluetooth
//
//  Created by Suyeon Hwang on 9/30/24.
//

import UIKit
import PinLayout

class ViewController: UIViewController {

    private let label: UILabel = {
        let label = UILabel()
        label.text = "첫 화면"
        label.textColor = .black
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .white
        
        view.addSubview(label)
        
        label.pin.left().right().vCenter()
        label.pin.top().bottom().hCenter()
    }


}

