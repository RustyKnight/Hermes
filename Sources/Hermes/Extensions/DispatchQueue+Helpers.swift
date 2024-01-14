//
//  DispatchQueue+Helpers.swift
//  SwannSecurityDeviceKit
//
//  Created by Shane Whitehead on 22/9/20.
//  Copyright © 2020 Shane Whitehead. All rights reserved.
//

import Foundation

extension DispatchQueue {    
    static let userInitiated = DispatchQueue.global(qos: .userInitiated)
    static let background = DispatchQueue.global(qos: .background)
    static let utility = DispatchQueue.global(qos: .utility)
    static let userInteractive = DispatchQueue.global(qos: .userInteractive)
    
    struct Concurrent {
        static let userInitiated = DispatchQueue(label: "SwannSecurity.concurrentUserInitiated", qos: .userInitiated, attributes: [.concurrent])
        static let background = DispatchQueue(label: "SwannSecurity.concurrentBackground", qos: .background, attributes: [.concurrent])
        static let utility = DispatchQueue(label: "SwannSecurity.concurrentUtility", qos: .utility, attributes: [.concurrent])
        static let userInteractive = DispatchQueue(label: "SwannSecurity.concurrentInteractive", qos: .userInteractive, attributes: [.concurrent])
    }
    
}
