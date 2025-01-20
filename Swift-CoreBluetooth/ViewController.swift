//
//  ViewController.swift
//  Swift-CoreBluetooth
//
//  Created by Suyeon Hwang on 9/30/24.
//

import UIKit
import PinLayout
import CoreBluetooth

class ViewController: UIViewController {
    
    private let baseView: UIView = {
        var view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    private let topStackView: UIStackView = {
        var view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.distribution = .fillEqually
        view.alignment = .fill
        view.spacing = 8
        return view
    }()
        
    private let stateLabel1: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "블루투스 상태"
        return label
    }()
        
    private let stateLabel2: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = ":"
        return label
    }()
        
    private let buttonStackView: UIStackView = {
        var view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.alignment = .fill
        view.spacing = 14
        return view
    }()
        
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("central mode 시작", for: .normal)
        return button
    }()
        
    private let stopButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("advertise mode 시작", for: .normal)
        return button
    }()
        
    private let searchLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "검색된 블루투스 기기"
        return label
    }()

    private let bottomBaseView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()
        
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.showsVerticalScrollIndicator = false
        view.keyboardDismissMode = .onDrag
        return view
    }()
    
    private let bottomStackView: UIStackView = {
        var view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.distribution = .fillEqually
        view.alignment = .fill
        view.spacing = 8
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .white
        
        addViews()
        applyConstraints()
        addTarget()
        
        BluetoothSerial.shared.delegate = self
    }

    private func addViews() {
        view.addSubview(baseView)
        baseView.addSubview(topStackView)
        baseView.addSubview(bottomBaseView)
        bottomBaseView.addSubview(scrollView)
        scrollView.addSubview(bottomStackView)
        topStackView.addArrangedSubview(stateLabel1)
        topStackView.addArrangedSubview(stateLabel2)
        topStackView.addArrangedSubview(buttonStackView)
        topStackView.addArrangedSubview(searchLabel)
        buttonStackView.addArrangedSubview(startButton)
        buttonStackView.addArrangedSubview(stopButton)
    }
    
    private func applyConstraints() {
        let baseViewConstraints = [
            baseView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            baseView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            baseView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            baseView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        
        let topStackViewConstraints = [
            topStackView.leadingAnchor.constraint(equalTo: baseView.leadingAnchor, constant: 30),
            topStackView.trailingAnchor.constraint(equalTo: baseView.trailingAnchor, constant: -30),
            topStackView.topAnchor.constraint(equalTo: baseView.topAnchor, constant: 30),
        ]
        
        let bottomBaseViewConstraints = [
            bottomBaseView.leadingAnchor.constraint(equalTo: baseView.leadingAnchor, constant: 30),
            bottomBaseView.trailingAnchor.constraint(equalTo: baseView.trailingAnchor, constant: -30),
            bottomBaseView.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 30),
            bottomBaseView.bottomAnchor.constraint(equalTo: baseView.bottomAnchor, constant: -30),
        ]
        
        let scrollViewConstraints = [
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: bottomBaseView.leadingAnchor),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: bottomBaseView.trailingAnchor),
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: bottomBaseView.topAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: bottomBaseView.bottomAnchor)
        ]
        
        let bottomStackViewConstraints = [
            bottomStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            bottomStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            bottomStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            bottomStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            bottomStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ]
        
        NSLayoutConstraint.activate(baseViewConstraints)
        NSLayoutConstraint.activate(topStackViewConstraints)
        NSLayoutConstraint.activate(bottomBaseViewConstraints)
        NSLayoutConstraint.activate(scrollViewConstraints)
        NSLayoutConstraint.activate(bottomStackViewConstraints)

    }
    
    private func addTarget() {
        startButton.addTarget(self, action: #selector(startButtonDidTap(_:)), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(stopButtonDidTap(_:)), for: .touchUpInside)
    }

    @objc func startButtonDidTap(_ sender: UIButton) {
        print("검색 시작")
        
        BluetoothSerial.shared.setBluetoothMode(to: .scanningMode)
    }
    
    @objc func stopButtonDidTap(_ sender: UIButton) {
        print("검색 종료, advertising mode 시작")
        BluetoothSerial.shared.setBluetoothMode(to: .advertisingMode)
//        BluetoothSerial.shared.addServicesWithData("Pochak user")
//        BluetoothSerial.shared.stopScan()
//        centralManager.stopScan()
    }
    
    private func addPeripheral(serial: String) {
        print("add peripheral")
        lazy var serialLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = serial
            return label
        }()
        
        bottomStackView.addArrangedSubview(serialLabel)
    }
}

// MARK: - Extension

extension ViewController: BluetoothSerialDelegate {
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?) {
        print("=== serial did discover peripheral ===")
//        let check: Bool = false
//        if !check {
//            peripheralList.append(peripheral)
            print("adding...")
            addPeripheral(serial: peripheral.name ?? peripheral.identifier.uuidString)
//        }
        LocalPushNotificationManager.shared.pushNotification(title: "👀 내 주변에 포차커가 있어요!",
                                                             body: "지금 눌러서 확인하기",
                                                             identifier: "POCHAK_NEARBY")
        print("=======================================")
        BluetoothSerial.shared.centralManager.stopScan()
    }
    
    func serialDidReceiveMessage(message: String) {
        print("received message!")
        let alert = UIAlertController(title: "블루투스 통신", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}
