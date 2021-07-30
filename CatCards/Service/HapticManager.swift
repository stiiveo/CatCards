//
//  HapticManager.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2021/2/2.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import UIKit

final class HapticManager {
    
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Public
    
    func vibrateForSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepareForInterfaceBuilder()
        generator.selectionChanged()
    }
    
    func vibrate(for type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
}
