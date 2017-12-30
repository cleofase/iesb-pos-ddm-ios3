//
//  PulseActivityIndicator.swift
//  CnesApp
//
//  Created by Cleofas Pereira on 29/12/2017.
//  Copyright © 2017 Cleofas Pereira. All rights reserved.
//

import Foundation
import UIKit

class PulseActivityIndicator {
    private var baseView: UIView?
    private var pulseView: UIImageView?
    
    func show(at view: UIView) {
        self.baseView = view
        
        let xImageView = view.bounds.width / 2 - 20
        let yImageView = view.bounds.height / 2 - 20
        pulseView = UIImageView(frame: CGRect(x: xImageView, y: yImageView, width: 33, height: 33))
        pulseView!.alpha = 0.5
        
        let pulseImage = UIImage(named: "heart_with_pulse_filled")
        pulseView!.image = pulseImage
        
        view.addSubview(pulseView!)
        
        UIView.animate(withDuration: 0.3,
                       delay: 0, options: [.repeat, .autoreverse, .curveEaseIn], animations: {[unowned self] in
                        self.pulseView!.transform = CGAffineTransform(scaleX: 2, y: 2)}, completion: nil)
    }
    
    func hide() {
        guard let _ = pulseView else {return}
        DispatchQueue.main.async {[weak self] in
            guard let _ = self else {return}
            self!.pulseView!.removeFromSuperview()
        }
    }
}
