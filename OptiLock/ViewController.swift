//
//  ViewController.swift
//  OptiLock
//
//  Created by Sanjayan Sarmenthiran
//
//  Face-ID powered smart-lock controller
//  Sends secure local network commands to ESP32 lock hardware
//  Includes custom haptic + sound feedback, animated UI, and status indicator
//

import AudioToolbox
import UIKit
import LocalAuthentication

class ViewController: UIViewController {

    // MARK: - Config
    // ESP32 IP address — masked for public repo security
    // Replace YOUR_DEVICE_IP_HERE with your actual local network address when testing
    private let esp32IP = "YOUR_DEVICE_IP_HERE"

    // MARK: - UI Outlets
    @IBOutlet weak var unlockCard: UIView!
    @IBOutlet weak var lockCard: UIView!
    @IBOutlet weak var unlockui: UIImageView!
    @IBOutlet weak var unlocktext: UILabel!
    @IBOutlet weak var locktext: UILabel!
    @IBOutlet weak var lockui: UIImageView!
    @IBOutlet weak var auth1: UILabel!
    @IBOutlet weak var auth2: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    // MARK: - User Actions
    @objc func unlockImageTapped() {
        feedbackBounce(for: unlockui)
        authenticateFaceID(for: "unlock")
    }

    @objc func lockImageTapped() {
        feedbackBounce(for: lockui)
        authenticateFaceID(for: "lock")
    }

    // MARK: - Haptic + bounce feedback
    func feedbackBounce(for view: UIView) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        AudioServicesPlaySystemSound(1104)

        UIView.animate(withDuration: 0.12, animations: {
            view.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
        }) { _ in
            UIView.animate(withDuration: 0.12) {
                view.transform = .identity
            }
        }
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Enable tap gestures
        unlockui.isUserInteractionEnabled = true
        lockui.isUserInteractionEnabled = true
        unlockui.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(unlockImageTapped)))
        lockui.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(lockImageTapped)))

        // Fade in main UI
        [unlockui, lockui, unlocktext, locktext, auth1, auth2, statusLabel].forEach { $0?.alpha = 0 }
        UIView.animate(withDuration: 1.0) {
            [self.unlockui, self.lockui, self.unlocktext, self.locktext, self.auth1, self.auth2, self.statusLabel].forEach { $0?.alpha = 1 }
        }

        // Card visual styling
        [unlockui, lockui].forEach { ui in
            ui?.superview?.layer.cornerRadius = 20
            ui?.superview?.layer.shadowColor = UIColor.black.cgColor
            ui?.superview?.layer.shadowOpacity = 0.15
            ui?.superview?.layer.shadowRadius = 8
            ui?.superview?.layer.shadowOffset = CGSize(width: 0, height: 4)
            ui?.superview?.clipsToBounds = false
        }

        statusLabel.text = "Status: Locked"
    }

    // MARK: - Face ID Handler
    private func authenticateFaceID(for action: String) {
        let context = LAContext()
        context.localizedFallbackTitle = ""
        context.interactionNotAllowed = false
        context.invalidate()

        let newContext = LAContext()
        newContext.localizedFallbackTitle = ""

        newContext.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Authenticate to \(action) the lock"
        ) { success, _ in
            DispatchQueue.main.async {
                if success {
                    print("✅ Face ID success: \(action)")
                    self.sendESP32Command(for: action)

                    if action == "unlock" {
                        self.unlocktext.textColor = .systemGreen
                        self.updateStatus("Status: Unlocked")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.unlocktext.textColor = .label
                        }
                    } else {
                        self.locktext.textColor = .systemRed
                        self.updateStatus("Status: Locked")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.locktext.textColor = .label
                        }
                    }
                } else {
                    print("❌ Face ID failed")
                    self.updateStatus("Auth Failed")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.updateStatus("Status: Locked")
                    }
                }
            }
        }
    }

    // MARK: - Networking: ESP32 Command
    private func sendESP32Command(for action: String) {
        let urlString = "http://\(esp32IP)/\(action)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { _, _, error in
            if let error = error {
                print("Network error:", error)
                return
            }
            print("✅ Command sent: \(action)")
        }.resume()
    }

    // MARK: - UI Status Text Transition
    func updateStatus(_ text: String) {
        UIView.transition(with: statusLabel, duration: 0.3, options: .transitionCrossDissolve) {
            self.statusLabel.text = text
        }
    }
}
