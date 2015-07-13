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
            let qos = Int(QOS_CLASS_USER_INITIATED.rawValue) // legacy qos variable stuff
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
            if newValue != nil {
                zoomToFit(scrollView!.superview!.frame.width)
            }
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
    
    var mustInitializeZoom = true
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        mustInitializeZoom = false
    }
    
    // called prior to an orientation change
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        zoomToFit(size.width)
    }
    
    func zoomToFit(viewWidth: CGFloat) {
        if mustInitializeZoom {
            if let iw = imageView.image?.size.width {
                 scrollView.zoomScale = viewWidth / iw  // this will cause the mustInitializeZoom flag to clear
            }
        }
        // zoomToFit is not permitted to clear the mustInitializeZoom flag
        // only a user-initiated zoom should do this
        mustInitializeZoom=true
    }

}
