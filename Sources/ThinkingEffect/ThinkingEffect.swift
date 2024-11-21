import Foundation
import SwiftUI

struct ThinkingEffectModifier: ViewModifier {
    @State private var maskTimer: Float
    @State private var gradientSpeed: Float
    @Binding var isThinking: Bool
    @State private var expansion: CGFloat = 0.5
    let cornerRadius: CGFloat
    
    @State private var phase: CGFloat = 0.0 // State variable to animate the phase of the wave
    @State private var lineWidth: CGFloat = 20.0 // State variable to animate the line width
    
    init(maskTimer: Float = 0.0, gradientSpeed: Float = 0.0000005, isThinking: Binding<Bool>, cornerRadius: CGFloat) {
        self.maskTimer = maskTimer
        self.gradientSpeed = gradientSpeed
        self._isThinking = isThinking
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        ZStack {
            if isThinking {
                content
                    .overlay {
                        ZStack {
                            glow(
                                amplitude: 6.0,
                                frequency: 2.0,
                                phase: phase,
                                color: .red,
                                clocwise: true, cornerRadius: cornerRadius
                            ).zIndex(10)
                            glow(
                                amplitude: 7.0,
                                frequency: 1.0,
                                phase: phase + 0.5,
                                color: .red,
                                clocwise: true,
                                cornerRadius: cornerRadius
                            ).zIndex(10)
                        }.allowsHitTesting(false)
                    }
                    .onAppear {
                        // Use a timer to continuously update the phase, creating an animation effect
                        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
                            DispatchQueue.main.async {
                                phase += 0.1
                            }
                        }
                    }
            } else {
                content
                    
            }
        }.animation(.default, value: isThinking)
    }
    
    @ViewBuilder
    func glow(amplitude: CGFloat, frequency: CGFloat, phase: CGFloat, color: Color, clocwise: Bool, cornerRadius: CGFloat) -> some View {
        GeometryReader { geometry in
            ZStack {
                MeshGradientView(
                    maskTimer: $maskTimer,
                    gradientSpeed: $gradientSpeed
                )
                .clipShape(
                    VariableWidthRoundedRectangle(
                        cornerRadius: 10,
                        lineWidths: [0, 0, 0, 0, 0]
                    )
                ).clipShape(RoundedRectangle(cornerRadius: 0))
                    .blur(radius: 2, opaque: false)
                    .foregroundColor(color)
                    .mask(
                        ContinuousWavyRoundedRectangle(
                            cornerRadius: cornerRadius, amplitude: amplitude,
                            frequency: frequency,
                            phase: phase,
                            clockwise: clocwise
                        )
                        .stroke(lineWidth: amplitude * 3)
                        .padding(1)
                    )
            }
            .blur(radius: 10)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                expansion = 20 // Controls how much the shape distorts
            }
        }
    }
    
    private struct MeshGradientView: View {
        @Binding var maskTimer: Float
        @Binding var gradientSpeed: Float
        
        var body: some View {
            MeshGradient(width: 3, height: 3, points: [
                .init(0, 0), .init(0.0, 0), .init(1, 0),
                
                [sinInRange(-0.8...(-0.2), offset: 0.439, timeScale: 0.342, t: maskTimer), sinInRange(0.3...0.7, offset: 3.42, timeScale: 0.984, t: maskTimer)],
                [sinInRange(0.1...0.8, offset: 0.239, timeScale: 0.084, t: maskTimer), sinInRange(0.2...0.8, offset: 5.21, timeScale: 0.242, t: maskTimer)],
                [sinInRange(1.0...1.5, offset: 0.939, timeScale: 0.084, t: maskTimer), sinInRange(0.4...0.8, offset: 0.25, timeScale: 0.642, t: maskTimer)],
                [sinInRange(-0.8...0.0, offset: 1.439, timeScale: 0.442, t: maskTimer), sinInRange(1.4...1.9, offset: 3.42, timeScale: 0.984, t: maskTimer)],
                [sinInRange(0.3...0.6, offset: 0.339, timeScale: 0.784, t: maskTimer), sinInRange(1.0...1.2, offset: 1.22, timeScale: 0.772, t: maskTimer)],
                [sinInRange(1.0...1.5, offset: 0.939, timeScale: 0.056, t: maskTimer), sinInRange(1.3...1.7, offset: 0.47, timeScale: 0.342, t: maskTimer)]
            ], colors: [
                .yellow, .purple, .indigo,
                .orange, .red, .blue,
                .indigo, .green, .mint
            ])
            .onAppear {
                Timer
                    .scheduledTimer(
                        withTimeInterval: TimeInterval(gradientSpeed),
                        repeats: true
                    ) { _ in
                    DispatchQueue.main.async {
                        maskTimer += gradientSpeed
                    }
                }
            }
            .ignoresSafeArea()
        }
        
        private func sinInRange(_ range: ClosedRange<Float>, offset: Float, timeScale: Float, t: Float) -> Float {
            let amplitude = (range.upperBound - range.lowerBound) / 2
            let midPoint = (range.upperBound + range.lowerBound) / 2
            return midPoint + amplitude * sin(timeScale * t + offset)
        }
    }
    
    private var computedScale: CGFloat {
        isThinking ? 1.2 : 1
    }
    
    private var animatedMaskBlur: CGFloat {
        isThinking ? 8 : 28
    }
}

struct RippleEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    public func thinkingEffect() -> some View {
        self.modifier(
            ThinkingEffectModifier(isThinking: .constant(true), cornerRadius: 0)
        )
    }
    
    public func thinkingEffect(enabled: Binding<Bool>) -> some View {
        self.modifier(
            ThinkingEffectModifier(isThinking: enabled, cornerRadius: 0)
        )
    }
    
    func rippleEffect() -> some View {
        self.modifier(RippleEffectModifier())
    }
}


fileprivate struct SampleView: View {
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Hello, World!")
                    .padding()
                    .frame(width: 200, height: 200)
            }
            
        }
        .thinkingEffect()
        .background(Color.black)
    }
}


#Preview {
    SampleView()
}

import SwiftUI

struct VariableWidthRoundedRectangle: Shape {
    var cornerRadius: CGFloat
    var lineWidths: [CGFloat]
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        }
    }
    
    func strokedPath(in rect: CGRect) -> Path {
        var path = Path()
        let roundedPath = self.path(in: rect)
        let length = roundedPath.length
        let segmentCount = lineWidths.count
        let segmentLength = length / CGFloat(segmentCount)
        
        for (index, lineWidth) in lineWidths.enumerated() {
            let start = CGFloat(index) * segmentLength / length
            let end = CGFloat(index + 1) * segmentLength / length
            
            let segment = roundedPath.trimmedPath(from: start, to: end)
            path.addPath(segment.strokedPath(StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)))
        }
        return path
    }
    
    func stroked(in rect: CGRect) -> some View {
        GeometryReader { geometry in
            self.strokedPath(in: rect)
                .fill(Color.primary) // Adjust to your color
        }
    }
}

extension Path {
    var length: CGFloat {
        var totalLength: CGFloat = 0
        var lastPoint: CGPoint?
        
        self.forEach { element in
            switch element {
                case .move(let to):
                    lastPoint = to
                case .line(let to):
                    if let last = lastPoint {
                        totalLength += last.distance(to: to)
                    }
                    lastPoint = to
                case .quadCurve(let to, _), .curve(let to, _, _):
                    if let last = lastPoint {
                        totalLength += last.distance(to: to)
                    }
                    lastPoint = to
                case .closeSubpath:
                    break
            }
        }
        return totalLength
    }
    
    func trimmedPath(from start: CGFloat, to end: CGFloat) -> Path {
        var newPath = Path()
        var totalLength: CGFloat = 0
        var lastPoint: CGPoint?
        
        self.forEach { element in
            guard end > start else { return }
            switch element {
                case .move(let to):
                    lastPoint = to
                    if start == 0 {
                        newPath.move(to: to)
                    }
                case .line(let to):
                    if let last = lastPoint {
                        let segmentLength = last.distance(to: to)
                        if totalLength >= start, totalLength + segmentLength <= end {
                            newPath.addLine(to: to)
                        } else if totalLength + segmentLength > start {
                            let partialStart = max(start - totalLength, 0)
                            let partialEnd = min(end - totalLength, segmentLength)
                            let fractionStart = partialStart / segmentLength
                            let fractionEnd = partialEnd / segmentLength
                            
                            let interpolatedStart = CGPoint.interpolate(from: last, to: to, fraction: fractionStart)
                            let interpolatedEnd = CGPoint.interpolate(from: last, to: to, fraction: fractionEnd)
                            
                            newPath.move(to: interpolatedStart)
                            newPath.addLine(to: interpolatedEnd)
                        }
                        totalLength += segmentLength
                    }
                    lastPoint = to
                case .quadCurve(let to, let control):
                    // Similar logic for quad curves
                    lastPoint = to
                case .curve(let to, let control1, let control2):
                    lastPoint = to
                case .closeSubpath:
                    newPath.closeSubpath()
            }
        }
        return newPath
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        sqrt(pow(self.x - point.x, 2) + pow(self.y - point.y, 2))
    }
    
    static func interpolate(from: CGPoint, to: CGPoint, fraction: CGFloat) -> CGPoint {
        CGPoint(
            x: from.x + (to.x - from.x) * fraction,
            y: from.y + (to.y - from.y) * fraction
        )
    }
}

struct ContinuousWavyRoundedRectangle: Shape {
    var cornerRadius: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat
    var clockwise: Bool = true
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Adjust frequency to maintain uniformity across the perimeter
        let perimeter = 2 * (rect.width + rect.height - 4 * cornerRadius) + 2 * .pi * cornerRadius * (
            clockwise
            ? 1 : -1)
        let adjustedFrequency = frequency / perimeter
        
        // Helper to calculate wave points for edges
        func wavyEdge(from start: CGPoint, to end: CGPoint, length: CGFloat, initialPhase: CGFloat, isVertical: Bool) -> Path {
            var wavePath = Path()
            wavePath.move(to: start)
            
            let steps = Int(length)
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let relativePhase = initialPhase + t * (length * adjustedFrequency * .pi * 2)
                let wave = amplitude * sin(relativePhase)
                
                let x = isVertical ? start.x + wave : start.x + t * (end.x - start.x)
                let y = isVertical ? start.y + t * (end.y - start.y) : start.y + wave
                
                wavePath.addLine(to: CGPoint(x: x, y: y))
            }
            
            return wavePath
        }
        
        // Helper to calculate wave points for corners
        func wavyCorner(center: CGPoint, radius: CGFloat, startAngle: Angle, endAngle: Angle, initialPhase: CGFloat) -> Path {
            var cornerPath = Path()
            let angleRange = endAngle - startAngle
            let arcLength = abs(angleRange.radians * radius)
            let steps = Int(arcLength)
            
            for i in 0...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let angle = startAngle.radians + t * angleRange.radians
                let relativePhase = initialPhase + t * (arcLength * adjustedFrequency * .pi * 2)
                let wave = amplitude * sin(relativePhase)
                
                let x = center.x + (radius + wave) * cos(angle)
                let y = center.y + (radius + wave) * sin(angle)
                
                if i == 0 {
                    cornerPath.move(to: CGPoint(x: x, y: y))
                } else {
                    cornerPath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            return cornerPath
        }
        
        var currentPhase: CGFloat = phase
        
        // Top-left corner
        path.addPath(wavyCorner(center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
                                radius: cornerRadius,
                                startAngle: .degrees(180),
                                endAngle: .degrees(270),
                                initialPhase: currentPhase))
        currentPhase += cornerRadius * .pi * adjustedFrequency * 2
        
        // Top edge
        let topLeft = CGPoint(x: rect.minX + cornerRadius, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX - cornerRadius, y: rect.minY)
        let topLength = rect.width - 2 * cornerRadius
        path.addPath(wavyEdge(from: topLeft, to: topRight, length: topLength, initialPhase: currentPhase + 3.2, isVertical: false))
        currentPhase += topLength * adjustedFrequency * .pi * 2
        
        // Top-right corner
        path.addPath(wavyCorner(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
                                radius: cornerRadius,
                                startAngle: .degrees(270),
                                endAngle: .degrees(360),
                                initialPhase: currentPhase))
        currentPhase += cornerRadius * .pi * adjustedFrequency * 2
        
        // Right edge
        let rightTop = CGPoint(x: rect.maxX, y: rect.minY + cornerRadius)
        let rightBottom = CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius)
        let rightLength = rect.height - 2 * cornerRadius
        path.addPath(wavyEdge(from: rightTop, to: rightBottom, length: rightLength, initialPhase: currentPhase, isVertical: true))
        currentPhase += rightLength * adjustedFrequency * .pi * 2
        
        // Bottom-right corner
        path.addPath(wavyCorner(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
                                radius: cornerRadius,
                                startAngle: .degrees(0),
                                endAngle: .degrees(90),
                                initialPhase: currentPhase))
        currentPhase += cornerRadius * .pi * adjustedFrequency * 2
        
        // Bottom edge
        let bottomRight = CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX + cornerRadius, y: rect.maxY)
        let bottomLength = rect.width - 2 * cornerRadius
        path.addPath(wavyEdge(from: bottomRight, to: bottomLeft, length: bottomLength, initialPhase: currentPhase, isVertical: false))
        currentPhase += bottomLength * adjustedFrequency * .pi * 2
        
        // Bottom-left corner
        path.addPath(wavyCorner(center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
                                radius: cornerRadius,
                                startAngle: .degrees(90),
                                endAngle: .degrees(180),
                                initialPhase: currentPhase))
        currentPhase += cornerRadius * .pi * adjustedFrequency * 2
        
        // Left edge
        let leftBottom = CGPoint(x: rect.minX, y: rect.maxY - cornerRadius)
        let leftTop = CGPoint(x: rect.minX, y: rect.minY + cornerRadius)
        let leftLength = rect.height - 2 * cornerRadius
        path.addPath(wavyEdge(from: leftBottom, to: leftTop, length: leftLength, initialPhase: currentPhase + 3.8, isVertical: true))
        currentPhase += leftLength * adjustedFrequency * .pi * 2
        
        path.closeSubpath()
        
        return path
    }
}
