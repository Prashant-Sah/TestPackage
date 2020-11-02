//
//  File.swift
//  
//
//  Created by Prashant Sah on 10/13/20.
//

import Foundation
import Combine

/// The file uploader class
public final class AWSUploader: Uploader {

    /// The AWS uploader configuration
    private let config: UploaderConfig

    /// This will used for the proper file URL when upload is done
    private(set) public var awsBaseURl: URL!

    /// The upload trigger
    public var uploadResult = PassthroughSubject<UploadResult, Never>()

    /// start the upload
    private var transferUtility: AWSS3TransferUtility!

    /// Init with the configuration
    init(config: UploaderConfig) {
        self.config = config
        self.initialize()
    }

    /// The methid to initialize cognito provider and transfer utility
    private func initialize() {

        /// check that all required configuration info is provided
        assert(config.regionType != nil, "The region for the AWS server is required.")
        assert(!config.identityPoolId.isEmpty, "The identity pool Id is required.")
        assert(!config.bucketName.isEmpty, "The bucket name is required.")

        /// create the AWS configuration
        let provider = AWSCognitoCredentialsProvider(regionType: config.regionType, identityPoolId: config.identityPoolId)
        let serviceConfiguration = AWSServiceConfiguration(region: config.regionType, credentialsProvider: provider)

        /// set the configuartion
        AWSServiceManager.default().defaultServiceConfiguration = serviceConfiguration

        /// set the base url from the configration
        awsBaseURl = AWSS3.default().configuration.endpoint.url

        /// set the transfer utility
        transferUtility = AWSS3TransferUtility.default()
    }

    /// Method to upload the file
    /// - Parameter file: the file to upload
    public func uploadFile(file: File) {
        // set the expression
        let expression = AWSS3TransferUtilityUploadExpression()

        /// listen for progress
        expression.progressBlock = { [weak self] _, progress in
            guard let self = self else { return }
            self.uploadResult.send(.progress(file, progress))
        }

        /// start upload based on either data or file url which ever is provided
        if let data = file.fileData {
            self.uploadDataFile(file: file, data: data, expression: expression)
        } else if let fileurl = file.fileURL {
            self.uploadPathFile(file: file, fileurl: fileurl, expression: expression)
        }
    }

    /// Method to perform the file upload when file data is provided
    /// - Parameters:
    ///   - file: the file info
    ///   - data: the file data
    ///   - expression: the aws expression
    private func uploadDataFile(file: File, data: Data, expression: AWSS3TransferUtilityUploadExpression) {
        transferUtility.uploadData(data, bucket: config.bucketName, key: file.key, contentType: file.mimeType.mimeIdentifier, expression: expression) { [weak self] (_, error) in
            guard let self = self else { return }
            if let error = error {
                self.uploadResult.send(.failure(file, error))
            } else {
                self.setUploadedURLToFile(file: file)
                self.uploadResult.send(.success(file))
            }
        }.continueWith { [weak self] task -> Any? in
            file.identifier = task.result?.taskIdentifier
            guard let self = self else { return nil }
            if let error = task.error {
                self.uploadResult.send(.failure(file, error))
            }
            return nil
        }
    }

    /// Method to perform the file upload when file path is provided
    /// - Parameters:
    ///   - file: The file info
    ///   - fileurl: the url of the file location
    ///   - expression: the aws expression
    private func uploadPathFile(file: File, fileurl: URL, expression: AWSS3TransferUtilityUploadExpression) {
        transferUtility.uploadFile(fileurl, bucket: config.bucketName, key: file.key, contentType: file.mimeType.mimeIdentifier, expression: expression) { [weak self] (_, error) in
            guard let self = self else { return }
            if let error = error {
                self.uploadResult.send(.failure(file, error))
            } else {
                self.setUploadedURLToFile(file: file)
                self.uploadResult.send(.success(file))
            }
        }.continueWith { [weak self] task -> Any? in
            file.identifier = task.result?.taskIdentifier
            guard let self = self else { return nil }
            if let error = task.error {
                self.uploadResult.send(.failure(file, error))
            }
            return nil
        }
    }

    /// Sets the uploaded file url for the file
    /// - Parameter file: the file that has completed uploading
    private func setUploadedURLToFile(file: File) {
        let awsURL = awsBaseURl.appendingPathComponent(config.bucketName).appendingPathComponent(file.key)
        file.uploadedURLString = awsURL.absoluteString
    }

    /// Cancels a upload task for the file that's being uploaded
    /// - Parameter file: the file being uploaded
    public func cancel(_ file: File) {
        guard let identifier = file.identifier else { return }
        transferUtility.enumerateToAssignBlocks(forUploadTask: { [weak self] task, _, _ in
            guard let self = self else { return }
            if task.taskIdentifier == identifier {
                task.cancel()
                self.uploadResult.send(.cancelled(file))
            }
        }, downloadTask: nil)
    }
}
