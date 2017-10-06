//
//  DeletionImpact.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/6/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

class DeletionImpact {
    private var messageComponents = [String]()

    private func addToComponents(value: Int, name: String) {
        if value > 0 {
            var result = "\(value) \(name)"
            if value > 1 {
                result += "s"
            }
            messageComponents.append(result)
        }
    }
    
    private func assembleComponents(initialMessage: String) -> String? {
        if messageComponents.count > 0 {
            var message = initialMessage
            for index in 0..<messageComponents.count {
                let component = messageComponents[index]
                if index > 0 {
                    if index == messageComponents.count - 1 {
                        message += ", and "
                    }
                    else {
                        message += ", "
                    }
                }
                
                message += component
            }
            return message + "."
        }
        else {
            return nil
        }
    }
    
    enum DeletionImpactType {
        case item(Item)
        case location(Location)
    }
    
    func showWarning(`for` type: DeletionImpactType, using vc: UIViewController, deletionAction: @escaping ()->()) {
    
        let (warning, typeName) = of(type)
        var message:String?
        var title:String
        
        if let impact = warning {
            title = "Warning!"
            message = impact
        }
        else {
            title = "Really delete this \(typeName)?"
        }
    
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default) { action in
        })
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { action in
            deletionAction()
        })
        vc.present(alert, animated: true, completion: nil)
    }

    private func of(_ type: DeletionImpactType) -> (warning: String?, typeName: String) {
        switch type {
        case .item(let item):
            return (of(item: item), "menu item")
            
        case .location(let location):
            return (of(location: location), "location")
        }
    }
    
    private func of(item:Item) -> String? {
        var numberImages = 0
        let numberComments = item.comments!.count
        
        for commentObj in item.comments! {
            let comment = commentObj as! Comment
            numberImages += comment.images!.count
        }
        
        addToComponents(value: numberComments, name: "comment")
        addToComponents(value: numberImages, name: "image")
        
        return assembleComponents(initialMessage: "Deleting this menu item will also remove: ")
    }
    
    private func of(location:Location) -> String? {
        var messageComponents = [String]()
        var numberImages = 0
        var numberComments = 0
        var numberMenuItems = 0
        
        if location.place!.locations!.count == 1 {
            messageComponents.append("its place information")
            numberMenuItems += location.place!.items!.count
            
            for itemObj in location.place!.items! {
                let item = itemObj as! Item
                numberComments += item.comments!.count
                
                for commentObj in item.comments! {
                    let comment = commentObj as! Comment
                    numberImages += comment.images!.count
                }
            }
        }
        
        numberImages += location.images!.count
        
        addToComponents(value: numberMenuItems, name: "menu item")
        addToComponents(value: numberComments, name: "comment")
        addToComponents(value: numberImages, name: "image")
        
        return assembleComponents(initialMessage: "Deleting this location will also remove: ")
    }
}
