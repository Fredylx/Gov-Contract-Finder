//
//  SearchView.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 2/5/26.
//

import SwiftUI
import OSLog
import UIKit

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    private let logger = Logger(subsystem: "Gov-Contract-Finder", category: "SearchView")
    @State private var debugSettings = DebugSettings.shared
    @State private var isDebugPresented = false
    @State private var themeController = ThemeController()
    @State private var featureFlags = FeatureFlags.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                LuxuryBackground()

                VStack(spacing: DesignSystem.Spacing.l) {
                    header
                    SearchFiltersView(viewModel: viewModel)
                    statusSection
                    resultsSection
                }
                .frame(maxWidth: 360, alignment: .leading)
                .safeAreaPadding(.horizontal, 24)
                .safeAreaPadding(.top, 16)
                .safeAreaPadding(.bottom, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        let startX = value.startLocation.x
                        let endX = value.location.x
                        let screenWidth = UIScreen.main.bounds.width
                        let startedAtRightEdge = startX > screenWidth * 0.85
                        let swipedLeft = endX < screenWidth * 0.55
                        if startedAtRightEdge && swipedLeft {
                            isDebugPresented = true
                        }
                    }
            )
            .onAppear {
                if debugSettings.isEnabled {
                    logger.debug("SearchView appeared")
                }
            }
            .sheet(isPresented: $isDebugPresented) {
                DebugPanelView(settings: debugSettings)
            }
            .overlay(alignment: .bottomTrailing) {
                if featureFlags.darkModeToggleEnabled {
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
            }
            .preferredColorScheme(featureFlags.darkModeToggleEnabled ? themeController.colorScheme : nil)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Gov Contract Finder")
                .font(DesignSystem.Typography.titleXL)
                .foregroundStyle(DesignSystem.Colors.primaryText)
            Text("Search federal opportunities and reach out fast.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusSection: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading opportunities...")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let error = viewModel.error {
                Text(error)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.red)
                    .cardStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var resultsSection: some View {
        Group {
            if viewModel.hasResults {
                Divider()
                    .overlay(DesignSystem.Colors.divider)
                resultsList
            } else if !viewModel.isLoading, viewModel.error == nil {
                emptyState
            }
        }
    }

    private var resultsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(resultsSummary)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                    Spacer()
                    Text(sortSummary)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                }

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
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start with a search")
                .font(DesignSystem.Typography.titleM)
                .foregroundStyle(DesignSystem.Colors.primaryText)
            Text("Use a keyword, NAICS, agency, and dates to find active opportunities.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
        }
        .cardStyle()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var resultsSummary: String {
        if viewModel.totalRecords > 0 {
            return "Showing \(viewModel.opportunities.count) of \(viewModel.totalRecords) results"
        }
        return "\(viewModel.opportunities.count) results"
    }

    private var sortSummary: String {
        switch viewModel.sortOption {
        case .postedNewest:
            return "Sorted: Posted Date (Newest)"
        case .postedOldest:
            return "Sorted: Posted Date (Oldest)"
        case .titleAZ:
            return "Sorted: Title (A–Z)"
        case .titleZA:
            return "Sorted: Title (Z–A)"
        }
    }
}

#Preview {
    SearchView()
}
