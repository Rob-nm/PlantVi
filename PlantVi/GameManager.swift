//
//  GameManager.swift
//  PlantVi
//
//  Created by Brandiuxx on 18/09/26.
//

import SwiftUI
internal import Combine

class GameManager: ObservableObject {
    // Inventario de mochila
    @Published var inventarioAgua: Int = 3
    @Published var inventarioAbono: Int = 2
    @Published var inventarioSpray: Int = 1
    
    // Niveles de la planta
    @Published var nivelVida: Double = 100.0
    @Published var nivelAgua: Double = 0.0
    @Published var nivelAbono: Double = 0.0
    
    // Sistema de plagas
    @Published var tienePlaga: Bool = false
    @Published var iconoPlaga: String = "🐛"
    
    // Acciones de cuidado
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
            // La plaga quita el doble de vida
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
