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
        self.labelSearchHeaderAdditionalRulesHeader.text = SKLocalization.searchHeaderAdditionalRules

        self.tableView.contentInset.bottom = 60.0 // Additional Keyboard Size
        self.labelSearchHeaderAdditionalRulesHeader.numberOfLines = 0

        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAdditionalRulesHeader()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let header = self.tableView.tableHeaderView else { return }
        let width = self.tableView.bounds.width
        guard width > 0, header.frame.width != width else { return }
        header.frame = CGRect(x: 0, y: 0, width: width, height: headerHeight(forWidth: width))
        self.tableView.tableHeaderView = header
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: false)
        }
    }

    // MARK: - Table view data source

    private func headerHeight(forWidth width: CGFloat) -> CGFloat {
        let labelWidth = width - 32 // leading 16 + trailing 16
        return labelSearchHeaderAdditionalRulesHeader.sizeThatFits(
            CGSize(width: labelWidth, height: .greatestFiniteMagnitude)
        ).height + 16 // top 8 + bottom 8
    }

    private func updateAdditionalRulesHeader() {
        guard self.words.isEmpty else {
            self.tableView.tableHeaderView = nil
            return
        }
        let header = self.viewSearchHeaderAdditionalRules!
        guard self.tableView.tableHeaderView !== header else { return }
        let width = max(self.tableView.bounds.width, UIScreen.main.bounds.width)
        header.translatesAutoresizingMaskIntoConstraints = true
        header.frame = CGRect(x: 0, y: 0, width: width, height: headerHeight(forWidth: width))
        self.tableView.tableHeaderView = header
    }

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
                self.updateAdditionalRulesHeader()
            }
        }
    }
}
