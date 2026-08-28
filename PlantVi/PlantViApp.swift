//
//  PlantViApp.swift
//  PlantVi
//
//  Created by Macbook on 8/28/26.
//

import SwiftUI
import CoreData

@main
struct PlantViApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
