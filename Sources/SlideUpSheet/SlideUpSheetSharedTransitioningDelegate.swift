//
//  SlideUpSheetSharedTransitioningDelegate.swift
//  
//
//  Created by Amr Mohamed on 11/02/2023.
//

import UIKit

public class SlideUpSheetSharedTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        SlideUpSheetPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        defer { Self.shared.removeAll(where: { $0 == self }) }
        return nil
    }
    
    public static var shared = [SlideUpSheetSharedTransitioningDelegate]()
    public static func sharedDelegate() -> SlideUpSheetSharedTransitioningDelegate? {
        let controller = SlideUpSheetSharedTransitioningDelegate()
        Self.shared.append(controller)
        return controller
    }
}

