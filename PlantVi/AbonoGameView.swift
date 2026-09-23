import SwiftUI

enum TrashType {
    case organico
    case inorganico
}

struct TrashItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let type: TrashType
}

struct AbonoGameView: View {
    @EnvironmentObject var gameManager: GameManager

    private let catalogo: [TrashItem] = [
        TrashItem(name: "Cáscara de banano", icon: "🍌", type: .organico),
        TrashItem(name: "Manzana", icon: "🍎", type: .organico),
        TrashItem(name: "Botella plástica", icon: "🍾", type: .inorganico),
        TrashItem(name: "Lata", icon: "🥫", type: .inorganico)
    ]

    @State private var itemActual: TrashItem = TrashItem(name: "Cáscara de banano", icon: "🍌", type: .organico)
    @State private var desplazamiento: CGSize = .zero
    @State private var mensaje: String = "¡Arrastra el residuo al bote correcto!"
    @State private var ganadosSesion: Int = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.green.opacity(0.15), Color.brown.opacity(0.12)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 20) {
                // Barra de estado superior
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "leaf.fill").foregroundColor(.green)
                        Text("En mochila: \(gameManager.inventarioAbono)")
                            .font(.headline)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.ultraThinMaterial).clipShape(Capsule())

                    Spacer()

                    Text("Ganados: +\(ganadosSesion)")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                Text(mensaje)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.center)
                    .frame(height: 35)

                Spacer()

                // Elemento arrastrable
                ZStack {
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)

                    VStack(spacing: 4) {
                        Text(itemActual.icon).font(.system(size: 50))
                        Text(itemActual.name).font(.caption.bold()).foregroundColor(.secondary)
                    }
                }
                .offset(desplazamiento)
                .gesture(
                    DragGesture()
                        .onChanged { g in desplazamiento = g.translation }
                        .onEnded { g in evaluar(movimiento: g.translation) }
                )

                Spacer()

                // Botes de destino
                HStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Image(systemName: "leaf.circle.fill").font(.system(size: 34)).foregroundColor(.green)
                        Text("Orgánico").font(.headline).foregroundColor(.green)
                        Text("Genera abono").font(.caption2).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity).frame(height: 115)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(16)

                    VStack(spacing: 6) {
                        Image(systemName: "trash.circle.fill").font(.system(size: 34)).foregroundColor(.gray)
                        Text("Inorgánico").font(.headline).foregroundColor(.gray)
                        Text("Reciclables").font(.caption2).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity).frame(height: 115)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Fábrica de Abono ♻️")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { siguiente() }
    }

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
            } else {
                mensaje = "¡Bien clasificado! Limpiaste el área 👏"
            }
            reset()
            siguiente()
        } else {
            mensaje = "¡Ups! Ese residuo no va ahí ❌"
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

