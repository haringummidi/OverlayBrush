import SwiftUI

struct ShareImageView: NSViewControllerRepresentable {
    let image: NSImage
    @Binding var isPresented: Bool

    func makeNSViewController(context: Context) -> NSViewController {
        let controller = NSViewController()
        DispatchQueue.main.async {
            let picker = NSSharingServicePicker(items: [image])
            picker.delegate = context.coordinator
            picker.show(relativeTo: .zero, of: controller.view, preferredEdge: .minY)
        }
        return controller
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, NSSharingServicePickerDelegate {
        let parent: ShareImageView
        init(parent: ShareImageView) { self.parent = parent }
        func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
            let parent = self.parent
            DispatchQueue.main.async {
                parent.isPresented = false
            }
        }
    }
}
