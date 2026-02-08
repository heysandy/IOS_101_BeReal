//
//  PostCell.swift
//  BeReal
//
//  Created by Charlie Hieger on 11/3/22.
//

import UIKit
import Alamofire
import AlamofireImage

class PostCell: UITableViewCell {

    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var postImageView: UIImageView!
    @IBOutlet private weak var captionLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!

    private var imageDataRequest: DataRequest?

    func configure(with post: Post) {
        // Username
        usernameLabel.text = post.user?.username

        // Caption
        captionLabel.text = post.caption

        // Upload metadata
        let timeText = post.createdAt.map { DateFormatter.postTimeFormatter.string(from: $0) } ?? "Unknown time"
        let locationText = post.locationName ?? "Unknown location"
        dateLabel.text = "\(timeText) • \(locationText)"

        // Image
        if let imageFile = post.imageFile,
           let imageUrl = imageFile.url {

            imageDataRequest = AF.request(imageUrl).responseImage { [weak self] response in
                switch response.result {
                case .success(let image):
                    self?.postImageView.image = image
                case .failure(let error):
                    print("❌ Image load error: \(error.localizedDescription)")
                }
            }
        }


    }

    override func prepareForReuse() {
        super.prepareForReuse()
        postImageView.image = nil
        imageDataRequest?.cancel()
        imageDataRequest = nil


    }
}
