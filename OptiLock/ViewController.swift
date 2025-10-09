//
//  ViewController.swift
//  OptiLock
//
//  Created by Sanjayan Sarmenthiran on 2025-09-28.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {

    // MARK: - Outlets

    
    @IBOutlet weak var unlockui: UIImageView!
    @IBOutlet weak var unlocktext: UILabel!
    @IBOutlet weak var locktext: UILabel!
    @IBOutlet weak var lockui: UIImageView!
    @IBOutlet weak var auth1: UILabel!
    @IBOutlet weak var auth2: UILabel!
    
    @objc func unlockImageTapped() {
        animatePress(for: unlockui)
        authenticateFaceID(for: "unlock")
    }

    @objc func lockImageTapped() {
        animatePress(for: lockui)
        authenticateFaceID(for: "lock")
    }
    
    func animatePress(for imageView: UIImageView) {
        UIView.animate(withDuration: 0.1,
                       animations: {
                           imageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                       }, completion: { _ in
                           UIView.animate(withDuration: 0.1) {
                               imageView.transform = .identity
                           }
                       })
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Enable interaction
        unlockui.isUserInteractionEnabled = true
        lockui.isUserInteractionEnabled = true

        // Add tap gesture
        let unlockTap = UITapGestureRecognizer(target: self, action: #selector(unlockImageTapped))
        unlockui.addGestureRecognizer(unlockTap)

        let lockTap = UITapGestureRecognizer(target: self, action: #selector(lockImageTapped))
        lockui.addGestureRecognizer(lockTap)

        unlockui.alpha = 0.0
        lockui.alpha = 0.0
        unlocktext.alpha = 0.0
        locktext.alpha = 0.0
        auth1.alpha = 0.0
        auth2.alpha = 0.0
        
        UIView.animate(withDuration: 1.0) {
            self.unlockui.alpha = 1.0
            self.lockui.alpha = 1.0
            self.unlocktext.alpha = 1.0
            self.locktext.alpha = 1.0
            self.auth1.alpha = 1.0
            self.auth2.alpha = 1.0
        }
    }

    // MARK: - Actions
    private func authenticateFaceID(for action: String) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to \(action) the lock"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        print("✅ Face ID successful for \(action)")
                        // TODO: send unlock/lock signal to ESP32 here
                    } else {
                        print("❌ Authentication failed for \(action)")
                    }
                }
            }
        } else {
            print("⚠️ Face ID not available")
        }
    }
}
