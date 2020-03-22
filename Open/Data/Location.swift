//
//  Location.swift
//  Open
//
//  Created by John McAvey on 3/20/20.
//  Copyright © 2020 John McAvey. All rights reserved.
//

import Foundation

public struct Address: Codable {
    
}

protocol Location {
    var address: Address { get }
    var name: String { get }
    var description: String { get }
    
    func open(at: Date) -> Bool
}

extension Location {
    public var isOpen: Bool {
        get {
            return open(at: Date())
        }
    }
}
