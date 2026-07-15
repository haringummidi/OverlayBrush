import SwiftUI

struct SystemColorPicker: View {
    @Binding var selectedColor: Color

    var body: some View {
        VStack(spacing: 16) {
            Text("Select a Color")
                .font(.headline)
                .foregroundColor(.primary)

            ColorPicker("", selection: $selectedColor)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .padding()

            Text("Selected Color")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Circle()
                .fill(selectedColor)
                .frame(width: 50, height: 50)
        }
    }
}
