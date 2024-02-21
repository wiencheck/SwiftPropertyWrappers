//
//  ContentView.swift
//  SwiftPropertyWrappersExample
//
//  Created by Adam Wienconek on 08/11/2023.
//

import SwiftUI
import SwiftPropertyWrappers

struct ContentView: View {
    
    @UserDefaultsStorage("test_value", defaultValue: false)
    var value: Bool
    
    var body: some View {
        VStack {
            Text("Value is \(value.stringValue)")
            Button(action: {
                value.toggle()
            }, label: {
                Text("Toggle")
            })
        }
        .padding()
    }
    
}

extension Bool {
    
    var stringValue: String {
        self ? "true" : "false"
    }
    
}

#Preview {
    ContentView()
}
