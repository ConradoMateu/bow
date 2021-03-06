//
//  WriterT.swift
//  Bow
//
//  Created by Tomás Ruiz López on 10/10/17.
//  Copyright © 2017 Tomás Ruiz López. All rights reserved.
//

import Foundation

public class WriterTF {}
public typealias WriterTPartial<F, W> = HK2<WriterTF, F, W>

public class WriterT<F, W, A> : HK3<WriterTF, F, W, A> {
    fileprivate let value : HK<F, (W, A)>
    
    public static func pure<Mono, Appl>(_ a : A, _ monoid : Mono, _ applicative : Appl) -> WriterT<F, W, A> where Mono : Monoid, Mono.A == W, Appl : Applicative, Appl.F == F {
        return WriterT(applicative.pure((monoid.empty, a)))
    }
    
    public static func both<Appl>(_ w : W, _ a : A, _ applicative : Appl) -> WriterT<F, W, A> where Appl : Applicative, Appl.F == F {
        return WriterT(applicative.pure((w, a)))
    }
    
    public static func fromTuple<Appl>(_ z : (W, A), _ applicative : Appl) -> WriterT<F, W, A> where Appl : Applicative, Appl.F == F {
        return WriterT(applicative.pure(z))
    }
    
    public static func putT<Func>(_ fa : HK<F, A>, _ w : W, _ functor : Func) -> WriterT<F, W, A> where Func : Functor, Func.F == F {
        return WriterT(functor.map(fa, { a in (w, a) }))
    }
    
    public static func put<Appl>(_ a : A, _ w : W, _ applicative : Appl) -> WriterT<F, W, A> where Appl : Applicative, Appl.F == F {
        return WriterT.putT(applicative.pure(a), w, applicative)
    }
    
    public static func putT2<Func>(_ vf : HK<F, A>, _ w : W, _ functor : Func) -> WriterT<F, W, A> where Func : Functor, Func.F == F {
        return WriterT(functor.map(vf, { v in (w, v) }))
    }
    
    public static func put2<Appl>(_ a : A, _ w : W, _ applicative : Appl) -> WriterT<F, W, A> where Appl : Applicative, Appl.F == F {
        return WriterT.putT2(applicative.pure(a), w, applicative)
    }

    public static func tell<Appl>(_ l : W, _ applicative : Appl) -> WriterT<F, W, Unit> where Appl : Applicative, Appl.F == F {
        return WriterT<F, W, Unit>.put(unit, l, applicative)
    }
    
    public static func value<Appl, Mono>(_ a : A, _ applicative : Appl, _ monoid : Mono) -> WriterT<F, W, A> where Appl : Applicative, Appl.F == F, Mono : Monoid, Mono.A == W {
        return WriterT.put(a, monoid.empty, applicative)
    }
    
    public static func valueT<Func, Mono>(_ fa : HK<F, A>, _ functor : Func, _ monoid : Mono) -> WriterT<F, W, A> where Func : Functor, Func.F == F, Mono : Monoid, Mono.A == W {
        return WriterT.putT(fa, monoid.empty, functor)
    }
    
    public static func empty<MonoK>(_ monoidK : MonoK) -> WriterT<F, W, A> where MonoK : MonoidK, MonoK.F == F {
        return WriterT(monoidK.emptyK())
    }
    
    public static func pass<Mon>(_ fa : WriterT<F, W, ((W) -> W, A)>, _ monad : Mon) -> WriterT<F, W, A> where Mon : Monad, Mon.F == F {
        return WriterT(monad.flatMap(fa.content(monad), { tuple2FA in monad.map(fa.write(monad), { l in (tuple2FA.0(l), tuple2FA.1) }) }))
    }
    
    public static func tailRecM<B, Mon>(_ a : A, _ f : @escaping (A) -> HK<WriterTPartial<F, W>, Either<A, B>>, _ monad : Mon) -> WriterT<F, W, B> where Mon : Monad, Mon.F == F {
        return WriterT<F, W, B>(monad.tailRecM(a, { inA in
            monad.map(WriterT<F, W, Either<A, B>>.ev(f(inA)).value, { pair in
                pair.1.fold(Either<A, (W, B)>.left,
                            { b in Either<A, (W, B)>.right((pair.0, b)) })
            })
        }))
    }
    
    public static func ev(_ fa : HK3<WriterTF, F, W, A>) -> WriterT<F, W, A> {
        return fa as! WriterT<F, W, A>
    }
    
    public init(_ value : HK<F, (W, A)>) {
        self.value = value
    }
    
    public func map<B, Func>(_ f : @escaping (A) -> B, _ functor : Func) -> WriterT<F, W, B> where Func : Functor, Func.F == F {
        return WriterT<F, W, B>(functor.map(value, { pair in (pair.0, f(pair.1)) }))
    }
    
    public func mapAcc<U, Mon>(_ f : @escaping (W) -> U, _ monad : Mon) -> WriterT<F, U, A> where Mon : Monad, Mon.F == F {
        return transform({ pair in (f(pair.0), pair.1) }, monad)
    }
    
    public func bimap<B, U, Mon>(_ g : @escaping (W) -> U, _ f : @escaping (A) -> B, _ monad : Mon) -> WriterT<F, U, B> where Mon : Monad, Mon.F == F {
        return transform({ pair in (g(pair.0), f(pair.1))}, monad)
    }
    
    public func liftF<B, Appl>(_ fb : HK<F, B>, _ applicative : Appl) -> WriterT<F, W, B> where Appl : Applicative, Appl.F == F {
        return WriterT<F, W, B>(applicative.map2(fb, value, { x, y in (y.0, x) }))
    }
    
    public func ap<B, SemiG, Mon>(_ ff : WriterT<F, W, (A) -> B>, _ semigroup : SemiG, _ monad : Mon) -> WriterT<F, W, B> where SemiG : Semigroup, SemiG.A == W, Mon : Monad, Mon.F == F {
        return ff.flatMap({ pair in self.map(pair, monad)}, semigroup, monad)
    }
    
    public func flatMap<B, SemiG, Mon>(_ f : @escaping (A) -> WriterT<F, W, B>, _ semigroup : SemiG, _ monad : Mon) -> WriterT<F, W, B> where SemiG : Semigroup, SemiG.A == W, Mon : Monad, Mon.F == F {
        return WriterT<F, W, B>(monad.flatMap(value, { pair in monad.map(f(pair.1).value, { pair2 in (semigroup.combine(pair.0, pair2.0), pair2.1) }) }))
    }
    
    public func semiflatMap<B, SemiG, Mon>(_ f : @escaping (A) -> HK<F, B>, _ semigroup : SemiG, _ monad : Mon) -> WriterT<F, W, B> where SemiG : Semigroup, SemiG.A == W, Mon : Monad, Mon.F == F {
        return flatMap({ a in self.liftF(f(a), monad) }, semigroup, monad)
    }
    
    public func subflatMap<B, Mon>(_ f : @escaping (A) -> (W, B), _ monad : Mon) -> WriterT<F, W, B> where Mon : Monad, Mon.F == F {
        return transform({ pair in f(pair.1) }, monad)
    }
    
    public func transform<B, U, Mon>(_ f : @escaping ((W, A)) -> (U, B), _ monad : Mon) -> WriterT<F, U, B> where Mon : Monad, Mon.F == F {
        return WriterT<F, U, B>(monad.flatMap(value, { pair in monad.pure(f(pair)) }))
    }
    
    public func swap<Mon>(_ monad : Mon) -> WriterT<F, A, W> where Mon : Monad, Mon.F == F {
        return transform({ pair in (pair.1, pair.0) }, monad)
    }
    
    public func combineK<SemiGK>(_ y : WriterT<F, W, A>, _ semigroupK : SemiGK) -> WriterT<F, W, A> where SemiGK : SemigroupK, SemiGK.F == F {
        return WriterT(semigroupK.combineK(value, y.value))
    }
    
    public func tell<SemiG, Mon>(_ w : W, _ semigroup : SemiG, _ monad : Mon) -> WriterT<F, W, A> where SemiG : Semigroup, SemiG.A == W, Mon : Monad, Mon.F == F {
        return mapAcc({ inW in semigroup.combine(inW, w) }, monad)
    }
    
    public func listen<Mon>(_ monad : Mon) -> HK<WriterTPartial<F, W>, (W, A)> where Mon : Monad, Mon.F == F {
        return WriterT<F, W, (W, A)>(monad.flatMap(content(monad), { a in monad.map(self.write(monad), { l in (l, (l, a)) }) }))
    }
    
    public func content<Func>(_ functor : Func) -> HK<F, A> where Func : Functor, Func.F == F {
        return functor.map(value, { pair in pair.1 })
    }
    
    public func write<Func>(_ functor : Func) -> HK<F, W> where Func : Functor, Func.F == F {
        return functor.map(value, { pair in pair.0 })
    }
    
    public func reset<Mono, Mon>(_ monoid : Mono, _ monad : Mon) -> WriterT<F, W, A> where Mono : Monoid, Mono.A == W, Mon : Monad, Mon.F == F {
        return mapAcc(constF(monoid.empty), monad)
    }
}

public extension WriterT {
    public static func functor<FuncF>(_ functor : FuncF) -> WriterTFunctor<F, W, FuncF> {
        return WriterTFunctor<F, W, FuncF>(functor)
    }
    
    public static func applicative<MonF, MonoW>(_ monad : MonF, _ monoid : MonoW) -> WriterTApplicative<F, W, MonF, MonoW> {
        return WriterTApplicative<F, W, MonF, MonoW>(monad, monoid)
    }
    
    public static func monad<MonF, MonoW>(_ monad : MonF, _ monoid : MonoW) -> WriterTMonad<F, W, MonF, MonoW> {
        return WriterTMonad<F, W, MonF, MonoW>(monad, monoid)
    }
    
    public static func monadFilter<MonFilF, MonoW>(_ monad : MonFilF, _ monoid : MonoW) -> WriterTMonadFilter<F, W, MonFilF, MonoW> {
        return WriterTMonadFilter<F, W, MonFilF, MonoW>(monad, monoid)
    }
    
    public static func semigroupK<SemiKF>(_ semigroupK : SemiKF) -> WriterTSemigroupK<F, W, SemiKF> {
        return WriterTSemigroupK<F, W, SemiKF>(semigroupK)
    }

    public static func monoidK<MonoKF>(_ monoidK : MonoKF) -> WriterTMonoidK<F, W, MonoKF> {
        return WriterTMonoidK<F, W, MonoKF>(monoidK)
    }
    
    public static func writer<MonF, MonoW>(_ monad : MonF, _ monoid : MonoW) -> WriterTMonadWriter<F, W, MonF, MonoW> {
        return WriterTMonadWriter<F, W, MonF, MonoW>(monad, monoid)
    }
    
    public static func eq<EqF>(_ eq : EqF) -> WriterTEq<F, W, A, EqF> {
        return WriterTEq<F, W, A, EqF>(eq)
    }
}

public class WriterTFunctor<G, W, FuncG> : Functor where FuncG : Functor, FuncG.F == G {
    public typealias F = WriterTPartial<G, W>
    
    private let functor : FuncG
    
    public init(_ functor : FuncG) {
        self.functor = functor
    }
    
    public func map<A, B>(_ fa: HK<HK<HK<WriterTF, G>, W>, A>, _ f: @escaping (A) -> B) -> HK<HK<HK<WriterTF, G>, W>, B> {
        return WriterT.ev(fa).map(f, functor)
    }
}

public class WriterTApplicative<G, W, MonG, MonoW> : WriterTFunctor<G, W, MonG>, Applicative where MonG : Monad, MonG.F == G, MonoW : Monoid, MonoW.A == W {
    
    fileprivate let monad : MonG
    fileprivate let monoid : MonoW
    
    public init(_ monad : MonG, _ monoid : MonoW) {
        self.monad = monad
        self.monoid = monoid
        super.init(monad)
    }
    
    public func pure<A>(_ a: A) -> HK<HK<HK<WriterTF, G>, W>, A> {
        return WriterT(monad.pure((monoid.empty, a)))
    }
    
    public func ap<A, B>(_ fa: HK<HK<HK<WriterTF, G>, W>, A>, _ ff: HK<HK<HK<WriterTF, G>, W>, (A) -> B>) -> HK<HK<HK<WriterTF, G>, W>, B> {
        return WriterT.ev(fa).ap(WriterT.ev(ff), monoid, monad)
    }
}

public class WriterTMonad<G, W, MonG, MonoW> : WriterTApplicative<G, W, MonG, MonoW>, Monad where MonG : Monad, MonG.F == G, MonoW : Monoid, MonoW.A == W {
    
    public func flatMap<A, B>(_ fa: HK<HK<HK<WriterTF, G>, W>, A>, _ f: @escaping (A) -> HK<HK<HK<WriterTF, G>, W>, B>) -> HK<HK<HK<WriterTF, G>, W>, B> {
        return WriterT.ev(fa).flatMap({ a in WriterT.ev(f(a)) }, monoid, monad)
    }
    
    public func tailRecM<A, B>(_ a: A, _ f: @escaping (A) -> HK<HK<HK<WriterTF, G>, W>, Either<A, B>>) -> HK<HK<HK<WriterTF, G>, W>, B> {
        return WriterT.tailRecM(a, f, monad)
    }
}

public class WriterTMonadFilter<G, W, MonFilG, MonoW> : WriterTMonad<G, W, MonFilG, MonoW>, MonadFilter where MonFilG : MonadFilter, MonFilG.F == G, MonoW : Monoid, MonoW.A == W {
    
    private let monadFilter : MonFilG
    
    override public init(_ monadFilter : MonFilG, _ monoid : MonoW) {
        self.monadFilter = monadFilter
        super.init(monadFilter, monoid)
    }
    
    public func empty<A>() -> HK<HK<HK<WriterTF, G>, W>, A> {
        return WriterT(monadFilter.empty())
    }
}

public class WriterTSemigroupK<G, W, SemiKG> : SemigroupK where SemiKG : SemigroupK, SemiKG.F == G {
    public typealias F = WriterTPartial<G, W>
    
    private let semigroupK : SemiKG
    
    public init(_ semigroupK : SemiKG) {
        self.semigroupK = semigroupK
    }
    
    public func combineK<A>(_ x: HK<HK<HK<WriterTF, G>, W>, A>, _ y: HK<HK<HK<WriterTF, G>, W>, A>) -> HK<HK<HK<WriterTF, G>, W>, A> {
        return WriterT.ev(x).combineK(WriterT.ev(y), semigroupK)
    }
}

public class WriterTMonoidK<G, W, MonoKG> : WriterTSemigroupK<G, W, MonoKG>, MonoidK where MonoKG : MonoidK, MonoKG.F == G {
    
    private let monoidK : MonoKG
    
    override public init(_ monoidK : MonoKG) {
        self.monoidK = monoidK
        super.init(monoidK)
    }
    
    public func emptyK<A>() -> HK<HK<HK<WriterTF, G>, W>, A> {
        return WriterT(monoidK.emptyK())
    }
}

public class WriterTMonadWriter<G, V, MonG, MonoW> : WriterTMonad<G, V, MonG, MonoW>, MonadWriter where MonG : Monad, MonG.F == G, MonoW : Monoid, MonoW.A == V {
    public typealias W = V
    
    public func writer<A>(_ aw: (V, A)) -> HK<HK<HK<WriterTF, G>, V>, A> {
        return WriterT.put2(aw.1, aw.0, monad)
    }
    
    public func listen<A>(_ fa: HK<HK<HK<WriterTF, G>, V>, A>) -> HK<HK<HK<WriterTF, G>, V>, (V, A)> {
        return WriterT(monad.flatMap(WriterT.ev(fa).content(self.monad), { a in
            self.monad.map(WriterT.ev(fa).write(self.monad), { l in
                (l, (l, a))
            })
        }))
    }
    
    public func pass<A>(_ fa: HK<HK<HK<WriterTF, G>, V>, ((V) -> V, A)>) -> HK<HK<HK<WriterTF, G>, V>, A> {
        return WriterT<G, V, A>.pass(WriterT.ev(fa), monad)
    }
}

public class WriterTEq<F, W, B, EqF> : Eq where EqF : Eq, EqF.A == HK<F, (W, B)> {
    public typealias A = HK3<WriterTF, F, W, B>
    
    private let eq : EqF
    
    public init(_ eq : EqF) {
        self.eq = eq
    }
    
    public func eqv(_ a: HK<HK<HK<WriterTF, F>, W>, B>, _ b: HK<HK<HK<WriterTF, F>, W>, B>) -> Bool {
        let a = WriterT.ev(a)
        let b = WriterT.ev(b)
        return eq.eqv(a.value, b.value)
    }
}








