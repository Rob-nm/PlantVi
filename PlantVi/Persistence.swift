//
//  Persistence.swift
//  PlantVi
//
//  Created by Macbook on 8/28/26.
//
//
//  PersistenceController.swift
//  PlantVi
//

import CoreData

struct PersistenceController {
    // Singleton para la app en ejecución
    static let shared = PersistenceController()

    // Configuración para Canvas / Preview de Xcode
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Datos iniciales de prueba para el preview
        let nueva = PlantaEntity(context: viewContext)
        nueva.id = UUID()
        nueva.inventarioAgua = 3
        nueva.inventarioAbono = 2
        nueva.inventarioSpray = 1
        nueva.nivelVida = 100.0
        nueva.nivelAgua = 40.0
        nueva.nivelAbono = 30.0
        nueva.tienePlaga = false
        nueva.iconoPlaga = "🐛"

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Error no resuelto en preview: \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Asegúrate de que este nombre coincida con tu archivo .xcdatamodeld
        container = NSPersistentContainer(name: "PlantVi")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Error al cargar Core Data: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
