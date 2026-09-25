//
//  PlantaView.swift
//  PlantVi
//
//  Created by Brandiuxx on 31/08/26.
//

import SwiftUI
internal import Combine

//Modelo de datos
struct PlantaGuardada: Identifiable {
    let id = UUID()
    let nombre: String
    let icono: String
}

//Vista Principal
struct PlantaView: View {
    @EnvironmentObject var gameManager: GameManager

    // Niveles de la planta
    @State private var nivelAgua: Double = 0.0
    @State private var nivelAbono: Double = 0.0
    @State private var nivelVida: Double = 100.0

    let temporizador = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()

    @State private var escalaPlanta: CGFloat = 1.0
    @State private var mostrandoLluvia: Bool = false
    @State private var mostrandoBrillos: Bool = false

    @State private var especiesAdultas = ["🪴", "🌳", "🌵", "🌻", "🌴"]
    @State private var plantaSecretaActual: String = "🪴"
    @State private var moverNubes: Bool = false

    @State private var miJardin: [PlantaGuardada] = []
    @State private var mostrarAlertaNombre: Bool = false
    @State private var nombreIngresado: String = ""
    @State private var mostrarModalInventario: Bool = false

    // Generadores hápticos nativos para confirmación sensorial
    private let exitoHaptico = UIImpactFeedbackGenerator(style: .medium)
    private let alertaHaptica = UINotificationFeedbackGenerator()

    var esDeDia: Bool {
        let horaActual = Calendar.current.component(.hour, from: Date())
        return horaActual >= 6 && horaActual < 19
    }

    var iconoPlanta: String {
        if nivelVida <= 0 { return "🍂" }
        else if nivelAgua >= 100 && nivelAbono >= 100 { return plantaSecretaActual }
        else if nivelAgua >= 30 && nivelAbono >= 30 { return "🌱" }
        else { return "🌰" }
    }

    // Descripción en lenguaje natural para VoiceOver
    var descripcionEstadoPlanta: String {
        if nivelVida <= 0 {
            return "Planta marchita. Tu planta necesita agua y abono de inmediato para revivir."
        } else if nivelAgua >= 100 && nivelAbono >= 100 {
            return "Planta completamente crecida y saludable. Lista para llevarla al refugio."
        } else if nivelAgua >= 30 && nivelAbono >= 30 {
            return "Planta en etapa de brote verde, creciendo sanamente."
        } else {
            return "Semilla en la tierra, esperando agua y abono para germinar."
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: esDeDia ? [.blue, .cyan] : [.black, .purple],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()

                // Fondo dinámico (Sol/Luna)
                VStack {
                    HStack {
                        Text(esDeDia ? "☁️" : "🌙").font(.system(size: 80))
                            .offset(x: moverNubes ? 250 : -250)
                            .animation(.linear(duration: 25).repeatForever(autoreverses: false), value: moverNubes)
                            .accessibilityLabel(esDeDia ? "Es de día con cielo despejado y nubes" : "Es de noche con cielo estrellado")
                        Spacer()
                    }.padding(.top, 50)
                    Spacer()
                }.onAppear { moverNubes = true }

                VStack(spacing: 24) {

                    // Barras de progreso con lectura numérica para VoiceOver
                    VStack(spacing: 12) {
                        ProgressView("❤️ Vida", value: nivelVida, total: 100)
                            .tint(.red)
                            .accessibilityLabel("Salud de la planta")
                            .accessibilityValue("\(Int(nivelVida)) por ciento")

                        ProgressView("💧 Agua", value: nivelAgua, total: 100)
                            .tint(.blue)
                            .accessibilityLabel("Nivel de agua")
                            .accessibilityValue("\(Int(nivelAgua)) por ciento")

                        ProgressView("🌱 Abono", value: nivelAbono, total: 100)
                            .tint(.brown)
                            .accessibilityLabel("Nivel de abono")
                            .accessibilityValue("\(Int(nivelAbono)) por ciento")
                    }
                    .padding().background(.ultraThinMaterial).cornerRadius(15).padding(.horizontal).bold()

                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Text("💧")
                            Text("\(gameManager.inventarioAgua) disponibles")
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Agua disponible en mochila: \(gameManager.inventarioAgua) raciones")

                        HStack(spacing: 6) {
                            Text("🌱")
                            Text("\(gameManager.inventarioAbono) disponibles")
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Abono disponible en mochila: \(gameManager.inventarioAbono) raciones")
                    }

                    Spacer()

                    // Planta Principal
                    ZStack {
                        Text(iconoPlanta)
                            .font(.system(size: 150))
                            .scaleEffect(escalaPlanta)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: escalaPlanta)

                        if mostrandoLluvia { Text("🌧️").font(.system(size: 80)).offset(y: -120).transition(.opacity).accessibilityHidden(true) }
                        if mostrandoBrillos { Text("✨").font(.system(size: 60)).offset(y: 80).transition(.opacity).accessibilityHidden(true) }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Tu planta")
                    .accessibilityValue(descripcionEstadoPlanta)
                    .accessibilityHint("Regar o abonar para ayudarla a crecer")

                    Text(nivelVida <= 0 ? "¡Tu planta necesita ayuda!" : (nivelAgua >= 100 && nivelAbono >= 100 ? "¡Planta Lista!" : "Cuidando mi semilla"))
                        .font(.title2).bold().foregroundColor(.white)
                        .accessibilityLabel(nivelVida <= 0 ? "Tu planta necesita ayuda urgente" : (nivelAgua >= 100 && nivelAbono >= 100 ? "Planta lista para cosechar" : "Cuidando mi semilla"))

                    Spacer()

                    // Botones de acción principales
                    VStack {
                        if nivelAgua >= 100 && nivelAbono >= 100 && nivelVida > 0 {
                            Button(action: {
                                alertaHaptica.notificationOccurred(.success)
                                UIAccessibility.post(notification: .announcement, argument: "Abriendo ventana para bautizar y mover al refugio.")
                                mostrarAlertaNombre = true
                            }) {
                                Text("Mover al Refugio")
                                    .font(.headline).padding().frame(maxWidth: .infinity)
                                    .background(Color.green).foregroundColor(.white).cornerRadius(15)
                            }
                            .accessibilityLabel("Mover planta al refugio")
                            .accessibilityHint("Guarda esta planta adulta en tu jardín y comienza una nueva")
                        } else {
                            HStack(spacing: 16) {
                                // Botón Regar
                                Button(action: regarPlanta) {
                                    VStack(spacing: 2) {
                                        Text("Regar")
                                            .font(.headline)
                                        Text("Usa 1 💧 (\(gameManager.inventarioAgua))")
                                            .font(.caption2)
                                    }
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(gameManager.inventarioAgua > 0 ? Color.blue : Color.gray.opacity(0.6))
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                                }
                                .disabled(gameManager.inventarioAgua == 0)
                                .accessibilityLabel("Regar planta")
                                .accessibilityValue("\(gameManager.inventarioAgua) gotas disponibles")
                                .accessibilityHint(gameManager.inventarioAgua > 0 ? "Gasta 1 de agua y aumenta la hidratación y vida" : "No tienes agua. Consigue más en los juegos")

                                // Botón Abonar
                                Button(action: abonarPlanta) {
                                    VStack(spacing: 2) {
                                        Text("Abonar")
                                            .font(.headline)
                                        Text("Usa 1 🌱 (\(gameManager.inventarioAbono))")
                                            .font(.caption2)
                                    }
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(gameManager.inventarioAbono > 0 ? Color.brown : Color.gray.opacity(0.6))
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                                }
                                .disabled(gameManager.inventarioAbono == 0)
                                .accessibilityLabel("Abonar planta")
                                .accessibilityValue("\(gameManager.inventarioAbono) abonos disponibles")
                                .accessibilityHint(gameManager.inventarioAbono > 0 ? "Gasta 1 de abono y nutre a la planta" : "No tienes abono. Ve al juego de reciclaje para conseguir más")
                            }
                        }
                    }
                    .padding().background(.ultraThinMaterial).cornerRadius(20).padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .onReceive(temporizador) { _ in
                if (nivelAgua < 100 || nivelAbono < 100) && nivelVida > 0 {
                    nivelVida = max(0, nivelVida - 5)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        exitoHaptico.impactOccurred()
                        mostrarModalInventario = true
                    }) {
                        Label("Mochila", systemImage: "backpack.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Abrir Mochila e Inventario")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: JardinView(coleccion: miJardin)) {
                        Text("🪴").font(.title3)
                    }
                    .accessibilityLabel("Ver Mi Refugio de Plantas")
                }
            }
            .sheet(isPresented: $mostrarModalInventario) {
                InventarioModalView(
                    nivelAgua: $nivelAgua,
                    nivelAbono: $nivelAbono,
                    onAccionAplicada: { tipo in
                        recuperarVida()
                        activarEfecto(tipo: tipo)
                    }
                )
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

    // MARK: - Acciones con Anuncios de Voz y Hápticos

    private func regarPlanta() {
        if gameManager.inventarioAgua > 0 {
            gameManager.inventarioAgua -= 1
            if nivelAgua < 100 { nivelAgua = min(100, nivelAgua + 10) }
            recuperarVida()
            activarEfecto(tipo: "agua")
            exitoHaptico.impactOccurred()
            
            UIAccessibility.post(
                notification: .announcement,
                argument: "Planta regada. Nivel de agua al \(Int(nivelAgua)) por ciento."
            )
        }
    }

    private func abonarPlanta() {
        if gameManager.inventarioAbono > 0 {
            gameManager.inventarioAbono -= 1
            if nivelAbono < 100 { nivelAbono = min(100, nivelAbono + 10) }
            recuperarVida()
            activarEfecto(tipo: "abono")
            exitoHaptico.impactOccurred()
            
            UIAccessibility.post(
                notification: .announcement,
                argument: "Planta abonada. Nivel de abono al \(Int(nivelAbono)) por ciento."
            )
        }
    }

    func activarEfecto(tipo: String) {
        escalaPlanta = 1.2
        withAnimation {
            if tipo == "agua" { mostrandoLluvia = true }
            if tipo == "abono" { mostrandoBrillos = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation { mostrandoLluvia = false; mostrandoBrillos = false; escalaPlanta = 1.0 }
        }
    }

    func recuperarVida() {
        if nivelVida < 100 {
            nivelVida = min(100, nivelVida + 15)
        }
    }

    func guardarPlanta() {
        let nombreFinal = nombreIngresado.isEmpty ? "Sin nombre" : nombreIngresado
        let nuevaPlanta = PlantaGuardada(nombre: nombreFinal, icono: plantaSecretaActual)
        miJardin.append(nuevaPlanta)

        UIAccessibility.post(notification: .announcement, argument: "Planta \(nombreFinal) guardada con éxito en el refugio.")

        nivelAgua = 0.0; nivelAbono = 0.0; nivelVida = 100.0
        nombreIngresado = ""
        plantaSecretaActual = especiesAdultas.randomElement() ?? "🪴"
    }
}

// MARK: - Modal de Inventario con Accesibilidad
struct InventarioModalView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var nivelAgua: Double
    @Binding var nivelAbono: Double
    var onAccionAplicada: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Recursos disponibles para cuidar tu planta:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    // Tarjeta Agua
                    HStack(spacing: 16) {
                        Text("💧").font(.system(size: 40)).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Agua Dulce").font(.headline)
                            Text("Tienes: \(gameManager.inventarioAgua)").font(.subheadline).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Aplicar") {
                            if gameManager.inventarioAgua > 0 {
                                gameManager.inventarioAgua -= 1
                                nivelAgua = min(100, nivelAgua + 10)
                                onAccionAplicada("agua")
                                UIAccessibility.post(notification: .announcement, argument: "Agua aplicada desde la mochila.")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .disabled(gameManager.inventarioAgua == 0)
                        .accessibilityLabel("Aplicar agua a la planta")
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    .accessibilityElement(children: .combine)

                    HStack(spacing: 16) {
                        Text("🌱").font(.system(size: 40)).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Abono Orgánico").font(.headline)
                            Text("Tienes: \(gameManager.inventarioAbono)").font(.subheadline).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Aplicar") {
                            if gameManager.inventarioAbono > 0 {
                                gameManager.inventarioAbono -= 1
                                nivelAbono = min(100, nivelAbono + 10)
                                onAccionAplicada("abono")
                                UIAccessibility.post(notification: .announcement, argument: "Abono aplicado desde la mochila.")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.brown)
                        .disabled(gameManager.inventarioAbono == 0)
                        .accessibilityLabel("Aplicar abono a la planta")
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    .accessibilityElement(children: .combine)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 16)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Mochila 🎒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Vista Refugio
struct JardinView: View {
    var coleccion: [PlantaGuardada]

    var body: some View {
        ZStack {
            Color.green.opacity(0.1).ignoresSafeArea()
            if coleccion.isEmpty {
                Text("Tu refugio está vacío. ¡Sigue cuidando plantas para repoblar el bosque!")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding()
                    .accessibilityLabel("El refugio está vacío. Aún no tienes plantas guardadas.")
            } else {
                List(coleccion) { planta in
                    HStack(spacing: 20) {
                        Text(planta.icono).font(.system(size: 50)).accessibilityHidden(true)
                        Text(planta.nombre).font(.title3).bold()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Planta guardada: \(planta.nombre)")
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
        }.navigationTitle("Mi Refugio")
    }
}

#Preview {
    PlantaView()
        .environmentObject(GameManager())
}
