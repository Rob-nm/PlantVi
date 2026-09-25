//
//  GameManager.swift
//  PlantVi
//
//  Created by Brandiuxx on 18/09/26.
//


import SwiftUI
import CoreData
internal import Combine

class GameManager: ObservableObject {
    private let context: NSManagedObjectContext
    private var plantaEntity: PlantaEntity?

    @Published var inventarioAgua: Int = 3 { didSet { guardarEstadoPlanta() } }
    @Published var inventarioAbono: Int = 2 { didSet { guardarEstadoPlanta() } }
    @Published var inventarioSpray: Int = 1 { didSet { guardarEstadoPlanta() } }

    @Published var nivelVida: Double = 100.0 { didSet { guardarEstadoPlanta() } }
    @Published var nivelAgua: Double = 0.0   { didSet { guardarEstadoPlanta() } }
    @Published var nivelAbono: Double = 0.0  { didSet { guardarEstadoPlanta() } }
    @Published var tienePlaga: Bool = false  { didSet { guardarEstadoPlanta() } }
    @Published var iconoPlaga: String = "🐛" { didSet { guardarEstadoPlanta() } }

    //Colección del Refugio / Jardín
    @Published var jardinGuardado: [PlantaGuardadaEntity] = []

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        cargarDatos()
    }

    //carga y Guardado en Core Data
    private func cargarDatos() {
        let peticionPlanta: NSFetchRequest<PlantaEntity> = PlantaEntity.fetchRequest()

        do {
            let resultados = try context.fetch(peticionPlanta)
            if let existente = resultados.first {
                self.plantaEntity = existente
                self.inventarioAgua = Int(existente.inventarioAgua)
                self.inventarioAbono = Int(existente.inventarioAbono)
                self.inventarioSpray = Int(existente.inventarioSpray)
                self.nivelVida = existente.nivelVida
                self.nivelAgua = existente.nivelAgua
                self.nivelAbono = existente.nivelAbono
                self.tienePlaga = existente.tienePlaga
                self.iconoPlaga = existente.iconoPlaga ?? "🐛"
            } else {
                let nueva = PlantaEntity(context: context)
                nueva.id = UUID()
                nueva.inventarioAgua = 3
                nueva.inventarioAbono = 2
                nueva.inventarioSpray = 1
                nueva.nivelVida = 100.0
                nueva.nivelAgua = 0.0
                nueva.nivelAbono = 0.0
                nueva.tienePlaga = false
                nueva.iconoPlaga = "🐛"

                self.plantaEntity = nueva
                try context.save()
            }
        } catch {
            print("Error al cargar la planta de Core Data: \(error.localizedDescription)")
        }

        cargarJardin()
    }

    func cargarJardin() {
        let peticionJardin: NSFetchRequest<PlantaGuardadaEntity> = PlantaGuardadaEntity.fetchRequest()
        peticionJardin.sortDescriptors = [NSSortDescriptor(keyPath: \PlantaGuardadaEntity.fecha, ascending: false)]

        do {
            self.jardinGuardado = try context.fetch(peticionJardin)
        } catch {
            print("Error al cargar las plantas del refugio: \(error.localizedDescription)")
        }
    }

    private func guardarEstadoPlanta() {
        guard let entidad = plantaEntity else { return }

        entidad.inventarioAgua = Int64(inventarioAgua)
        entidad.inventarioAbono = Int64(inventarioAbono)
        entidad.inventarioSpray = Int64(inventarioSpray)
        entidad.nivelVida = nivelVida
        entidad.nivelAgua = nivelAgua
        entidad.nivelAbono = nivelAbono
        entidad.tienePlaga = tienePlaga
        entidad.iconoPlaga = iconoPlaga

        do {
            try context.save()
        } catch {
            print("Error al guardar estado de la planta: \(error.localizedDescription)")
        }
    }

    // Recompensa Aleatoria para Minijuegos
    @discardableResult
    func agregarRecursoAleatorio() -> (nombre: String, icono: String) {
        let opciones = [
            ("Agua dulce", "💧"),
            ("Abono orgánico", "🌱"),
            ("Spray Anti-Plagas", "🧴")
        ]
        let seleccion = opciones.randomElement()!
        switch seleccion.0 {
        case "Agua dulce":
            inventarioAgua += 1
        case "Abono orgánico":
            inventarioAbono += 1
        default:
            inventarioSpray += 1
        }
        return seleccion
    }

    // acciones del Refugio / Jardín
    func moverAlRefugio(nombre: String, icono: String) {
        let guardada = PlantaGuardadaEntity(context: context)
        guardada.id = UUID()
        guardada.nombre = nombre.isEmpty ? "Sin nombre" : nombre
        guardada.icono = icono
        guardada.fecha = Date()

        do {
            try context.save()
            cargarJardin()

            self.nivelAgua = 0.0
            self.nivelAbono = 0.0
            self.nivelVida = 100.0
            self.tienePlaga = false
        } catch {
            print("Error al guardar planta en el refugio: \(error.localizedDescription)")
        }
    }

    //Cuidado de la Planta
    func regar() {
        guard inventarioAgua > 0 else { return }
        inventarioAgua -= 1
        if nivelAgua < 100 { nivelAgua = min(100, nivelAgua + 10) }
        recuperarVida(15)
    }

    func abonar() {
        guard inventarioAbono > 0 else { return }
        inventarioAbono -= 1
        if nivelAbono < 100 { nivelAbono = min(100, nivelAbono + 10) }
        recuperarVida(15)
    }

    func curarPlaga() {
        guard tienePlaga && inventarioSpray > 0 else { return }
        inventarioSpray -= 1
        tienePlaga = false
        recuperarVida(20)
    }

    func generarPlagaAleatoria() {
        guard !tienePlaga && nivelVida > 20 else { return }
        tienePlaga = true
        iconoPlaga = ["🐛", "🦗", "🍄"].randomElement() ?? "🐛"
    }

    func ticTemporizador() {
        if tienePlaga {
            nivelVida = max(0, nivelVida - 10)
        } else if (nivelAgua < 100 || nivelAbono < 100) && nivelVida > 0 {
            nivelVida = max(0, nivelVida - 5)
        }
    }

    private func recuperarVida(_ puntos: Double) {
        if nivelVida < 100 {
            nivelVida = min(100, nivelVida + puntos)
        }
    }
}
