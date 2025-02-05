//
//  AppContext.swift
//  music-archive
//
//  Created by Ben Kamen on 2/4/25.
//
import SwiftUI
import CoreData
import AppKit

struct AppContext {
    
    @StateObject private var audioManager = AudioManager()
    @StateObject private var metadataSearch = MetadataSearch()
    @StateObject private var eventLogger = EventLogger()
    @StateObject private var playlistStore = PlaylistStore()
    
}
