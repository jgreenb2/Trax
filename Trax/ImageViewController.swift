//
//  ImageViewController.swift
//  Cassini
//
//  Created by jeff greenberg on 6/17/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {

    // this MVC has a simple one-var model which is the image URL
    // so we just handle it here rather than in its own class
    var imageURL: NSURL? {
        didSet {
            image=nil
            if view.window != nil {
                fetchImage()    // only get the image if the view is on-screen
            }
        }
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private func fetchImage() {
        if let url = imageURL {
            spinner?.startAnimating()
            let qos = Int(QOS_CLASS_USER_INITIATED.value) // legacy qos variable stuff
            dispatch_async(dispatch_get_global_queue(qos, 0)) {
                let imageData = NSData(contentsOfURL: url)
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    if url == self.imageURL {           // is captured url out of date?
                        if imageData != nil {
                            self.image = UIImage(data: imageData!)  // self needs explicit ref inside closure
                        } else {
                            self.image = nil
                        }
                    }
                }
            }

        }
    }
    private var imageView = UIImageView()
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.contentSize = imageView.frame.size
            scrollView.delegate = self
            scrollView.minimumZoomScale = 0.03
            scrollView.maximumZoomScale = 1.0
        }
    }
    
    private var image: UIImage? {
        get {return imageView.image}
        set {
            imageView.image=newValue
            imageView.sizeToFit()
            scrollView?.contentSize = imageView.frame.size
            spinner?.stopAnimating()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.addSubview(imageView)
    }
    
    // actually get the image data iff the view is going to be shown
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if image == nil {
            fetchImage()
        }
    }
}
