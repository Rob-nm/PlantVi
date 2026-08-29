import SwiftUI
internal import Combine

// Modelo de datos (Intacto)
struct PlantaGuardada: Identifiable {
    let id = UUID()
    let nombre: String
    let icono: String
}

struct ContentView: View {
    
    // Estados originales
    @State private var nivelAgua: Double = 0.0
    @State private var nivelAbono: Double = 0.0
    
    // ¡NUEVO! 1. Estado de Vida y el Temporizador
    @State private var nivelVida: Double = 100.0 // Empieza al máximo
    // El temporizador "dispara" un evento cada 3 segundos automáticamente
    let temporizador = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    
    // Estados de animaciones y visuales
    @State private var escalaPlanta: CGFloat = 1.0
    @State private var mostrandoLluvia: Bool = false
    @State private var mostrandoBrillos: Bool = false
    
    // Plantas, nubes y alertas
    @State private var especiesAdultas = ["🪴", "🌳", "🌵", "🌻", "🌴"]
    @State private var plantaSecretaActual: String = "🪴"
    @State private var moverNubes: Bool = false
    
    @State private var miJardin: [PlantaGuardada] = []
    @State private var mostrarAlertaNombre: Bool = false
    @State private var nombreIngresado: String = ""
    
    var esDeDia: Bool {
        let horaActual = Calendar.current.component(.hour, from: Date())
        return horaActual >= 6 && horaActual < 19
    }
    
    // ¡NUEVO! 2. Lógica visual de vida crítica
    var iconoPlanta: String {
        if nivelVida <= 0 { return "🍂" } // Si la vida llega a cero, se ve marchita
        else if nivelAgua >= 100 && nivelAbono >= 100 { return plantaSecretaActual }
        else if nivelAgua >= 30 && nivelAbono >= 30 { return "🌱" }
        else { return "🌰" }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                // Fondo y Nubes (Intacto)
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
                
                // Interfaz Principal
                VStack(spacing: 30) {
                    
                    // ¡NUEVO! 3. Agregamos la barra de Vida
                    VStack(spacing: 15) {
                        ProgressView("❤️ Vida", value: nivelVida, total: 100).tint(.red)
                        ProgressView("💧 Agua", value: nivelAgua, total: 100).tint(.blue)
                        ProgressView("🌱 Abono", value: nivelAbono, total: 100).tint(.brown)
                    }
                    .padding().background(.ultraThinMaterial).cornerRadius(15).padding(.horizontal).bold()
                    
                    Spacer()
                    
                    // Planta central
                    ZStack {
                        Text(iconoPlanta).font(.system(size: 150))
                            .scaleEffect(escalaPlanta)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: escalaPlanta)
                        
                        if mostrandoLluvia { Text("🌧️").font(.system(size: 80)).offset(y: -120).transition(.opacity) }
                        if mostrandoBrillos { Text("✨").font(.system(size: 60)).offset(y: 80).transition(.opacity) }
                    }
                    
                    // Mensaje dinámico según la vida
                    Text(nivelVida <= 0 ? "¡Tu planta necesita ayuda!" : (nivelAgua >= 100 && nivelAbono >= 100 ? "¡Planta Lista!" : "Cuidando mi semilla"))
                        .font(.title).bold().foregroundColor(.white)
                    
                    Spacer()
                    
                    // Botones
                    VStack {
                        if nivelAgua >= 100 && nivelAbono >= 100 && nivelVida > 0 {
                            Button(action: { mostrarAlertaNombre = true }) {
                                Text("Mover al Refugio")
                                    .font(.headline).padding().frame(maxWidth: .infinity)
                                    .background(Color.green).foregroundColor(.white).cornerRadius(15)
                            }
                        } else {
                            HStack(spacing: 20) {
                                Button(action: {
                                    if nivelAgua < 100 { nivelAgua += 10 }
                                    recuperarVida() // ¡NUEVO! Llama a la función de curar
                                    activarEfecto(tipo: "agua")
                                }) {
                                    Text("Regar").font(.title2).padding().frame(maxWidth: .infinity)
                                        .background(Color.blue).foregroundColor(.white).cornerRadius(15)
                                }
                                
                                Button(action: {
                                    if nivelAbono < 100 { nivelAbono += 10 }
                                    recuperarVida()
                                    activarEfecto(tipo: "abono")
                                }) {
                                    Text("Abonar").font(.title2).padding().frame(maxWidth: .infinity)
                                        .background(Color.brown).foregroundColor(.white).cornerRadius(15)
                                }
                            }
                        }
                    }
                    .padding().background(.ultraThinMaterial).cornerRadius(20).padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            // ¡NUEVO! 4. El evento del Temporizador
            .onReceive(temporizador) { _ in
                // Si la planta no está lista aún, pierde vida con el tiempo (evita que baje de 0)
                if (nivelAgua < 100 || nivelAbono < 100) && nivelVida > 0 {
                    nivelVida -= 5
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: JardinView(coleccion: miJardin)) {
                        Text("Mi Jardín 🪴").bold().foregroundColor(.white)
                    }
                }
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
    
    // Funciones
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
    
    // ¡NUEVO! 5. Función para curar la planta sin pasar de 100
    func recuperarVida() {
        if nivelVida < 100 {
            nivelVida += 15 // Recupera 15 puntos por cada riego/abono
            if nivelVida > 100 { nivelVida = 100 } // Tope máximo
        }
    }
    
    func guardarPlanta() {
        let nuevaPlanta = PlantaGuardada(nombre: nombreIngresado.isEmpty ? "Sin nombre" : nombreIngresado, icono: plantaSecretaActual)
        miJardin.append(nuevaPlanta)
        
        nivelAgua = 0.0; nivelAbono = 0.0; nivelVida = 100.0 // Reinicia la vida a tope
        nombreIngresado = ""
        plantaSecretaActual = especiesAdultas.randomElement() ?? "🪴"
    }
}

// Segunda Pantalla (Intacta)
struct JardinView: View {
    var coleccion: [PlantaGuardada]
    
    var body: some View {
        ZStack {
            Color.green.opacity(0.1).ignoresSafeArea()
            if coleccion.isEmpty {
                Text("Tu refugio está vacío. ¡Sigue cuidando plantas para repoblar el bosque!").font(.headline).multilineTextAlignment(.center).foregroundColor(.gray).padding()
            } else {
                List(coleccion) { planta in
                    HStack(spacing: 20) {
                        Text(planta.icono).font(.system(size: 50))
                        Text(planta.nombre).font(.title3).bold()
                    }.listRowBackground(Color.clear)
                }.scrollContentBackground(.hidden)
            }
        }.navigationTitle("Mi Refugio")
    }
}

#Preview {
    ContentView()
}
