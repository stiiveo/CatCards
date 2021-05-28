//
//  DelegateExtensions.swift
//  CatCards
//
//  Created by Jason Ou on 2021/5/28.
//  Copyright © 2021 Jason Ou Yang. All rights reserved.
//

import UIKit

extension HomeVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let pan = currentCard?.panGR
        let twoFingerPan = currentCard?.twoFingerPanGR
        let pinch = currentCard?.pinchGR
        let tap = currentCard?.tapGR
        
        let conditions: [Bool] = [
            gestureRecognizer == pinch && otherGestureRecognizer == pan,
            gestureRecognizer == twoFingerPan && otherGestureRecognizer == pan,
            gestureRecognizer == tap && otherGestureRecognizer == pan,
            gestureRecognizer == tap && otherGestureRecognizer == twoFingerPan,
            gestureRecognizer == tap && otherGestureRecognizer == pinch
        ]
        for condition in conditions where condition == true {
            return true
        }
        
        return false
    }
}

extension HomeVC: DataManagerDelegate {
    /// Number of saved images has reached the limit.
    func savedImagesMaxReached() {
        // Show alert to the user
        let alert = UIAlertController(title: Z.AlertMessage.DatabaseError.alertTitle,
                                      message: Z.AlertMessage.DatabaseError.alertMessage,
                                      preferredStyle: .alert)
        let acknowledgeAction = UIAlertAction(title: Z.AlertMessage.DatabaseError.actionTitle,
                                              style: .cancel)
        alert.addAction(acknowledgeAction)
        
        present(alert, animated: true, completion: nil)
    }
}

