//
//  DisambiguationView.swift
//  SafeWay London
//

import SwiftUI

/// Shown when TfL found more than one place for the text. The user picks one for
/// each unclear side and then the journey request is sent again.
struct DisambiguationView: View {
    let disambiguation: JourneyDisambiguation
    let onResolve: (_ origin: JourneyLocationCandidate?, _ destination: JourneyLocationCandidate?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedOrigin: JourneyLocationCandidate?
    @State private var selectedDestination: JourneyLocationCandidate?

    private var originCandidates: [JourneyLocationCandidate] { disambiguation.origin ?? [] }
    private var destinationCandidates: [JourneyLocationCandidate] { disambiguation.destination ?? [] }

    private var canContinue: Bool {
        (originCandidates.isEmpty || selectedOrigin != nil) &&
        (destinationCandidates.isEmpty || selectedDestination != nil)
    }

    var body: some View {
        NavigationStack {
            List {
                if !originCandidates.isEmpty {
                    Section("Which starting point did you mean?") {
                        ForEach(originCandidates) { candidate in
                            CandidateRow(candidate: candidate, isSelected: selectedOrigin == candidate) {
                                selectedOrigin = candidate
                            }
                        }
                    }
                }

                if !destinationCandidates.isEmpty {
                    Section("Which destination did you mean?") {
                        ForEach(destinationCandidates) { candidate in
                            CandidateRow(candidate: candidate, isSelected: selectedDestination == candidate) {
                                selectedDestination = candidate
                            }
                        }
                    }
                }
            }
            .navigationTitle("Confirm location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        onResolve(selectedOrigin, selectedDestination)
                    }
                    .disabled(!canContinue)
                }
            }
        }
    }
}

private struct CandidateRow: View {
    let candidate: JourneyLocationCandidate
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(candidate.displayName)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DisambiguationView(
        disambiguation: JourneyDisambiguation(
            origin: [
                JourneyLocationCandidate(name: "Kings Cross, Camden", lat: 51.5308, lon: -0.1238),
                JourneyLocationCandidate(name: "Kings Cross St Pancras Station", lat: 51.5300, lon: -0.1240),
            ],
            destination: nil
        )
    ) { _, _ in }
}
