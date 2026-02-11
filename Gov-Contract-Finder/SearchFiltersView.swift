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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Search contracts", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)

                Button("Search") {
                    if DebugSettings.shared.isEnabled {
                        logger.debug("search button tapped text=\(viewModel.searchText, privacy: .public)")
                    }
                    Task { await viewModel.search() }
                }
                .buttonStyle(.borderedProminent)
            }
            HStack {
                Button("Software (Last 6 Months)") {
                    viewModel.applySoftwareLastSixMonthsPreset()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                TextField("MM/DD/YYYY", text: Binding(
                    get: { viewModel.postedFrom ?? "" },
                    set: { viewModel.postedFrom = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .overlay(alignment: .trailing) {
                    Text("Posted From")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                        .opacity((viewModel.postedFrom ?? "").isEmpty ? 1 : 0)
                }
                .onChange(of: viewModel.postedFrom ?? "") { _, newValue in
                    let digits = newValue.filter { $0.isNumber }
                    let formatted = formatDateInput(digits)
                    if formatted != newValue {
                        viewModel.postedFrom = formatted.isEmpty ? nil : formatted
                    }
                }

                TextField("MM/DD/YYYY", text: Binding(
                    get: { viewModel.postedTo ?? "" },
                    set: { viewModel.postedTo = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .overlay(alignment: .trailing) {
                    Text("Posted To")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                        .opacity((viewModel.postedTo ?? "").isEmpty ? 1 : 0)
                }
                .onChange(of: viewModel.postedTo ?? "") { _, newValue in
                    let digits = newValue.filter { $0.isNumber }
                    let formatted = formatDateInput(digits)
                    if formatted != newValue {
                        viewModel.postedTo = formatted.isEmpty ? nil : formatted
                    }
                }
            }

            DisclosureGroup("Advanced filters") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("NAICS (e.g., 541511)", text: Binding(
                            get: { viewModel.naics ?? "" },
                            set: { viewModel.naics = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)

                        TextField("Notice Type", text: Binding(
                            get: { viewModel.noticeType ?? "" },
                            set: { viewModel.noticeType = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        TextField("Set-Aside Code", text: Binding(
                            get: { viewModel.setAsideCode ?? "" },
                            set: { viewModel.setAsideCode = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)

                        Picker("Sort", selection: $viewModel.sort) {
                            Text("Posted Date").tag("postedDate")
                            Text("Title").tag("title")
                        }
                        .pickerStyle(.menu)

                        Picker("Order", selection: $viewModel.order) {
                            Text("Descending").tag("desc")
                            Text("Ascending").tag("asc")
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}
