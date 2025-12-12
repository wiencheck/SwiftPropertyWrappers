//
//  PostPublished.swift
//  Plum
//
//  Created by Adam Wienconek on 01/02/2022.
//  Copyright © 2022 adam.wienconek. All rights reserved.
//

import Foundation
import Combine

/// A type that publishes changes about its `wrappedValue` property _after_ the property has changed (using `didSet` semantics).
/// Reimplementation of `Combine.Published`, which uses `willSet` semantics.
@propertyWrapper
public class PostPublished<Value> {
        
    private let valueSubject: CurrentValueSubject<Value, Never>
    private let shouldUpdate: ((Value, Value) -> Bool)?
    
    public init(
        wrappedValue: Value,
        shouldUpdate: ((Value, Value) -> Bool)? = nil
    ) {
        self.valueSubject = CurrentValueSubject<Value, Never>(wrappedValue)
        self.shouldUpdate = shouldUpdate
    }
    
    public var wrappedValue: Value {
        get { valueSubject.value }
        set {
            if shouldUpdate?(wrappedValue, newValue) == false {
                return
            }
            valueSubject.value = newValue
        }
    }
    
    /// A `Publisher` that emits the new value of `wrappedValue` _after it was_ mutated (using `didSet` semantics).
    public var projectedValue: AnyPublisher<Value, Never> {
        valueSubject.eraseToAnyPublisher()
    }
    
}

public extension Publisher {
    
    /// Maps the `Output` of its upstream to `Void` and type erases its upstream to `AnyPublisher`.
    func voidPublisher() -> AnyPublisher<Void, Failure> {
        map { _ in Void() }
        .eraseToAnyPublisher()
    }
    
}
