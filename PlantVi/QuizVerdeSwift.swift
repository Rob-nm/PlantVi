//
//  QuizVerdeSwift.swift
//  PlantVi
//
//  Created by Brandiuxx on 24/09/26.
//
//
//  QuizVerdeSwift.swift
//  PlantVi
//

import SwiftUI

//Modelo de Pregunta
struct PreguntaQuiz: Identifiable {
    let id = UUID()
    let texto: String
    let icono: String
    let opciones: [String]
    let indiceCorrecto: Int
    let explicacion: String
}
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
            opciones: ["Por las ramas", "Por las raíces", "Por las flores", "Por el tronco"],
            indiceCorrecto: 1,
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
                    HStack(spacing: 10) {
                        RecursoBadge(icono: "💧", valor: gameManager.inventarioAgua)
                        RecursoBadge(icono: "🌱", valor: gameManager.inventarioAbono)
                        RecursoBadge(icono: "🧴", valor: gameManager.inventarioSpray)

                        Spacer()

                        Text("Pregunta \(indicePreguntaActual + 1)/\(preguntasPartida.count)")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal)

                    VStack(spacing: 14) {
                        Text(pregunta.icono)
                            .font(.system(size: 60))

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

        
                    Text(mensajeMotivacional)
                        .font(.subheadline.bold())
                        .foregroundColor(respuestaAcertada ? .green : (indicesFallados.isEmpty ? .secondary : .orange))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .frame(height: 40)

                    VStack(spacing: 12) {
                        ForEach(0..<pregunta.opciones.count, id: \.self) { indice in
                            BotonOpcionQuiz(
                                texto: pregunta.opciones[indice],
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
            mensajeMotivacional = frasesAnimo.randomElement() ?? "¡Sigue intentando!"
        }
    }

    private func siguientePregunta() {
        if indicePreguntaActual + 1 < preguntasPartida.count {
            withAnimation {
                indicePreguntaActual += 1
                indicesFallados.removeAll()
                respuestaAcertada = false
                mensajeMotivacional = "¡Vamos por otra! Elige tu respuesta 👇"
            }
        } else {
            let premio = gameManager.agregarRecursoAleatorio()
            premioObtenidoTexto = "\(premio.icono) +1 \(premio.nombre)"
            mostrarAlertaPremioFinal = true
        }
    }
}

enum EstadoBotonQuiz {
    case normal
    case correcto
    case incorrectoReintentar
}

struct BotonOpcionQuiz: View {
    let texto: String
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

//Chip Contador de Recurso
struct RecursoBadge: View {
    let icono: String
    let valor: Int

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
    }
}

#Preview {
    NavigationStack {
        QuizVerdeView()
            .environmentObject(GameManager())
    }
}
