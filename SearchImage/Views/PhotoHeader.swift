
//
//  File.swift
//  SearchImage
//
//  Created by LU XIAOQUAN on 2017/07/12.
//  Copyright © 2017年 PM001192. All rights reserved.
//

import Foundation
import UIKit

class PhotoHeader: UICollectionReusableView {
    
    var searchBar: UISearchBar!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.red
        
        searchBar = UISearchBar(frame: self.frame)
        self.addSubview(searchBar)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
