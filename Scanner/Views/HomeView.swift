//
//  HomeView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Home")
                    .font(.largeTitle)
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}
