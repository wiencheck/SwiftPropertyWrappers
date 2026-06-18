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
    private let cacheValue: Bool
    
    private var valueSubject: (any Subject<Value, Never>)!
    
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
        
        if cacheValue {
            let initialValue = retrieveValue()
            self.valueSubject = CurrentValueSubject(initialValue)
        } else {
            self.valueSubject = PassthroughSubject<Value, Never>()
        }
    }
    
    public var wrappedValue: Value {
        get { retrieveValue() }
        set { store(newValue) }
    }
    
    public var projectedValue: AnyPublisher<Value, Never> {
        if cacheValue {
            valueSubject.eraseToAnyPublisher()
        } else {
            Publishers.Merge(
                Just(retrieveValue())
                    .eraseToAnyPublisher(),
                valueSubject.eraseToAnyPublisher()
            )
            .eraseToAnyPublisher()
        }
    }
    
}

private extension UserDefaultsStorage {
    
    func retrieveValue() -> Value {
        if let cachedValue = (valueSubject as? CurrentValueSubject<Value, Never>)?.value {
            return cachedValue
        }
        do {
            if let data = container.data(forKey: key) {
                let value = try decoder.decode(Value.self, from: data)
                
                if let cvs = valueSubject as? CurrentValueSubject<Value, Never> {
                    cvs.value = value
                }
                return value
            }
        } catch {
            Logger.error("UserDefaultsStorage: Could not retrieve stored value due to error: \(error)")
        }
        return defaultValue
    }
    
    func store(_ value: Value) {
        do {
            if (value as AnyObject) is NSNull {
                container.removeObject(forKey: key)
            } else {
                let data = try encoder.encode(value)
                container.set(data, forKey: key)
            }
        } catch {
            Logger.error("UserDefaultsStorage: Could not store value due to error: \(error)")
            return
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
