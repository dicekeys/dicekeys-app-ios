//
//  KnownDiceKey+CoreDataProperties.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/27.
//
//

import Foundation
import CoreData


extension KnownDiceKey {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<KnownDiceKey> {
        return NSFetchRequest<KnownDiceKey>(entityName: "KnownDiceKey")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var nickname: String?

}

extension KnownDiceKey : Identifiable {

}
