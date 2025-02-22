//
//  StorageManager.swift
//  realtime-chat
//
//  Created by Đại Nguyễn  on 11/25/20.
//

import Foundation
import FirebaseStorage

final class StorageManager  {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /*
     /images/dainguyennhu-gmail-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Upload picture to firebase storage and returns completion with url string  to download
    public func uploadProfilePicture(with data: Data, filename: String, completion: @escaping UploadPictureCompletion) {
        
        storage.child("images/\(filename)").putData(data, metadata: nil, completion: {metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return 
            }
            
            self.storage.child("images/\(filename)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("failed to get download url")
                    completion(.failure(StorageErrors.failedToDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("download URL return : \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    /// Upload image will be sent in a conversation
    public func uploadMessagePhoto(with data: Data, filename: String, completion: @escaping UploadPictureCompletion) {
        
        storage.child("messages_images/\(filename)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("messages_images/\(filename)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("failed to get download url")
                    completion(.failure(StorageErrors.failedToDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("download URL return : \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    // upload video
    public func uploadMessageVideo(with fileUrl: URL, filename: String, completion: @escaping UploadPictureCompletion) {
        
        print("url \(fileUrl) --- \(filename)")
        storage.child("messages_videos/\(filename)").putFile(from: fileUrl, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for video \(error )")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("messages_videos/\(filename)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("failed to get download url")
                    completion(.failure(StorageErrors.failedToDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("download URL return : \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        
        case failedToDownloadURL
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        
        reference.downloadURL(completion: {url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToDownloadURL))
                return
            }
            
            completion(.success(url))
        })
    }
}
