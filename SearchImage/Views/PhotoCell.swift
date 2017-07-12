//
//  ImageCollectionViewCell.swift
//  SearchImage
//
//  Created by PM001192 on 2017/06/14.
//  Copyright © 2017年 PM001192. All rights reserved.
//

import Foundation
import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.contentMode = .scaleAspectFill
        
    }
    
}
