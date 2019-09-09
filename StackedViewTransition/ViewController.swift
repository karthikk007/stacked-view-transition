//
//  ViewController.swift
//  StackedViewTransition
//
//  Created by Karthik on 06/09/19.
//  Copyright © 2019 Karthik. All rights reserved.
//

import UIKit

enum CardState {
    case expanded
    case collapsed
}

extension CardState {
    var opposite: CardState {
        switch self {
        case .expanded:
            return .collapsed
        case .collapsed:
            return .expanded
        }
    }
}

class ViewController: UIViewController {
    

    
    let cardHandleAreaHeight: CGFloat = 40
    let cardHeight: CGFloat = 650.0

    var cardViewController: CardViewController!
    var visualEffectView: UIVisualEffectView!
    
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgress = [CGFloat]()
    
    var currentState = CardState.collapsed
    var animatingState = CardState.collapsed

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupCard()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }


    func setupCard() {
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = view.frame
        self.view.addSubview(visualEffectView)
        
        cardViewController = CardViewController(nibName: "CardViewController", bundle: nil)
        
        self.addChild(cardViewController)
        self.view.addSubview(cardViewController.view)
        
        cardViewController.view.frame = CGRect(x: 0, y: self.view.frame.height - cardHandleAreaHeight, width: self.view.frame.width, height: cardHeight)
        
        cardViewController.view.clipsToBounds = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(sender:)))
        
        cardViewController.topHandleView.addGestureRecognizer(tapGestureRecognizer)
        cardViewController.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc
    func handleTap(sender: UITapGestureRecognizer) {
        switch sender.state {
        case .ended:
            animateTransitionIfNeeded(to: currentState.opposite, duration: 1.0)
        default:
            break
        }
    }
    
    @objc
    func handlePan(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            startInteractiveTransition(state: currentState.opposite, duration: 5.0)
        case .changed:
            let translation = sender.translation(in: self.cardViewController.view)


            var fractionComplete = -translation.y / (cardHeight - cardHandleAreaHeight)

            print("xx fractionComplete = \(fractionComplete)")

            if currentState == .expanded { fractionComplete *= -1 }
            if runningAnimations[0].isReversed { fractionComplete *= -1 }

            print("fractionComplete = \(fractionComplete)")
            print("runningAnimations[0].isReversed = \(runningAnimations[0].isReversed)")
            print("runningAnimations[0].fractionComplete = \(runningAnimations[0].fractionComplete)")

            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:

            let translation = sender.translation(in: self.cardViewController.view)
            print("ended translation.y = \(translation.y)")
            let yVelocity = sender.velocity(in: cardViewController.view).y

            if yVelocity == 0 {
                runningAnimations.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
                break
            }

            var shouldReverseAnimation = false
            switch currentState {
            case .expanded:
                if yVelocity < 0 {
                    shouldReverseAnimation = true
                }
            case .collapsed:
                if yVelocity > 0 {
                    shouldReverseAnimation = true
                }
            }

            continueInteractiveTransition(reverseAnimation: shouldReverseAnimation)
        default:
            break
        }
    }
    
    func continueInteractiveTransition(reverseAnimation: Bool) {
        
        runningAnimations.forEach { $0.isReversed = reverseAnimation }
        
        runningAnimations.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
    }
    
    func updateInteractiveTransition(fractionCompleted: CGFloat) {
        for (index, animation) in runningAnimations.enumerated() {
            animation.fractionComplete = fractionCompleted + animationProgress[index]
        }
        
        print("animationProgress[0] = \(animationProgress[0])")
    }
    
    func startInteractiveTransition(state: CardState, duration: TimeInterval) {
        // start the animations
        animateTransitionIfNeeded(to: currentState.opposite, duration: 1)
        
        // pause all animations, since the next event may be a pan changed
        runningAnimations.forEach { $0.pauseAnimation() }
        
        // keep track of each animator's progress
        animationProgress = runningAnimations.map { $0.fractionComplete }
    }
    
    func animateTransitionIfNeeded(to state: CardState, duration: TimeInterval) {
        
        guard runningAnimations.isEmpty else {
            if animatingState == state {
                runningAnimations.forEach { $0.isReversed = !$0.isReversed }
            }
            return
        }
        
        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1.0) {
            switch state {
            case .expanded:
                self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHeight + 20
                self.cardViewController.view.layer.cornerRadius = 25
                self.visualEffectView.effect = UIBlurEffect(style: .dark)
                self.cardViewController.topHandleView.backgroundColor = .white
                self.cardViewController.visualEffectView.alpha = 0.7
            case .collapsed:
                self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHandleAreaHeight
                self.cardViewController.view.layer.cornerRadius = 0
                self.visualEffectView.effect = nil
                self.cardViewController.topHandleView.backgroundColor = .black
                self.cardViewController.visualEffectView.alpha = 1.0
            }
            
            self.view.layoutIfNeeded()
        }
        
        animator.addCompletion { (animatingPosition) in
            
            switch animatingPosition {
            case .start:
                //                self.currentState = state.opposite
                break
            case .end:
                self.currentState = state
            case .current:
                break
            @unknown default:
                break
            }
            
            self.animatingState = self.currentState
            self.runningAnimations.removeAll()
        }
        
        runningAnimations.append(animator)
        animator.startAnimation()
        
        animatingState = state
    }
}


//// MARK: - InstantPanGestureRecognizer
///// A pan gesture that enters into the `began` state on touch down instead of waiting for a touches moved event.
//class InstantPanGestureRecognizer: UIPanGestureRecognizer {
//
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
//        if (self.state == UIGestureRecognizer.State.began) { return }
//        super.touchesBegan(touches, with: event)
//        self.state = UIGestureRecognizer.State.began
//    }
//
//}
