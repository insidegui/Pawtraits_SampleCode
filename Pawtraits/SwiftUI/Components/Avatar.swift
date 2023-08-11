import SwiftUI

struct Avatar<ClipShape: InsettableShape>: View {
    var image: Image
    var size: CGFloat
    var shape: ClipShape

    init(image: Image, size: CGFloat, shape: ClipShape) {
        self.image = image
        self.size = size
        self.shape = shape
    }

    var body: some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(shape)
    }
}

extension Avatar where ClipShape == Circle {
    init(image: Image, size: CGFloat) {
        self.image = image
        self.size = size
        self.shape = Circle()
    }
}
