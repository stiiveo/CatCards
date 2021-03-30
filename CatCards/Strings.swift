//
//  Strings.swift
//  CatCards
//
//  Created by Jason Ou Yang on 2020/12/17.
//  Copyright © 2020 Jason Ou Yang. All rights reserved.
//

import Foundation

struct Z {
    struct Onboard {
        static let greetTitle = NSLocalizedString("GREET_TITLE", comment: "Greeting")
        static let greet_1 = NSLocalizedString("GREET_1", comment: "Greet message 1")
        static let greet_2 = NSLocalizedString("GREET_2", comment: "Greet message 2")
        static let zoomGestureTitle = NSLocalizedString("ZOOM_GESTURE_TITLE", comment: "Title of zooming gesture instruction")
        static let zoomInstruction = NSLocalizedString("HOW_TO_ZOOM_IN", comment: "Instruction of how to zoom in the picture")
        static let buttonInstruction = NSLocalizedString("BUTTON_TITLE", comment: "Usage of all UI buttons")
        static let shareButton = NSLocalizedString("SHARE_BUTTON", comment: "Usage of all UI buttons")
        static let undoButton = NSLocalizedString("UNDO_BUTTON", comment: "Usage of all UI buttons")
        static let saveButton = NSLocalizedString("SAVE_BUTTON", comment: "Usage of all UI buttons")
        static let showDownloadsButton = NSLocalizedString("VIEW_SAVED", comment: "View saved images")
        static let continuePrompt = NSLocalizedString("PROMPT", comment: "Prompt message")
        static let finalPrompt = NSLocalizedString("START_PROMPT", comment: "Prompt to start")
    }
    
    struct AlertMessage {
        struct APIError {
            static let alertTitle = NSLocalizedString("API_ERROR_ALERT_TITLE", comment: "")
            static let alertMessage = NSLocalizedString("API_ERROR_ALERT_MESSAGE", comment: "")
            static let actionTitle = NSLocalizedString("API_ERROR_ALERT_ACTION", comment: "")
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
