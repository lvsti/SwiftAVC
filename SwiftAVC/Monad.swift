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


public struct Box<A> {
    public let unbox : () -> A
    
    public init(_ x : A) {
        unbox = { x }
    }
}

enum Either<E,A> {
    case Left(Box<E>)
    case Right(Box<A>)
}

struct EitherState<E,S,A1> {
    let runEitherState: S -> (Either<E,A1>, S)

    static func get() -> EitherState<E,S,S> {
        return EitherState<E,S,S> { s in (.Right(Box(s)), s) }
    }
    
    static func put(s: S) -> EitherState<E,S,()> {
        return EitherState<E,S,()> { _ in (.Right(Box(())), s) }
    }
    
    static func fail(error: E) -> EitherState<E,S,A1> {
        return EitherState<E,S,A1> { s in (.Left(Box(error)), s) }
    }
}

extension EitherState: Monad {
    typealias A = A1
    typealias B = Swift.Any
    typealias MA = EitherState<E,S,A>
    typealias MB = EitherState<E,S,B>
    
    static func unit(x: A) -> EitherState<E,S,A> {
        return EitherState<E,S,A> { s in (.Right(Box(x)), s) }
    }
    
    func bind<B>(f: A -> EitherState<E,S,B>) -> EitherState<E,S,B> {
        return EitherState<E,S,B> { s in
            let (ea, s1) = self.runEitherState(s)
            switch ea {
            case .Left(let error): return (.Left(error), s1)
            case .Right(let box): return f(box.unbox()).runEitherState(s1)
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


