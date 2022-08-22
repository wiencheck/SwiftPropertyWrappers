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
    
    public var wrappedValue: Value {
        get { didChangeSubject.value }
        set { didChangeSubject.value = newValue }
    }
    
    private let didChangeSubject: CurrentValueSubject<Value, Never>
    public init(wrappedValue: Value) {
        self.didChangeSubject = .init(wrappedValue)
    }
    
    /// A `Publisher` that emits the new value of `wrappedValue` _after it was_ mutated (using `didSet` semantics).
    public var projectedValue: AnyPublisher<Value, Never> {
        didChangeSubject.eraseToAnyPublisher()
    }
    
}
