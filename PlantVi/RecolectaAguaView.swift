import SwiftUI
internal import Combine

struct RecolectaAguaView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gameManager: GameManager // <--- Conexión al Manager global
    
    // Estados del minijuego
    @State private var posicionCubetaX: CGFloat = 0.0
    @State private var posicionGotaX: CGFloat = CGFloat.random(in: -100...100)
    @State private var posicionGotaY: CGFloat = -180.0
    @State private var gotasRecolectadas: Int = 0
    @State private var juegoTerminado: Bool = false
    
    let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    let metaGotas: Int = 10
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.8), .indigo], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(.white)
                        .bold()
                    Spacer()
                    Text("💧 \(gotasRecolectadas) / \(metaGotas)")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                }
                .padding()
                
                Spacer()
                
                ZStack {
                    VStack(spacing: 0) {
                        Text("☁️")
                            .font(.system(size: 110))
                        Spacer()
                    }
                    .frame(height: 500)
                    .offset(y: -50)
                    
                    Text("💧")
                        .font(.system(size: 35))
                        .offset(x: posicionGotaX, y: posicionGotaY)
                    
                    Text("🪣")
                        .font(.system(size: 70))
                        .offset(x: posicionCubetaX, y: 200)
                }
                .frame(height: 500)
                
                Spacer()
                
                HStack(spacing: 40) {
                    Button(action: { moverCubeta(izquierda: true) }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: { moverCubeta(izquierda: false) }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 30)
            }
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
    
    func moverCubeta(izquierda: Bool) {
        withAnimation(.linear(duration: 0.1)) {
            if izquierda {
                posicionCubetaX = max(-120, posicionCubetaX - 40)
            } else {
                posicionCubetaX = min(120, posicionCubetaX + 40)
            }
        }
    }
    
    func actualizarFisicaGota() {
        guard !juegoTerminado else { return }
        posicionGotaY += 7.0
        
        if posicionGotaY >= 180 && posicionGotaY <= 220 {
            if abs(posicionGotaX - posicionCubetaX) < 45 {
                gotasRecolectadas += 1
                reiniciarGota()
                if gotasRecolectadas >= metaGotas {
                    juegoTerminado = true
                }
            }
        }
        
        if posicionGotaY > 240 {
            reiniciarGota()
        }
    }
    
    func reiniciarGota() {
        posicionGotaY = -180.0
        posicionGotaX = CGFloat.random(in: -100...100)
    }
}
