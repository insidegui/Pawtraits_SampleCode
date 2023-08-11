//
//  ModalLoadingView.swift
//  Pawtraits
//
//  Created by Guilherme Rambo on 03/08/23.
//

import SwiftUI

struct ModalLoadingView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(Material.thin)
            ProgressView()
        }
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 10)
        .transition(.scale(scale: 0.2).combined(with: .opacity))
    }
}

#Preview {
    ZStack {
        Rectangle()
            .fill(Color.indigo)
            .ignoresSafeArea()
            .overlay {
                ModalLoadingView()
            }
    }
}
