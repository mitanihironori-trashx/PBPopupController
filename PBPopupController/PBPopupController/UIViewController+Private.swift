//
//  UIViewController+Private.swift
//  PBPopupController
//
//  Created by Patrick BODET on 15/04/2018.
//  Copyright © 2018 Patrick BODET. All rights reserved.
//

import Foundation
import UIKit
import ObjectiveC

//_setContentOverlayInsets:
private let sCoOvBase64 = "X3NldENvbnRlbnRPdmVybGF5SW5zZXRzOg=="
//_updateContentOverlayInsetsFromParentIfNecessary
private let uCOIFPINBase64 = "X3VwZGF0ZUNvbnRlbnRPdmVybGF5SW5zZXRzRnJvbVBhcmVudElmTmVjZXNzYXJ5"
//_hideBarWithTransition:isExplicit:
private let hBWTiEBase64 = "X2hpZGVCYXJXaXRoVHJhbnNpdGlvbjppc0V4cGxpY2l0Og=="
//_showBarWithTransition:isExplicit:
private let sBWTiEBase64 = "X3Nob3dCYXJXaXRoVHJhbnNpdGlvbjppc0V4cGxpY2l0Og=="
//_setToolbarHidden:edge:duration:
private let sTHedBase64 = "X3NldFRvb2xiYXJIaWRkZW46ZWRnZTpkdXJhdGlvbjo="
//hideBarWithTransition:
private let hBWTBase64 = "aGlkZUJhcldpdGhUcmFuc2l0aW9uOg=="
//showBarWithTransition:
private let sBWTBase64 = "c2hvd0JhcldpdGhUcmFuc2l0aW9uOg=="

public extension UITabBarController
{
    private static let swizzleImplementation: Void = {
        let instance = UITabBarController.self()
        
        let aClass: AnyClass! = object_getClass(instance)
        
        var originalMethod: Method!
        var swizzledMethod: Method!
        
        originalMethod = class_getInstanceMethod(aClass, #selector(setViewControllers(_ :animated:)))
        swizzledMethod = class_getInstanceMethod(aClass, #selector(pb_setViewControllers(_ :animated:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        //_hideBarWithTransition:isExplicit:
        var selName = _PBPopupDecodeBase64String(base64String: hBWTiEBase64)!
        var selector = NSSelectorFromString(selName)
        originalMethod = class_getInstanceMethod(aClass, selector)
        swizzledMethod = class_getInstanceMethod(aClass, #selector(_hBWT(t:iE:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        //_showBarWithTransition:isExplicit:
        selName = _PBPopupDecodeBase64String(base64String: sBWTiEBase64)!
        selector = NSSelectorFromString(selName)
        originalMethod = class_getInstanceMethod(aClass, selector)
        swizzledMethod = class_getInstanceMethod(aClass, #selector(_sBWT(t:iE:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()
    
    /**
     :nodoc:
     */
    @objc static func tbc_swizzle() {
        _ = self.swizzleImplementation
    }
    
    //_hideBarWithTransition:isExplicit:
    @objc private func _hBWT(t: Int, iE: Bool) {
        self.isTabBarHiddenDuringTransition = true
        
        self._hBWT(t: t, iE: iE)
        
        if (t > 0) {
            let rv = objc_getAssociatedObject(self, &AssociatedKeys.popupBar) as? PBPopupBar
            if (rv != nil) {
                if popupController.popupPresentationState != .hidden {
                    var duration: TimeInterval = 0.35
                    if let coordinator = self.selectedViewController?.transitionCoordinator {
                        duration = coordinator.transitionDuration
                    }
                    var insets: UIEdgeInsets = .zero
                    if #available(iOS 11.0, *) {
                        insets = self.view.window?.safeAreaInsets ?? .zero
                    }
                    
                    UIView.animate(withDuration: duration) {
                        self.popupController.popupBarView.frame = self.popupController.popupBarViewFrameForPopupStateClosed()
                        self.popupController.popupBarView.frame.origin.y -= insets.bottom
                        self.popupController.popupBarView.frame.size.height += insets.bottom
                    }
                }
                self.bottomBar.isHidden = true
            }
        }
    }

    //_showBarWithTransition:isExplicit:
    @objc private func _sBWT(t: Int, iE: Bool) {
        self.isTabBarHiddenDuringTransition = false
        
        self._sBWT(t: t, iE: iE)
        
        if (t > 0) {
            if let rv = objc_getAssociatedObject(self, &AssociatedKeys.popupBar) as? PBPopupBar {
                if popupController.popupPresentationState != .hidden {
                    self.selectedViewController?.transitionCoordinator?.animate(alongsideTransition: { (_ context) in
                        self.popupController.popupBarView.frame = self.popupController.popupBarViewFrameForPopupStateClosed()
                        rv.layoutIfNeeded()
                    }, completion: { (_ context) in
                        if context.isCancelled {
                            self.isTabBarHiddenDuringTransition = true
                            UIView.animate(withDuration: 0.15) {
                                self.popupController.popupBarView.frame = self.popupController.popupBarViewFrameForPopupStateClosed()
                                rv.layoutIfNeeded()
                            }
                        }
                        self.bottomBar.isHidden = context.isCancelled ? true : false
                    })
                }
            }
        }
    }

    @objc private func pb_setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        if #available(iOS 11.0, *) {
            for obj in viewControllers {
                let additionalInsets = UIEdgeInsets(top: 0, left: 0, bottom: self.viewControllers?.first?.additionalSafeAreaInsets.bottom ?? 0.0, right: 0)
                _LNPopupSupportFixInsetsForViewController(obj, false, additionalInsets)
            }
        }
        self.pb_setViewControllers(viewControllers, animated: animated)
    }
}

internal extension UITabBarController
{
    @objc override func _animateBottomBarToHidden( _ hidden: Bool) {
        let height = self.tabBar.frame.height
        if height > 0.0 {
            if hidden == false {
                var frame = tabBar.frame
                frame.origin.y = self.view.bounds.height - height
                self.tabBar.center = frame.center
                //self.tabBar.frame.origin.y = self.view.bounds.height - height
            }
            else {
                self.tabBar.frame.origin.y = self.view.bounds.height
            }
        }
    }
    
    @objc override func _setBottomBarPosition( _ position: CGFloat) {
        let height = self.tabBar.frame.height
        if height > 0.0 {
            self.tabBar.frame.origin.y = position
        }
    }
    
    @objc override func insetsForBottomBar() -> UIEdgeInsets {
        if #available(iOS 11.0, *) {
            if let bottomBarInsets = self.popupController.dataSource?.popupController?(self.popupController, insetsFor: self.bottomBar) {
                return bottomBarInsets
            }
            return self.tabBar.isHidden == false ? UIEdgeInsets.zero : self.view.window?.safeAreaInsets ?? UIEdgeInsets.zero
        } else {
            return UIEdgeInsets.zero
        }
    }
    
    @objc override func defaultFrameForBottomBar() -> CGRect {
        var bottomBarFrame = self.tabBar.frame
        let bottomBarSizeThatFits = self.tabBar.sizeThatFits(CGSize.zero)
        
        bottomBarFrame.size.height = max(bottomBarFrame.size.height, bottomBarSizeThatFits.height)
        
        bottomBarFrame.origin = CGPoint(x: 0, y: self.view.bounds.size.height - (self.isTabBarHiddenDuringTransition ? 0.0 : bottomBarFrame.size.height))

        return bottomBarFrame
    }
}

public extension UINavigationController
{
    private static let swizzleImplementation: Void = {
        let instance = UINavigationController.self()
        
        let aClass: AnyClass! = object_getClass(instance)
        
        var originalMethod: Method!
        var swizzledMethod: Method!
        
        originalMethod = class_getInstanceMethod(aClass, #selector(pushViewController(_ :animated:)))
        swizzledMethod = class_getInstanceMethod(aClass, #selector(pb_pushViewController(_ :animated:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        originalMethod = class_getInstanceMethod(aClass, #selector(setViewControllers(_ :animated:)))
        swizzledMethod = class_getInstanceMethod(aClass, #selector(pb_setViewControllers(_ :animated:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        //_setToolbarHidden:edge:duration:
        var selName = _PBPopupDecodeBase64String(base64String: sTHedBase64)!
        var selector = NSSelectorFromString(selName)
        originalMethod = class_getInstanceMethod(aClass, selector)
        swizzledMethod = class_getInstanceMethod(aClass, #selector(_sTH(h:e:d:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()
    
    /**
     :nodoc:
     */
    @objc static func nc_swizzle() {
        _ = self.swizzleImplementation
    }

    //_setToolbarHidden:edge:duration:
    @objc private func _sTH(h: Bool, e: UInt, d: CGFloat) {
        if let rv = objc_getAssociatedObject(self, &AssociatedKeys.popupBar) as? PBPopupBar {
            if popupController.popupPresentationState != .hidden {
                self.popupController.popupBarView.frame = self.popupController.popupBarViewFrameForPopupStateClosed()
                
                self._sTH(h: h, e: e, d: d)
                self.bottomBar.isHidden = h

                if let coordinator = self.transitionCoordinator {
                    coordinator.animate(alongsideTransition: { (_ context) in
                        self.popupController.popupBarView.frame = self.popupController.popupBarViewFrameForPopupStateClosed()
                        rv.layoutIfNeeded()
                    }) { (_ context) in
                    }
                }
            }
            else {
                self._sTH(h: h, e: e, d: d)
            }
        }
        else {
            self._sTH(h: h, e: e, d: d)
        }
    }

    @objc private func pb_pushViewController(_ viewController: UIViewController, animated: Bool)
    {
        if #available(iOS 11.0, *) {
            if let svc = self.parent as? UISplitViewController {
                if let vc = svc.viewControllers.first, let rv = objc_getAssociatedObject(vc, &AssociatedKeys.popupBar) as? PBPopupBar, !rv.isHidden {
                    let additionalInsets = UIEdgeInsets(top: 0, left: 0, bottom: rv.popupBarHeight, right: 0)
                    _LNPopupSupportFixInsetsForViewController(viewController, false, additionalInsets)
                }
                let additionalInsets = UIEdgeInsets(top: 0, left: 0, bottom: svc.additionalSafeAreaInsets.bottom, right: 0)
                _LNPopupSupportFixInsetsForViewController(svc, false, additionalInsets)
            }
            else {
                let additionalInsets = UIEdgeInsets(top: 0, left: 0, bottom: self.topViewController?.additionalSafeAreaInsets.bottom ?? 0.0, right: 0)
                _LNPopupSupportFixInsetsForViewController(viewController, false, additionalInsets)
            }
        }
        self.pb_pushViewController(viewController, animated: animated)
    }
    
    @objc private func pb_setViewControllers(_ viewControllers: [UIViewController], animated: Bool)
    {
        if #available(iOS 11.0, *) {
            for obj in viewControllers {
                let additionalInsets = UIEdgeInsets(top: 0, left: 0, bottom: self.topViewController?.additionalSafeAreaInsets.bottom ?? 0.0, right: 0)
                _LNPopupSupportFixInsetsForViewController(obj, false, additionalInsets)
            }
        }
        self.pb_setViewControllers(viewControllers, animated: animated)
    }
}

internal extension UINavigationController
{
    @objc override func _animateBottomBarToHidden( _ hidden: Bool) {
        var height = self.toolbar.frame.height
        if let tabBarController = self.tabBarController {
            height += tabBarController.defaultFrameForBottomBar().height
        }
        
        let insets = self.insetsForBottomBar()

        if height > 0.0 {
            if hidden == false {
                self.toolbar.frame.origin.y = self.view.bounds.height - height - insets.bottom
            }
            else {
                self.toolbar.frame.origin.y = self.view.bounds.height
            }
            
            if let tabBarController = self.tabBarController {
                tabBarController._animateBottomBarToHidden(hidden)
            }
        }
    }
    
    @objc override func _setBottomBarPosition( _ position: CGFloat) {
        let height = self.toolbar.frame.height
        if height > 0.0 {
            self.toolbar.frame.origin.y = position
        }
    }
    
    @objc override func insetsForBottomBar() -> UIEdgeInsets {
        if #available(iOS 11.0, *) {
            if let tabBarController = self.tabBarController, tabBarController.isTabBarHiddenDuringTransition == false {
                return tabBarController.insetsForBottomBar()
            }
            return self.view.window?.safeAreaInsets ?? UIEdgeInsets.zero
        } else {
            return UIEdgeInsets.zero
        }
    }
    
    @objc override func defaultFrameForBottomBar() -> CGRect {
        var toolBarFrame = self.toolbar.frame
        
        toolBarFrame.origin = CGPoint(x: 0, y: self.view.bounds.height - (self.isToolbarHidden ? 0.0 : toolBarFrame.size.height))

        if let tabBarController = self.tabBarController {
            let tabBarFrame = tabBarController.defaultFrameForBottomBar()
            toolBarFrame.origin.y -= tabBarController.isTabBarHiddenDuringTransition ? 0.0 : tabBarFrame.height
        }
        
        return toolBarFrame
    }
}

public extension UIViewController
{
    private static let swizzleImplementation: Void = {
        let instance = UIViewController.self()
        
        let aClass: AnyClass! = object_getClass(instance)
        
        var originalMethod: Method!
        var swizzledMethod: Method!
        
        #if !targetEnvironment(macCatalyst)
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 11 {
            //_setContentOverlayInsets:
            var selName = _PBPopupDecodeBase64String(base64String: sCoOvBase64)!
            var selector = NSSelectorFromString(selName)
            originalMethod = class_getInstanceMethod(aClass, selector)
            swizzledMethod = class_getInstanceMethod(aClass, #selector(_sCoOvIns(insets:)))
            if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
        else {
            //_updateContentOverlayInsetsFromParentIfNecessary
            var selName = _PBPopupDecodeBase64String(base64String: uCOIFPINBase64)!
            var selector = NSSelectorFromString(selName)
            originalMethod = class_getInstanceMethod(aClass, selector)
            swizzledMethod = class_getInstanceMethod(aClass, #selector(_uCOIFPIN))
            if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
        #else
        var selName = _PBPopupDecodeBase64String(base64String: uCOIFPINBase64)!
        var selector = NSSelectorFromString(selName)
        originalMethod = class_getInstanceMethod(aClass, selector)
        swizzledMethod = class_getInstanceMethod(aClass, #selector(_uCOIFPIN))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        #endif

        originalMethod = class_getInstanceMethod(aClass, #selector(addChild(_:)))
        swizzledMethod = class_getInstanceMethod(aClass, #selector(pb_addChild(_ :)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
        
        originalMethod = class_getInstanceMethod(aClass, #selector(viewWillTransition(to:with:)))
        swizzledMethod = class_getInstanceMethod(aClass, #selector(pb_viewWillTransition(to:with:)))
        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()
    
    /**
     :nodoc:
     */
    @objc static func vc_swizzle() {
        _ = self.swizzleImplementation
    }
    
    //_setContentOverlayInsets:
    @objc private func _sCoOvIns(insets: UIEdgeInsets) {
        var newInsets = insets
        newInsets.bottom += self.additionalSafeAreaInsetsBottomForContainer
        if let rv = objc_getAssociatedObject(self, &AssociatedKeys.popupBar) as? PBPopupBar {
            if !(rv.isHidden) && self.popupController.popupPresentationState != .dismissing {
                newInsets.bottom += rv.frame.height
                self._sCoOvIns(insets:newInsets)
            }
            else {
                self._sCoOvIns(insets:newInsets)
            }
        }
        else {
            self._sCoOvIns(insets:newInsets)
        }
    }

    //_updateContentOverlayInsetsFromParentIfNecessary
    @objc private func _uCOIFPIN() {
        self._uCOIFPIN()
    }
    
    internal func pb_popupController() -> PBPopupController! {
        let rv = PBPopupController(containerViewController: self)
        self.popupController = rv
        return rv
    }

    @objc private func pb_addChild(_ viewController: UIViewController)
    {
        self.pb_addChild(viewController)

        if self.additionalSafeAreaInsetsBottomForContainer > 0 {
            let additionalInsets = UIEdgeInsets(top: 0, left: 0, bottom: self.additionalSafeAreaInsetsBottomForContainer, right: 0)
            if #available(iOS 11.0, *) {
                if self.additionalSafeAreaInsets.bottom == 0 {
                    _LNPopupSupportFixInsetsForViewController(self, false, additionalInsets)
                }
            }
            else {
                _LNPopupSupportFixInsetsForViewController(self, false, additionalInsets)
            }
        }

        if #available(iOS 11.0, *) {
            if let svc = self as? UISplitViewController {
                if let vc1 = svc.viewControllers.first, let rv = objc_getAssociatedObject(vc1, &AssociatedKeys.popupBar) as? PBPopupBar, !rv.isHidden {
                    if let vc2 = svc.viewControllers.last {
                        let additionalInsets = UIEdgeInsets(top: 0, left: 0, bottom: -rv.popupBarHeight, right: 0)
                        _LNPopupSupportFixInsetsForViewController(vc2, false, additionalInsets)
}
                }
                let additionalInsets = UIEdgeInsets(top: 0, left: 0, bottom: svc.additionalSafeAreaInsets.bottom, right: 0)
                _LNPopupSupportFixInsetsForViewController(svc, false, additionalInsets)
            }
            else {
                let additionalInsets = UIEdgeInsets(top: 0, left: 0, bottom: self.additionalSafeAreaInsets.bottom, right: 0)
                _LNPopupSupportFixInsetsForViewController(viewController, false, additionalInsets)
            }
        }
    }
    
    private func viewWillTransitionToSize(_ size: CGSize,  with coordinator: UIViewControllerTransitionCoordinator) {
        if let rv = objc_getAssociatedObject(self, &AssociatedKeys.popupBar) as? PBPopupBar {
            if self.popupController.popupPresentationState != .dismissing {
                self.popupController.popupBarView.frame = self.popupController.popupPresentationState == .hidden ? self.popupController.popupBarViewFrameForPopupStateHidden() :  self.popupController.popupBarViewFrameForPopupStateClosed()
            }
            if self.popupController.popupPresentationState == .closed {
                self.popupContentView.frame = self.popupController.popupBarViewFrameForPopupStateClosed()
                self.popupContentViewController.view.frame.origin = self.popupContentView.frame.origin
                self.popupContentViewController.view.frame.size = CGSize(width: self.popupContentView.frame.size.width, height: self.view.frame.height)
            }
            
            rv.setNeedsUpdateConstraints()
            rv.setNeedsLayout()
            rv.layoutIfNeeded()
        }
    }

    @objc private func pb_viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.pb_viewWillTransition(to: size, with: coordinator)
        if (objc_getAssociatedObject(self, &AssociatedKeys.popupBar) as? PBPopupBar) != nil {
            coordinator.animate(alongsideTransition: {(_ context: UIViewControllerTransitionCoordinatorContext) -> Void in
                self.viewWillTransitionToSize(size, with: coordinator)
                
            }, completion: {(_ context: UIViewControllerTransitionCoordinatorContext) -> Void in
                // Fix for split view controller layout issue
                if let rv = objc_getAssociatedObject(self, &AssociatedKeys.popupBar) as? PBPopupBar {
                    rv.layoutSubviews()
                }
            })
        }
    }
    
    internal func _cleanupPopup() {
        PBLog("_cleanupPopup")
        objc_setAssociatedObject(self, &AssociatedKeys.popupContentViewController, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &AssociatedKeys.popupContentView, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &AssociatedKeys.bottomBar, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &AssociatedKeys.popupBar, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &AssociatedKeys.popupController, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &AssociatedKeys.popupContainerViewController, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

internal extension UIViewController
{
    @objc func _animateBottomBarToHidden( _ hidden: Bool) {
        let height = self.popupController.bottomBarHeight
        
        let insets = self.insetsForBottomBar()
        
        if height > 0.0 {
            if hidden == false {
                self.bottomBar.frame.origin.y = self.view.bounds.height - height - insets.bottom
            }
            else {
                self.bottomBar.frame.origin.y = self.view.bounds.height
            }
        }
    }
    
    @objc func _setBottomBarPosition( _ position: CGFloat) {
        let height = self.popupController.bottomBarHeight
        if height > 0.0 {
            self.bottomBar.frame.origin.y = position
        }
    }
    
    @objc func insetsForBottomBar() -> UIEdgeInsets {
        var insets: UIEdgeInsets = .zero
        if #available(iOS 11.0, *) {
            insets = self.view.window?.safeAreaInsets ?? UIEdgeInsets.zero
        }
        if self.popupController.dataSource?.bottomBarView?(for: self.popupController) != nil {
            if let bottomBarInsets = self.popupController.dataSource?.popupController?(self.popupController, insetsFor: self.bottomBar) {
                insets = bottomBarInsets
            }
        }
        return insets
    }
    
    @objc func defaultFrameForBottomBar() -> CGRect {
        var bottomBarFrame = CGRect(x: 0.0, y: self.view.bounds.size.height, width: self.view.bounds.size.width, height: 0.0)
        if let bottomBarView = self.popupController.dataSource?.bottomBarView?(for: self.popupController) {
            if let defaultFrame = self.popupController.dataSource?.popupController?(self.popupController, defaultFrameFor: self.bottomBar) {
                return defaultFrame
            }
            else {
                bottomBarFrame = bottomBarView.frame
            }
        }
        bottomBarFrame.origin = CGPoint(x: bottomBarFrame.origin.x, y: self.view.bounds.height - (self.bottomBar.isHidden ? 0.0 : bottomBarFrame.size.height))
        return bottomBarFrame
    }
}
