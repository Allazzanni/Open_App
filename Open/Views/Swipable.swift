//
//  Swipable.swift
//  Open
//
//  Created by John McAvey on 3/20/20.
//  Copyright © 2020 John McAvey. All rights reserved.
//

import Foundation
import SwiftUI

struct Swipable<Content: View>: ViewModifier {
    let onAccept: () -> Void
    let onReject: () -> Void
    
    func body(content: _ViewModifier_Content<Swipable<Content>>) -> some View {
        SwipeView(content: content, onAccept: self.onAccept, onReject: self.onReject)
    }
}

extension View {
    func swipable(onAccept: @escaping () -> Void, onReject: @escaping () -> Void) -> some View {
        let modifier = Swipable<Self>(onAccept: onAccept, onReject: onReject)
        return self.modifier(modifier)
    }
}

struct SwipeView<Content: View>: View {
    let content: Content
    let onAccept: () -> Void
    let onReject: () -> Void
    
    @State var showAccept: Bool = false
    @State var showReject: Bool = false
    @State private var translation: CGSize = .zero
    
    private var thresholdPercentage: CGFloat = 0.35
    private var displayThresholdPercentage: CGFloat = 0.15
    
    init(content: Content, onAccept: @escaping () -> Void, onReject: @escaping () -> Void) {
        self.content = content
        self.onAccept = onAccept
        self.onReject = onReject
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                self.content
                if self.showAccept {
                    Image.confirm
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.green)
                } else if self.showReject {
                    Image.reject
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.red)
                }
            }
            .offset(x: self.translation.width, y: self.translation.height)
            .gesture(self.drag(in: geometry))
            .rotationEffect(self.rotationOffset(from: geometry), anchor: .bottom)
        }
    }
    
    func rotationOffset(from geometry: GeometryProxy) -> Angle {
        let scalar: Double = 40
        return .degrees(Double(self.translation.width / geometry.size.width) * scalar)
    }
    
    private func shouldCommit(_ geometry: GeometryProxy, from gesture: DragGesture.Value) -> Bool {
        return abs(self.getGesturePercentage(geometry, from: gesture)) > self.thresholdPercentage
    }
    
    private func isAccept(_ geometry: GeometryProxy, from gesture: DragGesture.Value) -> Bool {
        return shouldCommit(geometry, from: gesture) && towardsAccept(geometry, from: gesture)
    }
    
    private func isReject(_ geometry: GeometryProxy, from gesture: DragGesture.Value) -> Bool {
        return shouldCommit(geometry, from: gesture) && towardsReject(geometry, from: gesture)
    }
    
    private func towardsAccept(_ geometry: GeometryProxy, from gesture: DragGesture.Value) -> Bool {
        let pct = self.getGesturePercentage(geometry, from: gesture)
        return  pct > 0 && abs(pct) > displayThresholdPercentage
    }
    
    private func towardsReject(_ geometry: GeometryProxy, from gesture: DragGesture.Value) -> Bool {
        let pct = self.getGesturePercentage(geometry, from: gesture)
        return  pct < 0 && abs(pct) > displayThresholdPercentage
    }
    
    private func getGesturePercentage(_ geometry: GeometryProxy, from gesture: DragGesture.Value) -> CGFloat {
        gesture.translation.width / geometry.size.width
    }
    
    func drag(in geometry: GeometryProxy) -> some Gesture {
        DragGesture()
        .onChanged { value in
            self.translation = value.translation
            withAnimation {
                self.showAccept = self.towardsAccept(geometry, from: value)
                self.showReject = self.towardsReject(geometry, from: value)
            }
        }.onEnded { value in
            self.showAccept = false
            self.showReject = false
            
            if self.isReject(geometry, from: value) {
                self.onReject()
            } else if self.isAccept(geometry, from: value) {
                self.onAccept()
            } else {
                self.translation = .zero
            }
        }
    }
}

extension String: Identifiable {
    public var id: Int { self.hashValue }
}

struct PreviewView: View {
    @State var entries: [String] = [
        "One",
        "Two",
        "Three",
        "Four",
        "Five",
        "Six",
        "Seven",
        "Eight",
        "Nine",
        "Ten",
        "Eleven"
    ]
    var body: some View {
        CardSwipeList(values: self.entries, handler: self.handle) { value in
            Text(value)
        }
    }
    
    func handle(value: String, kind: Kind) {
        switch kind {
        case .accept:
            print("Accepted \(value)")
            self.remove(string: value)
        case .reject:
            print("Rejected \(value)")
            self.remove(string: value)
        }
    }
    
    func remove(string: String) {
        let _ = self.entries.firstIndex(of: string).map { index in
            withAnimation {
                self.entries.remove(at: index)
            }
        }
    }
}

struct SwipeView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewView()
    }
}

