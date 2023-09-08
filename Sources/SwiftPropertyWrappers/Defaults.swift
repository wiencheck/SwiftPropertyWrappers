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
public class Defaults<Value: Codable> {
    
    private let key: String
    private let defaultValue: Value
    private let container: UserDefaults
    private let encoder: any EncoderProtocol
    private let decoder: any DecoderProtocol
    private let valueSubject: PassthroughSubject<Value, Never>
    
    /// Initializes the property wrapper.
    /// - Parameters:
    ///   - key: Key under which the value will be stored in user defaults.
    ///   - defaultValue: Default value that will be read when no value yet persists.
    ///   - container: Instance of `UserDefaults` which will be used for persisting the value. Defaults to `standard`.
    public init(
        key: String,
        defaultValue: Value,
        container: UserDefaults = .standard,
        encoder: any EncoderProtocol = JSONEncoder(),
        decoder: any DecoderProtocol = JSONDecoder()
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.container = container
        self.encoder = encoder
        self.decoder = decoder
        valueSubject = .init()
    }
    
    public var wrappedValue: Value {
        get {
            guard let data = container.data(forKey: key),
                  let value = try? decoder.decode(Value.self, from: data) else {
                return defaultValue
            }
            return value
        }
        set {
            if let data = try? encoder.encode(newValue),
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

public extension Defaults where Value: ExpressibleByNilLiteral {
    
    /// Initializes the property wrapper with `nil` as default value.
    /// - Parameters:
    ///   - key: Key under which the value will be stored in user defaults.
    ///   - defaultValue: Default value that will be read when no value yet persists.
    ///   - container: Instance of `UserDefaults` which will be used for persisting the value. Defaults to `standard`.
    convenience init(
        key: String,
        container: UserDefaults = .standard
    ) {
        self.init(
            key: key,
            defaultValue: nil,
            container: container
        )
    }
    
}
