//
//  AsyncCommand.swift
//
//
//  Created by Vinh on 19/08/2023.
//

import Foundation
import Vapor

/// AsyncCommand protocol
protocol AsyncCommand: Command {
    func asyncRun(using context: CommandContext, signature: Signature) async throws
}

extension AsyncCommand {
    func run(using context: CommandContext, signature: Signature) throws {
        let promise = context
            .application
            .eventLoopGroup
            .next()
            .makePromise(of: Void.self)
        
        promise.completeWithTask {
            try await asyncRun(
                using: context,
                signature: signature
            )
        }

        try promise.futureResult.wait()
    }
}
