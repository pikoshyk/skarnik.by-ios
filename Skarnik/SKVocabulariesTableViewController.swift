//
//  SKDictionariesTableViewController.swift
//  Skarnik
//
//  Created by Logout on 6.10.22.
//

import UIKit

class SKVocabulariesTableViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var viewAdditionKeyboardButtons: SKAdditionalKeyboardView!
    var viewAdditionKeyboardButtonsHidden: Bool?
    var bottomConstraintAdditionKeyboardButtons: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.extendedLayoutIncludesOpaqueBars = true
        self.updateTitleBar()
        self.updateSegments()
        self.addKeyboardObserver()
        self.assignSearchBarController()
        self.addAdditionKeyboardButtons()
    }
    
    func updateTitleBar() {
        let buttonItem = UIBarButtonItem(title: SKLocalization.vocabulariesAdvancedSearch, style: .plain, target: self, action: #selector(onOpenStarnikBy))
        self.navigationItem.rightBarButtonItem = buttonItem
    }
    
    func updateSegments() {
        self.segmentedControl.setTitle(SKLocalization.segmentHistory, forSegmentAt: 0)
        self.segmentedControl.setTitle(SKLocalization.segmentRusBel, forSegmentAt: 1)
        self.segmentedControl.setTitle(SKLocalization.segmentBelRus, forSegmentAt: 2)
        self.segmentedControl.setTitle(SKLocalization.segmentDefinition, forSegmentAt: 3)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    func sectionTitle(tableSection: Int) -> String {
        let abc = SKVocabularyIndex.shared.wordsIndexes(vocabularyType: self.selectedVocabularyType)
        let sectionTitle = abc[tableSection]
        return sectionTitle
    }
    
    func word(tableIndexPath: IndexPath) -> SKWord? {
        let vocabularyType = self.selectedVocabularyType
        var word: SKWord?
        if vocabularyType == .history {
            word = SKStorageController.shared.words[tableIndexPath.row]
        } else {
            let sectionTitle = self.sectionTitle(tableSection: tableIndexPath.section)
            word = SKVocabularyIndex.shared.word(index: tableIndexPath.row, query: sectionTitle, vocabularyType: vocabularyType).first
        }
        return word
    }
    
    @IBAction func onOpenStarnikBy() {
        guard let url = URL(string: "https://starnik.by") else {
            return
        }

        UIApplication.shared.open(url)
    }
    
    func openWord(_ word: SKWord, fromHistory: Bool) {
        if fromHistory == false {
            SKStorageController.shared.addWord(word)
            if self.selectedVocabularyType == .history {
                self.tableView.reloadData()
            }
        }

        var wordDetailsViewController: SKWordDetailsViewController?
        if #available(iOS 14.0, *) {
            wordDetailsViewController = self.splitViewController?.viewController(for: .secondary) as? SKWordDetailsViewController
        } else {
            let controllers: [UIViewController]? = self.splitViewController?.viewControllers
            let countControllers = controllers?.count ?? 0
            if countControllers == 1 {
                wordDetailsViewController = self.storyboard?.instantiateViewController(withIdentifier: "SKWordDetailsViewController") as? SKWordDetailsViewController
            }
            else if countControllers >= 2 {
                wordDetailsViewController = controllers?.last as? SKWordDetailsViewController
            }
        }
        if let wordDetailsViewController = wordDetailsViewController {
            self.splitViewController?.showDetailViewController(wordDetailsViewController, sender: self)
            wordDetailsViewController.word = word
        }

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension SKVocabulariesTableViewController: SKSearchWordsTableViewControllerDelegate {
    func onSearchWordSelected(word: SKWord) {
        self.openWord(word, fromHistory: false)
    }
}

extension SKVocabulariesTableViewController { // SegmentedControl
    var selectedVocabularyType: ESKVocabularyType {
        get {
            let index = self.segmentedControl.selectedSegmentIndex
            let type = ESKVocabularyType(rawValue: index)!
            return type
        }
    }
    
    @IBAction func onSelectedSegment(_ sender: UISegmentedControl) {
        self.tableView.reloadData()
    }
}

extension SKVocabulariesTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let word = self.word(tableIndexPath: indexPath) {
            let isHistory = (self.selectedVocabularyType == .history)
            self.openWord(word, fromHistory: isHistory)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension SKVocabulariesTableViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if self.selectedVocabularyType == .history {
            return true
        }

        return false
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return SKLocalization.cellDeleteActionTitle
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle:   UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            SKStorageController.shared.removeWord(index: indexPath.row)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .middle)
            tableView.endUpdates()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        let vocabularyType = self.selectedVocabularyType
        var count = 0
        if vocabularyType == .history {
            count = 1
        } else {
            count = SKVocabularyIndex.shared.wordsIndexes(vocabularyType: self.selectedVocabularyType).count
        }
        return count
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        let abc = SKVocabularyIndex.shared.wordsIndexes(vocabularyType: self.selectedVocabularyType)
        return abc
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionTitle = self.sectionTitle(tableSection: section)
        return sectionTitle
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let vocabularyType = self.selectedVocabularyType
        var count = 0
        if vocabularyType == .history {
            count = SKStorageController.shared.words.count
        } else {
            let sectionTitle = self.sectionTitle(tableSection: section)
            count = SKVocabularyIndex.shared.wordsCount(query: sectionTitle, vocabularyType: self.selectedVocabularyType)
        }
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "wordCell", for: indexPath)
        let vocabularyType = self.selectedVocabularyType
        if vocabularyType == .history {
            let word = SKStorageController.shared.words[indexPath.row]
            cell.textLabel?.text = word.word
            cell.detailTextLabel?.text = word.lang_id.name?.uppercased()
        } else {
            let word = self.word(tableIndexPath: indexPath)
            cell.textLabel?.text = word?.word
            cell.detailTextLabel?.text = nil
        }

        return cell
    }

}

extension SKVocabulariesTableViewController: SKAdditionalKeyboardViewDelegate {
    
    func addAdditionKeyboardButtons() {
        guard let keyboardView = self.viewAdditionKeyboardButtons else {
            return
        }

        var window: UIWindow?
        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene: UIWindowScene = scene as? UIWindowScene {
                    window = windowScene.windows.last
                }
            }
        } else {
            window = UIApplication.shared.keyWindow
        }
        guard let window = window else {
            return
        }

        keyboardView.isHidden = true
        window.addSubview(keyboardView)

        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        let views: [String: UIView] = ["view": window, "newView": keyboardView]
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[newView]|", options: [], metrics: nil, views: views)
        window.addConstraints(horizontalConstraints)

        let topConstraint = NSLayoutConstraint(item: keyboardView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: window, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
        window.addConstraint(topConstraint)
        
        let bottomConstrain = NSLayoutConstraint(item: window, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: keyboardView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0)
        window.addConstraint(bottomConstrain)
        self.bottomConstraintAdditionKeyboardButtons = bottomConstrain

        window.setNeedsLayout()
        window.layoutIfNeeded()

        self.viewAdditionKeyboardButtons.delegate = self
    }

    func onAdditionalKeyboardCharPressed(char: String) {
        var text = self.navigationItem.searchController?.searchBar.text ?? ""
        text += char
        self.navigationItem.searchController?.searchBar.text = text
    }
    
    func addKeyboardObserver() {
        self.viewAdditionKeyboardButtons.isHidden = true
        self.viewAdditionKeyboardButtonsHidden = nil

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
          forName: UIApplication.willResignActiveNotification,
          object: nil, queue: .main) { (notification) in
              if self.viewAdditionKeyboardButtons.isHidden == false {
                  self.viewAdditionKeyboardButtons.isHidden = true
                  self.viewAdditionKeyboardButtonsHidden = true
              }
        }
        notificationCenter.addObserver(
          forName: UIApplication.didBecomeActiveNotification,
          object: nil, queue: .main) { (notification) in
              if self.viewAdditionKeyboardButtonsHidden == true {
                  self.viewAdditionKeyboardButtons.isHidden = false
                  self.viewAdditionKeyboardButtonsHidden = false
              }
        }

        notificationCenter.addObserver(
          forName: UIResponder.keyboardWillChangeFrameNotification,
          object: nil, queue: .main) { (notification) in
            self.handleKeyboard(notification: notification)
        }
        notificationCenter.addObserver(
          forName: UIResponder.keyboardWillShowNotification,
          object: nil, queue: .main) { (notification) in
            self.handleKeyboard(notification: notification)
        }
        notificationCenter.addObserver(
          forName: UIResponder.keyboardWillHideNotification,
          object: nil, queue: .main) { (notification) in
            self.handleKeyboard(notification: notification)
        }
    }
    
    func handleKeyboard(notification: Notification) {
        let durationKey = UIResponder.keyboardAnimationDurationUserInfoKey
        let duration = notification.userInfo![durationKey] as! Double
        
        var keyboardHeight: CGFloat = 0
        if notification.name != UIResponder.keyboardWillHideNotification {
            let frameKey = UIResponder.keyboardFrameEndUserInfoKey
            let keyboardFrameValue = notification.userInfo![frameKey] as! NSValue
            let keyboardScreenEndFrame = keyboardFrameValue.cgRectValue
            keyboardHeight = keyboardScreenEndFrame.size.height
        }

        let curveKey = UIResponder.keyboardAnimationCurveUserInfoKey
        let curveValue = notification.userInfo![curveKey] as! Int
        let curve = UIView.AnimationCurve(rawValue: curveValue)!

        self.viewAdditionKeyboardButtons.isHidden = (keyboardHeight == 0) ? true : false
        if(self.viewAdditionKeyboardButtons.isHidden) {
            self.viewAdditionKeyboardButtonsHidden = nil
        }
        let animator = UIViewPropertyAnimator(duration: duration, curve: curve) {
            self.bottomConstraintAdditionKeyboardButtons?.constant = keyboardHeight
            self.viewAdditionKeyboardButtons.superview?.layoutIfNeeded()
        }

        animator.startAnimation()
    }
}

extension SKVocabulariesTableViewController: UISearchBarDelegate {
    
    func updateSearchBar(_ searchBar: UISearchBar) {
        searchBar.placeholder = SKLocalization.searchbarSearchWords
        searchBar.autocapitalizationType = .none
        searchBar.returnKeyType = .default
        searchBar.delegate = self
        searchBar.setValue(SKLocalization.searchbarCancel, forKey: "cancelButtonText")
    }
    
    var isSearchBarEmpty: Bool {
        return self.navigationItem.searchController?.searchBar.text?.isEmpty ?? true
    }
}

extension SKVocabulariesTableViewController: UISearchControllerDelegate {

    func assignSearchBarController() {
        guard let searchResultsTableViewController = self.storyboard?.instantiateViewController(withIdentifier: "SKSearchWordsTableViewController") as? SKSearchWordsTableViewController else {
            return
        }
        searchResultsTableViewController.delegate = self
        let searchController = UISearchController(searchResultsController: searchResultsTableViewController)
        searchController.searchResultsUpdater = searchResultsTableViewController
        searchController.obscuresBackgroundDuringPresentation = true
        self.updateSearchBar(searchController.searchBar)
        self.navigationItem.searchController = searchController
        searchController.showsSearchResultsController = true
        self.definesPresentationContext = true
    }
}
