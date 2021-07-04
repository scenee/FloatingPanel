// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI

struct ResultsList: UIViewControllerRepresentable {
    var onCreateScrollView: (_ scrollView: UIScrollView) -> Void

    func makeUIViewController(
        context: Context
    ) -> ResultsTableViewController {
        let rtvc = ResultsTableViewController()
        DispatchQueue.main.async {
            onCreateScrollView(rtvc.tableView)
        }
        return rtvc
    }

    func updateUIViewController(
        _ uiViewController: ResultsTableViewController,
        context: Context
    ) {
    }
}

struct TableViewItem: Hashable {
    let color: Color
    let symbolName: String
    let title: String
    let description: String
}

final class ResultsTableViewController: UITableViewController {
    private let reuseIdentifier = "HostingCell<ResultListCell>"

    // MARK: Section

    private enum Section: CaseIterable {
        case main
    }

    private var dataSource: UITableViewDiffableDataSource<Section, TableViewItem>?

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = .clear
        tableView.register(HostingCell<ResultListCell>.self, forCellReuseIdentifier: reuseIdentifier)

        // A little trick for removing the cell separators
        tableView.tableFooterView = UIView()

        configureDataSource()
    }

    // MARK: UITableViewDataSource

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource
        <Section, TableViewItem>(tableView: tableView) { [weak self] tableView, _, tableItem -> UITableViewCell? in
            self?.tableView(tableView, cellForTableViewItem: tableItem)
        }
        tableView.dataSource = dataSource

        var snapshot = NSDiffableDataSourceSnapshot<Section, TableViewItem>()

        snapshot.appendSections([.main])

        let results: [TableViewItem] = (1...100).map {
            TableViewItem(
                color: Color(red: 255 / 255.0, green: 94 / 255.0 , blue: 94 / 255.0),
                symbolName: "heart.fill",
                title: "Favorites",
                description: "\($0) Places"
            )
        }
        snapshot.appendItems(results, toSection: .main)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    private func tableView(
        _ tableView: UITableView,
        cellForTableViewItem tableViewItem: TableViewItem
    ) -> UITableViewCell {
        let cell: HostingCell<ResultListCell> = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! HostingCell<ResultListCell>
        setupResultTableViewCell(
            cell,
            color: tableViewItem.color,
            symbolName: tableViewItem.symbolName,
            title: tableViewItem.title,
            description: tableViewItem.description
        )
        return cell
    }

    private func setupResultTableViewCell(
        _ cell: HostingCell<ResultListCell>,
        color: Color,
        symbolName: String,
        title: String,
        description: String
    ) {
        cell.set(
            rootView: ResultListCell(
                color: color,
                symbolName: symbolName,
                title: title,
                description: description
            ),
            parentController: self
        )
    }

    // MARK: UITableViewDelegate

    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

struct ResultListCell: View {
    let color: Color
    let symbolName: String
    let title: String
    let description: String

    var body: some View {
        HStack {
            Image(systemName: symbolName)
                .foregroundColor(.white)
                .font(.headline)
                .padding(8)
                .background(Circle().fill(color))
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
        .padding()
    }
}
