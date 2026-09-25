//
//  MemoramaForestal.swift
//  PlantVi
//
//  Created by Brandiuxx on 24/09/26.
//

//
//  MemoramaForestalView.swift
//  PlantVi
//

import SwiftUI

// MARK: - Modelo de la Carta del Memorama
struct CartaMemorama: Identifiable {
    let id = UUID()
    let icono: String
    let nombre: String
    var estaVolteada: Bool = false
    var estaEmparejada: Bool = false
}

// MARK: - Vista del Juego Memorama Forestal
struct MemoramaForestalView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    // Catálogo temático (Árboles, naturaleza y plagas)
    private let paresDisponibles: [(icono: String, nombre: String)] = [
        ("🌲", "Pino"),
        ("🌳", "Roble"),
        ("🌴", "Palmera"),
        ("☀️", "Energía Solar"),
        ("💨", "Oxígeno"),
        ("🐛", "Plaga Oruga")
    ]

    @State private var cartas: [CartaMemorama] = []
    @State private var indicesSeleccionados: [Int] = []
    @State private var bloqueado: Bool = false
    @State private var intentos: Int = 0
    @State private var juegoCompletado: Bool = false
    @State private var recompensaEntregada: Bool = false

    let columnas = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            // Fondo con tonos forestales
            LinearGradient(
                colors: [Color.purple.opacity(0.12), Color.green.opacity(0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Barra superior de estado
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "cross.vial.fill")
                            .foregroundColor(.orange)
                        Text("Sprays: \(gameManager.inventarioSpray)")
                            .font(.headline)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())

                    Spacer()

                    Text("Intentos: \(intentos)")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                Text("Encuentra todas las parejas del bosque para ganar un Spray Anti-Plagas 🧴")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Tablero de 12 cartas (3x4)
                LazyVGrid(columns: columnas, spacing: 12) {
                    ForEach(Array(cartas.enumerated()), id: \.element.id) { indice, carta in
                        TarjetaMemoramaView(carta: carta)
                            .onTapGesture {
                                tocarCarta(en: indice)
                            }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Botón de reiniciar partida
                Button(action: reiniciarJuego) {
                    Label("Reiniciar Tablero", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.bold())
                        .foregroundColor(.purple)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 16)
            }
        }
        .navigationTitle("Memorama Forestal 🌲")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if cartas.isEmpty {
                reiniciarJuego()
            }
        }
        .alert("¡Bosque Protegido! 🎉", isPresented: $juegoCompletado) {
            Button("¡Genial!") {
                dismiss()
            }
        } message: {
            Text("Completaste el memorama en \(intentos) intentos.\n\n¡Has ganado +1 Spray Anti-Plagas 🧴 para defender a tu planta!")
        }
    }

    // MARK: - Lógica de Juego
    private func reiniciarJuego() {
        var nuevasCartas: [CartaMemorama] = []
        for par in paresDisponibles {
            nuevasCartas.append(CartaMemorama(icono: par.icono, nombre: par.nombre))
            nuevasCartas.append(CartaMemorama(icono: par.icono, nombre: par.nombre))
        }
        cartas = nuevasCartas.shuffled()
        indicesSeleccionados.removeAll()
        intentos = 0
        juegoCompletado = false
        recompensaEntregada = false
        bloqueado = false
    }

    private func tocarCarta(en indice: Int) {
        guard !bloqueado else { return }
        guard !cartas[indice].estaVolteada && !cartas[indice].estaEmparejada else { return }

        // Voltear la carta
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            cartas[indice].estaVolteada = true
        }
        indicesSeleccionados.append(indice)

        // Si se han volteado 2 cartas, evaluar
        if indicesSeleccionados.count == 2 {
            intentos += 1
            bloqueado = true
            let primerIndice = indicesSeleccionados[0]
            let segundoIndice = indicesSeleccionados[1]

            if cartas[primerIndice].nombre == cartas[segundoIndice].nombre {
                // ¡Pareja encontrada!
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    withAnimation {
                        cartas[primerIndice].estaEmparejada = true
                        cartas[segundoIndice].estaEmparejada = true
                    }
                    indicesSeleccionados.removeAll()
                    bloqueado = false
                    verificarVictoria()
                }
            } else {
                // No coinciden: voltear de nuevo tras breve pausa
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        cartas[primerIndice].estaVolteada = false
                        cartas[segundoIndice].estaVolteada = false
                    }
                    indicesSeleccionados.removeAll()
                    bloqueado = false
                }
            }
        }
    }

    private func verificarVictoria() {
        if cartas.allSatisfy({ $0.estaEmparejada }) && !recompensaEntregada {
            recompensaEntregada = true
            // Entregar el spray al inventario global
            gameManager.inventarioSpray += 1
            juegoCompletado = true
        }
    }
}

// MARK: - Tarjeta Individual con animación 3D de volteo
struct TarjetaMemoramaView: View {
    let carta: CartaMemorama

    var body: some View {
        ZStack {
            if carta.estaVolteada || carta.estaEmparejada {
                // Frente de la carta (Descubierta)
                VStack(spacing: 4) {
                    Text(carta.icono)
                        .font(.system(size: 38))
                    Text(carta.nombre)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 95)
                .background(carta.estaEmparejada ? Color.green.opacity(0.2) : Color(.secondarySystemGroupedBackground))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(carta.estaEmparejada ? Color.green : Color.purple.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            } else {
                // Reverso de la carta (Oculta)
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.7), Color.indigo.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 95)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }
        }
        .rotation3DEffect(
            .degrees((carta.estaVolteada || carta.estaEmparejada) ? 0 : 180),
            axis: (x: 0, y: 1, z: 0)
        )
        .opacity(carta.estaEmparejada ? 0.75 : 1.0)
    }
}

// MARK: - Vista Previa
#Preview {
    NavigationStack {
        MemoramaForestalView()
            .environmentObject(GameManager())
    }
}
