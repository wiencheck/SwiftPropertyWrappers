//
//  Keychain.swift
//  Plum
//
//  Created by Adam Wienconek on 09/04/2022.
//  Copyright © 2022 adam.wienconek. All rights reserved.
//

import Foundation
import Combine
import SimpleKeychain

/// Property wrapper that uses iOS Keychain for persisting value.
@propertyWrapper
public class KeychainStorage<Value: Codable> {
    
    private let key: String
    private let keychain: SimpleKeychain
    private let defaultValue: Value
    private let valueSubject: PassthroughSubject<Value, Never>
    
    /// Initializes the property wrapper.
    /// - Parameters:
    ///   - keychain: Instance of `SimpleKeychain` to be used for persisting the value.
    ///   - key: Key under which the value will be stored in the keychain.
    ///   - defaultValue: Default value that will be read when no value yet persists.
    public init(
        keychain: SimpleKeychain = .init(),
        key: String,
        defaultValue: Value
    ) {
        self.keychain = keychain
        self.key = key
        self.defaultValue = defaultValue
        self.valueSubject = .init()
    }
    
    public var wrappedValue: Value {
        get {
            do {
                let data = try keychain.data(forKey: key)
                return try JSONDecoder().decode(Value.self, from: data)
            } catch {
                print("*** Could not read value from keychain, error: \(error)")
            }
            return defaultValue
        }
        set {
            do {
                let anyValue = newValue as Any
                guard let value = anyValue as? Value else {
                    try keychain.deleteItem(forKey: key)
                    return
                }
                let data = try JSONEncoder().encode(value)
                try keychain.set(data, forKey: key)
            } catch {
                print("*** Could not store value to keychain, error: \(error)")
            }
        }
    }
    
    public var projectedValue: AnyPublisher<Value, Never> {
        valueSubject.eraseToAnyPublisher()
    }
    
}

public extension KeychainStorage where Value: ExpressibleByNilLiteral {
    
    /// Initializes the property wrapper with `nil` as default value.
    /// - Parameters:
    ///   - keychain: Instance of `SimpleKeychain` to be used for persisting the value.
    ///   - key: Key under which the value will be stored in the keychain.
    convenience init(
        keychain: SimpleKeychain = .init(),
        key: String
    ) {
        self.init(
            keychain: keychain,
            key: key,
            defaultValue: nil
        )
    }
    
}
