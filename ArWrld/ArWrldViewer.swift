//
//  ArWrldViewer.swift
//  ArWrld
//
//  Created by David Hodge on 1/30/18.
//  Copyright © 2018 David Hodge. All rights reserved.
//

import UIKit

class ArWrldViewer: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self
        webView.loadRequest(URLRequest(url: URL(string: "http://arwrld.com")!))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }

}
