//
//  PrivateKeyCreationViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/5/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class PrivateKeyCreationViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, TutorialCardDelegate, PrivateKeyCardDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var closeButton: UIButton!

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

    override func viewDidLoad() {
        super.viewDidLoad()
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

    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @objc func swipedLeft(_ sender: Any?) {
        if currPosition == maxPosition {
            return
        }

        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: IndexPath(row: Int(self.currPosition) + 1, section: 0), at: .centeredHorizontally, animated: true)
            self.currPosition += 1

        }
    }

    @objc func swipedRight(_ sender: Any?) {
        if currPosition == minPosition {
            return
        }

        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: IndexPath(row: Int(self.currPosition) - 1, section: 0), at: .centeredHorizontally, animated: true)
            self.currPosition -= 1
        }
    }

    func backTapped() {
        swipedRight(nil)
    }

    func forwardTapped() {
        swipedLeft(nil)
    }

    func backupTapped() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "segueToPerformBackup", sender: nil)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let row = indexPath.row
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
        let data = TutorialCardCollectionViewCell.TutorialCardData(title: titles[row], infoOne: infoOnes[row], infoTwo: infoTwos[row], emphasis: emphasises[row])
        cell.data = data
        cell.delegate = self
        return cell
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
    }
}
