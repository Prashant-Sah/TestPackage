import Foundation
import Combine
import Framework

public protocol Uploader {
    /// common file upload
    func uploadFile(file: File)

    /// The upload trigger
    var uploadResult: PassthroughSubject<UploadResult, Never> { get set }

    /// common file upload, requires Router info for upload to server
    func uploadFile(file: File, router: NetworkingRouter)

    /// cancel file upload
    func cancel(_ file: File)
}

extension Uploader {

    public func uploadFile(file: File) { }

    public func uploadFile(file: File, router: NetworkingRouter) { }

}

