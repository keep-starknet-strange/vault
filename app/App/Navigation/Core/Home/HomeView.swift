//
//  Home.swift
//  Vault
//
//  Created by Charles Lanier on 01/04/2024.
//

import SwiftUI

class User {
    let address: String
    let username: String
    let avatarUrl: String?

    init(address: String, username: String, avatarUrl: String? = nil) {
        self.address = address
        self.username = username
        self.avatarUrl = avatarUrl
    }
}

class Transfer: Identifiable {
    let from: User
    let to: User
    let amount: USDCAmount
    let date: Date

    init(from: User, to: User, amount: USDCAmount, timestamp: Double) {
        self.from = from
        self.to = to
        self.amount = amount
        self.date = Date(timeIntervalSince1970: timestamp)
    }
}

class History {
    let transfers: [Transfer]

    var groupedTransfers: [Date: [Transfer]] {
        get {
            return Dictionary(grouping: self.transfers) { (transfer) -> Date in
                Calendar.current.startOfDay(for: transfer.date)
            }
        }
    }

    init(transfers: [Transfer]) {
        self.transfers = transfers
    }
}

let users: [String: User] = [
    "me": User(
        address: "0xdead",
        username: "Bobby"
    ),
    "sbf": User(
        address: "0x1",
        username: "SBF",
        avatarUrl: "https://fortune.com/img-assets/wp-content/uploads/2022/11/SBF-1.jpg"
    ),
    "apple": User(
        address: "0x2",
        username: "Apple",
        avatarUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRIHoznvT47BiebsgSlaiey1FKjGR8xZru6gROHvntwI3QSA2I7T08Ys7g1by9_iBw-ekI&usqp=CAU"
    ),
    "vitalik": User(
        address: "0x3",
        username: "Vitalik",
        avatarUrl: "https://images.moneycontrol.com/static-mcnews/2021/05/vitalik-Buterin-ethereum.jpg?impolicy=website&width=1600&height=900"
    ),
    "satoshi": User(address: "0x4", username: "Satoshi N"),
    "alex": User(
        address: "0x5",
        username: "Alex",
        avatarUrl: "https://www.cryptotimes.io/wp-content/uploads/2024/02/Matter_Labs_co-founder_and_CEO_Alex_Gluchowski_proposed_an_Ethereum_court_system.jpg.webp"
    ),
    "abdel": User(
        address: "0x6",
        username: "Abdel.stark",
        avatarUrl: "https://miro.medium.com/v2/resize:fit:1400/1*BTiOG6PF5d9ToTAZqlIjuw.jpeg"
    ),
]

struct HomeView: View {

    @State private var showingAddFundsWebView = false
    @State private var showingSendingView = false

    private var me: User {
        get {
            return users["me"]!
        }
    }

    let history: History

    init() {
        self.history = History(transfers: [
            Transfer(from: users["me"]!, to: users["sbf"]!, amount: USDCAmount(1_604_568_230_000), timestamp: 1712199068),
            Transfer(from: users["me"]!, to: users["apple"]!, amount: USDCAmount(4_249_990_000), timestamp: 1711924459),
            Transfer(from: users["vitalik"]!, to: users["me"]!, amount: USDCAmount(70_000_000_000), timestamp: 1711878225),

            Transfer(from: users["alex"]!, to: users["me"]!, amount: USDCAmount(1_000_000), timestamp: 1711847328),
            Transfer(from: users["me"]!, to: users["satoshi"]!, amount: USDCAmount(32_570_000), timestamp: 1712000648),

            Transfer(from: users["abdel"]!, to: users["me"]!, amount: USDCAmount(10_000), timestamp: 1711828026),
        ])
    }

    var body: some View {
        List {

            VStack {

                // MARK: Balance

                VStack(spacing: 12) {
                    Text("Account Balance")
                        .foregroundStyle(.neutral2)
                        .textTheme(.bodyPrimary)

                    BalanceView()
                }
                .padding(EdgeInsets(top: 32, leading: 0, bottom: 42, trailing: 0))

                // MARK: Transfers

                HStack {
                    Spacer(minLength: 16)

                    IconButtonWithText("Send") {
                        self.showingSendingView = true
                    } icon: {
                        Image(systemName: "arrow.up")
                            .iconify()
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .fullScreenCover(isPresented: self.$showingSendingView) {
                        SendingView()
                    }

                    Spacer(minLength: 8)

                    IconButtonWithText("Request") {
                        // TODO: Handle sending
                    } icon: {
                        Image(systemName: "arrow.down")
                            .iconify()
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 8)

                    IconButtonWithText("Add funds") {
                        self.showingAddFundsWebView = true
                    } icon: {
                        Image(systemName: "plus")
                            .iconify()
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .sheet(isPresented: $showingAddFundsWebView) {
                        WebView(url: URL(string: "https://app.fun.xyz")!)
                    }

                    Spacer(minLength: 16)
                }
            }
            .padding(.bottom, 16)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(EmptyView())
            .listRowSeparator(.hidden)

            // MARK: History

            ForEach(self.history.groupedTransfers.keys.sorted(by: >), id: \.self) { day in
                Section {
                    ForEach(0..<self.history.groupedTransfers[day]!.count, id: \.self) { index in
                        let transfer = self.history.groupedTransfers[day]![index]
                        let isFirst = index == 0;
                        let isLast = index == self.history.groupedTransfers[day]!.count - 1

                        TransferRow(transfer: transfer, me: self.me)
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
                    Text(formatSectionHeader(for: day).uppercased())
                        .textTheme(.headlineSmall)
                        .listRowInsets(EdgeInsets(top: 32, leading: 8, bottom: 12, trailing: 0))
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(EmptyView())
            }
        }
        .onAppear {
            // dirty hack to remove the top padding of the list
            UICollectionView.appearance().contentInset.top = -30
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
    }

    func formatSectionHeader(for date: Date) -> String {
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
    NavigationStack {
        HomeView()
    }
}
