//
//  UserDefault.swift
//  Plum
//
//  Created by Adam Wienconek on 15/11/2021.
//  Copyright © 2021 adam.wienconek. All rights reserved.
//

import Foundation
import Combine

@propertyWrapper
struct CodableStorage<Value: Codable> {
        
    private let filename: String
    private let defaultValue: Value
    private let directory: StorageHelper.Directory
    private let publisher: PassthroughSubject<Value, Never> = .init()

    init(filename: String, defaultValue: Value, directory: StorageHelper.Directory) {
        self.filename = filename
        self.defaultValue = defaultValue
        self.directory = directory
    }

    var wrappedValue: Value {
        get {
            StorageHelper.retrieve(filename, from: directory) ?? defaultValue
        }
        set {
            let value = newValue as Any
            guard let safeValue = value as? Value else {
                try? StorageHelper.remove(filename,
                                     from: directory)
                return
            }
            do {
                try StorageHelper.store(safeValue, to: directory, as: filename)
                publisher.send(safeValue)
            } catch {
                print("*** Failed to save object with name: \(filename), error: \(error)")
            }
        }
    }
    
    var projectedValue: AnyPublisher<Value, Never> {
        publisher.eraseToAnyPublisher()
    }
}
