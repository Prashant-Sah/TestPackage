//
//  MimeType.swift
//  Ice Breaker
//
//  Created by mukesh on 9/17/20.
//  Copyright © 2020 Ebpearls. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

/// The MIME Type for the file
public enum MimeType: CaseIterable {
    
    /// Jpeg image
    case imageJpeg
    
    /// Png Image
    case imagePng
    
    /// Pdf file
    case pdf
    
    /// wrod document
    case doc
    
    /// extended office document
    case docX

    // excel
    case xls
    case xlsx

    // power point
    case ppt
    case pptx
    
    /// The mime identifier for the file
    public var mimeIdentifier: String {
        switch self {
        case .imagePng:     return "image/png"
        case .imageJpeg:    return "image/jpg"
        case .pdf:          return "application/pdf"
        case .doc:          return "application/msword"
        case .docX:         return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case .xls:          return "application/vnd.ms-excel"
        case .xlsx:         return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case .ppt:          return "application/vnd.ms-powerpoint"
        case .pptx:         return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        }
    }

    public var docPickerIdentifier: String {
        switch self {
        case .imageJpeg, .imagePng:
            return ""
        case .pdf:
            return kUTTypePDF as String
        case .doc:
            return "com.microsoft.word.doc"
        case .docX:
            return "org.openxmlformats.wordprocessingml.document"
        case .xls:
            return "com.microsoft.excel.xls"
        case .xlsx:
            return "org.openxmlformats.spreadsheetml.sheet"
        case .ppt:
            return "com.microsoft.powerpoint.ppt"
        case .pptx:
            return "org.openxmlformats.presentationml.presentation"
        }
    }
    
    /// The extensions for the file
    public var fileExtension: String {
        switch self {
        case .imagePng: return "png"
        case .imageJpeg: return "jpg"
        case .pdf: return "pdf"
        case .doc: return "doc"
        case .docX: return "docx"
        case .xls: return "xls"
        case .xlsx: return "xlsx"
        case .ppt: return "ppt"
        case .pptx: return "pptx"
        }
    }

    public var image: UIImage {
        switch self {
        case .imagePng, .imageJpeg:
            return UIImage(named: "avatar")!
        case .pdf:
            return UIImage(named: "pdf")!
        case .doc, .docX, .ppt, .pptx:
            return UIImage(named: "doc")!
        case .xls, .xlsx:
            return UIImage(named: "excel")!
        }
    }

}
