//
//  UploadResult.swift
//  Ice Breaker
//
//  Created by mukesh on 9/17/20.
//  Copyright © 2020 Ebpearls. All rights reserved.
//

import Foundation

/// The result for the file uploader
public enum UploadResult: ResultMaker {
    case success(File)
    case progress(File, Progress)
    case failure(File, Error)
    case cancelled(File)
}

/// The state of the upload
public enum UploadState {
    case success
    case progress(Progress)
    case failure(Error)
}
