//
//  OldCurrentValueSubject.swift
//  Plum
//
//  Created by Adam Wienconek on 02/02/2022.
//  Copyright © 2022 adam.wienconek. All rights reserved.
//

import Foundation
import Combine

/// A type that publishes changes about its `wrappedValue` property as well, as value that was assigned before, _after_ the property has changed (using `didSet` semantics).
@propertyWrapper
class OldCurrentValueSubject<Value, Failure>: Subject where Failure: Error {
    
    typealias Output = (oldValue: Value?, currentValue: Value)

    var wrappedValue: Value {
        didSet {
            send((oldValue, wrappedValue))
        }
    }
    
    private let wrapped: CurrentValueSubject<Output, Failure>
    
    init(wrappedValue value: Value) {
        wrappedValue = value
        wrapped = .init((nil, value))
    }
    
    func send(_ value: Output) {
        wrapped.send(value)
    }
    
    func send(completion: Subscribers.Completion<Failure>) {
        wrapped.send(completion: completion)
    }
    
    func send(subscription: Subscription) {
        wrapped.send(subscription: subscription)
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        wrapped.receive(subscriber: subscriber)
    }
}
