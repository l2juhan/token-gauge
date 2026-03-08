import SwiftUI

struct ClaudeIconView: View {
    var size: CGFloat = 24

    var body: some View {
        Image("ClaudeLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }
}
