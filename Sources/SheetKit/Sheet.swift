//
//  Sheet.swift
//  
//
//  Created by Ahmed Ibrahim on 22/01/2022.
//

import Foundation
import UIKit

public enum Detent {
    case small
    case medium
    case large
}

enum Constants {
    enum Grapper {
        static let width: CGFloat = 40
        static let height: CGFloat = 5
        static var cornerRadius = height / 2
        
        static let margin: CGFloat = 8
    }
}

public class Sheet: UIViewController, SheetType {
    let header: Header?
    let body: UIViewController
    var topAnchor: NSLayoutConstraint!
    var scrollView: UIScrollView?
    var container: UIViewController!
    weak var delegate: SheetDelegate?
    
    let defaultTopMargin: CGFloat = 120
    
    var currentDetent: Detent = .large
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    
    public required init(header: Header? = nil, body: UIViewController) {
        self.header = header
        self.body = body
        
        super.init(nibName: nil, bundle: nil)
        
        setupViews()
        style()
    }
    
    public func present(in container: UIViewController) {
        self.container = container
        container.addChild(self)
        container.view.addSubview(view)
        self.didMove(toParent: container)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.leadingAnchor.constraint(equalTo: container.view.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: container.view.trailingAnchor).isActive = true
        view.heightAnchor.constraint(equalToConstant: container.view.bounds.height).isActive = true
                
        topAnchor = view.topAnchor.constraint(equalTo: container.view.topAnchor, constant: defaultTopMargin)
        topAnchor.isActive = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.setupGestureRecognizer()
        }
        
        setDetent(.medium, animated: false)
    }
    
    public func setDetent(_ detent: Detent, animated: Bool) {
        setDetent(detent, animationVelocity: 0, animated: animated)
    }
    
    // MARK: - Internal
    
    func setDetent(_ detent: Detent, animationVelocity velocity: CGFloat, animated: Bool = true) {
        
        currentDetent = detent
        let margin = marginForDetent(currentDetent)
        
//        let distanceToTravel = abs(margin - topAnchor.constant)
//        let initialSpringVelocity = velocity > 0 ? velocity / distanceToTravel : 0
        
        let updateBlock = {
            self.topAnchor.constant = margin
            self.container.view.layoutIfNeeded()
            self.body.view.alpha = detent == .small ? 0 : 1
        }
        
        if animated {
            UIView.animate(
                withDuration: 0.65,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0,
                options: [.allowUserInteraction],
                animations: updateBlock,
                completion: nil
            )
        } else {
            updateBlock()
        }
        
        delegate?.didSelectDetent(detent)
    }
    
    func style() {
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.backgroundColor = .systemBackground
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    func setupViews() {
        // Setup Grapper
        let grapperMargin = Constants.Grapper.margin
        let grapper = grapperView()
        view.addSubview(grapper)
        grapper.layer.cornerRadius = Constants.Grapper.cornerRadius
        grapper.translatesAutoresizingMaskIntoConstraints = false
        grapper.heightAnchor.constraint(equalToConstant: Constants.Grapper.height).isActive = true
        grapper.widthAnchor.constraint(equalToConstant: Constants.Grapper.width).isActive = true
        grapper.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        grapper.topAnchor.constraint(equalTo: view.topAnchor, constant: grapperMargin).isActive = true
        
        // Setup Header
        if let header = header {
            let vc = header.viewController
            addChild(vc)
            view.addSubview(vc.view)
            vc.didMove(toParent: self)
            
            // Setup header constraints
            vc.view.translatesAutoresizingMaskIntoConstraints = false
            
            vc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            vc.view.topAnchor.constraint(equalTo: grapper.bottomAnchor, constant: grapperMargin).isActive = true
            vc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            vc.view.heightAnchor.constraint(equalToConstant: header.height).isActive = true
        }
        
        addChild(body)
        view.addSubview(body.view)
        body.didMove(toParent: self)
        
        // Setup body constraints
        body.view.translatesAutoresizingMaskIntoConstraints = false
        
        body.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        body.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        body.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        if let header = header {
            body.view.topAnchor.constraint(equalTo: header.viewController.view.bottomAnchor).isActive = true
//            header.viewController.view.bottomAnchor.constraint(equalTo: body.view.topAnchor).isActive = true
        } else {
            body.view.topAnchor.constraint(equalTo: grapper.bottomAnchor, constant: grapperMargin).isActive = true
        }
    }
    
    func grapperView() -> UIView {
        let view = UIView()
        view.backgroundColor = .tertiaryLabel
        return view
    }
    
    func setupGestureRecognizer() {
        scrollView = findScrollView()
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(recognizer:)))
        recognizer.delegate = self
        recognizer.requiresExclusiveTouchType = false
        scrollView?.addGestureRecognizer(recognizer)
        
        scrollView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: defaultTopMargin, right: 0)
        
        if let header = header {
            let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(recognizer:)))
            recognizer.delegate = self
            recognizer.requiresExclusiveTouchType = false
            header.viewController.view.addGestureRecognizer(recognizer)
        }
        
        setupViewGestureRecognizer(for: view)
    }
    
    func setupViewGestureRecognizer(for view: UIView) {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(recognizer:)))
        recognizer.delegate = self
        recognizer.requiresExclusiveTouchType = false
        view.addGestureRecognizer(recognizer)
    }
    
    @objc
    func handlePan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .failed:
            print("failed")
            fallthrough
        case .cancelled:
            print("cancelled")
            fallthrough
        case .ended:
            print("ended")
            landOnTheNearestDetent(velocity: recognizer.velocity(in: nil).y)
            
            // Rest scrolling position (based on the below condition) only if the gesture was on a scroll view
            if recognizer.view is UIScrollView {
                let largeDetentMargin = marginForDetent(.large)
                if let scrollView = scrollView, scrollView.contentOffset.y <= 0 || topAnchor.constant > largeDetentMargin {
                    // Do this to avoid letting the scroll view continue scrolling after
                    // the end of gesture
                    scrollView.setContentOffset(.zero, animated: false)
                }
            }
        case .changed:
            let translation = recognizer.translation(in: nil).y
            
            if recognizer.view is UIScrollView {
                let largeDetentMargin = marginForDetent(.large)
                if let scrollView = scrollView, scrollView.contentOffset.y <= 0 || topAnchor.constant > largeDetentMargin {
                    topAnchor.constant += translation
                    scrollView.contentOffset.y = 0
                }
            } else {
                topAnchor.constant += translation
            }
            
            recognizer.setTranslation(.zero, in: nil)
        case .possible:
            print("possible")
        case .began:
            print("began")
        @unknown default:
            fatalError()
        }
    }
    
    func landOnTheNearestDetent(velocity: CGFloat) {
        setDetent(closestDetent(), animationVelocity: velocity)
    }
    
    func findScrollView() -> UIScrollView? {
        return findScrollView(in: body.view)
    }
    
    func findScrollView(in view: UIView) -> UIScrollView? {
        if view is UIScrollView { return view as? UIScrollView }
        
        for subview in view.subviews {
            if let scrollView = findScrollView(in: subview) {
                return scrollView
            }
        }
        
        return nil
    }
    
    func closestDetent() -> Detent {
        let currentPosition = topAnchor.constant
        
        // Sort by distance and then return the closest detent
        
        let items: [Pair<Detent, CGFloat>] = [
            Pair(a: Detent.small, b: abs(currentPosition - marginForDetent(.small))),
            Pair(a: Detent.medium, b: abs(currentPosition - marginForDetent(.medium))),
            Pair(a: Detent.large, b: abs(currentPosition - marginForDetent(.large))),
        ]
        
        return items.sorted(by: { $0.b < $1.b })[0].a
        
    }
    
    func marginForDetent(_ detent: Detent) -> CGFloat {
        switch detent {
        case .large:
            return defaultTopMargin
        case .medium:
            return container.view.bounds.height / 2
        case .small:
            return container.view.bounds.height - 100
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    
}

extension Sheet: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view is UIScrollView {
            return true // To avoid conflict with UIScrollView gesture
        }
        return false
    }
}
