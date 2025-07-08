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
import FileHelper

/// Property wrapper that uses iOS Keychain for persisting value.
@propertyWrapper
public class KeychainStorage<Value: Codable> {
    
    private let key: String
    private let keychain: SimpleKeychain
    private let decoder: any DecoderProtocol
    private let encoder: any EncoderProtocol
    private let defaultValue: Value
    private let valueSubject: PassthroughSubject<Value, Never>
    private let cacheValue: Bool
    
    private var cachedValue: Value?
    
    /// Initializes the property wrapper.
    /// - Parameters:
    ///   - keychain: Instance of `SimpleKeychain` to be used for persisting the value.
    ///   - key: Key under which the value will be stored in the keychain.
    ///   - defaultValue: Default value that will be read when no value yet persists.
    ///   - cacheValue: Flag indicating whether stored value should be kept in memory. Pass `true` if decoding the value could cause a performance issue.
    public init(
        _ key: String,
        defaultValue: Value,
        keychain: SimpleKeychain = .init(),
        encoder: any EncoderProtocol = JSONEncoder(),
        decoder: any DecoderProtocol = JSONDecoder(),
        cacheValue: Bool = false
    ) {
        self.keychain = keychain
        self.key = key
        self.defaultValue = defaultValue
        self.encoder = encoder
        self.decoder = decoder
        self.valueSubject = .init()
        self.cacheValue = cacheValue
    }
    
    public var wrappedValue: Value {
        get { retrieveValue() }
        set { store(newValue) }
    }
    
    public var projectedValue: AnyPublisher<Value, Never> {
        valueSubject.eraseToAnyPublisher()
    }
    
}

private extension KeychainStorage {
    
    func retrieveValue() -> Value {
        if let cachedValue {
            return cachedValue
        }
        do {
            if let data = try? keychain.data(forKey: key) {
                return try decoder.decode(Value.self, from: data)
            }
        } catch {
            print("KeychainStorage: Could not retrieve stored value due to error: \(error)")
        }
        return defaultValue
    }
    
    func store(_ value: Value) {
        do {
            if (value as AnyObject) is NSNull {
                try keychain.deleteItem(forKey: key)
            }
            else {
                let data = try encoder.encode(value)
                try keychain.set(data, forKey: key)
            }
        } catch {
            print("KeychainStorage: Could not store value due to error: \(error)")
            return
        }
        if cacheValue {
            cachedValue = value
        }
        valueSubject.send(value)
    }
    
}

public extension KeychainStorage where Value: ExpressibleByNilLiteral {
    
    /// Initializes the property wrapper with `nil` as default value.
    /// - Parameters:
    ///   - keychain: Instance of `SimpleKeychain` to be used for persisting the value.
    ///   - key: Key under which the value will be stored in the keychain.
    convenience init(
        key: String,
        keychain: SimpleKeychain = .init()
    ) {
        self.init(
            key,
            defaultValue: nil, 
            keychain: keychain
        )
    }
    
}
