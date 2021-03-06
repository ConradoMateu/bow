//
//  Functor.swift
//  Bow
//
//  Created by Tomás Ruiz López on 28/9/17.
//  Copyright © 2017 Tomás Ruiz López. All rights reserved.
//

import Foundation

public protocol Functor : Typeclass {
    associatedtype F
    
    func map<A, B>(_ fa : HK<F, A>, _ f : @escaping (A) -> B) -> HK<F, B>
}

public extension Functor {
    public func lift<A, B>(_ f : @escaping (A) -> B) -> (HK<F, A>) -> HK<F, B> {
        return { fa in self.map(fa, f) }
    }
    
    public func void<A>(_ fa : HK<F, A>) -> HK<F, ()> {
        return self.map(fa, {_ in })
    }
    
    public func fproduct<A, B>(_ fa : HK<F, A>, _ f : @escaping (A) -> B) -> HK<F, (A, B)> {
        return self.map(fa, { a in (a, f(a)) })
    }
    
    public func `as`<A, B>(_ fa : HK<F, A>, _ b : B) -> HK<F, B> {
        return self.map(fa, { _ in b })
    }
    
    public func tupleLeft<A, B>(_ fa : HK<F, A>, _ b : B) -> HK<F, (B, A)> {
        return self.map(fa, { a in (b, a) })
    }
    
    public func tupleRight<A, B>(_ fa : HK<F, A>, _ b : B) -> HK<F, (A, B)> {
        return self.map(fa, { a in (a, b) })
    }
}

