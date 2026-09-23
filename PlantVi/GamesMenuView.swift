//  GamesMenuView.swift
//  PlantVi
//
//  Created by Brandiuxx on 31/08/26.
//
//  Pantalla 3: menú de minijuegos
//

import SwiftUI

// MARK: - Modelo de un minijuego

struct Juego: Identifiable {
    let id = UUID()
    let nombre: String
    let icono: String
    let color: Color
    let descripcion: String
}

// MARK: - Menú principal de juegos

struct GamesMenuView: View {

    let juegos: [Juego] = [
        Juego(
            nombre: "Recolecta Agua",
            icono: "cloud.rain.fill",
            color: .blue,
            descripcion: "Atrapa gotas que caen de las nubes"
        ),
        Juego(
            nombre: "Recicla y Abona",
            icono: "trash.fill",
            color: .brown,
            descripcion: "Separa la basura orgánica de la inorgánica"
        ),
        Juego(
            nombre: "Quiz Verde",
            icono: "questionmark.circle.fill",
            color: .orange,
            descripcion: "Pon a prueba lo que sabes sobre los árboles"
        ),
        Juego(
            nombre: "Memorama Forestal",
            icono: "square.grid.2x2.fill",
            color: .purple,
            descripcion: "Encuentra las parejas de especies de árboles"
        ),
        Juego(
            nombre: "Esquiva la Tala",
            icono: "scissors",
            color: .red,
            descripcion: "Esquiva las motosierras y protege al bosque"
        ),
        Juego(
            nombre: "Siembra Exprés",
            icono: "leaf.arrow.circlepath",
            color: .green,
            descripcion: "Planta semillas antes de que se acabe el tiempo"
        )
    ]

    let columnas = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columnas, spacing: 20) {
                    ForEach(juegos) { juego in
                        NavigationLink(destination: destinoJuego(para: juego)) {
                            TarjetaJuego(juego: juego)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Minijuegos 🎮")
        }
    }

    // MARK: - Enrutador de Juegos
    @ViewBuilder
    private func destinoJuego(para juego: Juego) -> some View {
        switch juego.nombre {
        case "Recicla y Abona":
            AbonoGameView()
        // Cuando tengas listos los demás juegos, agregas sus casos aquí:
        // case "Recolecta Agua":
        //     AguaGameView()
        default:
            // Llama a tu archivo existente PlaceholderGameView.swift
            PlaceholderGameView(juego: juego)
        }
    }
}

// MARK: - Tarjeta visual de cada juego

struct TarjetaJuego: View {
    let juego: Juego

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: juego.icono)
                .font(.system(size: 36))
                .foregroundColor(.white)
                .frame(width: 68, height: 68)
                .background(juego.color)
                .clipShape(Circle())

            Text(juego.nombre)
                .font(.subheadline).bold()
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            Text(juego.descripcion)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 170)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }
}

#Preview {
    GamesMenuView()
        .environmentObject(GameManager())
}
