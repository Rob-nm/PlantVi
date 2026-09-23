
//  PlaceholderG.swift
//  PlantVi
//
//  Created by Brandiuxx on 31/08/26.
//

//
//  PlaceholderGameView.swift
//  Pantalla temporal a la que llega el usuario al elegir un juego del menú.
//  Aquí después se reemplazará cada caso por el juego real.
//

import SwiftUI

struct PlaceholderGameView: View {
    let juego: Juego

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: juego.icono)
                .font(.system(size: 80))
                .foregroundColor(juego.color)

            Text(juego.nombre)
                .font(.largeTitle).bold()
                .multilineTextAlignment(.center)

            Text("Este sera un minijuego")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle(juego.nombre)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PlaceholderGameView(
        juego: Juego(
            nombre: "Recolecta Agua",
            icono: "cloud.rain.fill",
            color: .blue,
            descripcion: "Atrapa gotas que caen de las nubes"
        )
    )
}
