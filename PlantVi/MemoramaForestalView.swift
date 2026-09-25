//
//  MemoramaForestalView.swift
//  PlantVi
//
//  Created by Brandiuxx on 24/09/26.
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

    // Generadores sensoriales
    private let exitoHaptico = UINotificationFeedbackGenerator()
    private let toqueHaptico = UIImpactFeedbackGenerator(style: .light)
    private let falloHaptico = UINotificationFeedbackGenerator()

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
                            .accessibilityHidden(true)
                        Text("Sprays: \(gameManager.inventarioSpray)")
                            .font(.headline)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Sprays curativos en mochila: \(gameManager.inventarioSpray)")

                    Spacer()

                    Text("Intentos: \(intentos)")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Intentos realizados: \(intentos)")
                }
                .padding(.horizontal)

                Text("Encuentra todas las parejas del bosque para ganar un Spray Anti-Plagas 🧴")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .accessibilityLabel("Instrucción: Encuentra todas las parejas del bosque para ganar un Spray Anti-Plagas.")

                // Tablero de 12 cartas (3x4)
                LazyVGrid(columns: columnas, spacing: 12) {
                    ForEach(Array(cartas.enumerated()), id: \.element.id) { indice, carta in
                        TarjetaMemoramaView(carta: carta)
                            .onTapGesture {
                                tocarCarta(en: indice)
                            }
                            // Soporte integral para VoiceOver
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(etiquetaAccesible(para: carta, indice: indice))
                            .accessibilityValue(valorAccesible(para: carta))
                            .accessibilityHint(pistaAccesible(para: carta))
                            .accessibilityAddTraits(.isButton)
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
                .accessibilityLabel("Reiniciar tablero de cartas")
                .accessibilityHint("Baraja las cartas y comienza de nuevo el juego")
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

    // MARK: - Accesibilidad y Lectura de VoiceOver

    private func etiquetaAccesible(para carta: CartaMemorama, indice: Int) -> String {
        return "Carta \(indice + 1) de \(cartas.count)"
    }

    private func valorAccesible(para carta: CartaMemorama) -> String {
        if carta.estaEmparejada {
            return "\(carta.nombre), pareja ya encontrada"
        } else if carta.estaVolteada {
            return "Mostrando \(carta.nombre)"
        } else {
            return "Oculta"
        }
    }

    private func pistaAccesible(para carta: CartaMemorama) -> String {
        if carta.estaEmparejada {
            return "Esta pareja ya fue completada."
        } else if carta.estaVolteada {
            return "Carta descubierta. Selecciona una segunda carta para comparar."
        } else {
            return "Toca dos veces para descubrir esta carta."
        }
    }

    // MARK: - Lógica de Juego y Anuncios Auditivos

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

        UIAccessibility.post(
            notification: .announcement,
            argument: "Tablero reiniciado con 12 cartas forestales cubiertas."
        )
    }

    private func tocarCarta(en indice: Int) {
        guard !bloqueado else { return }
        guard !cartas[indice].estaVolteada && !cartas[indice].estaEmparejada else { return }

        // Vibración háptica al pulsar
        toqueHaptico.impactOccurred()

        // Voltear la carta
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            cartas[indice].estaVolteada = true
        }
        indicesSeleccionados.append(indice)

        // Anuncio sonoro inmediato de la carta descubierta
        UIAccessibility.post(
            notification: .announcement,
            argument: "Descubriste: \(cartas[indice].nombre)"
        )

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

                    exitoHaptico.notificationOccurred(.success)

                    // Anuncio de par conseguido
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "¡Excelente! Encontraste la pareja de \(cartas[primerIndice].nombre)."
                    )

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

                    falloHaptico.notificationOccurred(.warning)

                    // Anuncio de no coincidencia
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "No coinciden. Las cartas se han vuelto a cubrir."
                    )
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

            exitoHaptico.notificationOccurred(.success)

            UIAccessibility.post(
                notification: .announcement,
                argument: "¡Felicidades! Has protegido el bosque completando todas las parejas. Ganaste 1 spray anti plagas para tu planta."
            )
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
                        .accessibilityHidden(true)
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
                        .accessibilityHidden(true)
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
