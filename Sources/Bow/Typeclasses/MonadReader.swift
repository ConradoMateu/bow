//
//  MonadReader.swift
//  Bow
//
//  Created by Tomás Ruiz López on 29/9/17.
//  Copyright © 2017 Tomás Ruiz López. All rights reserved.
//

import Foundation

public protocol MonadReader : Monad {
    associatedtype D
    
    func ask() -> HK<F, D>
    func local<A>(_ f : @escaping (D) -> D, _ fa : HK<F, A>) -> HK<F, A>
}

public extension MonadReader {
    public func reader<A>(_ f : @escaping (D) -> A) -> HK<F, A> {
        return self.map(ask(), f)
    }
}
