//
//  Cokleisli.swift
//  Bow
//
//  Created by Tomás Ruiz López on 2/10/17.
//  Copyright © 2017 Tomás Ruiz López. All rights reserved.
//

import Foundation

public class CokleisliF {}
public typealias CoreaderT<F, A, B> = Cokleisli<F, A, B>

public class Cokleisli<F, A, B> : HK3<CokleisliF, F, A, B> {
    internal let run : (HK<F, A>) -> B
    
    public static func pure(_ b : B) -> Cokleisli<F, A, B> {
        return Cokleisli<F, A, B>({ _ in b })
    }
    
    public static func ask<Comon>(_ comonad : Comon) -> Cokleisli<F, B, B> where Comon : Comonad, Comon.F == F {
        return Cokleisli<F, B, B>({ fb in comonad.extract(fb) })
    }
    
    public static func ev(_ fa : HK3<CokleisliF, F, A, B>) -> Cokleisli<F, A, B> {
        return fa as! Cokleisli<F, A, B>
    }
    
    public init(_ run : @escaping (HK<F, A>) -> B) {
        self.run = run
    }
    
    public func bimap<C, D, Comon>(_ g : @escaping (D) -> A, _ f : @escaping (B) -> C, _ comonad : Comon) -> Cokleisli<F, D, C> where Comon : Comonad, Comon.F == F {
        return Cokleisli<F, D, C>({ fa in f(self.run(comonad.map(fa, g)))})
    }
    
    public func lmap<D, Comon>(_ g : @escaping (D) -> A, _ comonad : Comon) -> Cokleisli<F, D, B> where Comon : Comonad, Comon.F == F {
        return Cokleisli<F, D, B>({ fa in self.run(comonad.map(fa, g)) })
    }
    
    public func map<C>(_ f : @escaping (B) -> C) -> Cokleisli<F, A, C> {
        return Cokleisli<F, A, C>({ fa in f(self.run(fa)) })
    }
    
    public func contramapValue<C>(_ f : @escaping (HK<F, C>) -> HK<F, A>) -> Cokleisli<F, C, B> {
        return Cokleisli<F, C, B>({ fc in self.run(f(fc)) })
    }
    
    public func compose<D, Comon>(_ a : Cokleisli<F, D, A>, _ comonad : Comon) -> Cokleisli<F, D, B> where Comon : Comonad, Comon.F == F {
        return Cokleisli<F, D, B>({ fa in self.run(comonad.coflatMap(fa, a.run)) })
    }
    
    public func andThen<C, Comon>(_ a : HK<F, C>, _ comonad : Comon) -> Cokleisli<F, A, C> where Comon : Comonad, Comon.F == F {
        return Cokleisli<F, A, C>({ _ in comonad.extract(a) })
    }
    
    public func andThen<C, Comon>(_ a : Cokleisli<F, B, C>, _ comonad : Comon) -> Cokleisli<F, A, C> where Comon : Comonad, Comon.F == F {
        return a.compose(self, comonad)
    }
    
    public func flatMap<C>(_ f : @escaping (B) -> Cokleisli<F, A, C>) -> Cokleisli<F, A, C> {
        return Cokleisli<F, A, C>({ fa in f(self.run(fa)).run(fa) })
    }
}
