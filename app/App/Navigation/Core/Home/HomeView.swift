//
//  Home.swift
//  Vault
//
//  Created by Charles Lanier on 01/04/2024.
//

import SwiftUI

// PreferenceKey to store the scroll offset
struct ScrollOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

struct HomeView: View {

    @EnvironmentObject private var model: Model

    @StateObject private var txHistoryModel: PaginationModel<TransactionHistory> = PaginationModel(threshold: 7, pageSize: 15)

    @State private var showingAddFundsWebView = false
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ScrollView {

            // MARK: Balance

            VStack(spacing: 48) {
                HStack {
                    Spacer()

                    VStack(spacing: 12) {
                        Text("Account Balance")
                            .foregroundStyle(.neutral2)
                            .textTheme(.bodyPrimary)

                        BalanceView(balance: self.$model.balance)
                    }

                    Spacer()
                }
                .padding(.top, 180)
                .padding(.bottom, 58)

                ActionsView()

                HistoryView()
            }
        }
        .onAppear {
            self.txHistoryModel.start(withSource: TransactionHistory(address: self.model.address))
        }
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
        .edgesIgnoringSafeArea(.all)
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

    // MARK: - Actions View

    @ViewBuilder
    func ActionsView() -> some View {
        HStack {
            Spacer(minLength: 24)

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

            Spacer(minLength: 24)
        }
    }

    // MARK: - History View

    @ViewBuilder
    func HistoryView() -> some View {
        LazyVStack(spacing: 48) {
            if let txHistory = self.txHistoryModel.source {
                ForEach(
                    txHistory.groupedTransactions.keys.sorted(by: >),
                    id: \.self
                ) { day in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(self.formatSectionHeader(for: day).uppercased())
                            .textTheme(.headlineSmall)

                        VStack(spacing: 32) {
                            ForEach(0..<txHistory.groupedTransactions[day]!.count, id: \.self) { index in
                                let transfer = txHistory.groupedTransactions[day]![index]

                                TransferRow(transfer: transfer)
                                    .onAppear {
                                        self.txHistoryModel.onItemAppear(transfer)
                                    }
                            }
                        }
                        .padding(16)
                        .background(.background2)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
            }
        }
        .padding(.top, 32)
        .padding(.bottom, 120)
        .background(.background1)
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
