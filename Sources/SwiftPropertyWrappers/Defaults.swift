//
//  Storage.swift
//  Plum
//
//  Created by Adam Wienconek on 13/12/2021.
//  Copyright © 2021 adam.wienconek. All rights reserved.
//

import Foundation
import Combine

@propertyWrapper
public struct Defaults<Value> {
    
    private let key: String
    private let defaultValue: Value
    private let container: UserDefaults
    private let valueSubject: PassthroughSubject<Value, Never> = .init()

    public init(key: String, defaultValue: Value, container: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.container = container
    }
    
    public var wrappedValue: Value {
        get {
            container.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            let value = newValue as Any
            if let _value = value as? Value {
                container.set(_value, forKey: key)
            }
            else {
                container.removeObject(forKey: key)
            }
            valueSubject.send(newValue)
        }
    }
    
    public var projectedValue: AnyPublisher<Value, Never> {
        valueSubject.eraseToAnyPublisher()
    }
    
}
