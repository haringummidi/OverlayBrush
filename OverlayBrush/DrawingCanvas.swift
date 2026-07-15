import SwiftUI
struct MouseTracker: NSViewRepresentable {
    var onMove: (CGPoint) -> Void
    var onHover: (Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onMove: onMove, onHover: onHover)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let trackingArea = NSTrackingArea(
            rect: .zero,
            options: [.activeAlways, .inVisibleRect, .mouseMoved, .mouseEnteredAndExited],
            owner: context.coordinator,
            userInfo: nil
        )
        view.addTrackingArea(trackingArea)
        context.coordinator.nsView = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
    // --- MouseTracker Helper ---
    class Coordinator: NSObject {
        var onMove: ((CGPoint) -> Void)
        var onHover: ((Bool) -> Void)
        weak var nsView: NSView?

        init(onMove: @escaping (CGPoint) -> Void, onHover: @escaping (Bool) -> Void) {
            self.onMove = onMove
            self.onHover = onHover
        }

        @objc func mouseMoved(_ event: NSEvent) {
            guard let nsView = nsView else { return }
            let windowLocation = event.locationInWindow
            DispatchQueue.main.async {
                let localLocation = nsView.convert(windowLocation, from: nil)
                self.onMove(localLocation)
            }
        }
        @objc func mouseEntered(_ event: NSEvent) {
            DispatchQueue.main.async {
                self.onHover(true)
            }
        }
        @objc func mouseExited(_ event: NSEvent) {
            DispatchQueue.main.async {
                self.onHover(false)
            }
        }
    }

}




struct DrawingCanvas: View {
    @State private var strokes: [Stroke] = []
    @State private var currentStroke = Stroke(points: [], color: .red, lineWidth: 3, tool: .pen)
    @State private var selectedColor: Color = .red
    @State private var selectedStrokeSize: StrokeSize = .light
    @State private var selectedTool: SideToolbar.Tool = .pen
    @State private var dragStart: CGPoint? = nil

    // --- For cursor and indicator ---
    @State private var cursorPosition: CGPoint = .zero
    @State private var isHovering: Bool = false

    // --- For draggable toolbar ---
    // Restore initial toolbar position to previous layout (top trailing)
    @State private var toolbarPosition: CGPoint = CGPoint(x: 1000, y: 500)
    @State private var toolbarDragOffset: CGSize = .zero

    @EnvironmentObject var drawingModeState: DrawingModeState
    var drawingMode: Bool { drawingModeState.drawingMode }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                // Drawing area
                Canvas { context, size in
                    // Draw finished strokes
                    for stroke in strokes {
                        if stroke.points.count == 2 {
                            if stroke.tool == .arrow {
                                drawArrow(context: &context, from: stroke.points[0], to: stroke.points[1], color: stroke.color, lineWidth: stroke.lineWidth)
                            } else if stroke.tool == .rectangle {
                                let rect = CGRect(
                                    origin: stroke.points[0],
                                    size: CGSize(
                                        width: stroke.points[1].x - stroke.points[0].x,
                                        height: stroke.points[1].y - stroke.points[0].y
                                    )
                                )
                                context.stroke(Path(rect), with: .color(stroke.color), lineWidth: stroke.lineWidth)
                            } else if stroke.tool == .circle {
                                let rect = CGRect(
                                    x: min(stroke.points[0].x, stroke.points[1].x),
                                    y: min(stroke.points[0].y, stroke.points[1].y),
                                    width: abs(stroke.points[1].x - stroke.points[0].x),
                                    height: abs(stroke.points[1].y - stroke.points[0].y)
                                )
                                context.stroke(Path(ellipseIn: rect), with: .color(stroke.color), lineWidth: stroke.lineWidth)
                            }
                        } else {
                            // Draw freehand
                            var path = Path()
                            if let first = stroke.points.first {
                                path.move(to: first)
                                for pt in stroke.points.dropFirst() {
                                    path.addLine(to: pt)
                                }
                                context.stroke(path, with: .color(stroke.color), lineWidth: stroke.lineWidth)
                            }
                        }
                    }

                    // Draw current (unfinished) shape
                    if currentStroke.points.count == 2 {
                        if selectedTool == .arrow {
                            drawArrow(context: &context, from: currentStroke.points[0], to: currentStroke.points[1], color: currentStroke.color, lineWidth: currentStroke.lineWidth)
                        } else if selectedTool == .rectangle {
                            let rect = CGRect(
                                origin: currentStroke.points[0],
                                size: CGSize(
                                    width: currentStroke.points[1].x - currentStroke.points[0].x,
                                    height: currentStroke.points[1].y - currentStroke.points[0].y
                                )
                            )
                            context.stroke(Path(rect), with: .color(currentStroke.color), lineWidth: currentStroke.lineWidth)
                        } else if selectedTool == .circle {
                            let rect = CGRect(
                                x: min(currentStroke.points[0].x, currentStroke.points[1].x),
                                y: min(currentStroke.points[0].y, currentStroke.points[1].y),
                                width: abs(currentStroke.points[1].x - currentStroke.points[0].x),
                                height: abs(currentStroke.points[1].y - currentStroke.points[0].y)
                            )
                            context.stroke(Path(ellipseIn: rect), with: .color(currentStroke.color), lineWidth: currentStroke.lineWidth)
                        }
                    } else if let first = currentStroke.points.first, selectedTool == .pen {
                        var path = Path()
                        path.move(to: first)
                        for pt in currentStroke.points.dropFirst() {
                            path.addLine(to: pt)
                        }
                        context.stroke(path, with: .color(currentStroke.color), lineWidth: currentStroke.lineWidth)
                    }
                }
                .background(Color.clear)
                .ignoresSafeArea()
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let localPoint = value.location
                            cursorPosition = localPoint
                            switch selectedTool {
                            case .pen:
                                if currentStroke.points.isEmpty {
                                    currentStroke = Stroke(points: [localPoint], color: selectedColor, lineWidth: selectedStrokeSize.rawValue, tool: selectedTool)
                                } else {
                                    currentStroke.points.append(localPoint)
                                }
                            case .arrow, .rectangle, .circle:
                                if dragStart == nil {
                                    dragStart = value.startLocation
                                }
                                currentStroke = Stroke(points: [dragStart!, localPoint], color: selectedColor, lineWidth: selectedStrokeSize.rawValue, tool: selectedTool)
                            default:
                                break
                            }
                        }
                        .onEnded { value in
                            switch selectedTool {
                            case .pen:
                                if !currentStroke.points.isEmpty {
                                    strokes.append(currentStroke)
                                    currentStroke = Stroke(points: [], color: selectedColor, lineWidth: selectedStrokeSize.rawValue, tool: selectedTool)
                                }
                            case .arrow, .rectangle, .circle:
                                if dragStart != nil {
                                    strokes.append(currentStroke)
                                    currentStroke = Stroke(points: [], color: selectedColor, lineWidth: selectedStrokeSize.rawValue, tool: selectedTool)
                                    dragStart = nil
                                }
                            default:
                                break
                            }
                        }
                )

                // MouseTracker overlay (tracks mouse at all times)
                MouseTracker(
                    onMove: { point in
                        let flippedY = geo.size.height - point.y
                        cursorPosition = CGPoint(x: point.x, y: flippedY)
                    },
                    onHover: { hovering in
                        isHovering = hovering
                        if drawingMode && hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                )


                .allowsHitTesting(false) // So it doesn't block drawing

                // Color circle follows cursor when hovering & in drawing mode
                if isHovering && drawingMode {
                    Circle()
                        .stroke(selectedColor.opacity(0.7), lineWidth: 2)
                        .background(Circle().fill(selectedColor.opacity(0.18)))
                        .frame(width: CGFloat(selectedStrokeSize.rawValue) * 2.2, height: CGFloat(selectedStrokeSize.rawValue) * 2.2)
                        .position(cursorPosition)
                        .allowsHitTesting(false)
                }


                // Freely movable SideToolbar
                SideToolbar(selectedTool: $selectedTool, selectedColor: $selectedColor, selectedStrokeSize: $selectedStrokeSize)
                    .background(Color.clear)
                    .position(x: toolbarPosition.x + toolbarDragOffset.width, y: toolbarPosition.y + toolbarDragOffset.height)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                toolbarDragOffset = value.translation
                            }
                            .onEnded { value in
                                toolbarPosition.x += value.translation.width
                                toolbarPosition.y += value.translation.height
                                toolbarDragOffset = .zero
                            }
                    )
            }
            .onReceive(NotificationCenter.default.publisher(for: .undoStroke)) { _ in
                if !strokes.isEmpty { strokes.removeLast() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .clearAllStrokes)) { _ in
                strokes.removeAll()
            }
        }
    }

    func drawArrow(context: inout GraphicsContext, from: CGPoint, to: CGPoint, color: Color, lineWidth: CGFloat) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)

        // Arrowhead
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLength: CGFloat = 12 + lineWidth * 2
        let arrowAngle: CGFloat = .pi / 8

        let tip1 = CGPoint(
            x: to.x - arrowLength * cos(angle - arrowAngle),
            y: to.y - arrowLength * sin(angle - arrowAngle)
        )
        let tip2 = CGPoint(
            x: to.x - arrowLength * cos(angle + arrowAngle),
            y: to.y - arrowLength * sin(angle + arrowAngle)
        )

        path.move(to: to)
        path.addLine(to: tip1)
        path.move(to: to)
        path.addLine(to: tip2)

        context.stroke(path, with: .color(color), lineWidth: lineWidth)
    }
}
