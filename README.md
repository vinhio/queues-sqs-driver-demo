### Congiguration
Update `accessKeyId` and `secretAccessKey`, region, and queueURL in configure.swift file

    app.aws.client = AWSClient(
        credentialProvider: .static(accessKeyId: "do-not-show", secretAccessKey: "do-not-show"),
        httpClientProvider: .createNew
    )
    ....
    region: .uswest1,
    queueURL: "https://sqs.us-west-1.amazonaws.com/041855559468/swift-sqs"

### Process queues

    swift run App queues

### Create queues

    swift run App hello

