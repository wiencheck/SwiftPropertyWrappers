//
//  UserDefault.swift
//  Plum
//
//  Created by Adam Wienconek on 15/11/2021.
//  Copyright © 2021 adam.wienconek. All rights reserved.
//

import Foundation
import Combine
import FileHelper
import SimpleLogger

/// Property wrapper that handles persisting the value to disk.
@propertyWrapper
public class CodableStorage<Value: Codable> {
    
    private let filename: String
    private let defaultValue: Value
    private let directory: FileHelper.Directory
    private let encoder: any EncoderProtocol
    private let decoder: any DecoderProtocol
    private let cacheValue: Bool
    
    private var valueSubject: (any Subject<Value, Never>)!
    
    /// Initializes the property wrapper.
    /// - Parameters:
    ///   - filename: Name of the data file that will be saved to disk.
    ///   - defaultValue: Default value that will be read when no value yet persists.
    ///   - directory: Directory on disk to which the file should be saved.
    ///   - cacheValue: Flag indicating whether stored value should be kept in memory. Pass `true` if decoding the value could cause a performance issue.
    public init(
        _ filename: String,
        defaultValue: Value,
        directory: FileHelper.Directory,
        encoder: any EncoderProtocol = JSONEncoder(),
        decoder: any DecoderProtocol = JSONDecoder(),
        cacheValue: Bool = false
    ) {
        self.filename = filename
        self.defaultValue = defaultValue
        self.directory = directory
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

private extension CodableStorage {
    
    func retrieveValue() -> Value {
        if let cachedValue = (valueSubject as? CurrentValueSubject<Value, Never>)?.value {
            return cachedValue
        }
        do {
            if let value: Value = try FileHelper.retrieve(
                filename,
                from: directory,
                using: decoder
            ) {
                if let cvs = valueSubject as? CurrentValueSubject<Value, Never> {
                    cvs.value = value
                }
                return value
            }
        } catch {
            Logger.error("CodableStorage: Failed to retrieve file named: \(filename), error: \(error)")
        }
        return defaultValue
    }
    
    func store(_ value: Value) {
        do {
            if (value as AnyObject) is NSNull {
                try FileHelper.remove(
                    filename,
                    from: directory
                )
            } else {
                try FileHelper.store(
                    value,
                    to: directory,
                    as: filename
                )
            }
        } catch {
            Logger.error("CodableStorage: Failed to store file named: \(filename), error: \(error)")
            return
        }
        valueSubject.send(value)
    }
    
}

public extension CodableStorage where Value: ExpressibleByNilLiteral {
    
    /// Initializes the property wrapper with `nil` as default value.
    /// - Parameters:
    ///   - filename: Name of the data file that will be saved to disk.
    ///   - directory: Directory on disk to which the file should be saved.
    ///   - cacheValue: Flag indicating whether stored value should be kept in memory. Pass `true` if decoding the value could cause a performance issue.
    convenience init(
        _ filename: String,
        directory: FileHelper.Directory,
        cacheValue: Bool = false
    ) {
        self.init(
            filename,
            defaultValue: nil,
            directory: directory,
            cacheValue: cacheValue
        )
    }
    
}
