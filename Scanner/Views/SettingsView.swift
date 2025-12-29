//
//  SettingsView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Settings")
                    .font(.largeTitle)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
