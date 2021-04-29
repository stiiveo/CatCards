//
//  HapticManager.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/2/2.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import UIKit

final class HapticManager {
    var impactHaptic: UIImpactFeedbackGenerator? = nil
    var notificationHaptic: UINotificationFeedbackGenerator? = nil
    
    func prepareImpactGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        impactHaptic = UIImpactFeedbackGenerator(style: style)
        impactHaptic?.prepare()
    }
    
    func prepareNotificationGenerator() {
        notificationHaptic = UINotificationFeedbackGenerator()
        notificationHaptic?.prepare()
    }
    
    func releaseImpactGenerator() {
        impactHaptic = nil
    }
    
    func releaseNotificationGenerator() {
        notificationHaptic = nil
    }
}
