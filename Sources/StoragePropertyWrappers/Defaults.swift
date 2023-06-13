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
public class Defaults<Value: Codable> {
    
    private let key: String
    private let defaultValue: Value
    private let container: UserDefaults
    private let valueSubject: PassthroughSubject<Value, Never>

    public init(key: String, defaultValue: Value, container: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.container = container
        valueSubject = .init()
    }
    
    public var wrappedValue: Value {
        get {
            guard let data = container.data(forKey: key),
                  let value = try? JSONDecoder().decode(Value.self, from: data) else {
                return defaultValue
            }
            return value
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
                  !data.isEmpty {
                container.set(data, forKey: key)
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
