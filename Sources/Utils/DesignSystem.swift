import SwiftUI

// MARK: - Design Tokens

extension Color {
    static let aiPrimary    = Color(red: 0.0, green: 0.83, blue: 1.0)     // #00D4FF
    static let aiSuccess    = Color(red: 0.2, green: 0.78, blue: 0.35)   // #34C759
    static let aiWarning    = Color(red: 1.0, green: 0.58, blue: 0.0)    // #FF9500
    static let aiError      = Color(red: 1.0, green: 0.29, blue: 0.25)   // #FF4B4B
    static let aiBg         = Color(red: 0.06, green: 0.06, blue: 0.06)  // #0F0F0F
    static let aiSurface    = Color(red: 0.1, green: 0.1, blue: 0.1)     // #1A1A1A
    static let aiBorder     = Color(red: 0.16, green: 0.16, blue: 0.16)  // #2A2A2A
}

extension EdgeInsets {
    static let cardPadding = EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
}

// MARK: - Preview Helpers

#if DEBUG
struct DesignSystemPreview: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                ForEach(["aiPrimary","aiSuccess","aiWarning","aiError","aiBg","aiSurface","aiBorder"], id: \.self) { name in
                    VStack {
                        Color(name == "aiPrimary" ? Color.aiPrimary :
                              name == "aiSuccess" ? Color.aiSuccess :
                              name == "aiWarning" ? Color.aiWarning :
                              name == "aiError" ? Color.aiError :
                              name == "aiBg" ? Color.aiBg :
                              name == "aiSurface" ? Color.aiSurface : Color.aiBorder)
                            .frame(width: 48, height: 48)
                            .cornerRadius(8)
                        Text(name.replacingOccurrences(of: "ai", with: ""))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.aiBg)
    }
}

#Preview {
    DesignSystemPreview()
}
#endif
