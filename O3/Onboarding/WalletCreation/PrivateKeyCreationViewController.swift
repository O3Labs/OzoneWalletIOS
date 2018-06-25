//
//  PrivateKeyCreationViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/5/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import Crashlytics

class PrivateKeyCreationViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, TutorialCardDelegate, PrivateKeyCardDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var animationContainerView: UIView!

    @IBOutlet weak var learnMoreContainer: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var learnmoreButton: UIButton!

    // swiftlint:disable weak_delegate
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    // swiftlint:enable weak_delegate

    var titles: [String] = [OnboardingStrings.tutorialTitleOne, OnboardingStrings.tutorialTitleTwo,
                            OnboardingStrings.tutorialTitleThree, OnboardingStrings.tutorialTitleFour,
                            OnboardingStrings.tutorialTitleFive]
    var infoOnes: [String] = [OnboardingStrings.tutorialInfoOneOne, OnboardingStrings.tutorialInfoOneTwo,
                              OnboardingStrings.tutorialInfoOneThree, OnboardingStrings.tutorialInfoOneFour,
                              OnboardingStrings.tutorialInfoOneFive]
    var infoTwos: [String?] = [OnboardingStrings.tutorialInfoTwoOne, OnboardingStrings.tutorialInfoTwoTwo,
                               OnboardingStrings.tutorialInfoTwoThree, nil, OnboardingStrings.tutorialInfoTwoFive]
    var emphasises: [String?] = [nil, nil, OnboardingStrings.emphasisThree, nil, OnboardingStrings.emphasisFive]

    var wif: String = ""

    var currPosition = 0.0
    var maxPosition = 5.0
    var minPosition = 0.0

    var swipeDisabled = false

    let tutorialAnimation = LOTAnimationView(name: "LearnMore")

    func presentWalletGeneratedViewController() {
        let walletGeneratedVc = UIStoryboard(name: "WalletCreation", bundle: nil).instantiateViewController(withIdentifier: "walletGeneratedViewController")
        walletGeneratedVc.modalPresentationStyle = .overCurrentContext
        walletGeneratedVc.modalTransitionStyle = .crossDissolve
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.presentFromEmbedded(walletGeneratedVc, animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.reloadData()

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.swipedLeft(_:)))
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.swipedRight(_:)))
        swipeLeft.direction = .left
        swipeRight.direction = .right

        view.addGestureRecognizer(swipeLeft)
        view.addGestureRecognizer(swipeRight)
        view.isUserInteractionEnabled = true

        animationContainerView.embed(tutorialAnimation)
        view.bringSubview(toFront: learnMoreContainer)
        view.bringSubview(toFront: closeButton)

        tutorialAnimation.animationSpeed = CGFloat(1.4)
        presentWalletGeneratedViewController()

    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @objc func swipedLeft(_ sender: Any?) {
        if currPosition == maxPosition || swipeDisabled {
            return
        }

        if currPosition == minPosition {
            UIView.animate(withDuration: 0.2) {
                self.learnMoreContainer.alpha = 0.0
            }
        }

        DispatchQueue.main.async {
            self.swipeDisabled = true
            self.collectionView.scrollToItem(at: IndexPath(row: Int(self.currPosition) + 1, section: 0), at: .centeredHorizontally, animated: true)
            let keyFrame = NSNumber(value: (self.currPosition + 1) * 30.0)
            self.tutorialAnimation.play(toFrame: keyFrame) { _ in
                self.currPosition += 1
                self.swipeDisabled = false
            }
        }
    }

    @objc func swipedRight(_ sender: Any?) {
        if currPosition == minPosition || swipeDisabled {
            return
        }

        if self.currPosition == self.minPosition + 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIView.animate(withDuration: 0.2) {
                    self.learnMoreContainer.alpha = 1.0
                }
            }
        }

        DispatchQueue.main.async {
            self.swipeDisabled = true
            self.collectionView.scrollToItem(at: IndexPath(row: Int(self.currPosition) - 1, section: 0), at: .centeredHorizontally, animated: true)
            let currentKeyFrame = NSNumber(value: (self.currPosition) * 30.0)
            let nextKeyFrame = NSNumber(value: (self.currPosition - 1) * 30.0)
            self.tutorialAnimation.play(fromFrame: currentKeyFrame, toFrame: nextKeyFrame) { _ in
                self.swipeDisabled = false
                self.currPosition -= 1
            }
        }
    }

    func backTapped() {
        swipedRight(nil)
    }

    func forwardTapped() {
        if swipeDisabled {
            return
        }

        DispatchQueue.main.async {
            if self.collectionView.indexPathsForVisibleItems[0].row == Int(self.maxPosition) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    UIView.animate(withDuration: 0.2) {
                        self.learnMoreContainer.alpha = 1.0
                    }
                }

                let currentKeyFrame = NSNumber(value: (self.currPosition) * 30.0)
                self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .centeredHorizontally, animated: true)
                self.tutorialAnimation.animationSpeed = CGFloat(20.0)
                self.tutorialAnimation.play(fromFrame: currentKeyFrame, toFrame: NSNumber(value: 0)) { _ in
                    self.tutorialAnimation.animationSpeed = CGFloat(1.4)
                    self.swipeDisabled = false
                    self.currPosition = 0
                }
            } else {
                self.swipedLeft(nil)
            }
        }
    }

    func backupTapped() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "segueToPerformBackup", sender: nil)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        var row = indexPath.row
        if row == 0 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "privateKeyCollectionViewCell", for: indexPath)
                as? PrivateKeyCollectionViewCell else {
                    fatalError("unknown cell type attempting to be dequeue")
            }
            cell.delegate = self
            cell.data = wif
            return cell
        }

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tutorialCardCollectionViewCell", for: indexPath)
            as? TutorialCardCollectionViewCell else {
                fatalError("unknown cell type attempting to be dequeue")
        }

        row -= 1
        let data = TutorialCardCollectionViewCell.TutorialCardData(title: titles[row], infoOne: infoOnes[row], infoTwo: infoTwos[row], emphasis: emphasises[row])

        cell.data = data
        if row + 1 == Int(maxPosition) {
            cell.cardEmphasisLabel.textColor = Theme.light.positiveGainColor
            cell.forwardButton.setTitle(OnboardingStrings.finish, for: UIControlState())
        } else {
            cell.cardEmphasisLabel.textColor = Theme.light.negativeLossColor
        }

        cell.delegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            backupTapped()
        }
    }

    @IBAction func learnMoreButtonTapped(_ sender: Any) {
        Answers.logCustomEvent(withName: "Learn More About Private Key",
                               customAttributes: [:])
        swipedLeft(nil)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenSize = UIScreen.main.bounds
        return CGSize(width: screenSize.width, height: screenSize.height * 0.7)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: segue.destination)
        segue.destination.modalPresentationStyle = .custom
        segue.destination.transitioningDelegate = self.halfModalTransitioningDelegate
        guard let dest = segue.destination as? UINavigationController,
            let destChild = dest.childViewControllers[0] as? BackupTableViewController else {
                return
        }
        destChild.wif = wif
    }

    func setLocalizedStrings() {
        titleLabel.text = OnboardingStrings.titleAnimationHeader
        subtitleLabel.text = OnboardingStrings.subtitleAnimationHeader
        let attributedString = NSMutableAttributedString(string: OnboardingStrings.learnMore)
        attributedString.addAttribute(NSAttributedStringKey.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(NSAttributedStringKey.underlineColor, value: Theme.light.accentColor, range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: Theme.light.accentColor, range: NSRange(location: 0, length: attributedString.length))
        learnmoreButton.setAttributedTitle(attributedString, for: UIControlState())
    }
}
