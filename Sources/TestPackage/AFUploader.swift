//
//  File.swift
//  
//
//  Created by Prashant Sah on 10/13/20.
//

import Foundation

final public class AFUploader: Uploader {

    public var uploadResult: PassthroughSubject<UploadResult, Never> = PassthroughSubject<UploadResult, Never>()

    public func uploadFile(file: File, router: NetworkingRouter) {
        do {
            let urlRequest = try router.getRequest()
            // determine multipart params
            var jsonParams: [String: Any]?
            for encoder in router.encoders {
                switch encoder {
                case .json(let params):
                    jsonParams = params
                default:
                    break
                }
            }
            if let data = file.fileData {
                uploadDataFile(file: file, data: data, params: jsonParams, url: urlRequest)
            } else if let fileUrl = file.fileURL {
                uploadPathFile(file: file, fileurl: fileUrl, url: urlRequest)
            }
        } catch {
            assertionFailure("The url could not be made")
        }
    }

    /// Upload file with data
    /// - Parameters:
    ///   - file: File object
    ///   - data: data
    ///   - params: multipart params if required
    ///   - url: The url of the api
    private func uploadDataFile(file: File, data: Data, params: [String: Any]?, url: URLRequestConvertible) {
         AF.upload(multipartFormData: { (formData) in
            formData.append(data, withName: file.uploadKey)
            if let params = params {
                for (key, value) in params {
                    formData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
                }
            }
        }, with: url).uploadProgress(queue: .main) ({ [weak self] (progress) in
            guard let self = self else { return }
            self.uploadResult.send(.progress(file, progress))
            print("progress: \(progress.fractionCompleted)")
        }).responseJSON { [weak self] (response) in
            guard let self = self else { return }
            switch response.result {
            case .success(let response):
                file.uploadResponse = response
                self.uploadResult.send(.success(file))
            case .failure(let error):
                self.uploadResult.send(.failure(file, error))
            }
        }
    }

    /// Method to perform the file upload when file path is provided
    /// - Parameters:
    ///   - file: The file info
    ///   - fileurl: the url of the file location
    ///   - expression: The url of the api
    private func uploadPathFile(file: File, fileurl: URL, url: URLRequestConvertible) {
        AF.upload(fileurl, with: url).uploadProgress(queue: .main) { [weak self] (progress) in
            guard let self = self else { return }
            self.uploadResult.send(.progress(file, progress))
            print("progress: \(progress.fractionCompleted)")
        }.responseJSON { [weak self] (response) in
            guard let self = self else { return }
            switch response.result {
            case .success(let response):
                file.uploadResponse = response
                self.uploadResult.send(.success(file))
            case .failure(let error):
                self.uploadResult.send(.failure(file, error))
            }
        }
    }

    public func cancel(_ file: File) {

    }

}

