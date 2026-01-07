//
//  ContentView.swift
//  CodeMask
//
//  Created by Edison on 2026/1/5.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gear")
                .imageScale(.large)
                .font(.system(size: 40))
            
            Text("CodeMask Settings")
                .font(.title)
            
            Text("Settings implementation coming in Epic 3.")
                .foregroundStyle(.secondary)
        }
        .padding(50)
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    ContentView()
}
