//
//  OnboardingView.swift
//  music-archive
//
//  Created by Ben Kamen on 2/5/25.
//
import SwiftUI

struct OnboardingView: View {
    
    var body: some View {
        
        VStack(alignment: .leading, content: {
            Text("How to Use")
                .font(.headline)
            Text("Right click on a file in the Finder, and click on 'Tags'.")
                .font(.body)
            Text("Create a new tag called 'archive' and add the tag to any files you wish to show up in the music archive.")
                .font(.body)
        })
        
    }
    
    
}

#Preview {
    OnboardingView()
}
