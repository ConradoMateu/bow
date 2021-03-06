//
//  Kleisli.swift
//  Bow
//
//  Created by Tomás Ruiz López on 2/10/17.
//  Copyright © 2017 Tomás Ruiz López. All rights reserved.
//

import Foundation

public class KleisliF {}
public typealias ReaderT<F, D, A> = Kleisli<F, D, A>
public typealias KleisliPartial<F, D> = HK2<KleisliF, F, D>

public class Kleisli<F, D, A> : HK3<KleisliF, F, D, A> {
    internal let run : (D) -> HK<F, A>
    
    public static func ev(_ fa : HK3<KleisliF, F, D, A>) -> Kleisli<F, D, A> {
        return fa as! Kleisli<F, D, A>
    }
    
    public init(_ run : @escaping (D) -> HK<F, A>) {
        self.run = run
    }
    
    public func ap<B, Appl>(_ ff : Kleisli<F, D, (A) -> B>, _ applicative : Appl) -> Kleisli<F, D, B> where Appl : Applicative, Appl.F == F {
        return Kleisli<F, D, B>({ d in applicative.ap(self.run(d), ff.run(d)) })
    }
    
    public func map<B, Func>(_ f : @escaping (A) -> B, _ functor : Func) -> Kleisli<F, D, B> where Func : Functor, Func.F == F {
        return Kleisli<F, D, B>({ d in functor.map(self.run(d), f) })
    }
    
    public func flatMap<B, Mon>(_ f : @escaping (A) -> Kleisli<F, D, B>, _ monad : Mon)  -> Kleisli<F, D, B> where Mon : Monad, Mon.F == F {
        return Kleisli<F, D, B>({ d in monad.flatMap(self.run(d), { a in f(a).run(d) }) })
    }
    
    public func zip<B, Mon>(_ o : Kleisli<F, D, B>, _ monad : Mon) -> Kleisli<F, D, (A, B)> where Mon : Monad, Mon.F == F {
        return self.flatMap({ a in
            o.map({ b in (a, b) }, monad)
        }, monad)
    }
    
    public func local<DD>(_ f : @escaping (DD) -> D) -> Kleisli<F, DD, A> {
        return Kleisli<F, DD, A>({ dd in self.run(f(dd)) })
    }
    
    public func andThen<C, Mon>(_ f : Kleisli<F, A, C>, _ monad : Mon) -> Kleisli<F, D, C> where Mon : Monad, Mon.F == F {
        return andThen(f.run, monad)
    }
    
    public func andThen<B, Mon>(_ f : @escaping (A) -> HK<F, B>, _ monad : Mon) -> Kleisli<F, D, B> where Mon : Monad, Mon.F == F {
        return Kleisli<F, D, B>({ d in monad.flatMap(self.run(d), f) })
    }
    
    public func andThen<B, Mon>(_ a : HK<F, B>, _ monad : Mon) -> Kleisli<F, D, B> where Mon : Monad, Mon.F == F {
        return andThen({ _ in a }, monad)
    }
    
    public func handleErrorWith<E, MonErr>(_ f : @escaping (E) -> Kleisli<F, D, A>, _ monadError : MonErr) -> Kleisli<F, D, A> where MonErr : MonadError, MonErr.F == F, MonErr.E == E {
        return Kleisli<F, D, A>({ d in monadError.handleErrorWith(self.run(d), { e in f(e).run(d) }) })
    }
    
    public static func pure<Appl>(_ a : A, _ applicative : Appl) -> Kleisli<F, D, A> where Appl : Applicative, Appl.F == F {
        return Kleisli<F, D, A>({ _ in applicative.pure(a) })
    }
    
    public static func ask<Appl>(_ applicative : Appl) -> Kleisli<F, D, D> where Appl : Applicative, Appl.F == F {
        return Kleisli<F, D, D>({ d in applicative.pure(d) })
    }
    
    public static func raiseError<E, MonErr>(_ e : E, _ monadError : MonErr) -> Kleisli<F, D, A> where MonErr : MonadError, MonErr.F == F, MonErr.E == E {
        return Kleisli<F, D, A>({ _ in monadError.raiseError(e) })
    }
    
    public static func tailRecM<B, MonF>(_ a : A, _ f : @escaping (A) -> HK3<KleisliF, F, D, Either<A, B>>, _ monad : MonF) -> HK3<KleisliF, F, D, B> where MonF : Monad, MonF.F == F {
        return Kleisli<F, D, B>({ b in monad.tailRecM(a, { a in Kleisli<F, D, Either<A, B>>.ev(f(a)).run(b) })})
    }
    
    public func invoke(_ value : D) -> HK<F, A> {
        return run(value)
    }
}

public extension Kleisli {
    public static func functor<FuncF>(_ functor : FuncF) -> KleisliFunctor<F, D, FuncF> {
        return KleisliFunctor<F, D, FuncF>(functor)
    }
    
    public static func applicative<ApplF>(_ applicative : ApplF) -> KleisliApplicative<F, D, ApplF> {
        return KleisliApplicative<F, D, ApplF>(applicative)
    }
    
    public static func monad<MonF>(_ monad : MonF) -> KleisliMonad<F, D, MonF> {
        return KleisliMonad<F, D, MonF>(monad)
    }
    
    public static func reader<MonF>(_ monad : MonF) -> KleisliMonadReader<F, D, MonF> {
        return KleisliMonadReader<F, D, MonF>(monad)
    }
    
    public static func monadError<E, MonEF>(_ monadError : MonEF) -> KleisliMonadError<F, D, E, MonEF> {
        return KleisliMonadError<F, D, E, MonEF>(monadError)
    }
}

public class KleisliFunctor<G, D, FuncG> : Functor where FuncG : Functor, FuncG.F == G {
    public typealias F = KleisliPartial<G, D>
    
    private let functor : FuncG
    
    public init(_ functor : FuncG) {
        self.functor = functor
    }
    
    public func map<A, B>(_ fa: HK<HK<HK<KleisliF, G>, D>, A>, _ f: @escaping (A) -> B) -> HK<HK<HK<KleisliF, G>, D>, B> {
        return Kleisli.ev(fa).map(f, functor)
    }
}

public class KleisliApplicative<G, D, ApplG> : KleisliFunctor<G, D, ApplG>, Applicative where ApplG : Applicative, ApplG.F == G {
    
    private let applicative : ApplG
    
    override public init(_ applicative : ApplG) {
        self.applicative = applicative
        super.init(applicative)
    }
    
    public func pure<A>(_ a: A) -> HK<HK<HK<KleisliF, G>, D>, A> {
        return Kleisli.pure(a, applicative)
    }
    
    public func ap<A, B>(_ fa: HK<HK<HK<KleisliF, G>, D>, A>, _ ff: HK<HK<HK<KleisliF, G>, D>, (A) -> B>) -> HK<HK<HK<KleisliF, G>, D>, B> {
        return Kleisli.ev(fa).ap(Kleisli.ev(ff), applicative)
    }
}

public class KleisliMonad<G, D, MonG> : KleisliApplicative<G, D, MonG>, Monad where MonG : Monad, MonG.F == G {
    
    fileprivate let monad : MonG
    
    override public init(_ monad : MonG) {
        self.monad = monad
        super.init(monad)
    }
    
    public func flatMap<A, B>(_ fa: HK<HK<HK<KleisliF, G>, D>, A>, _ f: @escaping (A) -> HK<HK<HK<KleisliF, G>, D>, B>) -> HK<HK<HK<KleisliF, G>, D>, B> {
        return Kleisli.ev(fa).flatMap({ a in Kleisli.ev(f(a)) }, monad)
    }
    
    public func tailRecM<A, B>(_ a: A, _ f: @escaping (A) -> HK<HK<HK<KleisliF, G>, D>, Either<A, B>>) -> HK<HK<HK<KleisliF, G>, D>, B> {
        return Kleisli.tailRecM(a, f, monad)
    }
}

public class KleisliMonadReader<G, E, MonG> : KleisliMonad<G, E, MonG>, MonadReader where MonG : Monad, MonG.F == G {
    public typealias D = E
    
    public func ask() -> HK<HK<HK<KleisliF, G>, E>, E> {
        return Kleisli<G, E, E>.ask(monad)
    }
    
    public func local<A>(_ f: @escaping (E) -> E, _ fa: HK<HK<HK<KleisliF, G>, E>, A>) -> HK<HK<HK<KleisliF, G>, E>, A> {
        return Kleisli.ev(fa).local(f)
    }
}

public class KleisliMonadError<G, D, Err, MonErrG> : KleisliMonad<G, D, MonErrG>, MonadError where MonErrG : MonadError, MonErrG.F == G, MonErrG.E == Err {
    public typealias E = Err
    
    private let monadError : MonErrG
    
    override public init(_ monadError : MonErrG) {
        self.monadError = monadError
        super.init(monadError)
    }
    
    public func raiseError<A>(_ e: Err) -> HK<HK<HK<KleisliF, G>, D>, A> {
        return Kleisli<G, D, A>.raiseError(e, monadError)
    }
    
    public func handleErrorWith<A>(_ fa: HK<HK<HK<KleisliF, G>, D>, A>, _ f: @escaping (Err) -> HK<HK<HK<KleisliF, G>, D>, A>) -> HK<HK<HK<KleisliF, G>, D>, A> {
        return Kleisli.ev(fa).handleErrorWith({ e in Kleisli.ev(f(e)) }, monadError)
    }
}
