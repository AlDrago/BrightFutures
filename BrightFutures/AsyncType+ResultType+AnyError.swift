//
//  AsyncType+ResultType+AnyError.swift
//  BrightFutures
//
//  Created by Daniel Leping on 12/22/15.
//  Copyright © 2015 Thomas Visser. All rights reserved.
//

import Foundation
import Result

/// Executes the given task on `Queue.global` and wraps the result of the task in a Future
/// If the given closure throws, returns an error
public func future<T>(task: @autoclosure @escaping () throws -> T) -> Future<T, AnyError> {
    return future(context: DispatchQueue.global().context, task: task)
}

/// Executes the given task on `Queue.global` and wraps the result of the task in a Future
/// If the given closure throws, returns an error
public func future<T>(task: @escaping () throws -> T) -> Future<T, AnyError> {
    return future(context: DispatchQueue.global().context, task: task)
}

/// Executes the given task on the given context and wraps the result of the task in a Future
/// If the given closure throws, returns an error
public func future<T>(context: ExecutionContext, task: @escaping () throws -> T) -> Future<T, AnyError> {
    return Future { complete in
        do {
            complete(Result(value: try task()))
        } catch let e {
            complete(Result(error: AnyError(cause: e)))
        }
    }
}

public extension AsyncType where Value: ResultProtocol, Value.Error == AnyError {
    public var error: Error? {
        return result?.error?.cause
    }
    
    /// Adds the given closure as a callback for when the future fails. The closure is executed on the given context.
    /// If no context is given, the behavior is defined by the default threading model (see README.md)
    /// Returns self
    @discardableResult
    public func onFailure(context: @escaping ExecutionContext = DefaultThreadingModel(), callback: @escaping (Error) -> Void) -> Self {
        self.onComplete(context) { result in
            result.analysis(ifSuccess: { _ in }, ifFailure: { error in
                callback(error.cause)
            })
        }
        return self
    }
    
    
    /// Returns a future that succeeds with the value returned from the given closure when it is invoked with the success value
    /// If the given closure throws, returns an error
    /// from this future. If this future fails, the returned future fails with the same error.
    /// The closure is executed on the given context. If no context is given, the behavior is defined by the default threading model (see README.md)
    public func map<U>(context: @escaping ExecutionContext, f: @escaping (Value.Value) throws -> U) -> Future<U, AnyError> {
        return self.flatMap(context) { (value:Value.Value) -> Result<U, Value.Error> in
            do {
                return Result(value: try f(value))
            } catch let e as AnyError {
                return Result(error: e)
            } catch let e {
                return Result(error: AnyError(cause: e))
            }
        }
    }
    
    /// See `map<U>(context c: ExecutionContext, f: (T) -> U) -> Future<U>`
    /// If the given closure throws, returns an error
    /// The given closure is executed according to the default threading model (see README.md)
    public func map<U>(f: @escaping (Value.Value) throws -> U) -> Future<U, AnyError> {
        return self.map(context: DefaultThreadingModel(), f: f)
    }
    
    /// Returns a future that completes with this future if this future succeeds or with the value returned from the given closure
    /// when it is invoked with the error that this future failed with.
    /// The closure is executed on the given context. If no context is given, the behavior is defined by the default threading model (see README.md)
    public func recover(context c: @escaping ExecutionContext = DefaultThreadingModel(), task: @escaping (Error) -> Value.Value) -> Future<Value.Value, NoError> {
        return self.recoverWith(context: c) { error -> Future<Value.Value, NoError> in
            return Future<Value.Value, NoError>(value: task((error as! AnyError).cause))
        }
    }
    
    /// Returns a future that completes with this future if this future succeeds or with the value returned from the given closure
    /// when it is invoked with the error that this future failed with.
    /// If the given closure throws, returns an error
    /// The closure is executed on the given context. If no context is given, the behavior is defined by the default threading model (see README.md)
    public func recover(context c: @escaping ExecutionContext = DefaultThreadingModel(), task: @escaping (Error) throws -> Value.Value) -> Future<Value.Value, AnyError> {
        return self.recoverWith(context: c) { error -> Future<Value.Value, AnyError> in
            do {
                return Future<Value.Value, AnyError>(value: try task(error))
            } catch let e as AnyError {
                return Future<Value.Value, AnyError>(error: e)
            } catch let e {
                return Future<Value.Value, AnyError>(error: AnyError(cause: e))
            }
        }
    }
    
    /// Returns a future that completes with this future if this future succeeds or with the value returned from the given closure
    /// when it is invoked with the error that this future failed with.
    /// This function should be used in cases where there are two asynchronous operations where the second operation (returned from the given closure)
    /// should only be executed if the first (this future) fails.
    /// The closure is executed on the given context. If no context is given, the behavior is defined by the default threading model (see README.md)
    public func recoverWith<E1: Error>(context c: @escaping ExecutionContext = DefaultThreadingModel(), task: @escaping (Error) -> Future<Value.Value, E1>) -> Future<Value.Value, E1> {
        return recoverWith(context: c) { (error:Value.Error) -> Future<Value.Value, E1> in
            return task((error as! AnyError).cause)
        }
    }
    
    /// See `mapError<E1>(context c: ExecutionContext, f: ErrorType -> E1) -> Future<T, E1>`
    /// The given closure is executed according to the default threading model (see README.md)
    public func mapError<E1: Error>(f: @escaping (Error) -> E1) -> Future<Value.Value, E1> {
        return mapError { (error:Value.Error) -> E1 in
            f(error.cause)
        }
    }
    
    /// Returns a future that fails with the error returned from the given closure when it is invoked with the error
    /// from this future. If this future succeeds, the returned future succeeds with the same value and the closure is not executed.
    /// The closure is executed on the given context.
    public func mapError<E1: Error>(context c: @escaping ExecutionContext, f: @escaping (Error) -> E1) -> Future<Value.Value, E1> {
        return mapError(c) { (error:Value.Error) -> E1 in
            f(error.cause)
        }
    }
}

public extension AsyncType where Value: ResultProtocol {
    /// See `map<U>(context c: ExecutionContext, f: (T) -> U) -> Future<U>`
    ///
    /// If the given closure throws, returns an error
    /// The given closure is executed according to the default threading model (see README.md)
    public func map<U>(f: @escaping (Value.Value) throws -> U) -> Future<U, AnyError> {
        return self.map(context: DefaultThreadingModel(), f: f)
    }
    
    /// Returns a future that succeeds with the value returned from the given closure when it is invoked with the success value
    /// from this future. If this future fails, the returned future fails with the same error.
    /// If the given closure throws, returns an error
    /// The closure is executed on the given context. If no context is given, the behavior is defined by the default threading model (see README.md)
    public func map<U>(context context: @escaping ExecutionContext, f: @escaping (Value.Value) throws -> U) -> Future<U, AnyError> {
        return self.mapError(context, f: { e in
            AnyError(cause: e)
        }).map(context: context, f:f)
    }
    
    /// Returns a future that completes with this future if this future succeeds or with the value returned from the given closure
    /// when it is invoked with the error that this future failed with.
    /// If the given closure throws, returns an error
    /// The closure is executed on the given context. If no context is given, the behavior is defined by the default threading model (see README.md)
    public func recover(context c: @escaping ExecutionContext = DefaultThreadingModel(), task: @escaping (Value.Error) throws -> Value.Value) -> Future<Value.Value, AnyError> {
        return self.recoverWith(context: c) { error -> Future<Value.Value, AnyError> in
            do {
                return Future<Value.Value, AnyError>(value: try task(error))
            } catch let e {
                return Future<Value.Value, AnyError>(error: AnyError(cause: e))
            }
        }
    }
}
