
import SwiftUI

struct HUDView: View {
    let message: String
    let type: HUD.State.FeedbackType
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(iconColor)
            
            Text(message)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(iconColor.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private var iconName: String {
        switch type {
        case .success: return "checkmark.shield.fill"
        case .error: return "exclamationmark.shield.fill"
        case .neutral: return "shield.fill"
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .success: return Color.blue // Story 1.5 decision: Use Blue for both Success cases
        case .error: return Color.red
        case .neutral: return Color.gray
        }
    }
}

#Preview {
    HUDView(message: "Secured", type: .success)
        .padding()
}
