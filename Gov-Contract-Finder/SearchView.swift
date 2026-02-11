//
//  SearchView.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 2/5/26.
//

import SwiftUI
import OSLog

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    private let logger = Logger(subsystem: "Gov-Contract-Finder", category: "SearchView")
    @State private var debugSettings = DebugSettings.shared
    @State private var isDebugPresented = false
    @State private var themeController = ThemeController()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                SearchFiltersView(viewModel: viewModel)

                if viewModel.isLoading {
                    ProgressView("Loading opportunities...")
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let error = viewModel.error {
                    Text(error)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if viewModel.hasResults {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.opportunities) { opportunity in
                                NavigationLink {
                                    OpportunityDetailView(opportunity: opportunity)
                                } label: {
                                    OpportunityCardView(opportunity: opportunity)
                                }
                                .buttonStyle(.plain)
                            }

                            if viewModel.canLoadMore {
                                if viewModel.isLoadingMore {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .frame(maxWidth: .infinity)
                                        .padding(.top, 8)
                                } else {
                                    Color.clear
                                        .frame(height: 1)
                                        .onAppear {
                                            Task { await viewModel.loadMore() }
                                        }
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                } else {
                    Text("Search for contracts to get started.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("Gov Contract Finder")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Debug") {
                        isDebugPresented = true
                    }
                }
            }
            .onAppear {
                if debugSettings.isEnabled {
                    logger.debug("SearchView appeared")
                }
            }
            .sheet(isPresented: $isDebugPresented) {
                DebugPanelView(settings: debugSettings)
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    themeController.toggle()
                } label: {
                    Image(systemName: themeController.colorScheme == .dark ? "sun.max.fill" : themeController.colorScheme == .light ? "circle.lefthalf.filled" : "moon.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding()
            }
            .preferredColorScheme(themeController.colorScheme)
        }
    }
}

#Preview {
    SearchView()
}
