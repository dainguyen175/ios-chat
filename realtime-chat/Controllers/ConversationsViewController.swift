//
//  ViewController.swift
//  realtime-chat
//
//  Created by Đại Nguyễn  on 11/13/20.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}

class ConversationsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        
        table.isHidden = true
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        
        return table
    }()
    
    private let noConversation: UILabel = {
        let label = UILabel()
        label.text = ("Bạn chưa có cuộc hội thoại nào!")
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        
        return label
    }()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        
        view.addSubview(tableView)
        view.addSubview(noConversation)
        
        setupTableView()
        fetchConversation()
        startListeningForConversations()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification , object: nil, queue: .main, using: { [weak self] _ in
            
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.startListeningForConversations()
        })
        
    }

    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        print("starting convos fetch...")
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        DatabaseManager.shared.getAllConversations(with: safeEmail, completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                print("successfully got conversation models")
                guard !conversations.isEmpty else {
                    return
                }
                
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print("failed to get convos: \(error)")
            }
        })
    }
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationViewController()
        
        vc.completion = { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            let currentConversation = strongSelf.conversations
            
            if let targetConversation = currentConversation.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email)
            }) {
                let vc = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
            else {
                strongSelf.createNewConversation(result: result)
            }

        }
        
        let navVC = UINavigationController(rootViewController: vc)
        
        present(navVC, animated: true)
    }
    
    private func createNewConversation(result: searchResult) {
        let email = result.email
        let name = DatabaseManager.safeEmail(emailAddress: result.name)
        
        // kiểm tra database nếu conversation đã có
        // nếu có sử dụng lại conversation id
        
        DatabaseManager.shared.conversationExists(with: email, completion: { [weak self] result in
            
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let conversationId):
                let vc = ChatViewController(with: email, id: conversationId)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        })
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateAuth()
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
    

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func fetchConversation() {
        tableView.isHidden = false
    }
}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
  
        let model = conversations[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        
        cell.configure(with: model)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = conversations[indexPath.row]
        
        openConversation(model)
    }
    
    func openConversation(_ model: Conversation) {
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // begin delete
            
            let conversationId = conversations[indexPath.row].id
            tableView.beginUpdates()
            
            DatabaseManager.shared.deleteConversation(conversationId: conversationId, completion: { [weak self] success in
                if success {
                    self?.conversations.remove(at: indexPath.row)
                    
                    tableView.deleteRows(at: [indexPath], with: .left)
                    
                }
            })
            
            
            // begin update
            tableView.endUpdates()
        }
    }
}
