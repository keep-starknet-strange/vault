//
//  Home.swift
//  Vault
//
//  Created by Charles Lanier on 01/04/2024.
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var model: Model

    @StateObject private var txHistoryModel: PaginationModel<TransactionHistory> = PaginationModel(threshold: 1, pageSize: 1)

    @State private var showingAddFundsWebView = false

    var body: some View {
        List {

            VStack {

                // MARK: Balance

                VStack(spacing: 12) {
                    Text("Account Balance")
                        .foregroundStyle(.neutral2)
                        .textTheme(.bodyPrimary)

                    BalanceView(balance: self.$model.balance)
                }
                .padding(EdgeInsets(top: 32, leading: 0, bottom: 42, trailing: 0))

                // MARK: Transfers

                HStack {
                    Spacer(minLength: 8)

                    IconButton(size: .large, priority: .primary) {
                        self.model.showSendingView = true
                    } icon: {
                        Image(systemName: "arrow.up")
                            .iconify()
                            .fontWeight(.semibold)
                    }
                    .withText("Send")
                    .frame(maxWidth: .infinity)

                    Spacer()

                    IconButton(size: .large) {
                        // TODO: Handle sending
                    } icon: {
                        Image(systemName: "arrow.down")
                            .iconify()
                            .fontWeight(.semibold)
                    }
                    .withText("Request")
                    .frame(maxWidth: .infinity)

                    Spacer()

                    IconButton(size: .large) {
                        self.showingAddFundsWebView = true
                    } icon: {
                        Image(systemName: "plus")
                            .iconify()
                            .fontWeight(.medium)
                    }
                    .withText("Add funds")
                    .frame(maxWidth: .infinity)
                    .sheet(isPresented: $showingAddFundsWebView) {
                        WebView(url: URL(string: "https://app.fun.xyz")!)
                    }

                    Spacer(minLength: 8)
                }
            }
            .padding(.bottom, 16)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(EmptyView())
            .listRowSeparator(.hidden)

            // MARK: History

            if let txHistory = self.txHistoryModel.source {
                ForEach(
                    txHistory.groupedTransactions.keys.sorted(by: >),
                    id: \.self
                ) { day in
                    Section {
                        ForEach(0..<txHistory.groupedTransactions[day]!.count, id: \.self) { index in
                            let transfer = txHistory.groupedTransactions[day]![index]
                            let isFirst = index == 0;
                            let isLast = index == txHistory.groupedTransactions[day]!.count - 1

                            TransferRow(transfer: transfer)
                                .onAppear {
                                    self.txHistoryModel.onItemAppear(transfer)
                                }
                                .padding(16)
                                .background(.background2)
                                .clipShape(
                                    .rect(
                                        topLeadingRadius: isFirst ? 16 : 0,
                                        bottomLeadingRadius: isLast ? 16 : 0,
                                        bottomTrailingRadius: isLast ? 16 : 0,
                                        topTrailingRadius: isFirst ? 16 : 0
                                    )
                                )
                        }
                    } header: {
                        Text(self.formatSectionHeader(for: day).uppercased())
                            .textTheme(.headlineSmall)
                            .listRowInsets(EdgeInsets(top: 32, leading: 8, bottom: 12, trailing: 0))
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSeparator(.hidden)
                    .listRowBackground(EmptyView())
                }
            }
        }
        .onAppear {
            // dirty hack to remove the top padding of the list
            UICollectionView.appearance().contentInset.top = -30
            self.txHistoryModel.start(withSource: TransactionHistory(address: self.model.address))
        }
        .safeAreaInset(edge: .bottom) {
            EmptyView().frame(height: 90)
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .scrollContentBackground(.hidden)
        .listStyle(.grouped)
        .scrollIndicators(.hidden)
        .defaultBackground()
        .navigationBarItems(
            trailing: IconButton(size: .custom(IconButtonSize.medium.buttonSize, 20)) {} icon: {
                Image("Gear")
                    .iconify()
            }
        )
        .removeNavigationBarBorder()
        .fullScreenCover(isPresented: self.$model.showSendingView) {
            SendingView()
        }
    }

    private func formatSectionHeader(for date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE d MMMM" // Day DD Month
            return formatter.string(from: date)
        }
    }
}

#Preview {
    struct HomeViewPreviews: View {

        @StateObject var model = Model()

        var body: some View {
            NavigationStack {
                HomeView()
                    .environmentObject(self.model)
            }
        }
    }

    return HomeViewPreviews()
}
