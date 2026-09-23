//
//  SupportResource.swift
//  SafeWay London
//

import Foundation

/// Represents a support resource action
enum SupportAction: Equatable {
    case phone(number: String)
    case website(URL)
}

/// Model for a support resource card
struct SupportResource: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let systemImage: String
    let actionTitle: String
    let action: SupportAction
    let websiteURL: URL?
    let isEmergency: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        systemImage: String,
        actionTitle: String,
        action: SupportAction,
        websiteURL: URL? = nil,
        isEmergency: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
        self.websiteURL = websiteURL
        self.isEmergency = isEmergency
    }
}

/// Confirmation dialog information
struct SupportConfirmation: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
}
