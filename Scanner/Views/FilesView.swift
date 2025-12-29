//
//  FilesView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct FilesView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Files")
                    .font(.largeTitle)
            }
            .navigationTitle("Files")
        }
    }
}

#Preview {
    FilesView()
}
