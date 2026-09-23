import SwiftUI
internal import Combine

struct PlantaGuardada: Identifiable {
    let id = UUID()
    let nombre: String
    let icono: String
}

struct PlantaView: View {
    @EnvironmentObject var gameManager: GameManager

    let temporizador = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()

    @State private var escalaPlanta: CGFloat = 1.0
    @State private var mostrandoLluvia: Bool = false
    @State private var mostrandoBrillos: Bool = false
    @State private var mostrandoSpray: Bool = false

    @State private var especiesAdultas = ["🪴", "🌳", "🌵", "🌻", "🌴"]
    @State private var plantaSecretaActual: String = "🪴"
    @State private var moverNubes: Bool = false

    @State private var miJardin: [PlantaGuardada] = []
    @State private var mostrarAlertaNombre: Bool = false
    @State private var nombreIngresado: String = ""
    @State private var mostrarModalInventario: Bool = false

    var esDeDia: Bool {
        let hora = Calendar.current.component(.hour, from: Date())
        return hora >= 6 && hora < 19
    }

    var iconoPlanta: String {
        if gameManager.nivelVida <= 0 { return "🍂" }
        else if gameManager.nivelAgua >= 100 && gameManager.nivelAbono >= 100 { return plantaSecretaActual }
        else if gameManager.nivelAgua >= 30 && gameManager.nivelAbono >= 30 { return "🌱" }
        else { return "🌰" }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: esDeDia ? [.blue, .cyan] : [.black, .purple],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()

                VStack {
                    HStack {
                        Text(esDeDia ? "☁️" : "🌙").font(.system(size: 80))
                            .offset(x: moverNubes ? 250 : -250)
                            .animation(.linear(duration: 25).repeatForever(autoreverses: false), value: moverNubes)
                        Spacer()
                    }.padding(.top, 50)
                    Spacer()
                }.onAppear { moverNubes = true }

                VStack(spacing: 20) {
                    // Barras de progreso
                    VStack(spacing: 12) {
                        ProgressView("❤️ Vida", value: gameManager.nivelVida, total: 100).tint(.red)
                        ProgressView("💧 Agua", value: gameManager.nivelAgua, total: 100).tint(.blue)
                        ProgressView("🌱 Abono", value: gameManager.nivelAbono, total: 100).tint(.brown)
                    }
                    .padding().background(.ultraThinMaterial).cornerRadius(15).padding(.horizontal).bold()

                    // Indicadores rápidos de la mochila
                    HStack(spacing: 12) {
                        Text("💧 \(gameManager.inventarioAgua)")
                            .font(.caption.bold())
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(.ultraThinMaterial).clipShape(Capsule())

                        Text("🌱 \(gameManager.inventarioAbono)")
                            .font(.caption.bold())
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(.ultraThinMaterial).clipShape(Capsule())

                        Text("🧴 \(gameManager.inventarioSpray)")
                            .font(.caption.bold())
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(.ultraThinMaterial).clipShape(Capsule())
                    }

                    Spacer()

                    // Visual de la Planta, Plagas y Efectos
                    ZStack {
                        Text(iconoPlanta).font(.system(size: 150))
                            .scaleEffect(escalaPlanta)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: escalaPlanta)

                        if gameManager.tienePlaga && gameManager.nivelVida > 0 {
                            Text(gameManager.iconoPlaga)
                                .font(.system(size: 44))
                                .offset(x: 45, y: -40)
                                .transition(.scale)
                        }

                        if mostrandoLluvia { Text("🌧️").font(.system(size: 80)).offset(y: -120).transition(.opacity) }
                        if mostrandoBrillos { Text("✨").font(.system(size: 60)).offset(y: 80).transition(.opacity) }
                        if mostrandoSpray { Text("💨").font(.system(size: 60)).offset(x: 40, y: -30).transition(.opacity) }
                    }

                    // Mensaje de estado
                    if gameManager.tienePlaga && gameManager.nivelVida > 0 {
                        Text("¡Una plaga está atacando tu planta! ⚠️")
                            .font(.subheadline.bold())
                            .foregroundColor(.yellow)
                    } else {
                        Text(gameManager.nivelVida <= 0 ? "¡Tu planta necesita ayuda!" : (gameManager.nivelAgua >= 100 && gameManager.nivelAbono >= 100 ? "¡Planta Lista!" : "Cuidando mi semilla"))
                            .font(.title2).bold().foregroundColor(.white)
                    }

                    Spacer()

                    // Controles inferiores
                    VStack(spacing: 12) {
                        if gameManager.tienePlaga && gameManager.nivelVida > 0 {
                            Button(action: {
                                withAnimation {
                                    gameManager.curarPlaga()
                                    activarEfecto(tipo: "spray")
                                }
                            }) {
                                HStack {
                                    Image(systemName: "cross.vial.fill")
                                    Text("Usar Spray Anti-Plagas (\(gameManager.inventarioSpray))")
                                }
                                .font(.headline).foregroundColor(.white).padding().frame(maxWidth: .infinity)
                                .background(gameManager.inventarioSpray > 0 ? Color.orange : Color.gray.opacity(0.6))
                                .cornerRadius(15)
                            }
                            .disabled(gameManager.inventarioSpray == 0)
                        }

                        if gameManager.nivelAgua >= 100 && gameManager.nivelAbono >= 100 && gameManager.nivelVida > 0 {
                            Button(action: { mostrarAlertaNombre = true }) {
                                Text("Mover al Refugio")
                                    .font(.headline).padding().frame(maxWidth: .infinity)
                                    .background(Color.green).foregroundColor(.white).cornerRadius(15)
                            }
                        } else {
                            HStack(spacing: 16) {
                                Button(action: {
                                    gameManager.regar()
                                    activarEfecto(tipo: "agua")
                                }) {
                                    VStack(spacing: 2) {
                                        Text("Regar").font(.headline)
                                        Text("(\(gameManager.inventarioAgua) 💧)").font(.caption2)
                                    }
                                    .padding(.vertical, 12).frame(maxWidth: .infinity)
                                    .background(gameManager.inventarioAgua > 0 ? Color.blue : Color.gray.opacity(0.6))
                                    .foregroundColor(.white).cornerRadius(15)
                                }
                                .disabled(gameManager.inventarioAgua == 0)

                                Button(action: {
                                    gameManager.abonar()
                                    activarEfecto(tipo: "abono")
                                }) {
                                    VStack(spacing: 2) {
                                        Text("Abonar").font(.headline)
                                        Text("(\(gameManager.inventarioAbono) 🌱)").font(.caption2)
                                    }
                                    .padding(.vertical, 12).frame(maxWidth: .infinity)
                                    .background(gameManager.inventarioAbono > 0 ? Color.brown : Color.gray.opacity(0.6))
                                    .foregroundColor(.white).cornerRadius(15)
                                }
                                .disabled(gameManager.inventarioAbono == 0)
                            }
                        }
                    }
                    .padding().background(.ultraThinMaterial).cornerRadius(20).padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .onReceive(temporizador) { _ in
                gameManager.ticTemporizador()
                if Int.random(in: 1...10) == 1 {
                    gameManager.generarPlagaAleatoria()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { mostrarModalInventario = true }) {
                        Label("Mochila", systemImage: "backpack.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: JardinView(coleccion: miJardin)) {
                        Text("🪴").font(.title3)
                    }
                }
            }
            .sheet(isPresented: $mostrarModalInventario) {
                InventarioModalView()
                    .environmentObject(gameManager)
            }
            .alert("Bautiza a tu planta", isPresented: $mostrarAlertaNombre) {
                TextField("Nombre (ej. Panchito)", text: $nombreIngresado)
                Button("Guardar", action: guardarPlanta)
                Button("Cancelar", role: .cancel) { }
            } message: {
                Text("¡Felicidades! ¿Cómo quieres llamar a tu nueva planta?")
            }
        }
    }

    func activarEfecto(tipo: String) {
        escalaPlanta = 1.2
        withAnimation {
            if tipo == "agua" { mostrandoLluvia = true }
            if tipo == "abono" { mostrandoBrillos = true }
            if tipo == "spray" { mostrandoSpray = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation {
                mostrandoLluvia = false
                mostrandoBrillos = false
                mostrandoSpray = false
                escalaPlanta = 1.0
            }
        }
    }

    func guardarPlanta() {
        let nueva = PlantaGuardada(nombre: nombreIngresado.isEmpty ? "Sin nombre" : nombreIngresado, icono: plantaSecretaActual)
        miJardin.append(nueva)
        gameManager.nivelAgua = 0.0
        gameManager.nivelAbono = 0.0
        gameManager.nivelVida = 100.0
        gameManager.tienePlaga = false
        nombreIngresado = ""
        plantaSecretaActual = especiesAdultas.randomElement() ?? "🪴"
    }
}

// MARK: - Modal de Mochila
struct InventarioModalView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                filaRecurso(icono: "💧", nombre: "Agua dulce", cantidad: gameManager.inventarioAgua, color: .blue) {
                    gameManager.regar()
                }
                
                filaRecurso(icono: "🌱", nombre: "Abono orgánico", cantidad: gameManager.inventarioAbono, color: .brown) {
                    gameManager.abonar()
                }
                
                filaRecurso(icono: "🧴", nombre: "Spray Anti-Plagas", cantidad: gameManager.inventarioSpray, color: .orange) {
                    gameManager.curarPlaga()
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Mochila 🎒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }
    
    @ViewBuilder
    private func filaRecurso(icono: String, nombre: String, cantidad: Int, color: Color, accion: @escaping () -> Void) -> some View {
        HStack(spacing: 16) {
            Text(icono).font(.system(size: 38))
            VStack(alignment: .leading, spacing: 2) {
                Text(nombre).font(.headline)
                Text("Disponibles: \(cantidad)").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Button("Usar", action: accion)
                .buttonStyle(.borderedProminent)
                .tint(color)
                .disabled(cantidad == 0)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

// MARK: - Vista Jardín
struct JardinView: View {
    var coleccion: [PlantaGuardada]
    var body: some View {
        ZStack {
            Color.green.opacity(0.1).ignoresSafeArea()
            if coleccion.isEmpty {
                Text("Tu refugio está vacío.").foregroundColor(.gray)
            } else {
                List(coleccion) { planta in
                    HStack(spacing: 16) {
                        Text(planta.icono).font(.system(size: 40))
                        Text(planta.nombre).font(.headline)
                    }
                }
            }
        }.navigationTitle("Mi Refugio")
    }
}


#Preview {
    PlantaView()
        .environmentObject(GameManager())
}
