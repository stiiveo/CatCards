//
//  Strings.swift
//  CatAndDog
//
//  Created by Jason Ou Yang on 2020/12/17.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import Foundation

struct Z {
    struct OnboardingLabel {
        static let cardGesture = NSLocalizedString("CARD_GESTURE", comment: "Hint of card swiping gesture")
        static let shareButton = NSLocalizedString("SHARE_BUTTON", comment: "Sharing button")
        static let undoButton = NSLocalizedString("UNDO_BUTTON", comment: "Undo the last card")
        static let saveButton = NSLocalizedString("SAVE_BUTTON", comment: "Saving image button")
        static let browseButton = NSLocalizedString("BROWSE_IMAGES", comment: "Browse saved images")
        static let blessLabel = NSLocalizedString("SHARE_BUTTON", comment: "Bless the user")
    }
    
    struct AlertMessage {
        struct NetworkError {
            static let alertTitle = NSLocalizedString("NETWORK_ERROR_ALERT_TITLE", comment: "")
            static let alertMessage = NSLocalizedString("NETWORK_ERROR_ALERT_MESSAGE", comment: "")
            static let actionTitle = NSLocalizedString("NETWORK_ERROR_ALERT_ACTION", comment: "")
        }
        
        struct DatabaseError {
            static let alertTitle = NSLocalizedString("DATABASE_ERROR_ALERT_TITLE", comment: "")
            static let alertMessage = NSLocalizedString("DATABASE_ERROR_ALERT_MESSAGE", comment: "")
            static let actionTitle = NSLocalizedString("DATABASE_ERROR_ALERT_ACTION", comment: "")
        }
        
        struct DeleteWarning {
            static let alertTitle = NSLocalizedString("DELETE_WARNING_ALERT_TITLE", comment: "")
            static let actionTitle = NSLocalizedString("DELETE_WARNING_ALERT_ACTION", comment: "")
            static let cancelTitle = NSLocalizedString("DELETE_WARNING_ALERT_CANCEL", comment: "")
        }
    }
    
    struct BackgroundView {
        static let noDataLabel = NSLocalizedString("NO_DATA_LABEL_TEXT", comment: "")
    }
}
