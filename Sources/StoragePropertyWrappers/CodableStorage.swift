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

/// Property wrapper that handles persisting the value to disk.
@propertyWrapper
public class CodableStorage<Value: Codable> {
    
    private let filename: String
    private let defaultValue: Value
    private var cachedValue: Value?
    private let directory: FileHelper.Directory
    private let encoder: any EncoderProtocol
    private let decoder: any DecoderProtocol
    private let publisher: PassthroughSubject<Value, Never> = .init()
    private let shouldCacheValue: Bool
    
    /// Initializes the property wrapper.
    /// - Parameters:
    ///   - filename: Name of the data file that will be saved to disk.
    ///   - defaultValue: Default value that will be read when no value yet persists.
    ///   - directory: Directory on disk to which the file should be saved.
    ///   - shouldCacheValue: Flag indicating whether stored value should be kept in memory. Pass `true` if decoding the value could cause a performance issue.
    public init(
        filename: String,
        defaultValue: Value,
        directory: FileHelper.Directory,
        encoder: any EncoderProtocol = JSONEncoder(),
        decoder: any DecoderProtocol = JSONDecoder(),
        shouldCacheValue: Bool = false
    ) {
        self.filename = filename
        self.defaultValue = defaultValue
        self.directory = directory
        self.encoder = encoder
        self.decoder = decoder
        self.shouldCacheValue = shouldCacheValue
    }
    
    public var wrappedValue: Value {
        get {
            if let cachedValue {
                return cachedValue
            }
            return FileHelper.retrieve(
                filename,
                from: directory,
                using: decoder
            ) ?? defaultValue
        }
        set {
            let value = newValue as Any
            guard let safeValue = value as? Value else {
                try? FileHelper.remove(filename, from: directory)
                cachedValue = nil
                return
            }
            do {
                try FileHelper.store(
                    safeValue,
                    to: directory,
                    as: filename,
                    using: encoder
                )
                if shouldCacheValue {
                    cachedValue = safeValue
                }
                publisher.send(safeValue)
            } catch {
                print("*** Failed to save object with name: \(filename), error: \(error)")
            }
        }
    }
    
    public var projectedValue: AnyPublisher<Value, Never> {
        publisher.eraseToAnyPublisher()
    }
    
}

public extension CodableStorage where Value: ExpressibleByNilLiteral {
    
    /// Initializes the property wrapper with `nil` as default value.
    /// - Parameters:
    ///   - filename: Name of the data file that will be saved to disk.
    ///   - directory: Directory on disk to which the file should be saved.
    ///   - shouldCacheValue: Flag indicating whether stored value should be kept in memory. Pass `true` if decoding the value could cause a performance issue.
    convenience init(
        filename: String,
        directory: FileHelper.Directory,
        shouldCacheValue: Bool = false
    ) {
        self.init(
            filename: filename,
            defaultValue: nil,
            directory: directory,
            shouldCacheValue: shouldCacheValue
        )
    }
    
}
