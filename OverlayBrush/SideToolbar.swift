import SwiftUI

struct SideToolbar: View {
    enum Tool: String {
        case pen, arrow, rectangle, text, circle, ellipse, redo, play, clock, hand, copy, scissors
    }
    @Binding var selectedTool: Tool
    @Binding var selectedColor: Color // <-- Add this binding for the current color
    @Binding var selectedStrokeSize: StrokeSize

    // Sizes for compact toolbar
    private let brushButtonSize: CGFloat = 26
    private let buttonSize: CGFloat = 16
    private let smallButtonSize: CGFloat = 8
    private let toolbarWidth: CGFloat = 38

    var body: some View {
        VStack(spacing: 22) {
            // Top Row: Close and More
            HStack(spacing: 17) {
                CircleIconButton(systemName: "xmark", iconSize: smallButtonSize, action: {
                    NSApplication.shared.terminate(nil)
                })
                CircleIconButton(systemName: "ellipsis", iconSize: smallButtonSize, action: { /* more/menu action */ })
            }
            .padding(.top, 4)
            .padding(.bottom, 3)

            // Main Tools
            ToolbarButton(
                systemName: "scribble",
                isActive: selectedTool == .pen,
                action: { selectedTool = .pen },
                buttonSize: brushButtonSize
            )
            ToolbarButton(
                systemName: "arrow.up.right",
                isActive: selectedTool == .arrow,
                action: { selectedTool = .arrow },
                buttonSize: brushButtonSize
            )
            ToolbarButton(
                systemName: "rectangle",
                isActive: selectedTool == .rectangle,
                action: { selectedTool = .rectangle },
                buttonSize: brushButtonSize
            )
            ToolbarButton(
                systemName: "circle",
                isActive: selectedTool == .circle,
                action: { selectedTool = .circle },
                buttonSize: brushButtonSize
            )
            ToolbarButton(
                text: "Aa",
                isActive: selectedTool == .text,
                action: { selectedTool = .text },
                buttonSize: brushButtonSize
            )

            // Divider
            Divider().frame(width: toolbarWidth - 4).background(Color.gray.opacity(0.16))

            // TODO
            // Need to implement stroke size
            StrokeSizeSelector(selectedStrokeSize: $selectedStrokeSize)


            // Divider
            Divider().frame(width: toolbarWidth - 4).background(Color.gray.opacity(0.16))

            // Loop icon (arrow.2.circlepath) to clear the screen
            ToolbarButton(
                systemName: "arrow.2.circlepath",
                isActive: false, // Not a selectable tool, just an action
                action: {
                    NotificationCenter.default.post(name: .clearAllStrokes, object: nil)
                },
                buttonSize: buttonSize
            )

            // Color Picker Button with Popover
            ColorPickerToolbarButton(selectedColor: $selectedColor, selectedTool: $selectedTool, isActive: selectedTool == .play, action: { selectedTool = .play }, buttonSize: buttonSize)



            ToolbarButton(
                systemName: "clock",
                isActive: selectedTool == .clock,
                action: { selectedTool = .clock },
                buttonSize: buttonSize
            )

            // Spacer(minLength: 0) // Minimal spacer for bottom alignment

            // Bottom row: hand, copy, scissors (horizontal)
            HStack(spacing: 10) {
                BottomBarIconButton(systemName: "hand.raised", isActive: selectedTool == .hand, action: { selectedTool = .hand }, size: smallButtonSize)
                BottomBarIconButton(systemName: "doc.on.doc", isActive: selectedTool == .copy, action: { selectedTool = .copy }, size: smallButtonSize)
                BottomBarIconButton(systemName: "scissors", isActive: selectedTool == .scissors, action: { selectedTool = .scissors }, size: smallButtonSize)
            }
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 32/255, green: 36/255, blue: 48/255), Color.black]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.28), radius: 5, x: 0, y: 2)
        .frame(width: toolbarWidth)
    }
}

// MARK: - Main Toolbar Button (no lock logic)
struct ToolbarButton: View {
    var systemName: String? = nil
    var text: String? = nil
    var customIcon: (() -> AnyView)? = nil
    var isActive: Bool
    var action: () -> Void
    var iconColor: Color? = nil
    var buttonSize: CGFloat

    init(systemName: String, isActive: Bool, action: @escaping () -> Void, buttonSize: CGFloat = 22, iconColor: Color? = nil) {
        self.systemName = systemName
        self.isActive = isActive
        self.action = action
        self.iconColor = iconColor
        self.buttonSize = buttonSize
    }

    init(text: String, isActive: Bool, action: @escaping () -> Void, buttonSize: CGFloat = 22) {
        self.text = text
        self.isActive = isActive
        self.action = action
        self.buttonSize = buttonSize
    }

    init(customIcon: @escaping () -> some View, isActive: Bool, action: @escaping () -> Void, buttonSize: CGFloat = 22) {
        self.customIcon = { AnyView(customIcon()) }
        self.isActive = isActive
        self.action = action
        self.buttonSize = buttonSize
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if let customIcon = customIcon {
                    customIcon()
                } else if let systemName = systemName {
                    Image(systemName: systemName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: buttonSize, height: buttonSize)
                        .foregroundColor(iconColor ?? (isActive ? .blue : .white.opacity(0.84)))
                } else if let text = text {
                    Text(text)
                        .font(.system(size: buttonSize * 0.7, weight: .semibold))
                        .foregroundColor(isActive ? .blue : .white.opacity(0.84))
                        .frame(width: buttonSize, height: buttonSize)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Top Icon Button (Close/More)
struct CircleIconButton: View {
    var systemName: String
    var iconSize: CGFloat
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(.white)
                .padding(iconSize * 0.45)
                .background(Color.black.opacity(0.33))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Bottom Bar Icon Button
struct BottomBarIconButton: View {
    var systemName: String
    var isActive: Bool
    var action: () -> Void
    var size: CGFloat

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .resizable()
                .frame(width: size * 0.93, height: size * 0.93)
                .foregroundColor(isActive ? .blue : .white.opacity(0.82))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Color Picker Toolbar Button
struct ColorPickerToolbarButton: View {
    @Binding var selectedColor: Color
    @Binding var selectedTool: SideToolbar.Tool
    var isActive: Bool
    var action: () -> Void
    var buttonSize: CGFloat
    @State private var showPopover = false

    var body: some View {
        Button(action: {
            action()
            showPopover = true
        }) {
            Circle()
                .fill(selectedColor)
                .frame(width: buttonSize - 4, height: buttonSize - 4)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.7), lineWidth: isActive ? 2 : 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showPopover, arrowEdge: .trailing) {
            FancyColorPicker(selectedColor: $selectedColor, selectedTool: $selectedTool)
                .frame(width: 220, height: 180)
                .padding(8)
        }
    }
}

// MARK: - Fancy Color Picker
struct FancyColorPicker: View {
    @Binding var selectedColor: Color
    @Binding var selectedTool: SideToolbar.Tool
    let colors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown, .black, .gray, .white
    ]

    let columns = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("Pick a Color")
                .font(.headline)
                .foregroundColor(.primary)
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(colors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle().stroke(selectedColor == color ? Color.accentColor : Color.clear, lineWidth: 3)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                        .onTapGesture {
                            selectedColor = color
                            selectedTool = .pen
                        }
                }
            }
            .padding(.horizontal, 8)
            Spacer(minLength: 0)
            HStack {
                Text("Selected:")
                    .font(.subheadline)
                Circle()
                    .fill(selectedColor)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.secondary, lineWidth: 1))
            }
        }
        .padding(.top, 8)
    }
}

enum StrokeSize: CGFloat, CaseIterable {
    case ultraLight = 2
    case thin = 3.5
    case light = 5
    case medium = 7
    case semibold = 9
    case bold = 12

    var label: String {
        switch self {
        case .ultraLight: return "Ultralight"
        case .thin: return "Thin"
        case .light: return "Light"
        case .medium: return "Medium"
        case .semibold: return "Semibold"
        case .bold: return "Bold"
        }
    }
}
struct StrokeSizeSelector: View {
    @Binding var selectedStrokeSize: StrokeSize
    @State private var showPopover = false

    // The three visual levels to show as icons
    let previewSizes: [StrokeSize] = [.thin, .light, .bold]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(previewSizes, id: \.self) { size in
                Button(action: {
                    selectedStrokeSize = size
                }) {
                    Circle()
                        .stroke(selectedStrokeSize == size ? Color.blue : Color.white.opacity(0.7), lineWidth: 2.2)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(selectedStrokeSize == size ? 0.3 : 0.13))
                        )
                        .frame(width: size.rawValue * 2, height: size.rawValue * 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            // Popover for all options
            Button(action: { showPopover = true }) {
                Image(systemName: "chevron.down")
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.leading, 2)
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showPopover, arrowEdge: .trailing) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(StrokeSize.allCases, id: \.self) { size in
                        Button(action: {
                            selectedStrokeSize = size
                            showPopover = false
                        }) {
                            HStack {
                                Text(size.label)
                                if selectedStrokeSize == size {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(selectedStrokeSize == size ? Color.accentColor.opacity(0.17) : Color.clear)
                    }
                }
                .padding(.vertical, 6)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(8)
                .frame(width: 130)
            }
        }
        .padding(.vertical, 2)
    }
}
