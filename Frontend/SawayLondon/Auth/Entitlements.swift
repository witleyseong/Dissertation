//
//  Entitlements.swift
//  SafeWay London
//

import Foundation

/// Plan tiers for feature gating
enum PlanTier: String {
    case free
    case premium
    
    init(from userPlan: String) {
        switch userPlan.lowercased() {
        case "premium":
            self = .premium
        default:
            self = .free
        }
    }
}

/// Features that can be gated by plan
enum Feature {
    case compareRoutes          // Basic feature (free)
    case unlimitedComparisons   // Free for now, could be gated later
    case savedRouteHistory      // Future premium
    case crimeFilters           // Future premium
    case customExposureBuffer   // Future premium
    case advancedAnalytics      // Future premium
}

/// Check if user is entitled to a feature
func isEntitled(to feature: Feature, plan: PlanTier) -> Bool {
    switch feature {
    case .compareRoutes, .unlimitedComparisons:
        // Currently free for all
        return true
        
    case .savedRouteHistory, .crimeFilters, .customExposureBuffer, .advancedAnalytics:
        // Future premium features
        return plan == .premium
    }
}
