//
//  music_archiveApp.swift
//  music-archive
//
//  Created by Ben Kamen on 1/31/25.
//

import SwiftUI

@main
struct music_archiveApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
