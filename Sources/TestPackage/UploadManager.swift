//
//  UploadManager.swift
//  Ice Breaker
//
//  Created by mukesh on 9/17/20.
//  Copyright © 2020 Ebpearls. All rights reserved.
//

import Foundation
import Combine

final public class UploadManager {
    
    /// The operation queueus
    private let pendingOperations = PendingOperations(concurrent: true)
    
    /// The subscription holder bag
    private var bag = Set<AnyCancellable>()
    
    /// The file upload result trigger
    public var trigger = PassthroughSubject<UploadResult, Never>()
    
    /// The file AWS uploader
    private let fileUploader: Uploader
   
    /// Initializer
    public init(fileUploader: Uploader) {
        self.fileUploader = fileUploader
    }
    
    /// Start the operation for uploading file
    /// - Parameter file: the file that will be uploaded
    public func uploadFile(file: File) {
        let uploadSynchronizer = UploadSyncronizer(uploader: fileUploader, file: file)
        addQueue(queueable: uploadSynchronizer)
    }
    
    /// Method to add operations to the queue
    /// - Parameter queueable: the queueable that will handle the states
    private func addQueue(queueable: OperationQueueable) {
        
        // create the queueable operation
        let operation = FrameworkOperation(queueable: queueable)
        
        // check when the operation completes
        operation.completionBlock = {[weak self] in
            guard let self = self else { return }
            self.pendingOperations.inProgressOperation.removeValue(forKey: operation.operationIdentifier)
        }
        
        /// add to the pending operations
        pendingOperations.inProgressOperation[operation.operationIdentifier] = operation
        pendingOperations.operationQueue.addOperation(operation)
        
        /// observe the trigger
        queueable.trigger.sink { [weak self] (state) in
            guard let self = self else { return }
            switch state {
            case .resumeQueue:
                self.pendingOperations.operationQueue.isSuspended = false
            case .suspendQueue:
                self.pendingOperations.operationQueue.isSuspended = true
            case .terminate:
                self.pendingOperations.operationQueue.cancelAllOperations()
            case .completed(let result), .pending(let result):
                guard let uploadResult = result as? UploadResult else {
                    assertionFailure("The result received is not of type UploadResult")
                    return
                }
                self.trigger.send(uploadResult)
            }
        }.store(in: &bag)
    }
    
    /// Cancels the uploading of specific file
    /// - Parameter file: the file who's uploading needs to be cancelled
    func cancelUploading(file: File) {
        #warning("")
        //fileUploader.cancel(file)
    }
}
