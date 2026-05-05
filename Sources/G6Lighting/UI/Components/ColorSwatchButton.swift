import SwiftUI

struct ColorSwatchButton: View {
    let color: RGBColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(color.swiftUIColor)
                    .frame(width: 26, height: 26)
                    .shadow(color: color.swiftUIColor.opacity(0.45), radius: 4, y: 1)
                if isSelected {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(.white, lineWidth: 2)
                        .frame(width: 26, height: 26)
                        .shadow(radius: 1)
                } else {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
                        .frame(width: 26, height: 26)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.0 : 0.96)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isSelected)
    }
}

extension RGBColor {
    var swiftUIColor: Color {
        Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }
}
