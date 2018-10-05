//
//  LandingViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/4/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import LocalAuthentication
import Crashlytics

class LandingViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var animationViewContainer: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var orSeperatorLabel: UILabel!
    @IBOutlet weak var createNewWalletButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginButtonLeading: NSLayoutConstraint!
    @IBOutlet weak var loginButtonTrailing: NSLayoutConstraint!

    var animationView = LOTAnimationView(name: "Landing")
    var currPosition = 0.0
    var maxPosition = 4.0
    var minPosition = 0.0
    var swipeDisabled = false
    var userSwiped = false

    var titles = [OnboardingStrings.landingTitleOne, OnboardingStrings.landingTitleTwo, OnboardingStrings.landingTitleThree, OnboardingStrings.landingTitleFour, OnboardingStrings.landingTitleFive]
    var subtitles = [OnboardingStrings.landingSubtitleOne, OnboardingStrings.landingSubtitleTwo, OnboardingStrings.landingSubtitleThree, OnboardingStrings.landingSubtitleFour, OnboardingStrings.landingSubtitleFive]

    override func viewDidLoad() {
        super.viewDidLoad()
        if UIScreen().scale <= CGFloat(2) {
            animationView.contentScaleFactor = 0.5
            collectionViewTopConstraint.constant = -36
            updateViewConstraints()
        } else {
            animationView.frame = animationViewContainer.frame
            animationView.center = animationViewContainer.center
        }

        if UIDevice.current.userInterfaceIdiom == .pad {
            loginButtonTrailing.constant = 128
            loginButtonLeading.constant = 128
            collectionViewTopConstraint.constant = -90
            updateViewConstraints()
        }

        animationView.contentMode = .scaleAspectFit
        animationViewContainer.embed(animationView)
        //animationViewContainer.addSubview(animationView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tappedPage(_:)))
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.swipedLeft(_:)))
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.swipedRight(_:)))
        swipeLeft.direction = .left
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeLeft)
        view.addGestureRecognizer(swipeRight)

        animationViewContainer.addGestureRecognizer(tap)
        view.isUserInteractionEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self

        setLocalizedStrings()

        timePaging()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        userSwiped = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
        super.viewWillDisappear(animated)

    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
        super.viewWillAppear(animated)
    }

    func timePaging() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.userSwiped || self.currPosition == self.maxPosition {
                return
            }
            self.swipedLeft(nil)
            self.timePaging()
        }
    }

    @objc func swipedLeft(_ sender: Any?) {
        if sender != nil {
            userSwiped = true
        }

        if currPosition == maxPosition || swipeDisabled {
            return
        }
        DispatchQueue.main.async {
            self.swipeDisabled = true
            self.pageControl.currentPage = Int(self.currPosition + 1)
            self.collectionView.scrollToItem(at: IndexPath(row: Int(self.currPosition) + 1, section: 0), at: .centeredHorizontally, animated: true)
            let keyFrame = NSNumber(value: (self.currPosition + 1) * 30.0)
            self.animationView.play(toFrame: keyFrame) { _ in
                self.currPosition += 1
                self.swipeDisabled = false
            }
        }
    }

    @objc func swipedRight(_ sender: Any?) {
        if sender != nil {
            userSwiped = true
        }

        if currPosition == minPosition || swipeDisabled {
            return
        }

        DispatchQueue.main.async {
            self.swipeDisabled = true
            self.pageControl.currentPage = Int(self.currPosition - 1)
            self.collectionView.scrollToItem(at: IndexPath(row: Int(self.currPosition) - 1, section: 0), at: .centeredHorizontally, animated: true)
            let currentKeyFrame = NSNumber(value: (self.currPosition) * 30.0)
            let nextKeyFrame = NSNumber(value: (self.currPosition - 1) * 30.0)
            self.animationView.play(fromFrame: currentKeyFrame, toFrame: nextKeyFrame) { _ in
                self.swipeDisabled = false
                self.currPosition -= 1
            }
        }
    }

    @objc func tappedPage(_ sender: Any?) {
        swipedLeft(sender)
    }

    @IBAction func loginButtonTapped(_ sender: Any) {
        if !LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            OzoneAlert.alertDialog(message: OnboardingStrings.loginNoPassCodeError, dismissTitle: OzoneAlert.okPositiveConfirmString) {}
            return
        }
        performSegue(withIdentifier: "segueToLogin", sender: nil)
    }

    @IBAction func createNewWalletTapped(_ sender: Any) {
        //if user doesn't have wallet we then create one
        if !LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            OzoneAlert.alertDialog(message: OnboardingStrings.createWalletNoPassCodeError, dismissTitle: OzoneAlert.okPositiveConfirmString) {}
            return
        }
        Answers.logCustomEvent(withName: "Wallet Created", customAttributes: [:])
        performSegue(withIdentifier: "segueToWelcome", sender: nil)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "landingCollectionCell", for: indexPath) as? LandingCollectionCell else {
            fatalError("undefined table view behavior")
        }

        cell.data = LandingCollectionCell.Data(title: titles[indexPath.row], subtitle: subtitles[indexPath.row])
        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let dest = segue.destination as? PrivateKeyCreationViewController else {
            return
        }
        dest.wif = (Account()?.wif)!
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenSize = UIScreen.main.bounds
        return CGSize(width: screenSize.width, height: 77)
    }

    func setLocalizedStrings() {
        loginButton.setTitle(OnboardingStrings.loginTitle, for: UIControl.State())
        orSeperatorLabel.text = OnboardingStrings.stylizedOr
        createNewWalletButton.setTitle(OnboardingStrings.createNewWalletTitle, for: UIControl.State())
    }
}
