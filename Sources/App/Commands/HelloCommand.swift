//
//  HelloCommand.swift
//
//
//  Created by Vinh on 19/08/2023.
//

import Foundation
import Vapor
import Queues

/// Sample command
///     #swift run App hello
///
struct HelloCommand: AsyncCommand {
    static let name = "hello"

    struct Signature: CommandSignature {
    }

    var help: String {
        "Create some queues"
    }

    func asyncRun(using context: CommandContext, signature: Signature) async throws {
        let app: Application = context.application
        let queue: Queue = app.queues.queue

        for i in 1...3 {
            let emailData = EmailData(address: "vinh+\(i)@gmail.com",
                                      subject: "Testing SQS+\(i)",
                                      message: "Hello everybody+\(i)")

            try await queue.dispatch(EmailJob.self, emailData)
        }
        app.logger.info("Created queues")
    }
}
