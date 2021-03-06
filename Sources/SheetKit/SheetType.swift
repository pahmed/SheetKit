//
//  SheetType.swift
//  
//
//  Created by Ahmed Ibrahim on 22/01/2022.
//

import UIKit

protocol SheetDelegate: AnyObject {
    func didSelectDetent(_ detent: Detent)
}

public struct Header {
    let viewController: UIViewController
    let height: CGFloat
    
    public init(viewController: UIViewController, height: CGFloat) {
        self.viewController = viewController
        self.height = height
    }
}

protocol SheetType {
    init(header: Header?, body: UIViewController)
    
    func present(in container: UIViewController)
    
    func setDetent(_ detent: Detent, animated: Bool)
    
    var delegate: SheetDelegate? { get set }
}
