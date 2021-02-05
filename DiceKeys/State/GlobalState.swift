//
//  DefaultsStore.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/30.
//

import Foundation
import Combine
import SwiftUI

struct KnownDiceKeyIdentifiable: Identifiable {
    let id: String
}

enum TopLevelNavigateTo {
    case nowhere
    case loadDiceKey
    case diceKeyPresent
    case assemblyInstructions
}

struct ApiRequestWithCompletionCallback {
    let request: ApiRequest
    let callback: (Result<String, Error>) -> Void
}

final class GlobalState: ObservableObjectUpdatingOnAllChangesToUserDefaults {
    static private(set) var instance = GlobalState()

    enum Fields: String {
        case knownDiceKeys
        case neverAskUserToSave
        case savedDerivationRecipes
    }
    
    @Published private var apiRequestApprovalQueue: [ApiRequestWithCompletionCallback] = []

    func askUserToApproveApiRequest(_ request: ApiRequest, _ callback: @escaping (Result<String, Error>) -> Void) -> Void {
        apiRequestApprovalQueue.append(ApiRequestWithCompletionCallback(request: request, callback: callback))
        self.sendChangeEventOnMainThread()
    }
    
    func removeApiRequestApproval() {
        apiRequestApprovalQueue.removeFirst()
        self.sendChangeEventOnMainThread()
    }
    
    var requestForUserToApprove: ApiRequestWithCompletionCallback? {
        return apiRequestApprovalQueue.first
    }
    
    @Published var topLevelNavigation: TopLevelNavigateTo = .nowhere {
        didSet { self.sendChangeEventOnMainThread() }
    }
    
    @Published var diceKeyLoaded: DiceKey? = nil {
        didSet { self.sendChangeEventOnMainThread() }
    }
    
    private var cachedDiceKeyState: UnlockedDiceKeyState? = nil
    var diceKeyState: UnlockedDiceKeyState? {
        if (cachedDiceKeyState?.diceKey != self.diceKeyLoaded) {
            if let diceKey = diceKeyLoaded {
                cachedDiceKeyState = UnlockedDiceKeyState(diceKey: diceKey)
            } else {
                cachedDiceKeyState = nil
            }
        }
        return cachedDiceKeyState
    }

    @UserDefault(Fields.savedDerivationRecipes.rawValue, "") private var savedDerivationRecipesJson: String

    var savedDerivationRecipes: [DerivationRecipe] {
        get {
            return savedDerivationRecipesJson == "" ? [] :
                (try? DerivationRecipe.listFromJson(savedDerivationRecipesJson)) ?? []
        } set {
            if let derivablesJson = try? DerivationRecipe.listToJson(newValue) {
                self.savedDerivationRecipesJson = derivablesJson
                self.sendChangeEventOnMainThread()
            }
        }
    }

    func saveRecipe(_ recipeToSave: DerivationRecipe?) {
        guard let recipe = recipeToSave else { return }
        if savedDerivationRecipes.allSatisfy({ $0.id != recipe.id }) {
            self.savedDerivationRecipes = (
                self.savedDerivationRecipes + [recipe]
            )
            .sorted(by: { a, b in a.id < b.id })
            self.sendChangeEventOnMainThread()
        }
    }

    func removeRecipe(_ recipeId: String) {
        self.savedDerivationRecipes = savedDerivationRecipes.filter { $0.id != recipeId }
    }
    func removeRecipe(_ recipe: DerivationRecipe?) {
        if let recipeId = recipe?.id {
            removeRecipe(recipeId)
        }
    }

    @UserDefault(Fields.knownDiceKeys.rawValue, []) private(set) var knownDiceKeys: [String]

    func addKnownDiceKey(keyId: String) {
        if !knownDiceKeys.contains(keyId) {
            self.knownDiceKeys = knownDiceKeys + [keyId]
        }
    }
    func removeKnownDiceKey(keyId: String) {
        self.knownDiceKeys = knownDiceKeys.filter { $0 != keyId }
    }

    var knownDiceKeysIdentifiable: [KnownDiceKeyIdentifiable] {
        knownDiceKeys.map { KnownDiceKeyIdentifiable(id: $0) }
    }

    @UserDefault(Fields.neverAskUserToSave.rawValue, false) var neverAskUserToSave: Bool
}
