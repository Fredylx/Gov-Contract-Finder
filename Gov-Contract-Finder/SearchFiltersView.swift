//
//  SearchFiltersView.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 1/31/26.
//

import SwiftUI
import OSLog

struct SearchFiltersView: View {
    @Bindable var viewModel: SearchViewModel
    private let logger = Logger(subsystem: "Gov-Contract-Finder", category: "SearchFiltersView")
    @State private var isNAICSPresetsExpanded = false
    @State private var featureFlags = FeatureFlags.shared

    private func formatDateInput(_ value: String) -> String {
        let digits = value.filter { $0.isNumber }
        var result = ""
        for (index, char) in digits.prefix(8).enumerated() {
            if index == 2 || index == 4 {
                result.append("/")
            }
            result.append(char)
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            if hasActiveFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.s) {
                        if let agency = viewModel.agency, !agency.isEmpty {
                            FilterChip(text: "Agency: \(agency)")
                        }
                        if let naics = viewModel.naics, !naics.isEmpty {
                            FilterChip(text: "NAICS: \(naics)")
                        }
                        if let postedFrom = viewModel.postedFrom, !postedFrom.isEmpty {
                            FilterChip(text: "From: \(postedFrom)")
                        }
                        if let postedTo = viewModel.postedTo, !postedTo.isEmpty {
                            FilterChip(text: "To: \(postedTo)")
                        }
                    }
                }
            }

            HStack(spacing: DesignSystem.Spacing.s) {
                TextField("Search contracts", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .font(DesignSystem.Typography.body)
                    .onChange(of: viewModel.searchText) { _, _ in
                        viewModel.scheduleAutoSearch()
                    }
                    .accessibilityLabel("Search contracts")

                Button("Search") {
                    if DebugSettings.shared.isEnabled {
                        logger.debug("search button tapped text=\(viewModel.searchText, privacy: .public)")
                    }
                    Task { await viewModel.search() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel("Search contracts")
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                TextField("Agency", text: Binding(
                    get: { viewModel.agency ?? "" },
                    set: { viewModel.agency = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .font(DesignSystem.Typography.body)
                .onChange(of: viewModel.agency ?? "") { _, _ in
                    viewModel.scheduleAutoSearch()
                }
                .accessibilityLabel("Agency")

                TextField("NAICS (e.g., 541511)", text: Binding(
                    get: { viewModel.naics ?? "" },
                    set: { viewModel.naics = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .font(DesignSystem.Typography.body)
                .onChange(of: viewModel.naics ?? "") { _, _ in
                    viewModel.scheduleAutoSearch()
                }
                .accessibilityLabel("NAICS")
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                TextField("MM/DD/YYYY", text: Binding(
                    get: { viewModel.postedFrom ?? "" },
                    set: { viewModel.postedFrom = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .font(DesignSystem.Typography.body)
                .keyboardType(.numberPad)
                .overlay(alignment: .trailing) {
                    Text("Posted From")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .padding(.trailing, 8)
                        .opacity((viewModel.postedFrom ?? "").isEmpty ? 1 : 0)
                }
                .onChange(of: viewModel.postedFrom ?? "") { _, newValue in
                    let digits = newValue.filter { $0.isNumber }
                    let formatted = formatDateInput(digits)
                    if formatted != newValue {
                        viewModel.postedFrom = formatted.isEmpty ? nil : formatted
                    }
                    viewModel.scheduleAutoSearch()
                }
                .accessibilityLabel("Posted from date")

                TextField("MM/DD/YYYY", text: Binding(
                    get: { viewModel.postedTo ?? "" },
                    set: { viewModel.postedTo = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .font(DesignSystem.Typography.body)
                .keyboardType(.numberPad)
                .overlay(alignment: .trailing) {
                    Text("Posted To")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .padding(.trailing, 8)
                        .opacity((viewModel.postedTo ?? "").isEmpty ? 1 : 0)
                }
                .onChange(of: viewModel.postedTo ?? "") { _, newValue in
                    let digits = newValue.filter { $0.isNumber }
                    let formatted = formatDateInput(digits)
                    if formatted != newValue {
                        viewModel.postedTo = formatted.isEmpty ? nil : formatted
                    }
                    viewModel.scheduleAutoSearch()
                }
                .accessibilityLabel("Posted to date")
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                Button("Software (Last 6 Months)") {
                    viewModel.applySoftwareLastSixMonthsPreset()
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(maxWidth: .infinity, alignment: .leading)

                if featureFlags.naicsPresetsEnabled {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            Button("NAICS 541511 – Custom Computer Programming") {
                                viewModel.applyNAICSPreset(code: "541511", title: "custom software")
                                isNAICSPresetsExpanded = false
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button("NAICS 541512 – Computer Systems Design") {
                                viewModel.applyNAICSPreset(code: "541512", title: "systems design")
                                isNAICSPresetsExpanded = false
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button("NAICS 541519 – Other Computer Related Services") {
                                viewModel.applyNAICSPreset(code: "541519", title: "IT services")
                                isNAICSPresetsExpanded = false
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button("NAICS 541715 – R&D (Engineering/Life Sciences)") {
                                viewModel.applyNAICSPreset(code: "541715", title: "research and development")
                                isNAICSPresetsExpanded = false
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button("NAICS 518210 – Data Processing/Hosting") {
                                viewModel.applyNAICSPreset(code: "518210", title: "data processing")
                                isNAICSPresetsExpanded = false
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button("NAICS 541513 – Computer Facilities Mgmt") {
                                viewModel.applyNAICSPreset(code: "541513", title: "facilities management")
                                isNAICSPresetsExpanded = false
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button("NAICS 541690 – Sci/Tech Consulting") {
                                viewModel.applyNAICSPreset(code: "541690", title: "technical consulting")
                                isNAICSPresetsExpanded = false
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button("NAICS 541330 – Engineering Services") {
                                viewModel.applyNAICSPreset(code: "541330", title: "engineering services")
                                isNAICSPresetsExpanded = false
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button("NAICS 541611 – Mgmt Consulting") {
                                viewModel.applyNAICSPreset(code: "541611", title: "management consulting")
                                isNAICSPresetsExpanded = false
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.top, 4)
                    } label: {
                        HStack(spacing: 6) {
                            Text("NAICS Presets")
                                .font(DesignSystem.Typography.body.weight(.semibold))
                                .foregroundStyle(DesignSystem.Colors.accentNavy)
                            Spacer()
                        }
                    }
                }
            }

            if featureFlags.sortControlEnabled {
                Picker("Sort", selection: $viewModel.sortOption) {
                    Text("Posted Date (Newest)").tag(SearchViewModel.SortOption.postedNewest)
                    Text("Posted Date (Oldest)").tag(SearchViewModel.SortOption.postedOldest)
                    Text("Title (A–Z)").tag(SearchViewModel.SortOption.titleAZ)
                    Text("Title (Z–A)").tag(SearchViewModel.SortOption.titleZA)
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.sortOption) { _, _ in
                    viewModel.scheduleAutoSearch()
                }
                .font(DesignSystem.Typography.body.weight(.semibold))
                .tint(DesignSystem.Colors.accentNavy)
                .accessibilityLabel("Sort results")
            }

            DisclosureGroup {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                    TextField("Notice Type", text: Binding(
                        get: { viewModel.noticeType ?? "" },
                        set: { viewModel.noticeType = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(DesignSystem.Typography.body)
                    .onChange(of: viewModel.noticeType ?? "") { _, _ in
                        viewModel.scheduleAutoSearch()
                    }
                    .accessibilityLabel("Notice type")

                    TextField("Set-Aside Code", text: Binding(
                        get: { viewModel.setAsideCode ?? "" },
                        set: { viewModel.setAsideCode = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(DesignSystem.Typography.body)
                    .onChange(of: viewModel.setAsideCode ?? "") { _, _ in
                        viewModel.scheduleAutoSearch()
                    }
                    .accessibilityLabel("Set-aside code")
                }
                .padding(.top, 4)
            } label: {
                HStack(spacing: 6) {
                    Text("Advanced Filters")
                        .font(DesignSystem.Typography.body.weight(.semibold))
                        .foregroundStyle(DesignSystem.Colors.accentNavy)
                    Spacer()
                }
            }
        }
        .cardStyle()
    }
}

private struct FilterChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.Colors.primaryText)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(DesignSystem.Colors.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(DesignSystem.Colors.divider.opacity(0.7), lineWidth: 1)
            )
    }
}

private extension SearchFiltersView {
    var hasActiveFilters: Bool {
        !(viewModel.agency ?? "").isEmpty ||
        !(viewModel.naics ?? "").isEmpty ||
        !(viewModel.postedFrom ?? "").isEmpty ||
        !(viewModel.postedTo ?? "").isEmpty
    }
}
