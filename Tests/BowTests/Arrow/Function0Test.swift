//
//  Function0Test.swift
//  BowTests
//
//  Created by Tomás Ruiz López on 21/11/17.
//  Copyright © 2017 Tomás Ruiz López. All rights reserved.
//

import XCTest
@testable import Bow

class Function0Test: XCTestCase {
    
    var generator : (Int) -> HK<Function0F, Int> {
        return { a in Function0.pure(a) }
    }
    
    let eq = Function0.eq(Int.order)
    let eqUnit = Function0.eq(UnitEq())
    
    func testEqLaws() {
        EqLaws.check(eq: self.eq, generator: self.generator)
    }
    
    func testFunctorLaws() {
        FunctorLaws<Function0F>.check(functor: Function0<Int>.functor(), generator: self.generator, eq: self.eq, eqUnit: self.eqUnit)
    }
    
    func testApplicativeLaws() {
        ApplicativeLaws<Function0F>.check(applicative: Function0<Int>.applicative(), eq: self.eq)
    }
    
    func testMonadLaws() {
        MonadLaws<Function0F>.check(monad: Function0<Int>.monad(), eq: self.eq)
    }
    
    func testComonadLaws() {
        ComonadLaws<Function0F>.check(comonad: Function0<Int>.comonad(), generator: self.generator, eq: self.eq)
    }
}
