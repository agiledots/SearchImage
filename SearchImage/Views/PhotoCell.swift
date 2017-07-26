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
    @IBOutlet weak var checkImageView: UIImageView!

    var editing:Bool = false {
        didSet{
            self.checkImageView?.isHidden = !editing
        }
    }
    
    override var isSelected: Bool{
        didSet {
            self.checkImageView?.image = self.isSelected ? #imageLiteral(resourceName: "check") : #imageLiteral(resourceName: "uncheck")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.imageView.contentMode = .scaleAspectFill
        
        self.checkImageView?.translatesAutoresizingMaskIntoConstraints = false
        self.checkImageView?.contentMode = .scaleAspectFit
        self.checkImageView?.clipsToBounds = true
        self.checkImageView?.isHidden = true
        self.checkImageView?.image = #imageLiteral(resourceName: "uncheck")
        self.contentView.addSubview(self.checkImageView!)
        
    }
    
}
