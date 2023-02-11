//
//  SheetPresentationController.swift
//
//  Copyright (c) 2020 Amr Mohamed (https://github.com/iAmrMohamed)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import Combine

public class SheetPresentationController: UIPresentationController {
    private struct Constants {
        static let dismissVelocityLimit = CGFloat(500)
        static let handleViewSize = CGSize(width: 50, height: 5)
    }
    
    private var isKeyboardVisible = false
    private var keyboardHeight = CGFloat()
    
    private var observers = Set<AnyCancellable>()
    
    public var scrollView: UIScrollView?
    public var allowsDismissing = true
    
    /// The background dimming view
    public lazy var dimmingView: UIView = {
        let view = UIView()
        view.alpha = 0.0
        view.backgroundColor = UIColor(white: 0.0, alpha: 1 / 3)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// The bottom rubbing view sets underneath the presentedView
    /// gives the sheet the rubbing effect when pulled up
    private lazy var rubbingView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var handleView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.layer.backgroundColor = #colorLiteral(red: 0.8980392157, green: 0.8980392157, blue: 0.9176470588, alpha: 1).cgColor
        view.layer.cornerRadius = Constants.handleViewSize.height / 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    public override var shouldPresentInFullscreen: Bool {
        true
    }
    
    public override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    public override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        registerKeyboardObservers()
        
        if let presentedView {
            setupPresentedView(presentedView)
            setupHandleView(presentedView: presentedView)
        }
        
        if let containerView {
            setupDimmingView(containerView: containerView)
            setupRubbingView(containerView: containerView)
            addDismissTapGestureOnDimmingView()
        }
        
        presentedViewController.preferredContentSize = presentingViewController.view.frame.size
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1.0
        })
    }
    
    public override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        rubbingView.removeFromSuperview()
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.0
        })
    }
    
    public override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        var frame = containerView.frame
        
        if isKeyboardVisible { frame.size.height -= max(0, keyboardHeight) }
        
        var height: CGFloat
        if let scrollView = scrollView {
            let contentSize = scrollView.contentSize.height + scrollView.adjustedContentInset.top + scrollView.adjustedContentInset.bottom
            height = min(frame.height * 0.9, contentSize)
        } else {
            height = min(frame.height * 0.9, presentedViewController.preferredContentSize.height)
        }
        
        if let nav = presentedViewController as? UINavigationController {
            height += nav.navigationBar.bounds.height + 100
        }
        
        frame.origin.y = frame.size.height - height
        frame.size.height = height
        return frame
    }
    
    public override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        guard let presentedView, presentedView.transform.isIdentity else {
            return
        }
        
        if presentedViewController.isBeingPresented || presentedViewController.isBeingDismissed {
            presentedView.frame = frameOfPresentedViewInContainerView
        } else {
            UIView.animate(withDuration: 1 / 3, delay: 0, options: [.layoutSubviews], animations: {
                self.presentedView?.frame = self.frameOfPresentedViewInContainerView
            })
        }
    }
    
    public override func preferredContentSizeDidChange(forChildContentContainer _: UIContentContainer) {
        containerView?.setNeedsLayout()
    }
    
    public override func systemLayoutFittingSizeDidChange(forChildContentContainer _: UIContentContainer) {
        containerView?.setNeedsLayout()
    }
}

extension SheetPresentationController {
    private func setupPresentedView(_ presentedView: UIView) {
        presentedView.layer.cornerRadius = 15.0
        presentedView.layer.masksToBounds = true
        presentedView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        if #available(iOS 13.0, *) {
            presentedView.layer.cornerCurve = .continuous
        }
        
        addDismissPanGestureTo(view: presentedView)
        if let view = containerView { addDismissPanGestureTo(view: view) }
        
        if let scrollView = presentedView.subviews.first as? UIScrollView {
            setupTackingScrollView(scrollView)
        } else if
            let nav = presentedViewController as? UINavigationController,
            let scrollView = nav.topViewController?.view.subviews.first as? UIScrollView
        {
            setupTackingScrollView(scrollView)
        }
    }
}

extension SheetPresentationController {
    private func addDismissPanGestureTo(view: UIView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panning))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }
}

// MARK: - Tacking ScrollView

extension SheetPresentationController {
    public func setupTackingScrollView(_ scrollView: UIScrollView) {
        self.scrollView = scrollView
        scrollView.contentInsetAdjustmentBehavior = .always
        scrollView.layoutIfNeeded()
        scrollView.publisher(for: \.contentSize).sink { [weak self] size in
            self?.containerView?.setNeedsLayout()
        }.store(in: &observers)
    }
}

// MARK: - DimmingView Setup

extension SheetPresentationController {
    private func setupDimmingView(containerView: UIView) {
        containerView.insertSubview(dimmingView, at: 0)
        
        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func addDismissTapGestureOnDimmingView() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissPresentedVC))
        dimmingView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissPresentedVC() {
        guard allowsDismissing else { return }
        presentedViewController.dismiss(animated: true)
    }
}

// MARK: - RubbingView Setup

extension SheetPresentationController {
    private func setupRubbingView(containerView: UIView) {
        rubbingView.backgroundColor = presentedView?.backgroundColor
        
        containerView.addSubview(rubbingView)
        
        var frame = containerView.frame
        frame.origin.y = frame.maxY - 1
        rubbingView.frame = frame
    }
}

// MARK: - HandleView Setup

extension SheetPresentationController {
    private func setupHandleView(presentedView: UIView) {
        presentedView.addSubview(handleView)
        
        NSLayoutConstraint.activate([
            handleView.topAnchor.constraint(equalTo: presentedView.topAnchor, constant: 10),
            handleView.centerXAnchor.constraint(equalTo: presentedView.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: Constants.handleViewSize.width),
            handleView.heightAnchor.constraint(equalToConstant: Constants.handleViewSize.height)
        ])
    }
}

// MARK: - Panning Gesture Recognizer

private extension SheetPresentationController {
    @objc func panning(_ pan: UIPanGestureRecognizer) {
        guard let containerView = self.containerView, let presentedView = self.presentedView else {
            return
        }
        
        let velocity = pan.velocity(in: containerView)
        let translation = pan.translation(in: containerView)
        
        switch pan.state {
        case .began, .changed:
            
            let newTranslation = CGAffineTransform(translationX: 0, y: {
                if self.allowsDismissing {
                    return translation.y > 0 ? translation.y : translation.y / 15
                } else {
                    return translation.y / 15
                }
            }())
            
            presentedView.transform = newTranslation
            rubbingView.transform = newTranslation
            
            let progress = 1 - (translation.y / presentedView.frame.height)
            dimmingView.alpha = max(0.0, min(1.0, progress))
            
        case .ended, .cancelled, .failed:
            guard allowsDismissing else {
                snapPresentedViewToOriginalFrame()
                return
            }
            
            let reachedDismissTranslation = translation.y > presentedView.frame.height / 2
            let reachedDismissVelocity = velocity.y > Constants.dismissVelocityLimit
            
            if reachedDismissTranslation || reachedDismissVelocity {
                presentedViewController.dismiss(animated: true) {
                    self.presentedView?.transform = .identity
                    self.rubbingView.transform = .identity
                }
            } else {
                snapPresentedViewToOriginalFrame()
            }
            
        default: break
        }
    }
    
    private func snapPresentedViewToOriginalFrame() {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.65,
            initialSpringVelocity: 0.5,
            options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                self.presentedView?.transform = .identity
                self.rubbingView.transform = .identity
                self.dimmingView.alpha = 1.0
            }, completion: { _ in
            }
        )
    }
}

// MARK: - UIGestureRecognizerDelegate

extension SheetPresentationController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let scrollView = scrollView else {
            return true
        }
        
        guard scrollView.isTracking else {
            // That means that touches was outside the scrollView
            // So we need to return true to begin this pan gesture
            return true
        }
        
        if scrollView.isAtTop && pan.direction == .down || scrollView.isAtBottom && pan.direction == .up {
            return true
        }
        
        if pan.direction == .left || pan.direction == .right {
            return false
        }
        
        return false
    }
    
    public func gestureRecognizer(_: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        scrollView?.panGestureRecognizer == otherGestureRecognizer
    }
}

private extension SheetPresentationController {
    func registerKeyboardObservers() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard
            let info = notification.userInfo,
            let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        
        switch notification.name {
        case UIResponder.keyboardWillShowNotification:
            isKeyboardVisible = true
            keyboardHeight = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        case UIResponder.keyboardWillHideNotification:
            keyboardHeight = 0
            isKeyboardVisible = false
        case UIResponder.keyboardWillChangeFrameNotification:
            keyboardHeight = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
        default: break
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: .init(rawValue: curve), animations: {
            self.presentedView?.frame = self.frameOfPresentedViewInContainerView
        })
    }
}
