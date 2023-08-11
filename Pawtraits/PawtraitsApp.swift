//
//  PawtraitsApp.swift
//  Pawtraits
//
//  Created by Guilherme Rambo on 31/07/23.
//

import SwiftUI

@main
struct PawtraitsApp: App {
    private var api = PawtraitsAPIClient()

    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.environment["PAWTRAITS_UIKIT"] == "1" {
                PawtraitsUIKitRootView(client: api)
                    .ignoresSafeArea()
            } else {
                RootView()
                    .environment(api)
            }
        }
    }
}
