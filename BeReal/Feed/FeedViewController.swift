//
//  FeedViewController.swift
//  BeReal
//
//  Created by Charlie Hieger on 11/1/22.
//

import UIKit

import ParseSwift

class FeedViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    private let refreshControl = UIRefreshControl()
    private let pageSize = 10
    private var isLoadingPosts = false
    private var hasMorePosts = true
    private let loadingMoreIndicator = UIActivityIndicatorView(style: .medium)

    private var posts = [Post]() {
        didSet {
            // Reload table view data any time the posts variable gets updated.
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "BeReal"

        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 25, weight: .bold)
        ]

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false

        refreshControl.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        configureLoadingMoreIndicator()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        queryPosts(reset: true)
    }

    @objc private func onPullToRefresh() {
        queryPosts(reset: true)
    }

    private func configureLoadingMoreIndicator() {
        loadingMoreIndicator.hidesWhenStopped = true
        loadingMoreIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingMoreIndicator)
        NSLayoutConstraint.activate([
            loadingMoreIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingMoreIndicator.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func setLoadingFooterVisible(_ isVisible: Bool) {
        if isVisible {
            loadingMoreIndicator.startAnimating()
        } else {
            loadingMoreIndicator.stopAnimating()
        }
    }

    private func queryPosts(reset: Bool) {
        guard !isLoadingPosts else {
            if reset {
                refreshControl.endRefreshing()
            }
            return
        }

        if !reset && !hasMorePosts {
            return
        }

        isLoadingPosts = true
        setLoadingFooterVisible(!reset)

        let skip = reset ? 0 : posts.count
        let query = Post.query()
            .include("user")
            .order([.descending("createdAt")])
            .limit(pageSize)
            .skip(skip)

        query.find { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                defer {
                    self.isLoadingPosts = false
                    self.refreshControl.endRefreshing()
                    self.setLoadingFooterVisible(false)
                }

                switch result {
                case .success(let fetchedPosts):
                    if reset {
                        self.posts = fetchedPosts
                    } else {
                        self.posts.append(contentsOf: fetchedPosts)
                    }
                    self.hasMorePosts = fetchedPosts.count == self.pageSize
                case .failure(let error):
                    self.showAlert(description: error.localizedDescription)
                }
            }
        }

// https://github.com/parse-community/Parse-Swift/blob/3d4bb13acd7496a49b259e541928ad493219d363/ParseSwift.playground/Pages/2%20-%20Finding%20Objects.xcplaygroundpage/Contents.swift#L66


    }

    @IBAction func onLogOutTapped(_ sender: Any) {
        showConfirmLogoutAlert()
    }

    private func showConfirmLogoutAlert() {
        let alertController = UIAlertController(title: "Log out of your account?", message: nil, preferredStyle: .alert)
        let logOutAction = UIAlertAction(title: "Log out", style: .destructive) { _ in
            NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(logOutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            return UITableViewCell()
        }
        cell.configure(with: posts[indexPath.row])
        return cell
    }
}

extension FeedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastPostIndex = posts.count - 1
        guard indexPath.row == lastPostIndex else { return }
        queryPosts(reset: false)
    }
}
