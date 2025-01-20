//
//  SecondViewController.swift
//  Swift-CoreBluetooth
//
//  Created by Suyeon Hwang on 1/21/25.
//

import UIKit

class SecondViewController: UIViewController {
    
    let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "알람을 누르면 이동하는 뷰컨트롤러"
        label.textColor = .black
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
