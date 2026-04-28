//
//  SKVocabulariesTableViewController.swift
//  Skarnik

import UIKit

class SKVocabulariesTableViewController: UIViewController {

    private var sections: [(title: String, words: [SKWord])] = []
    private var selectedType: ESKVocabularyType = .rus_bel
    private var loadTask: Task<Void, Never>?

    private lazy var segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: [
            SKLocalization.segmentRusBel,
            SKLocalization.segmentBelRus,
            SKLocalization.segmentDefinition
        ])
        sc.selectedSegmentIndex = 0
        sc.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return sc
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.dataSource = self
        tv.delegate = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.sectionIndexMinimumDisplayRowCount = 0
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = SKLocalization.tabVocabularies
        navigationItem.largeTitleDisplayMode = .never
        setupViews()
        loadWords()
    }

    // MARK: - Setup

    private func setupViews() {
        let appBackground = UIColor(named: "BackgroundColor") ?? .systemBackground
        view.backgroundColor = appBackground
        tableView.backgroundColor = appBackground

        let headerContainer = UIView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerContainer)

        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(segmentedControl)

        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        view.addSubview(divider)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            segmentedControl.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 8),
            segmentedControl.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -8),
            segmentedControl.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 12),
            segmentedControl.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -12),

            divider.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),

            tableView.topAnchor.constraint(equalTo: divider.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Data loading

    private func loadWords() {
        loadTask?.cancel()
        sections = []
        tableView.reloadData()
        tableView.isHidden = true
        activityIndicator.startAnimating()

        let type = selectedType
        loadTask = Task {
            let result = await Task.detached(priority: .userInitiated) {
                SKVocabularyIndex.shared.allWords(vocabularyType: type)
            }.value
            guard !Task.isCancelled else { return }
            sections = result
            activityIndicator.stopAnimating()
            tableView.isHidden = false
            tableView.reloadData()
        }
    }

    // MARK: - Actions

    @objc private func segmentChanged() {
        switch segmentedControl.selectedSegmentIndex {
        case 0: selectedType = .rus_bel
        case 1: selectedType = .bel_rus
        case 2: selectedType = .bel_definition
        default: break
        }
        loadWords()
    }
}

// MARK: - UITableViewDataSource

extension SKVocabulariesTableViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].words.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = sections[indexPath.section].words[indexPath.row].word
        cell.contentConfiguration = config
        cell.backgroundColor = tableView.backgroundColor
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        sections.map(\.title)
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        index
    }
}

// MARK: - UITableViewDelegate

extension SKVocabulariesTableViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let word = sections[indexPath.section].words[indexPath.row]
        SKStorageController.shared.addWord(word)
        showWordInDetail(word, entryPoint: "vocabulary")
    }
}
