//
//  UploadSyncornizer.swift
//  Ice Breaker
//
//  Created by mukesh on 9/17/20.
//  Copyright © 2020 Ebpearls. All rights reserved.
//

import Foundation
import Combine
import Framework

final class UploadSyncronizer: OperationQueueable {
    
    /// The file uploader
    private let uploader: Uploader
    
    /// The file that will be uploaded
    private let file: File
    
    /// The cancellation bag for subscriptions
    private var bag = Set<AnyCancellable>()
    
    /// Protocol conformance of the trigger
    var trigger = PassthroughSubject<SynchronizerState, Never>()
    
    /// Initializer
    public init(uploader: Uploader, file: File) {
        self.uploader = uploader
        self.file = file
        connectionObserver()
    }

    private func connectionObserver() {
        Connection.shared.connectionSate.sink(receiveValue: {[weak self] state in
            guard let self = self else { return }
            switch state {
            case .notConnected:
                self.cancelOperation()
            default:
                break
            }
        }).store(in: &bag)
    }

    private func cancelOperation() {
        self.uploader.cancel(self.file)
        self.trigger.send(.completed(UploadResult.failure(self.file, NetworkingError.noInternetConnection)))
    }
    
    /// Starts the synchronizer
    func start() {
        if !Connection.shared.isReachable {
            self.cancelOperation()
            return
        }
        /// prepare to listen from trigger from the uploader
        uploader.uploadResult.sink { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let uploadingFile), .failure(let uploadingFile, _), .cancelled(let uploadingFile):
                if uploadingFile == self.file {
                    self.trigger.send(.completed(result))
                }
            case .progress(let uploadingFile, _):
                if uploadingFile == self.file {
                    self.trigger.send(.pending(result))
                }
            }
        }.store(in: &bag)
        
        /// start the upload
        if let router = file.uploadRouter {
            uploader.uploadFile(file: file, router: router)
        } else {
            uploader.uploadFile(file: file)
        }
    }
}
