//
//  Monad.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.08..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct K0 {}
struct K1<A> {}

protocol Monad {
    typealias A
    typealias B
    typealias MA = K1<A>
    typealias MB = K1<B>
    
    class func unit(A) -> MA
    func bind(A -> MB) -> MB

    func >>-(Self, A -> MB) -> MB
    func >-(Self, MB) -> MB
}


public struct Wrap<A> {
    public let unwrap : () -> A
    
    public init(_ x : A) {
        unwrap = { x }
    }
}

public enum Either<E,A> {
    case Left(Wrap<E>)
    case Right(Wrap<A>)
}

struct EitherState<E,S,A1> {
    let runEitherState: S -> (Either<E,A1>, S)

    static func get() -> EitherState<E,S,S> {
        return EitherState<E,S,S> { s in (.Right(Wrap(s)), s) }
    }
    
    static func put(s: S) -> EitherState<E,S,()> {
        return EitherState<E,S,()> { _ in (.Right(Wrap(())), s) }
    }
    
    static func fail(error: E) -> EitherState<E,S,A1> {
        return EitherState<E,S,A1> { s in (.Left(Wrap(error)), s) }
    }
}

extension EitherState: Monad {
    typealias A = A1
    typealias B = Swift.Any
    typealias MA = EitherState<E,S,A>
    typealias MB = EitherState<E,S,B>
    
    static func unit(x: A) -> EitherState<E,S,A> {
        return EitherState<E,S,A> { s in (.Right(Wrap(x)), s) }
    }
    
    func bind<B>(f: A -> EitherState<E,S,B>) -> EitherState<E,S,B> {
        return EitherState<E,S,B> { s in
            let (ea, s1) = self.runEitherState(s)
            switch ea {
            case .Left(let error): return (.Left(error), s1)
            case .Right(let wrap): return f(wrap.unwrap()).runEitherState(s1)
            }
        }
    }
}

infix operator >>- {
    precedence 110
    associativity left
}

infix operator >- {
    precedence 110
    associativity left
}

func >>-<E,S,A,B>(ma: EitherState<E,S,A>, f: A -> EitherState<E,S,B>) -> EitherState<E,S,B> {
    return ma.bind(f)
}

func >-<E,S,A,B>(ma: EitherState<E,S,A>, mb: EitherState<E,S,B>) -> EitherState<E,S,B> {
    return ma.bind({_ in mb})
}


