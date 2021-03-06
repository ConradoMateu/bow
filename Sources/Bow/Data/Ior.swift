//
//  Ior.swift
//  Bow
//
//  Created by Tomás Ruiz López on 3/10/17.
//  Copyright © 2017 Tomás Ruiz López. All rights reserved.
//

import Foundation

public class IorF {}
public typealias IorPartial<A> = HK<IorF, A>

public class Ior<A, B> : HK2<IorF, A, B> {
    public static func left(_ a : A) -> Ior<A, B> {
        return IorLeft<A, B>(a)
    }
    
    public static func right(_ b : B) -> Ior<A, B> {
        return IorRight<A, B>(b)
    }
    
    public static func both(_ a : A, _ b : B) -> Ior<A, B> {
        return IorBoth<A, B>(a, b)
    }
    
    public static func fromMaybes(_ ma : Maybe<A>, _ mb : Maybe<B>) -> Maybe<Ior<A, B>> {
        return ma.fold({ mb.fold({ Maybe.none() },
                                 { b in Maybe.some(Ior.right(b))}) },
                       { a in mb.fold({ Maybe.some(Ior.left(a)) },
                                      { b in Maybe.some(Ior.both(a, b))})})
    }
    
    public static func loop<C, SemiG>(_ v : Ior<C, Either<A, B>>,
                                      _ f : @escaping (A) -> Ior<C, Either<A, B>>,
                                      _ semigroup : SemiG) -> Ior<C, B>
        where SemiG : Semigroup, SemiG.A == C {
        return v.fold({ left in Ior<C, B>.left(left) },
                      { right in
                        right.fold({ a in loop(f(a), f, semigroup) },
                                   { b in Ior<C, B>.right(b) })
                      },
                      { left, right in
                        right.fold({ a in
                                      f(a).fold({ aLeft in Ior<C, B>.left(semigroup.combine(aLeft, left)) },
                                                { aRight in loop(Ior<C, Either<A, B>>.both(left, aRight), f, semigroup) },
                                                { aLeft, aRight in loop(Ior<C, Either<A, B>>.both(semigroup.combine(left, aLeft), aRight), f, semigroup)})
                                   },
                                   { b in Ior<C, B>.both(left, b)})
                      })
    }
    
    public static func tailRecM<C, SemiG>(_ a : A, _ f : @escaping (A) -> HK<IorPartial<C>, Either<A, B>>, _ semigroup : SemiG) -> Ior<C, B> where SemiG : Semigroup, SemiG.A == C {
        return loop(Ior<C, Either<A, B>>.ev(f(a)), { a in Ior<C, Either<A, B>>.ev(f(a)) }, semigroup)
    }
    
    public static func ev(_ fa : HK2<IorF, A, B>) -> Ior<A, B> {
        return fa as! Ior<A, B>
    }
    
    public func fold<C>(_ fa : (A) -> C, _ fb : (B) -> C, _ fab : (A, B) -> C) -> C {
        switch self {
            case is IorLeft<A, B>:
                return (self as! IorLeft<A, B>).a |> fa
            case is IorRight<A, B>:
                return (self as! IorRight<A, B>).b |> fb
            case is IorBoth<A, B>:
                let both = self as! IorBoth<A, B>
                return fab(both.a, both.b)
            default:
                fatalError("Ior must only have left, right or both")
        }
    }
    
    public var isLeft : Bool {
        return fold(constF(true), constF(false), constF(false))
    }
    
    public var isRight : Bool {
        return fold(constF(false), constF(true), constF(false))
    }
    
    public var isBoth : Bool {
        return fold(constF(false), constF(false), constF(true))
    }
    
    public func foldL<C>(_ c : C, _ f : (C, B) -> C) -> C {
        return fold(constF(c),
                    { b in f(c, b) },
                    { _, b in f(c, b) })
    }
    
    public func foldR<C>(_ c : Eval<C>, _ f : (B, Eval<C>) -> Eval<C>) -> Eval<C> {
        return fold(constF(c),
                    { b in f(b, c) },
                    { _, b in f(b, c) })
    }
    
    public func traverse<G, C, Appl>(_ f : (B) -> HK<G, C>, _ applicative : Appl) -> HK<G, HK2<IorF, A, C>> where Appl : Applicative, Appl.F == G {
        return fold({ a in applicative.pure(Ior<A, C>.left(a)) },
                    { b in applicative.map(f(b), { c in Ior<A, C>.right(c) }) },
                    { _, b in applicative.map(f(b), { c in Ior<A, C>.right(c) }) })
    }
    
    public func map<C>(_ f : (B) -> C) -> Ior<A, C> {
        return fold(Ior<A, C>.left,
                    { b in Ior<A, C>.right(f(b)) },
                    { a, b in Ior<A, C>.both(a, f(b)) })
    }
    
    public func bimap<C, D>(_ fa : (A) -> C, _ fb : (B) -> D) -> Ior<C, D> {
        return fold({ a in Ior<C, D>.left(fa(a)) },
                    { b in Ior<C, D>.right(fb(b)) },
                    { a, b in Ior<C, D>.both(fa(a), fb(b)) })
    }
    
    public func mapLeft<C>(_ f : (A) -> C) -> Ior<C, B> {
        return fold({ a in Ior<C, B>.left(f(a)) },
                    Ior<C, B>.right,
                    { a, b in Ior<C, B>.both(f(a), b) })
    }
    
    public func flatMap<C, SemiG>(_ f : (B) -> Ior<A, C>, _ semigroup : SemiG) -> Ior<A, C> where SemiG : Semigroup, SemiG.A == A {
        return fold(Ior<A, C>.left,
                    f,
                    { a, b in f(b).fold({ lft in Ior<A, C>.left(semigroup.combine(a, lft)) },
                                        { rgt in Ior<A, C>.right(rgt) },
                                        { lft, rgt in Ior<A, C>.both(semigroup.combine(a, lft), rgt) })
                    })
    }
    
    public func ap<C, SemiG>(_ ff : Ior<A, (B) -> C>, _ semigroup : SemiG) -> Ior<A, C> where SemiG : Semigroup, SemiG.A == A {
        return ff.flatMap(self.map, semigroup)
    }
    
    public func swap() -> Ior<B, A> {
        return fold(Ior<B, A>.right,
                    Ior<B, A>.left,
                    { a, b in Ior<B, A>.both(b, a) })
    }
    
    public func unwrap() -> Either<Either<A, B>, (A, B)> {
        return fold({ a in Either.left(Either.left(a)) },
                    { b in Either.left(Either.right(b)) },
                    { a, b in Either.right((a, b)) })
    }
    
    public func pad() -> (Maybe<A>, Maybe<B>) {
        return fold({ a in (Maybe.some(a), Maybe.none()) },
                    { b in (Maybe.none(), Maybe.some(b)) },
                    { a, b in (Maybe.some(a), Maybe.some(b)) })
    }
    
    public func toEither() -> Either<A, B> {
        return fold(Either.left,
                    Either.right,
                    { _, b in Either.right(b) })
    }
    
    public func toMaybe() -> Maybe<B> {
        return fold({ _ in Maybe<B>.none() },
                    { b in Maybe<B>.some(b) },
                    { _, b in Maybe<B>.some(b) })
    }
    
    public func getOrElse(_ defaultValue : B) -> B {
        return fold(constF(defaultValue),
                    id,
                    { _, b in b })
    }
}

class IorLeft<A, B> : Ior<A, B> {
    fileprivate let a : A
    
    init(_ a : A) {
        self.a = a
    }
}

class IorRight<A, B> : Ior<A, B> {
    fileprivate let b : B
    
    init(_ b : B) {
        self.b = b
    }
}

class IorBoth<A, B> : Ior<A, B> {
    fileprivate let a : A
    fileprivate let b : B
    
    init(_ a : A, _ b : B) {
        self.a = a
        self.b = b
    }
}

extension Ior : CustomStringConvertible {
    public var description : String {
        return fold({ a in "Left(\(a))" },
                    { b in "Right(\(b))" },
                    { a, b in "Both(\(a),\(b))" })
    }
}

public extension Ior {
    public static func functor() -> IorFunctor<A> {
        return IorFunctor<A>()
    }
    
    public static func applicative<SemiG>(_ semigroup : SemiG) -> IorApplicative<A, SemiG> {
        return IorApplicative<A, SemiG>(semigroup)
    }
    
    public static func monad<SemiG>(_ semigroup : SemiG) -> IorMonad<A, SemiG> {
        return IorMonad<A, SemiG>(semigroup)
    }
    
    public static func foldable() -> IorFoldable<A> {
        return IorFoldable<A>()
    }
    
    public static func traverse() -> IorTraverse<A> {
        return IorTraverse<A>()
    }
    
    public static func eq<EqA, EqB>(_ eqa : EqA, _ eqb : EqB) -> IorEq<A, B, EqA, EqB> {
        return IorEq<A, B, EqA, EqB>(eqa, eqb)
    }
}

public class IorFunctor<L> : Functor {
    public typealias F = IorPartial<L>
    
    public func map<A, B>(_ fa: HK<HK<IorF, L>, A>, _ f: @escaping (A) -> B) -> HK<HK<IorF, L>, B> {
        return Ior.ev(fa).map(f)
    }
}

public class IorApplicative<L, SemiG> : IorFunctor<L>, Applicative where SemiG : Semigroup, SemiG.A == L {
    fileprivate let semigroup : SemiG
    
    public init(_ semigroup : SemiG) {
        self.semigroup = semigroup
    }
    
    public func pure<A>(_ a: A) -> HK<HK<IorF, L>, A> {
        return Ior<L, A>.right(a)
    }
    
    public func ap<A, B>(_ fa: HK<HK<IorF, L>, A>, _ ff: HK<HK<IorF, L>, (A) -> B>) -> HK<HK<IorF, L>, B> {
        return Ior.ev(fa).ap(Ior.ev(ff), semigroup)
    }
}

public class IorMonad<L, SemiG> : IorApplicative<L, SemiG>, Monad where SemiG : Semigroup, SemiG.A == L{
    
    public func flatMap<A, B>(_ fa: HK<HK<IorF, L>, A>, _ f: @escaping (A) -> HK<HK<IorF, L>, B>) -> HK<HK<IorF, L>, B> {
        return Ior.ev(fa).flatMap({ a in Ior.ev(f(a)) }, self.semigroup)
    }
    
    public func tailRecM<A, B>(_ a: A, _ f: @escaping (A) -> HK<HK<IorF, L>, Either<A, B>>) -> HK<HK<IorF, L>, B> {
        return Ior.tailRecM(a, f, self.semigroup)
    }
}

public class IorFoldable<L> : Foldable {
    public typealias F = IorPartial<L>
    
    public func foldL<A, B>(_ fa: HK<HK<IorF, L>, A>, _ b: B, _ f: @escaping (B, A) -> B) -> B {
        return Ior.ev(fa).foldL(b, f)
    }
    
    public func foldR<A, B>(_ fa: HK<HK<IorF, L>, A>, _ b: Eval<B>, _ f: @escaping (A, Eval<B>) -> Eval<B>) -> Eval<B> {
        return Ior.ev(fa).foldR(b, f)
    }
}

public class IorTraverse<L> : IorFoldable<L>, Traverse {
    public func traverse<G, A, B, Appl>(_ fa: HK<HK<IorF, L>, A>, _ f: @escaping (A) -> HK<G, B>, _ applicative: Appl) -> HK<G, HK<HK<IorF, L>, B>> where G == Appl.F, Appl : Applicative {
        return Ior.ev(fa).traverse(f, applicative)
    }
}

public class IorEq<L, R, EqL, EqR> : Eq where EqL : Eq, EqL.A == L, EqR : Eq, EqR.A == R {
    public typealias A = HK2<IorF, L, R>
    
    private let eql : EqL
    private let eqr : EqR
    
    public init(_ eql : EqL, _ eqr : EqR) {
        self.eql = eql
        self.eqr = eqr
    }
    
    public func eqv(_ a: HK2<IorF, L, R>, _ b: HK2<IorF, L, R>) -> Bool {
        let a = Ior.ev(a)
        let b = Ior.ev(b)
        return a.fold({ aLeft in
            b.fold({ bLeft in eql.eqv(aLeft, bLeft) }, constF(false), constF(false))
        },
                      { aRight in
            b.fold(constF(false), { bRight in eqr.eqv(aRight, bRight) }, constF(false))
        },
                      { aLeft, aRight in
            b.fold(constF(false), constF(false), { bLeft, bRight in eql.eqv(aLeft, bLeft) && eqr.eqv(aRight, bRight)})
        })
    }
}



