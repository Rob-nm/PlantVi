//
//  AbonoGameView.swift
//  PlantVi
//

import SwiftUI

// MARK: - Modelos de Datos

enum TrashType {
    case organico
    case inorganico
}

struct TrashItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let type: TrashType
    let descripcionAccesible: String
}

//Vista Principal del Juego

struct AbonoGameView: View {
    @EnvironmentObject var gameManager: GameManager

    private let catalogo: [TrashItem] = [
        TrashItem(name: "Cáscara de banano", icon: "🍌", type: .organico, descripcionAccesible: "Cáscara de banano o plátano"),
        TrashItem(name: "Manzana", icon: "🍎", type: .organico, descripcionAccesible: "Restos de manzana comida"),
        TrashItem(name: "Botella plástica", icon: "🍾", type: .inorganico, descripcionAccesible: "Botella vacía de plástico"),
        TrashItem(name: "Lata", icon: "🥫", type: .inorganico, descripcionAccesible: "Lata vacía de aluminio")
    ]

    @State private var itemActual: TrashItem = TrashItem(
        name: "Cáscara de banano",
        icon: "🍌",
        type: .organico,
        descripcionAccesible: "Cáscara de banano"
    )
    @State private var desplazamiento: CGSize = .zero
    @State private var mensaje: String = "¡Arrastra el residuo al bote correcto!"
    @State private var ganadosSesion: Int = 0
    @State private var mostrarAlertaAbono: Bool = false

    // Generadores hápticos nativos para feedback sensorial
    private let exitoHaptico = UINotificationFeedbackGenerator()
    private let errorHaptico = UINotificationFeedbackGenerator()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.green.opacity(0.15), Color.brown.opacity(0.12)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 20) {
                // Barra de estado superior accesible
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "leaf.fill").foregroundColor(.green)
                        Text("En mochila: \(gameManager.inventarioAbono)")
                            .font(.headline)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.ultraThinMaterial).clipShape(Capsule())
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Abono en mochila: \(gameManager.inventarioAbono) unidades")

                    Spacer()

                    Text("Ganados: +\(ganadosSesion)")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Abonos obtenidos en esta partida: \(ganadosSesion)")
                }
                .padding(.horizontal)

                // Mensaje en pantalla con etiqueta descriptiva
                Text(mensaje)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.center)
                    .frame(height: 35)
                    .accessibilityLabel(mensaje)

                Spacer()

                // Elemento arrastrable con soporte de VoiceOver y Acciones
                ZStack {
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)

                    VStack(spacing: 4) {
                        Text(itemActual.icon).font(.system(size: 50))
                            .accessibilityHidden(true)
                        Text(itemActual.name).font(.caption.bold()).foregroundColor(.secondary)
                    }
                }
                .offset(desplazamiento)
                .gesture(
                    DragGesture()
                        .onChanged { g in desplazamiento = g.translation }
                        .onEnded { g in evaluar(movimiento: g.translation) }
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Residuo actual: \(itemActual.descripcionAccesible)")
                .accessibilityHint("Arrastra hacia el bote inferior izquierdo para clasificar como orgánico, o al derecho para inorgánico. O activa las acciones personalizadas.")
                .accessibilityAction(named: "Depositar en Bote Orgánico") {
                    procesar(seleccion: .organico)
                }
                .accessibilityAction(named: "Depositar en Bote Inorgánico") {
                    procesar(seleccion: .inorganico)
                }

                Spacer()

                // Botes de Basura
                HStack(spacing: 20) {
                    DropZoneBin(
                        title: "Orgánico",
                        color: .green,
                        icon: "leaf.circle.fill",
                        subtitle: "Genera abono"
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Bote Orgánico. Recibe restos de comida y cáscaras para fabricar abono.")

                    DropZoneBin(
                        title: "Inorgánico",
                        color: .gray,
                        icon: "trash.circle.fill",
                        subtitle: "Reciclables"
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Bote Inorgánico. Recibe envases, plásticos y latas reciclables.")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Fábrica de Abono ♻️")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { siguiente() }
        .alert("¡Abono Creado! 🌱", isPresented: $mostrarAlertaAbono) {
            Button("¡Continuar!", role: .cancel) {
                siguiente()
            }
        } message: {
            Text("¡Clasificaste muy bien el residuo orgánico!\n\nSe ha guardado +1 Abono en tu mochila para nutrir a tu plantita.")
        }
    }

    // MARK: - Lógica de Juego y Evaluación

    private func evaluar(movimiento: CGSize) {
        guard movimiento.height > 35 else { reset(); return }

        if movimiento.width < -70 {
            procesar(seleccion: .organico)
        } else if movimiento.width > 70 {
            procesar(seleccion: .inorganico)
        } else {
            reset()
        }
    }

    private func procesar(seleccion: TrashType) {
        if itemActual.type == seleccion {
            if seleccion == .organico {
                gameManager.inventarioAbono += 1
                ganadosSesion += 1
                mensaje = "¡Excelente! Creaste +1 Abono 🌱"
                exitoHaptico.notificationOccurred(.success)
                
                // Anuncio sonoro automático para VoiceOver
                UIAccessibility.post(notification: .announcement, argument: "¡Excelente! Creaste un abono orgánico.")
                
                reset()
                mostrarAlertaAbono = true
            } else {
                mensaje = "¡Bien clasificado! Limpiaste el área 👏"
                exitoHaptico.notificationOccurred(.success)
                
                // Anuncio sonoro automático para VoiceOver
                UIAccessibility.post(notification: .announcement, argument: "¡Bien clasificado! Es un residuo inorgánico.")
                
                reset()
                siguiente()
            }
        } else {
            mensaje = "¡Ups! Ese residuo no va ahí ❌"
            errorHaptico.notificationOccurred(.error)
            
            // Anuncio sonoro automático para VoiceOver
            UIAccessibility.post(notification: .announcement, argument: "Residuo incorrecto. Inténtalo en el otro bote.")
            
            reset()
        }
    }

    private func siguiente() {
        if let nuevo = catalogo.randomElement() { itemActual = nuevo }
    }

    private func reset() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            desplazamiento = .zero
        }
    }
}

//Subvista para los Botes

struct DropZoneBin: View {
    let title: String
    let color: Color
    let icon: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundColor(color)
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 115)
        .background(color.opacity(0.12))
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        AbonoGameView()
            .environmentObject(GameManager())
    }
}
