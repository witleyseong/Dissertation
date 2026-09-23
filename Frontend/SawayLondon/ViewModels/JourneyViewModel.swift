//
//  JourneyViewModel.swift
//  SafeWay London
//

import Foundation

@Observable
final class JourneyViewModel {
    var journeys: [Journey] = []
    var isLoading = false
    var error: String?
    var lastSearchFrom: String = ""
    var lastSearchTo: String = ""

    /// Set when TfL found more than one place for the text. The UI asks the user to pick one.
    var pendingDisambiguation: JourneyDisambiguation?

    // the from/to of the last request, so a picked place is sent together with the same text
    private var pendingFrom: String = ""
    private var pendingTo: String = ""

    private let sessionStore: SessionStore

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }

    /// Plan journey from origin to destination
    @MainActor
    func planJourney(from: String, to: String) async {
        guard !from.isEmpty, !to.isEmpty else {
            error = "Please enter origin and destination"
            return
        }

        isLoading = true
        error = nil
        journeys = []
        pendingDisambiguation = nil
        pendingFrom = from
        pendingTo = to

        #if DEBUG
        print("Planning journey - From: \(from), To: \(to)")
        #endif

        do {
            let token = sessionStore.getToken()
            let response = try await JourneyAPI.planJourney(from: from, to: to, token: token)

            if let disambiguation = response.disambiguation {
                pendingDisambiguation = disambiguation
            } else if response.journeys.isEmpty {
                error = response.message ?? "No routes found for these locations"
            } else {
                journeys = response.journeys
                lastSearchFrom = from
                lastSearchTo = to
            }

            isLoading = false
        } catch let apiError as APIError {
            if case .unauthorized = apiError {
                sessionStore.handleUnauthorized()
                error = "Your session has expired. Please sign in again."
            } else {
                error = apiError.localizedDescription
            }
            isLoading = false
        } catch {
            self.error = "Error fetching routes: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Sends the request again after the user picks a place (uses the picked coordinates and keeps the text for the other side)
    @MainActor
    func resolveDisambiguation(origin: JourneyLocationCandidate?, destination: JourneyLocationCandidate?) async {
        let resolvedFrom = origin.map { "\($0.lat),\($0.lon)" } ?? pendingFrom
        let resolvedTo = destination.map { "\($0.lat),\($0.lon)" } ?? pendingTo
        await planJourney(from: resolvedFrom, to: resolvedTo)
    }
}

