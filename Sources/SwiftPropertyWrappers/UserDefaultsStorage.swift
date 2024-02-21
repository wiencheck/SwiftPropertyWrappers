//
//  Storage.swift
//  Plum
//
//  Created by Adam Wienconek on 13/12/2021.
//  Copyright © 2021 adam.wienconek. All rights reserved.
//

import Foundation
import Combine
import FileHelper

/// Property wrapper that handles persisting the value to user defaults.
@propertyWrapper
public class UserDefaultsStorage<Value: Codable> {
    
    private let key: String
    private let defaultValue: Value
    private let container: UserDefaults
    private let encoder: any EncoderProtocol
    private let decoder: any DecoderProtocol
    private let valueSubject: PassthroughSubject<Value, Never>
    private let cacheValue: Bool
    
    private var cachedValue: Value?
    
    /// Initializes the property wrapper.
    /// - Parameters:
    ///   - key: Key under which the value will be stored in user defaults.
    ///   - defaultValue: Default value that will be read when no value yet persists.
    ///   - container: Instance of `UserDefaults` which will be used for persisting the value. Defaults to `standard`.
    public init(
        _ key: String,
        defaultValue: Value,
        container: UserDefaults = .standard,
        encoder: any EncoderProtocol = JSONEncoder(),
        decoder: any DecoderProtocol = JSONDecoder(),
        cacheValue: Bool = false
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.container = container
        self.encoder = encoder
        self.decoder = decoder
        self.cacheValue = cacheValue
        
        self.valueSubject = .init()
    }
    
    public var wrappedValue: Value {
        get { retrieveValue() }
        set { store(newValue) }
    }
    
    public var projectedValue: AnyPublisher<Value, Never> {
        valueSubject.eraseToAnyPublisher()
    }
    
}

private extension UserDefaultsStorage {
    
    func retrieveValue() -> Value {
        if let cachedValue {
            return cachedValue
        }
        do {
            if let data = container.data(forKey: key) {
                return try decoder.decode(Value.self, from: data)
            }
        } catch {
            print("Defaults: Could not retrieve stored value due to error: \(error)")
        }
        return defaultValue
    }
    
    func store(_ value: Value) {
        do {
            if (value as AnyObject) is NSNull {
                container.removeObject(forKey: key)
            }
            else {
                let data = try encoder.encode(value)
                container.set(data, forKey: key)
            }
        } catch {
            print("Defaults: Could not store value due to error: \(error)")
            return
        }
        if cacheValue {
            cachedValue = value
        }
        valueSubject.send(value)
    }
    
}

public extension UserDefaultsStorage where Value: ExpressibleByNilLiteral {
    
    /// Initializes the property wrapper with `nil` as default value.
    /// - Parameters:
    ///   - key: Key under which the value will be stored in user defaults.
    ///   - defaultValue: Default value that will be read when no value yet persists.
    ///   - container: Instance of `UserDefaults` which will be used for persisting the value. Defaults to `standard`.
    convenience init(
        _ key: String,
        container: UserDefaults = .standard
    ) {
        self.init(
            key,
            defaultValue: nil,
            container: container
        )
    }
    
}
