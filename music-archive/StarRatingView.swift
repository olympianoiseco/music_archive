//
//  StarRatingView.swift
//  music-archive
//
//  Created by Ben Kamen on 2/2/25.
//

import SwiftUI

struct StarRatingView: View {
    let file: URL
    @State private var rating: Int = 0

    init(file: URL) {
        self.file = file
        // Retrieve the current rating (defaulting to 0 if none)
        if let existing = ArchiveMetadata.getRating(for: file) {
            _rating = State(initialValue: existing)
        } else {
            _rating = State(initialValue: 0)
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(star <= rating ? .yellow : .gray)
                    .onTapGesture {
                        do {
                            try ArchiveMetadata.setRating(for: file, rating: star)
                            rating = star
                        } catch {
                            print("Failed to set rating: \(error.localizedDescription)")
                        }
                    }
            }
        }
    }
}
