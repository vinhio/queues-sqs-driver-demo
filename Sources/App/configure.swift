import Vapor
import SotoCore
import QueuesRedisDriver

// configures your application
public func configure(_ app: Application) async throws {
    // Create AWSClient
    app.aws.client = AWSClient(
        credentialProvider: .static(accessKeyId: "do-not-show", secretAccessKey: "do-not-show"),
        httpClientProvider: .createNew
    )

    // Inital SQS queue
    let queueConfiguration = SQSQueuesConfiguration(
        client: app.aws.client,
        region: .uswest1,
        queueURL: "https://sqs.us-west-1.amazonaws.com/041855559468/swift-sqs"
    )
    app.queues.use(.sqs(queueConfiguration))

    // Inital Redis queue
//    try app.queues.use(.redis(.init(url: "redis://127.0.0.1:6379", pool: .init(connectionRetryTimeout: .seconds(60)))))

    // Register Queue Job
    let emailJob = EmailJob()
    app.queues.add(emailJob)

    // Register Command
    app.commands.use(HelloCommand(), as: HelloCommand.name)

    // register routes
    try routes(app)
}

// MARK: - Soto integration
/// Define a shared AWS using the Application extension.
extension Application {
    var aws: AWS {
        .init(application: self)
    }

    struct AWS {
        struct ClientKey: StorageKey {
            typealias Value = AWSClient
        }

        public var client: AWSClient {
            get {
                guard let client = self.application.storage[ClientKey.self] else {
                    fatalError("AWSClient not setup. Use application.aws.client = ...")
                }
                return client
            }
            nonmutating set {
                self.application.storage.set(ClientKey.self, to: newValue) {
                    // Auto shutdown when try to set new AWSClient instance
                    try $0.syncShutdown()
                }
            }
        }

        let application: Application
    }
}
