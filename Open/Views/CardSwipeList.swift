//
//  CardSwipeList.swift
//  Open
//
//  Created by John McAvey on 3/20/20.
//  Copyright © 2020 John McAvey. All rights reserved.
//

import Foundation
import SwiftUI

enum Kind {
    case accept
    case reject
}

struct AcceptButton: View {
    let onAccept: () -> Void
    
    var body: some View {
        Button(action: onAccept) {
            Image.confirm
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.green)
        }
    }
}

struct RejectButton: View {
    let onReject: () -> Void
    
    var body: some View {
        Button(action: onReject) {
            Image.reject
                .resizable()
                .frame(width: 30, height: 38)
                .foregroundColor(.red)
        }
    }
}

struct SwipeRow<Value>: View {
    let value: Value
    let handler: (Value, Kind) -> Void
    
    var body: some View {
        HStack {
            RejectButton() { self.handler(self.value, .reject) }
            Spacer()
            AcceptButton() { self.handler(self.value, .accept) }
        }
    }
}

struct SwipeCard<Value: Identifiable, Content: View>: View {
    let value: Value
    let handler: (Value, Kind) -> Void
    let inner: (Value) -> Content
    
    var body: some View {
        Card {
            VStack {
                self.inner(value)
                Spacer()
                SwipeRow(value: value, handler: handler)
                    .padding()
            }
        }
        .swipable(onAccept: { self.handler(self.value, .accept) },
                  onReject: { self.handler(self.value, .reject) })
    }
}

struct CardSwipeList<Value: Identifiable, Content: View>: View {
    let values: [Value]
    let handler: (Value, Kind) -> Void
    let inner: (Value) -> Content
    
    init(values: [Value], handler: @escaping (Value, Kind) -> Void, inner: @escaping (Value) -> Content) {
        self.values = values
        self.inner = inner
        self.handler = handler
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .center) {
                ForEach(self.values) { value in
                    SwipeCard(value: value, handler: self.handler, inner: self.inner)
                        .frame(width: 300, height: 300)
                        .padding([.leading, .trailing])
                }
            }
        }
    }
}

struct CardSwipeList_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SwipeCard(value: "Hello", handler: {_, _ in }) { _ in
                Text("Hello!")
            }
            .frame(width: 200, height: 200)
            PreviewView()
        }
    }
}
