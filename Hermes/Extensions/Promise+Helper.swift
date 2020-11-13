//
//  Promise+Helper.swift
//  TestPromiseKit
//
//  Created by Shane Whitehead on 24/9/20.
//

import Foundation
import PromiseKit

func firstly<U: Thenable>(on queue: DispatchQueue, execute body: @escaping () throws -> U) -> Promise<U.T> {
	return Promise<U.T> { (resolver) in
		queue.async {
			do {
				try body().pipe(to: resolver.resolve)
			} catch {
				resolver.reject(error)
			}
		}
	}
}

extension Promise {
	static func on<U>(_ dispatchQueue: DispatchQueue, execute body: @escaping (_ resolver: Resolver<U>) throws -> Void) -> Promise<U> {
		return Promise<U> { seal in
			dispatchQueue.async {
				do {
					try body(seal)
				} catch let error {
					seal.reject(error)
				}
			}
		}
	}
}

extension Promise {
	static func asVoid() -> Promise<Void> {
		return Promise<Void>().asVoid()
	}
}

func retry<T>(_ retries: Int, when condition: ((Error) -> Bool)? = nil, _ body: @escaping () -> Promise<T>) -> Promise<T> {
	var attempts = 0
	func attempt() -> Promise<T> {
		attempts += 1
		return body().recover { (error) -> Promise<T> in
			guard condition?(error) ?? true else { throw error }
			attempts += 1
			print(attempts)
			guard attempts < retries else { throw error }
			return firstly(execute: attempt)
		}
	}
	return attempt()
}

