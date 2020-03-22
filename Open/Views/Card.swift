//
//  Card.swift
//  Open
//
//  Created by John McAvey on 3/20/20.
//  Copyright © 2020 John McAvey. All rights reserved.
//

import Foundation
import SwiftUI

struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

extension View {
    func card() -> some View {
        Card() {
            self
        }
    }
}

struct Card_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello!")
            .frame(width: 100, height: 100)
            .card()
    }
}
