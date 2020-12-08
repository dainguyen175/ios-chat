//
//  ConversationTableViewCell.swift
//  realtime-chat
//
//  Created by Đại Nguyễn  on 12/5/20.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    
    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 40
        imageView.layer.masksToBounds = true
        
        return imageView
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
    
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        
        return label
    }()
    
    private let userMessageLabel: UILabel = {
        let label = UILabel()
    
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.numberOfLines = 0
        
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(userImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(userMessageLabel)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 80,
                                     height: 80)
        
        usernameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 0,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: (contentView.height - 20)/2)
        
        userMessageLabel.frame = CGRect(x: userImageView.right + 10,
                                        y: usernameLabel.bottom ,
                                        width: contentView.width - 20 - userImageView.width,
                                        height: (contentView.height - 20)/2)

    }

    public func configure(with model: Conversation) {
        self.userMessageLabel.text = model.latestMessage.text
        self.usernameLabel.text = model.name
        
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        
        StorageManager.shared.downloadURL(for: path, completion: {[weak self] result in
            switch result {
            case .success(let url):
                
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
                
            case .failure(let error):
                print("failed to get image url")
            }
        })
    }
}
