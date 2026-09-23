//
//  ContentView.swift
//  Raíz de la app: sigue llamándose ContentView para que el archivo @main
//  no tenga que tocarse. Ahora contiene el TabView con las 3 pestañas.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        TabView {
            
            ComicView()
                .tabItem {
                    Label("Historieta", systemImage: "book.fill")
                }
            PlantaView()
                .tabItem {
                    Label("Mi Planta", systemImage: "leaf.fill")
                }

            GamesMenuView()
                .tabItem {
                    Label("Juegos", systemImage: "gamecontroller.fill")
                }

        }
        .tint(.green)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(GameManager())
}
