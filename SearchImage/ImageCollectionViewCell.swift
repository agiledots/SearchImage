//
//  ImageCollectionViewCell.swift
//  SearchImage
//
//  Created by PM001192 on 2017/06/14.
//  Copyright © 2017年 PM001192. All rights reserved.
//

import Foundation
import UIKit

class ImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
//    @IBOutlet weak var visualEffectView: UIVisualEffectView!
//    @IBOutlet weak var imageView: UIImageView!


//    override func prepareForReuse(){
//        super.prepareForReuse()
//    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.imageView.contentMode = .scaleToFill
        
        self.contentView.layer.cornerRadius = 3.0
        self.contentView.layer.masksToBounds = true
        
//        visualEffectView.effect = UIBlurEffect(style: UIBlurEffectStyle.light)
    }


}
