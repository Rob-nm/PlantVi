//
//  RecolectaAguaView.swift
//  PlantVi
//

import SwiftUI
internal import Combine

struct RecolectaAguaView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameManager: GameManager
    
    @State private var posicionCubetaX: CGFloat = 0.0
    @State private var posicionGotaX: CGFloat = CGFloat.random(in: -100...100)
    @State private var posicionGotaY: CGFloat = -180.0
    @State private var gotasRecolectadas: Int = 0
    @State private var juegoTerminado: Bool = false
    
    let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    let metaGotas: Int = 10

    // Generadores hápticos nativos
    private let exitoHaptico = UINotificationFeedbackGenerator()
    private let toqueHaptico = UIImpactFeedbackGenerator(style: .light)
    
    // Descripción orientativa de la gota para VoiceOver
    private var posicionGotaTexto: String {
        if posicionGotaX < -35 {
            return "hacia la izquierda"
        } else if posicionGotaX > 35 {
            return "hacia la derecha"
        } else {
            return "por el centro"
        }
    }

    private var posicionCubetaTexto: String {
        if posicionCubetaX < -35 {
            return "a la izquierda"
        } else if posicionCubetaX > 35 {
            return "a la derecha"
        } else {
            return "en el centro"
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.8), .indigo], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.white)
                        .bold()
                        .accessibilityLabel("Cancelar y salir del juego")
                    
                    Spacer()
                    
                    Text("💧 \(gotasRecolectadas) / \(metaGotas)")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Progreso: \(gotasRecolectadas) de \(metaGotas) gotas recolectadas")
                }
                .padding()
                
                Spacer()
                
                // Zona de simulación
                ZStack {
                    VStack(spacing: 0) {
                        Text("☁️")
                            .font(.system(size: 110))
                            .accessibilityHidden(true)
                        Spacer()
                    }
                    .frame(height: 500)
                    .offset(y: -50)
                    
                    // Gota en movimiento (Oculta a VoiceOver para evitar saturación de lectura)
                    Text("💧")
                        .font(.system(size: 35))
                        .offset(x: posicionGotaX, y: posicionGotaY)
                        .accessibilityHidden(true)
                    
                    // Cubeta interactiva para VoiceOver
                    Text("🪣")
                        .font(.system(size: 70))
                        .offset(x: posicionCubetaX, y: 200)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Cubeta recolectora")
                        .accessibilityValue("Ubicada \(posicionCubetaTexto). Gota cayendo \(posicionGotaTexto).")
                        .accessibilityHint("Usa las acciones personalizadas para alinear la cubeta y atrapar el agua.")
                        .accessibilityAction(named: "Mover a la izquierda") {
                            moverCubeta(izquierda: true)
                        }
                        .accessibilityAction(named: "Mover a la derecha") {
                            moverCubeta(izquierda: false)
                        }
                        .accessibilityAction(named: "Alinear con la gota") {
                            // Asistencia directa para niños con discapacidad visual/motriz
                            posicionCubetaX = posicionGotaX
                            toqueHaptico.impactOccurred()
                            UIAccessibility.post(notification: .announcement, argument: "Cubeta alineada con la gota.")
                        }
                }
                .frame(height: 500)
                
                Spacer()
                
                // Controles en pantalla
                HStack(spacing: 40) {
                    Button(action: { moverCubeta(izquierda: true) }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Mover cubeta a la izquierda")
                    .accessibilityHint("Desplaza la cubeta hacia el lado izquierdo")
                    
                    Button(action: { moverCubeta(izquierda: false) }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Mover cubeta a la derecha")
                    .accessibilityHint("Desplaza la cubeta hacia el lado derecho")
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            anunciarInicio()
        }
        .onReceive(timer) { _ in
            actualizarFisicaGota()
        }
        .alert("¡Agua Recolectada! 🌧️", isPresented: $juegoTerminado) {
            Button("Guardar en Inventario") {
                // Sumamos 1 unidad a la variable real del GameManager
                gameManager.inventarioAgua += 1
                dismiss()
            }
        } message: {
            Text("¡Conseguiste 1 carga de agua! Puedes usarla desde la pantalla de Mi Planta.")
        }
    }
    
    // MARK: - Movimiento y Feedback
    
    func moverCubeta(izquierda: Bool) {
        toqueHaptico.impactOccurred()
        
        withAnimation(.linear(duration: 0.1)) {
            if izquierda {
                posicionCubetaX = max(-120, posicionCubetaX - 40)
            } else {
                posicionCubetaX = min(120, posicionCubetaX + 40)
            }
        }
    }
    
    // MARK: - Física del Juego
    
    func actualizarFisicaGota() {
        guard !juegoTerminado else { return }
        posicionGotaY += 7.0
        
        // Colisión con la cubeta
        if posicionGotaY >= 180 && posicionGotaY <= 220 {
            if abs(posicionGotaX - posicionCubetaX) < 45 {
                gotasRecolectadas += 1
                exitoHaptico.notificationOccurred(.success)
                
                // Anuncio breve cada vez que atrapa agua
                if gotasRecolectadas < metaGotas {
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "¡Gota atrapada! Llevas \(gotasRecolectadas) de \(metaGotas)."
                    )
                }
                
                reiniciarGota()
                
                if gotasRecolectadas >= metaGotas {
                    juegoTerminado = true
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "¡Meta cumplida! Recolectaste las 10 gotas. Toca guardar para sumarlas a tu inventario."
                    )
                }
            }
        }
        
        // Gota perdida en el suelo
        if posicionGotaY > 240 {
            reiniciarGota()
        }
    }
    
    func reiniciarGota() {
        posicionGotaY = -180.0
        posicionGotaX = CGFloat.random(in: -100...100)
    }

    private func anunciarInicio() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIAccessibility.post(
                notification: .announcement,
                argument: "Juego de Recolecta Agua iniciado. Atrapa 10 gotas moviendo la cubeta con las flechas o con las acciones de accesibilidad."
            )
        }
    }
}

#Preview {
    RecolectaAguaView()
        .environmentObject(GameManager())
}
