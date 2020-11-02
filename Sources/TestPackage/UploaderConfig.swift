//
//  UploaderConfig.swift
//  Ice Breaker
//
//  Created by mukesh on 9/17/20.
//  Copyright © 2020 Ebpearls. All rights reserved.
//

import Foundation

public class UploaderConfig {
    
    /// The region of the AWS server
    public var regionType: AWSRegionType! = nil
    
    /// The identity pool Id
    public var identityPoolId: String = ""
    
    /// Name of the bucket
    public var bucketName = ""
    
    /// The block configuration intializer
    public init(_ config: (UploaderConfig) -> Void) {
        config(self)
    }
}
