//
//  SearchFiltersView.swift
//  Gov-Contract-Finder
//
//  Created by Fredy lopez on 1/31/26.
//

struct SearchFiltersView: View {
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        HStack {
            TextField("Search contracts", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)

            Button("Search") {
                Task { await viewModel.search() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
