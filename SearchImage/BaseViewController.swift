//
//  BaseViewController.swift
//  SearchImage
//
//  Created by LU XIAOQUAN on 2017/07/26.
//  Copyright © 2017年 PM001192. All rights reserved.
//

import Foundation
import UIKit


class BaseViewController: UIViewController {
    
    var loadingAlert: UIAlertController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingAlert = UIAlertController(title: nil, message: "処理中...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        loadingAlert.view.addSubview(loadingIndicator)
        
    }
    
}
