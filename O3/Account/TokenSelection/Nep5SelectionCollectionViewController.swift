//
//  Nep5SelectionCollectionViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 5/1/18.
//  Copyright © 2018 drei. All rights reserved.
//

import Foundation
import UIKit
import Crashlytics

class Nep5SelectionCollectionViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate {
    let numberOfTokensPerRow: CGFloat = 2
    let gridSpacing: CGFloat = 8
    var supportedTokens = [NEP5Token]()
    var filteredTokens = [NEP5Token]()

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!

    func loadTokens() {
        O3Client().getTokens { result in
            switch result {
            case .failure:
                return
            case .success(let tokens):
                self.supportedTokens = tokens
                self.filteredTokens = self.supportedTokens
                DispatchQueue.main.async { self.collectionView?.reloadData() }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
        collectionView.dataSource = self
        collectionView.delegate = self
        searchBar.delegate = self
        self.hideKeyboardWhenTappedAround()
        loadTokens()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredTokens.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tokenGridCell", for: indexPath) as? TokenGridCell else {
            fatalError("Undefined cell grid behavior")
        }

        cell.data = filteredTokens[indexPath.row]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return gridSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let frameWidth = (view.frame.width - 16 - (CGFloat(max(0, numberOfTokensPerRow - 1)) * gridSpacing))
        return CGSize(width: frameWidth / numberOfTokensPerRow, height: frameWidth / numberOfTokensPerRow)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredTokens = searchText.isEmpty ? supportedTokens : supportedTokens.filter { (item: NEP5Token) -> Bool in
            return item.name.lowercased().hasPrefix(searchText.lowercased()) ||
                item.symbol.lowercased().hasPrefix(searchText.lowercased())
        }
        collectionView.reloadData()
    }

    func setThemedElements() {
        collectionView.theme_backgroundColor = O3Theme.backgroundColorPicker
        var background: UIImage
        if UserDefaultsManager.themeIndex == 0 {
            background = UIImage(color: .white)!
            searchBar.setTextFieldColor(color: .white)
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.black]
        } else {
            background = UIImage(color: Theme.dark.backgroundColor)!
            searchBar.setTextFieldColor(color: Theme.dark.backgroundColor)
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.white]
        }

        searchBar.theme_keyboardAppearance = O3Theme.keyboardPicker
        searchBar.theme_backgroundColor = O3Theme.backgroundColorPicker
        searchBar.theme_tintColor = O3Theme.textFieldTextColorPicker

        searchBar.setBackgroundImage(background, for: .any, barMetrics: UIBarMetrics.default)
    }

    func setLocalizedStrings() {

    }
}
