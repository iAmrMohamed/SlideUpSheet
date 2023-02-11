//
//  SheetSharedTransitioningDelegate.swift
//  
//
//  Created by Amr Mohamed on 11/02/2023.
//

import UIKit

public class SheetSharedTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        SheetPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        defer { Self.shared.removeAll(where: { $0 == self }) }
        return nil
    }
    
    public static var shared = [SheetSharedTransitioningDelegate]()
    public static func sharedDelegate() -> SheetSharedTransitioningDelegate? {
        let controller = SheetSharedTransitioningDelegate()
        Self.shared.append(controller)
        return controller
    }
}

