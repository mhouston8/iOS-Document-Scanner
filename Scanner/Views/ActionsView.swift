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
            AllActionsView()
                .navigationTitle("Document Tools")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ActionsView()
}
