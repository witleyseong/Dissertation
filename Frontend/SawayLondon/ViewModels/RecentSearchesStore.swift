//
//  RecentSearchesStore.swift
//  SafeWay London
//

import Foundation

@Observable
final class RecentSearchesStore {
    private(set) var searches: [RecentSearch] = []
    private let maxSearches = 8
    private let key = "recentSearches"
    
    init() {
        loadSearches()
    }
    
    /// Add a new search to the list
    func addSearch(from: String, to: String) {
        // Remove duplicate if exists (by from|to)
        searches.removeAll { $0.from == from && $0.to == to }
        
        // Add to front
        let newSearch = RecentSearch(from: from, to: to)
        searches.insert(newSearch, at: 0)
        
        // Keep only max searches
        if searches.count > maxSearches {
            searches = Array(searches.prefix(maxSearches))
        }
        
        saveSearches()
    }
    
    /// Clear all recent searches
    func clearAll() {
        searches = []
        saveSearches()
    }
    
    /// Remove a specific search
    func removeSearch(_ search: RecentSearch) {
        searches.removeAll { $0.id == search.id }
        saveSearches()
    }
    
    // MARK: - Persistence
    
    private func loadSearches() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([RecentSearch].self, from: data) else {
            return
        }
        searches = decoded
    }
    
    private func saveSearches() {
        if let encoded = try? JSONEncoder().encode(searches) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
