//
//  JobsSQSDriver.swift
//
//
//  Created by Vinh on 18/08/2023.
//

import Queues
import Foundation
import Vapor
import SotoSQS

// MARK: - AWS's SQS configuration
/// Make SQS configuration and use in configure.swift
public struct SQSQueuesConfiguration {
    let client: AWSClient
    let region: Region
    let queueURL: String
    
    init(client: AWSClient, region: Region, queueURL: String) {
        self.client = client
        self.region = region
        self.queueURL = queueURL
    }
}

// MARK: - Queue Composer
public struct QueueComposer {
    // SQS instance to handle all request to AWS's SQS
    let handler: SQS
    // Queue URL
    let queueURL: String
}

// MARK: -- SQS Queue
struct SQSQueue {
    let composer: QueueComposer
    let context: QueueContext
}

// MARK: - SQS
/// Register Amazone Web Service SQS in to Queue Driver
extension Application.Queues.Provider {

    /// Sets the driver to `Redis`
    /// - Parameter string: The `Redis` connection URL string
    /// - Throws: An error describing an invalid URL string
    /// - Returns: The new provider
    public static func sqs(client: AWSClient, region: Region, queueURL: String) throws -> Self {
        return .sqs(.init(client: client, region: region, queueURL: queueURL))
    }

    /// Sets the driver to `SQS`
    /// - Parameter configuration: The `SQSConfiguration` to enable the provider
    /// - Returns: The new provider
    public static func sqs(_ configuration: SQSQueuesConfiguration) -> Self {
        return .init {
            $0.queues.use(custom: SQSQueuesDriver(configuration: configuration))
        }
    }
}

// MARK: - A `QueuesDriver` for AWS SQS
public struct SQSQueuesDriver {
    let composer: QueueComposer

    /// Creates the SQSQueuesDriver
    /// - Parameters:
    ///   - configuration: The `SQSConfiguration` to boot the driver
    public init(configuration config: SQSQueuesConfiguration) {
        let sqs = SQS(client: config.client, region: config.region)

        self.composer = QueueComposer(handler: sqs, queueURL: config.queueURL)
    }
}

// MARK: - Make A SQS `QueuesDriver`
extension SQSQueuesDriver: QueuesDriver {
    /// Makes the `Queue`
    /// - Parameter context: Context to be passed to the creation of the `Queue`
    /// - Returns: The created `Queue`
    public func makeQueue(with context: QueueContext) -> Queue {
        SQSQueue(
            composer: self.composer,
            context: context
        )
    }

    /// Shuts down the driver
    public func shutdown() {
    }
}

// MARK: - SQS Queue implementation
extension SQSQueue: Queue {
    func get(_ id: JobIdentifier) -> EventLoopFuture<JobData> {
        let message: SQS.Message = self.context.application.jobPools[id.string]!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let jsonData = Data(message.body!.utf8)
        
        context.logger.info("Get job id \(id.string)")
        return self.context.eventLoop.makeCompletedFuture {
            try decoder.decode(JobData.self, from: jsonData)
        }
    }

    func set(_ id: JobIdentifier, to data: JobData) -> EventLoopFuture<Void> {
        // Convert to JSON string
        let jsonEncoder = JSONEncoder()
        let jsonData = try! jsonEncoder.encode(data)
        let jsonStr = String(data: jsonData, encoding: .utf8)!

        let sendRequest = SQS.SendMessageRequest(messageBody: jsonStr, queueUrl: self.composer.queueURL)
        return self.composer.handler.sendMessage(sendRequest)
            .map { result in
                context.logger.info("Add job id \(result.messageId!) - \(id.string)")

                return
            }
    }

    func clear(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        guard let message: SQS.Message = self.context.application.jobPools[id.string] else {
            return self.context.eventLoop.makeSucceededFuture(())
        }

        let receiptHandle = message.receiptHandle!

        // Make sure delete item in jobPools
        defer {
            self.context.application.jobPools[id.string] = nil
            context.logger.info("Delete job id \(id.string)")
        }

        let deleteRequest = SQS.DeleteMessageRequest(queueUrl: self.composer.queueURL, receiptHandle: receiptHandle)

        return self.composer.handler.deleteMessage(deleteRequest)
    }

    func pop() -> EventLoopFuture<JobIdentifier?> {
        let receiveRequest = SQS.ReceiveMessageRequest(maxNumberOfMessages: 1, queueUrl: self.composer.queueURL, waitTimeSeconds: 10)

        return self.composer.handler.receiveMessage(receiveRequest)
            .flatMapThrowing { result in
                let messages = result.messages ?? []

                guard let message = messages.first else {
                    return nil
                }

                self.context.application.jobPools[message.messageId!] = message

                context.logger.info("Pop job id \(message.messageId!)")
                return .init(string: message.messageId!)
            }
    }

    func push(_ id: JobIdentifier) -> EventLoopFuture<Void> {
        // Don't support for AWS SQS
        return self.context.eventLoop.makeSucceededFuture(())
    }
}

struct JobPoolStorageKey: StorageKey {
    typealias Value = [String: SQS.Message]
}

private extension Application {
    var jobPools: [String: SQS.Message] {
        get {
            self.storage[JobPoolStorageKey.self] ?? [:]
        }
        set {
            self.storage[JobPoolStorageKey.self] = newValue
        }
    }
}
