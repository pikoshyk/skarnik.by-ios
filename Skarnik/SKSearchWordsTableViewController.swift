//
//  SKSearchResultsTableViewController.swift
//  Skarnik
//
//  Created by Logout on 10.10.22.
//

import UIKit

protocol SKSearchWordsTableViewControllerDelegate {
    func onSearchWordSelected(word: SKWord)
}

class SKSearchWordsTableViewController: UITableViewController, UISearchResultsUpdating {
    
    @IBOutlet var viewSearchHeaderAdditionalRules: UIView!
    @IBOutlet var labelSearchHeaderAdditionalRulesHeader: UILabel!

    var delegate: SKSearchWordsTableViewControllerDelegate?
    var searchText: String?
    private var words: [SKWord] = []
    let backgroundSearchQueue = OperationQueue()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.backgroundSearchQueue.maxConcurrentOperationCount = 1
        self.backgroundSearchQueue.qualityOfService = .background
        self.tableView.contentInset.bottom = 60.0 // Additional Keyboard Size
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: false)
        }
    }

    // MARK: - Table view data source
    
//    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        guard let text = self.searchText else {
//            return nil
//        }
//
//        if SKVocabularyIndex.shared.requiredAdditionalSearchRules(queryLength: text.count) {
//            return self.viewSearchHeaderAdditionalRules
//        }
//
//        return nil
//    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = self.words.count
        return count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wordCell", for: indexPath)
        if self.words.count > indexPath.row {
            let word = self.words[indexPath.row]
            cell.textLabel?.text = word.word
            cell.detailTextLabel?.text = word.lang_id.name?.uppercased()
        } else {
            cell.textLabel?.text = nil
            cell.detailTextLabel?.text = nil
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let word = self.words[indexPath.row]
        self.delegate?.onSearchWordSelected(word: word)
    }

    func updateSearchResults(for searchController: UISearchController) {
        self.backgroundSearchQueue.cancelAllOperations()
        let text = searchController.searchBar.text ?? ""
        self.backgroundSearchQueue.addOperation {
            let myText = text.lowercased()
            var words:[SKWord] = []
            if myText.isEmpty == false {
                words = SKVocabularyIndex.shared.word(index: 0, query: myText, vocabularyType: .all, limit: 20)
            }
            DispatchQueue.main.sync {
                self.searchText = myText
                self.words = words
                self.tableView.reloadData()
            }
        }
    }
}
