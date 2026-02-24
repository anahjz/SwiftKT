//
//  KotlinCollectionError.swift
//  SwiftKT
//
//  Error types that approximate Kotlin's collection-related exceptions:
//  - NoSuchElementException
//  - IllegalArgumentException
//  - IndexOutOfBoundsException
//

import Foundation

public enum KotlinCollectionError: Error, Sendable {

    /// Kotlin: `NoSuchElementException`
    case noSuchElement

    /// Kotlin: `IllegalArgumentException`
    case illegalState(String)
}

