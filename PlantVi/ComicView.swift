//
//  ComicView.swift
//  PlantVi
//
//  Created by Brandiuxx on 31/08/26.

//  Pantalla 1: espacio tipo cómic para contar la historia del árbol
//  y la llegada de las empresas taladoras.
//

import SwiftUI

struct EscenaComic: Identifiable {
    let id = UUID()
    let imagenSistema: String
    let texto: String
}

struct ComicView: View {

    let escenas: [EscenaComic] = [
        EscenaComic(imagenSistema: "tree.fill", texto: "Había una vez un bosque lleno de vida..."),
        EscenaComic(imagenSistema: "building.2.fill", texto: "Un día, llegaron máquinas y empresas madereras..."),
        EscenaComic(imagenSistema: "scissors", texto: "Los árboles comenzaron a desaparecer, uno a uno..."),
        EscenaComic(imagenSistema: "hand.raised.fill", texto: "Pero alguien decidió actuar y plantar una semilla nueva...")
    ]

    @State private var indiceActual = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()

                Image(systemName: escenas[indiceActual].imagenSistema)
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                    .frame(height: 140)
                    .transition(.opacity)
                    .id(indiceActual)

                Text(escenas[indiceActual].texto)
                    .font(.title3).bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                HStack(spacing: 6) {
                    ForEach(0..<escenas.count, id: \.self) { i in
                        Circle()
                            .fill(i == indiceActual ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                Button(indiceActual == escenas.count - 1 ? "Finalizar" : "Siguiente") {
                    withAnimation {
                        if indiceActual < escenas.count - 1 {
                            indiceActual += 1
                        }
                    }
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Nuestra Historia 🌳")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ComicView()
}
