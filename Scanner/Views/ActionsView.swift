//
//  ActionsView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct ActionsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Actions")
                    .font(.largeTitle)
            }
            .navigationTitle("Actions")
        }
    }
}

#Preview {
    ActionsView()
}
