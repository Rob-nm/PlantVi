//
//  QuizVerdeSwift.swift
//  PlantVi
//
//  Created by Brandiuxx on 24/09/26.
//

import SwiftUI

// MARK: - Modelo de Pregunta
struct PreguntaQuiz: Identifiable {
    let id = UUID()
    let texto: String
    let icono: String
    let opciones: [String]
    let indiceCorrecto: Int
    let explicacion: String
}

// MARK: - Vista Principal
struct QuizVerdeView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    private let bancoPreguntas: [PreguntaQuiz] = [
        PreguntaQuiz(
            texto: "¿Qué gas vital producen los árboles y nos permite respirar?",
            icono: "💨",
            opciones: ["Oxígeno", "Humo", "Helio", "Nitrógeno"],
            indiceCorrecto: 0,
            explicacion: "¡Exacto! Mediante la fotosíntesis, las hojas absorben dióxido de carbono y liberan oxígeno puro."
        ),
        PreguntaQuiz(
            texto: "¿Por qué parte toman los árboles el agua y los nutrientes de la tierra?",
            icono: "🌱",
            opciones: ["Por las raíces", "Por las ramas", "Por las flores", "Por el tronco"],
            indiceCorrecto: 0,
            explicacion: "¡Muy bien! Las raíces subterráneas funcionan como popotes que absorben el agua del suelo."
        ),
        PreguntaQuiz(
            texto: "¿Qué energía natural usan las hojas verdes para fabricar su alimento?",
            icono: "☀️",
            opciones: ["Electricidad", "El viento", "Luz solar", "El frío"],
            indiceCorrecto: 2,
            explicacion: "¡Eso es! La luz solar es el ingrediente principal con el que las plantas hacen fotosíntesis."
        ),
        PreguntaQuiz(
            texto: "¿Cuál de estos animales es un gran polinizador y ayuda a que nazcan frutos en los árboles?",
            icono: "🐝",
            opciones: ["El mosquito", "La abeja", "La pulga", "El caracol"],
            indiceCorrecto: 1,
            explicacion: "¡Así se hace! Las abejas transportan el polen de flor en flor permitiendo que crezcan frutos y semillas."
        ),
        PreguntaQuiz(
            texto: "¿Qué insecto suele comerse las hojas verdes tiernas y convertirse en plaga?",
            icono: "🐛",
            opciones: ["La oruga", "La mariquita", "La lombriz", "La araña"],
            indiceCorrecto: 0,
            explicacion: "¡Correcto! Las orugas son muy voraces con las hojas verdes y necesitan ser controladas."
        )
    ]

    @State private var preguntasPartida: [PreguntaQuiz] = []
    @State private var indicePreguntaActual: Int = 0
    @State private var indicesFallados: Set<Int> = []
    @State private var respuestaAcertada: Bool = false
    @State private var mensajeMotivacional: String = "Elige la respuesta que creas correcta 👇"
    @State private var mostrarAlertaPremioFinal: Bool = false
    @State private var premioObtenidoTexto: String = ""

    // Generadores hápticos nativos
    private let exitoHaptico = UINotificationFeedbackGenerator()
    private let alertaHaptica = UINotificationFeedbackGenerator()
    private let seleccionHaptica = UISelectionFeedbackGenerator()

    private var preguntaActual: PreguntaQuiz? {
        guard !preguntasPartida.isEmpty && indicePreguntaActual < preguntasPartida.count else { return nil }
        return preguntasPartida[indicePreguntaActual]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.12), Color.green.opacity(0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if let pregunta = preguntaActual {
                VStack(spacing: 18) {
                    // Barra superior: recursos e indicador de avance
                    HStack(spacing: 10) {
                        RecursoBadge(icono: "💧", valor: gameManager.inventarioAgua, recursoNombre: "Agua")
                        RecursoBadge(icono: "🌱", valor: gameManager.inventarioAbono, recursoNombre: "Abono")
                        RecursoBadge(icono: "🧴", valor: gameManager.inventarioSpray, recursoNombre: "Spray")

                        Spacer()

                        Text("Pregunta \(indicePreguntaActual + 1)/\(preguntasPartida.count)")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .accessibilityLabel("Pregunta \(indicePreguntaActual + 1) de \(preguntasPartida.count)")
                    }
                    .padding(.horizontal)

                    // Tarjeta de la Pregunta
                    VStack(spacing: 14) {
                        Text(pregunta.icono)
                            .font(.system(size: 60))
                            .accessibilityHidden(true)

                        Text(pregunta.texto)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                    }
                    .padding(.vertical, 22)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                    .padding(.horizontal)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Pregunta número \(indicePreguntaActual + 1): \(pregunta.texto)")

                    // Mensaje motivacional o explicativo
                    Text(mensajeMotivacional)
                        .font(.subheadline.bold())
                        .foregroundColor(respuestaAcertada ? .green : (indicesFallados.isEmpty ? .secondary : .orange))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .frame(height: 40)
                        .accessibilityLabel("Mensaje: \(mensajeMotivacional)")

                    // Opciones de respuesta
                    VStack(spacing: 12) {
                        ForEach(0..<pregunta.opciones.count, id: \.self) { indice in
                            BotonOpcionQuiz(
                                texto: pregunta.opciones[indice],
                                numeroOpcion: indice + 1,
                                estadoBoton: estadoDeBoton(para: indice, pregunta: pregunta),
                                alPresionar: {
                                    verificarRespuesta(indiceSeleccionado: indice, pregunta: pregunta)
                                }
                            )
                            .disabled(respuestaAcertada || indicesFallados.contains(indice))
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Botón para avanzar de pregunta o terminar
                    if respuestaAcertada {
                        Button(action: siguientePregunta) {
                            HStack {
                                Text(indicePreguntaActual + 1 < preguntasPartida.count ? "Siguiente Pregunta" : "Reclamar Premio Final")
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .cornerRadius(16)
                            .shadow(color: Color.green.opacity(0.3), radius: 6, y: 3)
                        }
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .accessibilityLabel(indicePreguntaActual + 1 < preguntasPartida.count ? "Avanzar a la siguiente pregunta" : "Reclamar premio final y terminar el quiz")
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Quiz Verde 🌳")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if preguntasPartida.isEmpty {
                preguntasPartida = bancoPreguntas.shuffled()
                anunciarPreguntaActual()
            }
        }
        .alert("¡Quiz Completado! 🎉", isPresented: $mostrarAlertaPremioFinal) {
            Button("¡Genial!") {
                dismiss()
            }
        } message: {
            Text("¡Demostraste saber mucho sobre los árboles!\n\nTu recompensa ganada es:\n\(premioObtenidoTexto)\n\nSe ha guardado en tu mochila.")
        }
    }

    // MARK: - Lógica de Juego y Anuncios de Voz

    private func estadoDeBoton(para indice: Int, pregunta: PreguntaQuiz) -> EstadoBotonQuiz {
        if respuestaAcertada && indice == pregunta.indiceCorrecto {
            return .correcto
        } else if indicesFallados.contains(indice) {
            return .incorrectoReintentar
        } else {
            return .normal
        }
    }

    private func verificarRespuesta(indiceSeleccionado: Int, pregunta: PreguntaQuiz) {
        if indiceSeleccionado == pregunta.indiceCorrecto {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                respuestaAcertada = true
            }
            mensajeMotivacional = pregunta.explicacion
            exitoHaptico.notificationOccurred(.success)

            // Anuncio para VoiceOver
            UIAccessibility.post(
                notification: .announcement,
                argument: "¡Correcto! \(pregunta.explicacion)"
            )
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                _ = indicesFallados.insert(indiceSeleccionado)
            }
            let frasesAnimo = [
                "¡Casi! Prueba con otra opción 🌱",
                "¡No te rindas! Inténtalo otra vez ✨",
                "Esa no era, ¡pero estás muy cerca! 🔍",
                "¡Buen intento! Piensa en cómo viven los árboles 🌳"
            ]
            let mensaje = frasesAnimo.randomElement() ?? "¡Sigue intentando!"
            mensajeMotivacional = mensaje
            alertaHaptica.notificationOccurred(.warning)

            // Anuncio para VoiceOver
            UIAccessibility.post(
                notification: .announcement,
                argument: "Incorrecto. \(mensaje)"
            )
        }
    }

    private func siguientePregunta() {
        seleccionHaptica.selectionChanged()
        
        if indicePreguntaActual + 1 < preguntasPartida.count {
            withAnimation {
                indicePreguntaActual += 1
                indicesFallados.removeAll()
                respuestaAcertada = false
                mensajeMotivacional = "¡Vamos por otra! Elige tu respuesta 👇"
            }
            anunciarPreguntaActual()
        } else {
            let premio = gameManager.agregarRecursoAleatorio()
            premioObtenidoTexto = "\(premio.icono) +1 \(premio.nombre)"
            mostrarAlertaPremioFinal = true
            exitoHaptico.notificationOccurred(.success)

            UIAccessibility.post(
                notification: .announcement,
                argument: "¡Felicidades! Completaste el quiz. Ganaste una recompensa de \(premio.nombre) para tu mochila."
            )
        }
    }

    private func anunciarPreguntaActual() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let p = preguntaActual {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "Pregunta \(indicePreguntaActual + 1): \(p.texto)"
                )
            }
        }
    }
}

// MARK: - Estado y Botón de Opción con Accesibilidad
enum EstadoBotonQuiz {
    case normal
    case correcto
    case incorrectoReintentar
}

struct BotonOpcionQuiz: View {
    let texto: String
    let numeroOpcion: Int
    let estadoBoton: EstadoBotonQuiz
    let alPresionar: () -> Void

    var body: some View {
        Button(action: alPresionar) {
            HStack {
                Text(texto)
                    .font(.body.bold())
                    .foregroundColor(colorTexto)

                Spacer()

                if estadoBoton == .correcto {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if estadoBoton == .incorrectoReintentar {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(colorFondo)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorBorde, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .scaleEffect(estadoBoton == .correcto ? 1.02 : 1.0)
        // Soporte integral de VoiceOver
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Opción \(numeroOpcion): \(texto)")
        .accessibilityValue(valorAccesibilidad)
        .accessibilityHint(pistaAccesibilidad)
    }

    private var valorAccesibilidad: String {
        switch estadoBoton {
        case .normal: return ""
        case .correcto: return "Respuesta correcta seleccionada"
        case .incorrectoReintentar: return "Opción incorrecta ya intentada"
        }
    }

    private var pistaAccesibilidad: String {
        switch estadoBoton {
        case .normal: return "Toca dos veces para elegir esta opción."
        case .correcto: return "Acierto. Pulsa siguiente pregunta abajo."
        case .incorrectoReintentar: return "No disponible. Ya intentaste esta opción."
        }
    }

    private var colorFondo: Color {
        switch estadoBoton {
        case .normal: return Color(.secondarySystemGroupedBackground)
        case .correcto: return Color.green.opacity(0.18)
        case .incorrectoReintentar: return Color.orange.opacity(0.12)
        }
    }

    private var colorBorde: Color {
        switch estadoBoton {
        case .normal: return Color.clear
        case .correcto: return Color.green
        case .incorrectoReintentar: return Color.orange.opacity(0.5)
        }
    }

    private var colorTexto: Color {
        switch estadoBoton {
        case .normal: return .primary
        case .correcto: return .green
        case .incorrectoReintentar: return .secondary
        }
    }
}

// MARK: - Chip Contador de Recurso con Accesibilidad
struct RecursoBadge: View {
    let icono: String
    let valor: Int
    var recursoNombre: String = "Recurso"

    var body: some View {
        HStack(spacing: 4) {
            Text(icono)
            Text("\(valor)")
                .font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recursoNombre) en mochila: \(valor)")
    }
}

#Preview {
    NavigationStack {
        QuizVerdeView()
            .environmentObject(GameManager())
    }
}
