//
//  Functor.swift
//  CategoryCore
//
//  Created by Tomás Ruiz López on 28/9/17.
//  Copyright © 2017 Tomás Ruiz López. All rights reserved.
//

import Foundation

public protocol Functor : Typeclass {
    associatedtype F
    
    func map<A, B>(_ fa : HK<F, A>, _ f : (A) -> B) -> HK<F, B>
    func lift<A, B>(_ f : (A) -> B) -> (HK<F, A>) -> HK<F, B>
    func void<A>(_ fa : HK<F, A>) -> HK<F, ()>
    func fproduct<A, B>(_ fa : HK<F, A>, _ f : (A) -> B) -> HK<F, (A, B)>
    func `as`<A, B>(_ fa : HK<F, A>, _ b : B) -> HK<F, B>
    func tupleLeft<A, B>(_ fa : HK<F, A>, _ b : B) -> HK<F, (B, A)>
    func tupleRight<A, B>(_ fa : HK<F, A>, _ b : B) -> HK<F, (A, B)>
}

public extension Functor {
    public func void<A>(_ fa : HK<F, A>) -> HK<F, ()> {
        return self.map(fa, {_ in })
    }
    
    public func fproduct<A, B>(_ fa : HK<F, A>, _ f : (A) -> B) -> HK<F, (A, B)> {
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

