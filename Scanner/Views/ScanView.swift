//
//  ScanView.swift
//  Scanner
//
//  Created by Matthew Houston on 12/28/25.
//

import SwiftUI

struct ScanView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Scan")
                    .font(.largeTitle)
            }
            .navigationTitle("Scan")
        }
    }
}

#Preview {
    ScanView()
}
