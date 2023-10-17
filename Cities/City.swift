//
//  City.swift
//  Cities
//
//  Created by Yasar on 29.01.2021.
//

import Foundation
struct City {
    var image:UIImage!
    var name:String = ""
    
    init(image: UIImage, name: String){
        self.image = image
        self.name = name
    }
}
