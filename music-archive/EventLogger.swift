//
//  EventLogger.swift
//  music-archive
//
//  Created by Ben Kamen on 2/2/25.
//

import SwiftUI

struct LogEvent: Identifiable {
    let id = UUID()
    let date: Date
    let message: String
    let isError: Bool
    let firstOfDay: Bool
}

@MainActor
class EventLogger: ObservableObject {
    @Published var events: [LogEvent] = []
    
    func log(_ message: String, isError: Bool = false) {
        let now = Date()
        // Check if any event already exists on the same day.
        let isFirstOfDay = !events.contains { Calendar.current.isDate($0.date, inSameDayAs: now) }
        let event = LogEvent(date: now, message: message, isError: isError, firstOfDay: isFirstOfDay)
        events.insert(event, at: 0)
    }
}

extension DateFormatter {
    static let dateOnly: DateFormatter = {
       let formatter = DateFormatter()
       formatter.dateStyle = .short
       formatter.timeStyle = .none
       return formatter
    }()
    
    static let timeOnly: DateFormatter = {
       let formatter = DateFormatter()
       formatter.dateStyle = .none
       formatter.timeStyle = .medium
       return formatter
    }()
}


