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

@propertyWrapper
public class CodableStorage<Value: Codable> {
        
    private let filename: String
    private let defaultValue: Value
    private let directory: FileHelper.Directory
    private let publisher: PassthroughSubject<Value, Never> = .init()

    public init(filename: String,
                defaultValue: Value,
                directory: FileHelper.Directory) {
        self.filename = filename
        self.defaultValue = defaultValue
        self.directory = directory
    }

    public var wrappedValue: Value {
        get {
            FileHelper.retrieve(filename,
                                from: directory) ?? defaultValue
        }
        set {
            let value = newValue as Any
            guard let safeValue = value as? Value else {
                try? FileHelper.remove(filename,
                                       from: directory)
                return
            }
            do {
                try FileHelper.store(safeValue,
                                     to: directory, as: filename)
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
