//
//  YAMVolCricleLayer.swift
//  YAMAudioDemo
//
//  Created by 杨清晖 on 2018/4/9.
//  Copyright © 2018年 杨清晖. All rights reserved.
//

import UIKit

class YAMVolCricleLayer: CALayer, CAAnimationDelegate {

    var circleLayer: CAShapeLayer!
    
    init(size: CGSize) {
        
        super.init()
     
        circleLayer = CAShapeLayer()
        let path = UIBezierPath(arcCenter: CGPoint(x: size.width/2.0, y: size.height/2.0),
                                radius: size.width/2.0,
                                startAngle: 0,
                                endAngle: CGFloat(2 * Double.pi),
                                clockwise: false)
        circleLayer.backgroundColor = nil
//        circleLayer.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        circleLayer.fillColor = UIColor.green.withAlphaComponent(0.5).cgColor
        circleLayer.path = path.cgPath
        self.addSublayer(circleLayer)
    }
    
    func begin() {
        self.circleLayer.opacity = 1.0
    }
    
    func startRecorder(with value: Float) {
        let radius = self.frame.width * CGFloat(value * 5)

        let path = UIBezierPath(arcCenter: CGPoint(x: self.frame.width/2.0, y: self.frame.height/2.0),
                                radius: radius/2.0,
                                startAngle: 0,
                                endAngle: CGFloat(2 * Double.pi),
                                clockwise: false)
        circleLayer.path = path.cgPath
//        circleLayer.frame = CGRect(x: (w - self.frame.width)/2, y: (h - self.frame.height)/2, width: w, height: h)
    }
    
    func endRecorder(size: CGSize) {
        
//        let path = UIBezierPath(arcCenter: CGPoint(x: size.width/2.0, y: size.height/2.0),
//                                radius: size.width/2.0,
//                                startAngle: 0,
//                                endAngle: CGFloat(2 * Double.pi),
//                                clockwise: false)
//////
//////
//        self.circleLayer.path = path.cgPath
        

        let ani = CABasicAnimation(keyPath: "opacity")
        ani.delegate = self
        ani.duration = 0.3
        ani.fromValue = 0.5
        ani.toValue = 0
        ani.isRemovedOnCompletion = false
        ani.fillMode = kCAFillModeForwards
        self.circleLayer.add(ani, forKey: nil)
        
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        circleLayer.removeAllAnimations()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
