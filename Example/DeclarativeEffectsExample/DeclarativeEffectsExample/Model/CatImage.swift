//
//  CatImage.swift
//  DeclarativeEffectsExample
//
//  Created by Fabian Mücke on 27.07.23.
//

import Foundation
import Tagged

struct CatImage: Decodable, Equatable {
    enum _Id {}
    typealias Id = Tagged<_Id, String>
    
    let id: Id
    let url: URL
    let width: Double
    let height: Double
    let breeds: [Breed]
    
    enum Size: String {
        case small
        case medium = "med"
        case full
    }
    
    enum MimeType: String, Hashable {
        case gif
        case jpg
        case png
    }
}
