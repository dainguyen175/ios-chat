//
//  NewConversationViewController.swift
//  realtime-chat
//
//  Created by Đại Nguyễn  on 11/13/20.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    public var completion: ((searchResult) -> (Void))?

    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String: String]]()
    
    private var results = [searchResult]()
    
    private var hasFetched = false
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Tìm kiếm..."
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        
        table.isHidden = true
        table.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        
        return table
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        
        label.isHidden = true
        label.text = "Không tìm thấy người dùng"
        label.textAlignment = .center
        label.textColor = .systemPink
        label.font = .systemFont(ofSize: 12, weight: .medium)
        
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self
        view.backgroundColor = .systemBackground
        
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Huỷ", style: .done, target: self, action: #selector(dismissSelf))
        
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.width/4, y: (view.height - 200)/2, width: view.width/2, height: 150)
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}

extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        
        results.removeAll()
        
        spinner.show(in: view)
        
        self.searchUsers(querry: text)
        
    }
    
    func searchUsers(querry: String){
        // check if  array has firebase results
        if hasFetched  {
            // if it does, filter
            filterUsers(with: querry)
        } else {
            // if not, fetch them filter
            DatabaseManager.shared.getAllUsers(completion: {[weak self] result in
                switch result {
                case.success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUsers(with: querry)
                case.failure(let error):
                    print("failed to get user: \(error)")
                }
            })
        }
    }
    
    func filterUsers(with term: String){
        // update the UI: either show results or no result
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String,
              hasFetched else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        self.spinner.dismiss()
        
        let results: [searchResult] = self.users.filter({
            guard let email = $0["email"],
                  email != safeEmail else {
                return false
            }
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            guard let email = $0["email"],
                  let name = $0["name"]
            else {
                return nil
            }
            
            return searchResult(name: name, email: email)
        })
        
        self.results = results
        
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        } else {
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}


extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = results[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
        cell.configure(with: model)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // start conversation
        
        let targetUserData = results[indexPath.row]
        
        dismiss(animated: true, completion: {[weak self] in
            self?.completion?(targetUserData)
        })

    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}

struct searchResult {
    let name: String
    let email: String
}

