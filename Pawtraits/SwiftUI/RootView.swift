import SwiftUI

struct RootView: View {
    @Environment(PawtraitsAPIClient.self)
    private var api

    @State private var isLoading = true

    private var posts: [PawtraitsPost] {
        isLoading ? PawtraitsPost.placeholders : api.loadedPosts
    }

    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                LazyVStack(spacing: 32) {
                    ForEach(posts) { post in
                        DeferredNavigationLink(value: post, path: $navigationPath) { post in
                            try await api.fetchDetails(for: post)
                        } label: {
                            PostView(post: post)
                        }
                        .disabled(isLoading)
                    }
                }
            }
            .navigationTitle(Text("Pawtraits"))
            .navigationDestination(for: PawtraitsPost.self) { post in
                PostDetailsScreen(post: post)
            }
        }
        .task {
            try? await api.fetchPosts(page: 0)

            isLoading = false
        }
    }
}

#Preview("RootView") {
    RootView()
        .environment(PawtraitsAPIClient())
}
