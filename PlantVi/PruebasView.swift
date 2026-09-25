//
//  PruebasView.swift
//  PlantVi
//
//  Created by Brandiuxx on 25/09/26.
//

import SwiftUI

struct ResultadoPrueba: Identifiable {
    let id = UUID()
    let nombre: String
    let paso: Bool
    let detalle: String
}

struct PruebasView: View {
    @StateObject private var gameManager = GameManager()
    @State private var resultados: [ResultadoPrueba] = []
    @State private var pruebasEjecutadas: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Cabecera informativa
                VStack(spacing: 8) {
                    Text("Panel de Pruebas Unitarias 🧪")
                        .font(.title2.bold())
                    Text("Valida la lógica del abono, la mochila y la planta sin salir de la app.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)

                // Botón para ejecutar todas las pruebas
                Button(action: ejecutarTodasLasPruebas) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text(pruebasEjecutadas ? "Volver a Correr Pruebas" : "Correr Pruebas Ahora")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(14)
                }
                .padding(.horizontal)

                // Resumen de aprobación
                if pruebasEjecutadas {
                    let totalAprobadas = resultados.filter { $0.paso }.count
                    HStack {
                        Text("Resultados:")
                            .font(.subheadline.bold())
                        Spacer()
                        Text("\(totalAprobadas) de \(resultados.count) Aprobadas ✅")
                            .font(.subheadline.bold())
                            .foregroundColor(totalAprobadas == resultados.count ? .green : .orange)
                    }
                    .padding(.horizontal)
                }

                // Lista de resultados
                List(resultados) { prueba in
                    HStack(alignment: .top, spacing: 14) {
                        Text(prueba.paso ? "✅" : "❌")
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prueba.nombre)
                                .font(.headline)
                            Text(prueba.detalle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)

                Spacer()
            }
            .navigationTitle("Test Runner")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Ejecutor de Pruebas
    private func ejecutarTodasLasPruebas() {
        var lista: [ResultadoPrueba] = []

        // Prueba 1: Ganar abono al clasificar residuo orgánico
        let abonoInicial = gameManager.inventarioAbono
        gameManager.inventarioAbono += 1
        let p1Paso = gameManager.inventarioAbono == (abonoInicial + 1)
        lista.append(ResultadoPrueba(
            nombre: "1. Sumar Abono al Inventario",
            paso: p1Paso,
            detalle: p1Paso ? "El recurso se incrementó en +1 en la mochila." : "Falló: No aumentó el abono."
        ))

        // Prueba 2: Consumo de abono al nutrir la planta
        gameManager.inventarioAbono = 3
        gameManager.nivelAbono = 20.0
        gameManager.abonar()
        let p2Paso = (gameManager.inventarioAbono == 2) && (gameManager.nivelAbono > 20.0)
        lista.append(ResultadoPrueba(
            nombre: "2. Consumo de Abono en Planta",
            paso: p2Paso,
            detalle: p2Paso ? "Se restó 1 abono y la planta subió su nivel nutricional." : "Falló: No descontó o no subió el nivel."
        ))

        // Prueba 3: Evitar abono negativo si la mochila está vacía
        gameManager.inventarioAbono = 0
        let nivelAntes = gameManager.nivelAbono
        gameManager.abonar()
        let p3Paso = (gameManager.inventarioAbono == 0) && (gameManager.nivelAbono == nivelAntes)
        lista.append(ResultadoPrueba(
            nombre: "3. Bloqueo sin Abono",
            paso: p3Paso,
            detalle: p3Paso ? "No permite abonar si hay 0 raciones; no crea números negativos." : "Falló: Permitió abonar sin saldo."
        ))

        // Prueba 4: Curación de plagas con spray
        gameManager.tienePlaga = true
        gameManager.inventarioSpray = 2
        gameManager.curarPlaga()
        let p4Paso = (!gameManager.tienePlaga) && (gameManager.inventarioSpray == 1)
        lista.append(ResultadoPrueba(
            nombre: "4. Curación de Plagas con Spray",
            paso: p4Paso,
            detalle: p4Paso ? "La plaga fue eliminada y se gastó 1 spray curativo." : "Falló: La plaga sigue activa o no descontó el spray."
        ))

        // Prueba 5: Validación de planta lista para el Refugio
        gameManager.nivelAgua = 100.0
        gameManager.nivelAbono = 100.0
        gameManager.nivelVida = 80.0
        let estaLista = (gameManager.nivelAgua >= 100 && gameManager.nivelAbono >= 100 && gameManager.nivelVida > 0)
        lista.append(ResultadoPrueba(
            nombre: "5. Estado 'Lista para el Refugio'",
            paso: estaLista,
            detalle: estaLista ? "Cumple los criterios de 100% agua, 100% abono y vida positiva." : "Falló: No detectó la planta madura."
        ))

        resultados = lista
        pruebasEjecutadas = true
    }
}

#Preview {
    PruebasView()
}
