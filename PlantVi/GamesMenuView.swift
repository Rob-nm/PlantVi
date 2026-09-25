//
//  GamesMenuView.swift
//  PlantVi
//
//  Created by Brandiuxx on 31/08/26.
//
//  Pantalla 3: menú de minijuegos
//

import SwiftUI

// Modelo de un minijuego

struct Juego: Identifiable {
    let id = UUID()
    let nombre: String
    let icono: String
    let color: Color
    let descripcion: String
}

// Menú principal de juegos

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
        )
    ]

    let columnas = [
        GridItem(.adaptive(minimum: 155, maximum: 190), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Elige una actividad")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                        
                        Text("Gana agua, abono y recursos para cuidar tu planta.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 4)

                    LazyVGrid(columns: columnas, spacing: 16) {
                        ForEach(juegos) { juego in
                            NavigationLink(destination: destinoJuego(para: juego)) {
                                TarjetaJuego(juego: juego)
                            }
                            .buttonStyle(BotonTarjetaEstilo())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Minijuegos 🎮")
        }
    }

    //Enrutador de Juegos
    
    @ViewBuilder
    private func destinoJuego(para juego: Juego) -> some View {
        switch juego.nombre {
        case "Recolecta Agua":
            RecolectaAguaView()
            
        case "Recicla y Abona":
            AbonoGameView()
            
        case "Memorama Forestal":
            MemoramaForestalView()
        
        case "Quiz Verde":
            QuizVerdeView()
            
        default:
            PlaceholderGameView(juego: juego)
        }
    }
}

//Tarjeta visual de cada juego

struct TarjetaJuego: View {
    let juego: Juego

    var body: some View {
        VStack(spacing: 12) {
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [juego.color.opacity(0.85), juego.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: juego.color.opacity(0.35), radius: 8, x: 0, y: 4)

                Image(systemName: juego.icono)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, 4)

            // Textos
            VStack(spacing: 4) {
                Text(juego.nombre)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(juego.descripcion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 4)

            HStack(spacing: 4) {
                Text("Jugar")
                    .font(.caption2.bold())
                Image(systemName: "arrow.right.circle.fill")
                    .font(.caption2)
            }
            .foregroundColor(juego.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(juego.color.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 200)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
}

struct BotonTarjetaEstilo: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    GamesMenuView()
        .environmentObject(GameManager())
}
