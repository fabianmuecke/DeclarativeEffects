//
//  Breed.swift
//  DeclarativeEffectsExample
//
//  Created by Fabian Mücke on 27.07.23.
//

import Foundation
import Tagged

struct Breed: Decodable, Equatable {
    enum _Id {}
    typealias Id = Tagged<_Id, String>

    let id: Id
}
