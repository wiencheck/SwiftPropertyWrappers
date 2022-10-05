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

@propertyWrapper
class KeychainStorage<Value: Codable> {
    
    private let key: String
    private let keychain: SimpleKeychain
    private let defaultValue: Value
    private let valueSubject: PassthroughSubject<Value, Never>
    internal init(keychain: SimpleKeychain = .init(),
                  key: String,
                  defaultValue: Value) {
        self.keychain = keychain
        self.key = key
        self.defaultValue = defaultValue
        self.valueSubject = .init()
    }
    
    var wrappedValue: Value {
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
    
    var projectedValue: AnyPublisher<Value, Never> {
        valueSubject.eraseToAnyPublisher()
    }
    
}
