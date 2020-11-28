//
//  AppView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/23.
//

import SwiftUI
import CoreData

class AppState: ObservableObject {
    @Published var diceKey: DiceKey?
}

struct App_Previews: PreviewProvider {
    static var previews: some View {
        AppMainView()
    }
}

@main
struct AppView: App {
    @Environment(\.scenePhase) private var scenePhase
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            AppMainView()
                .onOpenURL { url in
                // FIXME -- handle deep linking API requests here
                print("\(url.absoluteString)")
            }
        }.onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                print("active")
            case .inactive:
                print("inactive")
            case .background:
                print("background")
                saveContext()
            default:
                print(phase)
            }
        }
    }

    var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SampleApp")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error for store \(storeDescription): \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
