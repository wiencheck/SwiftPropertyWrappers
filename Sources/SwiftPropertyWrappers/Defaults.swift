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
struct Defaults<Value: Codable> {
    
    private let key: String
    private let defaultValue: Value
    private let container: UserDefaults
    private let valueSubject: PassthroughSubject<Value, Never> = .init()

    init(key: String, defaultValue: Value, container: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.container = container
    }
    
    var wrappedValue: Value {
        get {
            // Read value from UserDefaults
            if let defaultsCompatible = Value.self as? UserDefaultsCompatible.Type,
            let value = defaultsCompatible.retrieve(from: container, atKey: key) as? Value {
                return value
            }
            guard let data = container.data(forKey: key) else {
                // Return defaultValue when no data in UserDefaults
                return defaultValue
            }

            // Convert data to the desire data type
            let value = try? JSONDecoder().decode(Value.self, from: data)
            return value ?? defaultValue
        }
        set {
            if let defaultsCompatible = newValue as? UserDefaultsCompatible {
                defaultsCompatible.store(in: container, atKey: key)
            } else {
                let value = newValue as Any
                // Convert newValue to data
                guard let safeValue = value as? Value,
                      let data = try? JSONEncoder().encode(safeValue) else {
                    container.removeObject(forKey: key)
                    return
                }
                
                // Set value to UserDefaults
                container.set(data, forKey: key)
            }
            valueSubject.send(newValue)
        }
    }
    
    var projectedValue: AnyPublisher<Value, Never> {
        valueSubject.eraseToAnyPublisher()
    }
    
}
