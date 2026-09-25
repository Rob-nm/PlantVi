import SwiftUI
internal import Combine

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

    @State private var mostrarAlertaNombre: Bool = false
    @State private var nombreIngresado: String = ""
    @State private var mostrarModalInventario: Bool = false

    private let exitoHaptico = UINotificationFeedbackGenerator()
    private let toqueHaptico = UIImpactFeedbackGenerator(style: .light)
    private let alertaHaptica = UINotificationFeedbackGenerator()

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
                }
                .accessibilityHidden(true)
                .onAppear { moverNubes = true }

                VStack(spacing: 20) {
                    // Barras de progreso
                    VStack(spacing: 12) {
                        ProgressView("❤️ Vida", value: gameManager.nivelVida, total: 100).tint(.red)
                            .accessibilityLabel("Nivel de vida: \(Int(gameManager.nivelVida)) por ciento")
                        ProgressView("💧 Agua", value: gameManager.nivelAgua, total: 100).tint(.blue)
                            .accessibilityLabel("Nivel de agua: \(Int(gameManager.nivelAgua)) por ciento")
                        ProgressView("🌱 Abono", value: gameManager.nivelAbono, total: 100).tint(.brown)
                            .accessibilityLabel("Nivel de abono: \(Int(gameManager.nivelAbono)) por ciento")
                    }
                    .padding().background(.ultraThinMaterial).cornerRadius(15).padding(.horizontal).bold()

                    // Indicadores rápidos de la mochila
                    HStack(spacing: 12) {
                        Text("💧 \(gameManager.inventarioAgua)")
                            .font(.caption.bold())
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(.ultraThinMaterial).clipShape(Capsule())
                            .accessibilityLabel("Agua disponible: \(gameManager.inventarioAgua) raciones")

                        Text("🌱 \(gameManager.inventarioAbono)")
                            .font(.caption.bold())
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(.ultraThinMaterial).clipShape(Capsule())
                            .accessibilityLabel("Abono disponible: \(gameManager.inventarioAbono) raciones")

                        Text("🧴 \(gameManager.inventarioSpray)")
                            .font(.caption.bold())
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(.ultraThinMaterial).clipShape(Capsule())
                            .accessibilityLabel("Sprays curativos disponibles: \(gameManager.inventarioSpray)")
                    }

                    Spacer()

                    // Centro visual aislado para el compilador
                    CentroPlantaView(
                        iconoPlanta: iconoPlanta,
                        escalaPlanta: escalaPlanta,
                        tienePlaga: gameManager.tienePlaga,
                        iconoPlaga: gameManager.iconoPlaga,
                        nivelVida: gameManager.nivelVida,
                        nivelAgua: gameManager.nivelAgua,
                        nivelAbono: gameManager.nivelAbono,
                        mostrandoLluvia: mostrandoLluvia,
                        mostrandoBrillos: mostrandoBrillos,
                        mostrandoSpray: mostrandoSpray,
                        alRegar: ejecutarRegar,
                        alAbonar: ejecutarAbonar,
                        alCurar: ejecutarCurarPlaga
                    )

                    // Mensaje de estado
                    if gameManager.tienePlaga && gameManager.nivelVida > 0 {
                        Text("¡Una plaga está atacando tu planta! ⚠️")
                            .font(.subheadline.bold())
                            .foregroundColor(.yellow)
                            .accessibilityLabel("Alerta: Una plaga está atacando tu planta. Usa el spray para curarla.")
                    } else {
                        Text(gameManager.nivelVida <= 0 ? "¡Tu planta necesita ayuda!" : (gameManager.nivelAgua >= 100 && gameManager.nivelAbono >= 100 ? "¡Planta Lista!" : "Cuidando mi semilla"))
                            .font(.title2).bold().foregroundColor(.white)
                            .accessibilityLabel(gameManager.nivelVida <= 0 ? "Tu planta necesita ayuda" : (gameManager.nivelAgua >= 100 && gameManager.nivelAbono >= 100 ? "¡Planta lista para cosechar!" : "Cuidando mi semilla"))
                    }

                    Spacer()

                    // Controles inferiores
                    VStack(spacing: 12) {
                        if gameManager.tienePlaga && gameManager.nivelVida > 0 {
                            Button(action: ejecutarCurarPlaga) {
                                HStack {
                                    Image(systemName: "cross.vial.fill")
                                    Text("Usar Spray Anti-Plagas (\(gameManager.inventarioSpray))")
                                }
                                .font(.headline).foregroundColor(.white).padding().frame(maxWidth: .infinity)
                                .background(gameManager.inventarioSpray > 0 ? Color.orange : Color.gray.opacity(0.6))
                                .cornerRadius(15)
                            }
                            .disabled(gameManager.inventarioSpray == 0)
                            .accessibilityLabel("Usar spray anti-plagas")
                            .accessibilityValue("\(gameManager.inventarioSpray) sprays disponibles")
                            .accessibilityHint("Elimina la plaga y salva a tu planta.")
                        }

                        if gameManager.nivelAgua >= 100 && gameManager.nivelAbono >= 100 && gameManager.nivelVida > 0 {
                            Button(action: { mostrarAlertaNombre = true }) {
                                Text("Mover al Refugio")
                                    .font(.headline).padding().frame(maxWidth: .infinity)
                                    .background(Color.green).foregroundColor(.white).cornerRadius(15)
                            }
                            .accessibilityLabel("Mover planta al refugio")
                            .accessibilityHint("Bautiza a tu planta adulta y guárdala en tu colección del jardín.")
                        } else {
                            HStack(spacing: 16) {
                                Button(action: ejecutarRegar) {
                                    VStack(spacing: 2) {
                                        Text("Regar").font(.headline)
                                        Text("(\(gameManager.inventarioAgua) 💧)").font(.caption2)
                                    }
                                    .padding(.vertical, 12).frame(maxWidth: .infinity)
                                    .background(gameManager.inventarioAgua > 0 ? Color.blue : Color.gray.opacity(0.6))
                                    .foregroundColor(.white).cornerRadius(15)
                                }
                                .disabled(gameManager.inventarioAgua == 0)
                                .accessibilityLabel("Regar planta")
                                .accessibilityValue("\(gameManager.inventarioAgua) raciones de agua disponibles")
                                .accessibilityHint("Aumenta el agua y recupera la vida de tu planta.")

                                Button(action: ejecutarAbonar) {
                                    VStack(spacing: 2) {
                                        Text("Abonar").font(.headline)
                                        Text("(\(gameManager.inventarioAbono) 🌱)").font(.caption2)
                                    }
                                    .padding(.vertical, 12).frame(maxWidth: .infinity)
                                    .background(gameManager.inventarioAbono > 0 ? Color.brown : Color.gray.opacity(0.6))
                                    .foregroundColor(.white).cornerRadius(15)
                                }
                                .disabled(gameManager.inventarioAbono == 0)
                                .accessibilityLabel("Abonar planta")
                                .accessibilityValue("\(gameManager.inventarioAbono) raciones de abono disponibles")
                                .accessibilityHint("Nutre la tierra y ayuda a crecer a tu planta.")
                            }
                        }
                    }
                    .padding().background(.ultraThinMaterial).cornerRadius(20).padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .onReceive(temporizador) { _ in
                let teniaPlagaAntes = gameManager.tienePlaga
                gameManager.ticTemporizador()
                
                if Int.random(in: 1...10) == 1 {
                    gameManager.generarPlagaAleatoria()
                    if !teniaPlagaAntes && gameManager.tienePlaga {
                        alertaHaptica.notificationOccurred(.warning)
                        UIAccessibility.post(
                            notification: .announcement,
                            argument: "¡Cuidado! Ha aparecido una plaga sobre tu planta. Usa el spray para salvarla."
                        )
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { mostrarModalInventario = true }) {
                        Label("Mochila", systemImage: "backpack.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Abrir mochila de recursos")
                    .accessibilityHint("Gestiona tu agua, abono y sprays guardados.")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: JardinView()) {
                        Text("🪴").font(.title3)
                    }
                    .accessibilityLabel("Ver Mi Refugio")
                    .accessibilityHint("Entra a ver todas las plantas que has rescatado.")
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

    private func ejecutarRegar() {
        guard gameManager.inventarioAgua > 0 else {
            UIAccessibility.post(notification: .announcement, argument: "No tienes agua en tu mochila. Consigue más en los juegos.")
            return
        }
        toqueHaptico.impactOccurred()
        gameManager.regar()
        activarEfecto(tipo: "agua")
        UIAccessibility.post(
            notification: .announcement,
            argument: "Planta regada. Nivel de agua al \(Int(gameManager.nivelAgua)) por ciento."
        )
    }

    private func ejecutarAbonar() {
        guard gameManager.inventarioAbono > 0 else {
            UIAccessibility.post(notification: .announcement, argument: "No tienes abono en tu mochila. Clasifica basura en el taller para crear más.")
            return
        }
        toqueHaptico.impactOccurred()
        gameManager.abonar()
        activarEfecto(tipo: "abono")
        UIAccessibility.post(
            notification: .announcement,
            argument: "Planta abonada. Nivel de abono al \(Int(gameManager.nivelAbono)) por ciento."
        )
    }

    private func ejecutarCurarPlaga() {
        guard gameManager.inventarioSpray > 0 else {
            UIAccessibility.post(notification: .announcement, argument: "No tienes sprays curativos. Juega al memorama para ganar uno.")
            return
        }
        exitoHaptico.notificationOccurred(.success)
        withAnimation {
            gameManager.curarPlaga()
            activarEfecto(tipo: "spray")
        }
        UIAccessibility.post(
            notification: .announcement,
            argument: "¡Plaga eliminada con éxito! Tu planta está a salvo."
        )
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
        gameManager.moverAlRefugio(nombre: nombreIngresado, icono: plantaSecretaActual)
        let nombreAsignado = nombreIngresado.isEmpty ? "tu planta" : nombreIngresado
        nombreIngresado = ""
        plantaSecretaActual = especiesAdultas.randomElement() ?? "🪴"
        
        exitoHaptico.notificationOccurred(.success)
        UIAccessibility.post(
            notification: .announcement,
            argument: "¡Felicidades! Has guardado a \(nombreAsignado) en tu refugio. Comienza a cuidar una nueva semilla."
        )
    }
}

//Subvista Aislada: Planta y Efectos Visuales

struct CentroPlantaView: View {
    let iconoPlanta: String
    let escalaPlanta: CGFloat
    let tienePlaga: Bool
    let iconoPlaga: String
    let nivelVida: Double
    let nivelAgua: Double
    let nivelAbono: Double
    let mostrandoLluvia: Bool
    let mostrandoBrillos: Bool
    let mostrandoSpray: Bool
    let alRegar: () -> Void
    let alAbonar: () -> Void
    let alCurar: () -> Void

    private var descripcionPlanta: String {
        if nivelVida <= 0 {
            return "Tu planta está marchita y necesita cuidados."
        } else if nivelAgua >= 100 && nivelAbono >= 100 {
            return "Tu planta ha crecido por completo y está lista para el refugio."
        } else if nivelAgua >= 30 && nivelAbono >= 30 {
            return "Tu planta es un brote verde en crecimiento."
        } else {
            return "Tu planta es una semilla en la tierra."
        }
    }

    private var valorAccesible: String {
        let vida = Int(nivelVida)
        let plaga = tienePlaga ? "¡Atención! Tiene una plaga encima." : ""
        return "\(descripcionPlanta) Vida al \(vida) por ciento. \(plaga)"
    }

    var body: some View {
        ZStack {
            Text(iconoPlanta)
                .font(.system(size: 150))
                .scaleEffect(escalaPlanta)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: escalaPlanta)

            if tienePlaga && nivelVida > 0 {
                Text(iconoPlaga)
                    .font(.system(size: 44))
                    .offset(x: 45, y: -40)
                    .transition(.scale)
            }

            if mostrandoLluvia {
                Text("🌧️")
                    .font(.system(size: 80))
                    .offset(y: -120)
                    .transition(.opacity)
            }

            if mostrandoBrillos {
                Text("✨")
                    .font(.system(size: 60))
                    .offset(y: 80)
                    .transition(.opacity)
            }

            if mostrandoSpray {
                Text("💨")
                    .font(.system(size: 60))
                    .offset(x: 40, y: -30)
                    .transition(.opacity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Planta principal")
        .accessibilityValue(valorAccesible)
        .accessibilityHint("Usa las acciones para regar, abonar o curar.")
        .accessibilityAction(named: "Regar planta", alRegar)
        .accessibilityAction(named: "Abonar planta", alAbonar)
        .accessibilityAction(named: "Curar plaga con spray", alCurar)
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
                    UIAccessibility.post(notification: .announcement, argument: "Usaste 1 de agua dulce.")
                }
                
                filaRecurso(icono: "🌱", nombre: "Abono orgánico", cantidad: gameManager.inventarioAbono, color: .brown) {
                    gameManager.abonar()
                    UIAccessibility.post(notification: .announcement, argument: "Usaste 1 de abono orgánico.")
                }
                
                filaRecurso(icono: "🧴", nombre: "Spray Anti-Plagas", cantidad: gameManager.inventarioSpray, color: .orange) {
                    gameManager.curarPlaga()
                    UIAccessibility.post(notification: .announcement, argument: "Usaste 1 spray anti-plagas.")
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
                        .accessibilityLabel("Cerrar mochila")
                }
            }
        }
    }
    
    @ViewBuilder
    private func filaRecurso(icono: String, nombre: String, cantidad: Int, color: Color, accion: @escaping () -> Void) -> some View {
        HStack(spacing: 16) {
            Text(icono).font(.system(size: 38))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(nombre).font(.headline)
                Text("Disponibles: \(cantidad)").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Button("Usar", action: accion)
                .buttonStyle(.borderedProminent)
                .tint(color)
                .disabled(cantidad == 0)
                .accessibilityLabel("Usar \(nombre)")
                .accessibilityValue("\(cantidad) disponibles")
                .accessibilityHint(cantidad > 0 ? "Aplica este recurso inmediatamente a tu planta." : "Agotado. Juega a los minijuegos para conseguir más.")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

// MARK: - Vista Jardín

struct JardinView: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        ZStack {
            Color.green.opacity(0.1).ignoresSafeArea()
            if gameManager.jardinGuardado.isEmpty {
                Text("Tu refugio está vacío. ¡Sigue cuidando plantas para repoblar el bosque!")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding()
                    .accessibilityLabel("Tu refugio está vacío. Cuida plantas hasta que crezcan para salvarlas aquí.")
            } else {
                List(gameManager.jardinGuardado) { planta in
                    HStack(spacing: 16) {
                        Text(planta.icono ?? "🪴").font(.system(size: 40))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(planta.nombre ?? "Sin nombre").font(.headline)
                            if let fecha = planta.fecha {
                                Text(fecha.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Planta guardada: \(planta.nombre ?? "Sin nombre"). Rescatada el \(planta.fecha?.formatted(date: .long, time: .omitted) ?? "recientemente").")
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Mi Refugio")
    }
}

#Preview {
    PlantaView()
        .environmentObject(GameManager())
}
