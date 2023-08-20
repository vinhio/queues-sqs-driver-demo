//
//  EmailJob.swift
//
//
//  Created by Vinh on 19/08/2023.
//

import Foundation
import Vapor
import Queues

struct EmailData: Content {
    let address: String
    let subject: String
    let message: String
}

///
/// Email Job
///   #swift run App queues
///      #swift run App queues --queue emails
///
struct EmailJob: AsyncJob {
    typealias Payload = EmailData

    func dequeue(_ context: QueueContext, _ payload: EmailData) async throws {
        context.logger.info("Sent email `\(payload.subject)` to `\(payload.address)` at \(Date())")
    }

    func error(_ context: QueueContext, _ error: Error, _ payload: EmailData) async throws {
        context.logger.error("Error sent email `\(payload.subject)` to `\(payload.address)`. Error \(error)")
    }
}

