//
//  SlideUpSheetBaseViewController.swift
//  
//
//  Created by Amr Mohamed on 11/02/2023.
//

import UIKit

open class SlideUpSheetBaseViewController: UIViewController {
    public convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        transitioningDelegate = self
        modalPresentationStyle = .custom
    }
}

extension SlideUpSheetBaseViewController: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        SlideUpSheetPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
