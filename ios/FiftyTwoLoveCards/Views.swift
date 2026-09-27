import SwiftUI
import UIKit

@main
struct FiftyTwoLoveCardsApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
                .task { await model.bootstrap() }
        }
    }
}

private let pink = Color(red: 249/255, green: 61/255, blue: 114/255)
private let pinkHi = Color(red: 252/255, green: 100/255, blue: 122/255)
private let cream = Color(red: 254/255, green: 245/255, blue: 243/255)
private let night = Color(red: 14/255, green: 12/255, blue: 21/255)
private let surface = Color(red: 24/255, green: 15/255, blue: 27/255)
private let darkBtn = Color(red: 49/255, green: 45/255, blue: 55/255)
private let muted = Color(red: 153/255, green: 137/255, blue: 147/255)
private let ink = Color(red: 14/255, green: 12/255, blue: 21/255)

struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ZStack {
            LinearGradient(colors: [night, surface], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if model.screen == .play && !model.deck.indices.contains(model.index) {
                HomeView()
            } else {
                switch model.screen {
                case .splash: SplashView()
                case .onboarding: OnboardingView()
                case .home: HomeView()
                case .settings: SettingsView()
                case .privacy: LegalView(title: "Privacy Policy", copy: LegalCopy.privacy, url: AppConfig.privacyURL)
                case .terms: LegalView(title: "Terms of Service", copy: LegalCopy.terms, url: AppConfig.termsURL)
                case .packDetail: PackDetailView()
                case .create: CreateView()
                case .setup: SetupView()
                case .play: PlayView()
                case .recap: RecapView()
                }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill").font(.largeTitle).foregroundStyle(pink)
            Text("52 Love Cards").font(.title.bold()).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(night)
    }
}

struct OnboardingView: View {
    @EnvironmentObject var model: AppModel
    @State private var offset: CGFloat = 0
    @State private var busy = false
    private let pages = [
        ("Questions for two", "52 Love Cards is a pass-the-phone game. Pick a pack, sit together, and talk through prompts written for couples.", "Welcome"),
        ("Turns and scores", "Choose how many cards and which type. You take turns. Give a mark from 1 to 10 after each answer; skip scores nothing.", "Play"),
        ("Your own pack", "Write a question and it lands in Our cards — a private pack just for the two of you, never mixed into the built-in sets.", "Create"),
    ]

    var body: some View {
        let i = min(model.onboardPage, 2)
        let page = pages[i]
        let peek = i < 2 ? pages[i + 1] : nil
        VStack {
            HStack {
                Spacer()
                Button("Skip") { model.skipOnboard() }.foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            SwipeCardStack(
                frontText: page.1,
                frontBadge: page.2,
                peekText: peek?.1,
                peekBadge: peek?.2 ?? page.2,
                offset: offset,
                frontHeading: page.0,
                peekHeading: peek?.0
            )
            .padding(.horizontal, 8)
            Spacer()
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { n in
                    Circle().fill(n == i ? pink : Color.white.opacity(0.2)).frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 16)
            Button(i >= 2 ? "Start" : "Next") { swipeNext() }
                .buttonStyle(PrimaryButton())
        }
        .padding(28)
    }

    func swipeNext() {
        if busy { return }
        busy = true
        withAnimation(.easeIn(duration: 0.28)) { offset = 520 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            model.nextOnboard()
            offset = 0
            busy = false
        }
    }
}

struct PackTile: View {
    var name: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(surface)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(pink.opacity(0.45), lineWidth: 1)
                LinearGradient(colors: [.clear, pink.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                VStack(alignment: .leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill").font(.caption2)
                        Text("pack").font(.caption)
                    }
                    .foregroundStyle(pink)
                    Text(name).font(.title3.bold()).foregroundStyle(.white).padding(.top, 8)
                    Spacer()
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                Circle().fill(pink).frame(width: 36, height: 36).overlay(Text("›").foregroundStyle(.white).bold()).padding(12)
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
    }
}

struct QuestionCard: View {
    var text: String
    var badge: String
    var heading: String? = nil

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(cream)
            VStack(alignment: .leading) {
                HStack {
                    Label(badge, systemImage: "heart.fill")
                        .font(.caption.bold())
                        .foregroundStyle(pink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 1, green: 0.89, blue: 0.93))
                        .clipShape(Capsule())
                    Spacer()
                }
                Spacer()
                VStack(spacing: 12) {
                    if let heading {
                        Text(heading).font(.title3.bold()).foregroundStyle(ink).multilineTextAlignment(.center)
                        Text(text).font(.body.weight(.medium)).foregroundStyle(ink.opacity(0.8)).multilineTextAlignment(.center)
                    } else {
                        Text(text).font(.title3.bold()).foregroundStyle(ink).multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
            .padding(20)
        }
        .aspectRatio(0.78, contentMode: .fit)
        .shadow(color: pink.opacity(0.25), radius: 18)
    }
}

struct HomeView: View {
    @EnvironmentObject var model: AppModel
    private let cols = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 0) {
                    Text("Select a ").font(.title.bold()).foregroundStyle(.white)
                    Text("Pack").font(.title.bold()).foregroundStyle(pink)
                }
                Spacer()
                Button { model.go(.settings) } label: {
                    Image(systemName: "gearshape.fill").foregroundStyle(.white)
                }
                Button("Create") { model.go(.create) }.foregroundStyle(.white.opacity(0.45))
                VStack(spacing: 4) {
                    Button("Game") { model.startGame() }.foregroundStyle(pink)
                    Capsule().fill(pink).frame(width: 28, height: 3)
                }
            }
            .padding(16)
            Text("v\(model.catalog.version) · \(model.cards.count) questions · \(model.loading ? "checking live…" : (model.catalogLive ? "live" : "on device — tap to retry live"))")
                .font(.caption)
                .foregroundStyle(muted)
                .padding(.horizontal, 16)
                .onTapGesture { Task { await model.refreshCatalog() } }
            ScrollView {
                LazyVGrid(columns: cols, spacing: 14) {
                    ForEach(model.displayPacks()) { pack in
                        PackTile(name: pack.name) { model.openPack(pack.id) }
                    }
                }
                .padding(16)
            }
        }
    }
}

struct SwipeCardStack: View {
    var frontText: String
    var frontBadge: String
    var peekText: String?
    var peekBadge: String
    var offset: CGFloat
    var frontHeading: String? = nil
    var peekHeading: String? = nil

    var body: some View {
        ZStack {
            if let peekText {
                QuestionCard(text: peekText, badge: peekBadge, heading: peekHeading)
                    .scaleEffect(0.94)
                    .opacity(0.9)
            }
            QuestionCard(text: frontText, badge: frontBadge, heading: frontHeading)
                .offset(x: offset)
                .rotationEffect(.degrees(Double(offset / 28)))
                .opacity(Double(max(0.15, 1 - abs(offset) / 900)))
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header(title: "Settings", back: { model.goHome() })
            row("Privacy Policy", "Read in the app or open the web page") { model.go(.privacy) }
            row("Terms of Service", "Read in the app or open the web page") { model.go(.terms) }
            row("Rate our app", "Leave a rating on the App Store") {
                if let url = URL(string: "https://apps.apple.com/search?term=52%20Love%20Cards") {
                    UIApplication.shared.open(url)
                }
            }
            row("Report a bug", "Opens email to \(AppConfig.supportEmail)") {
                let mail = "mailto:\(AppConfig.supportEmail)?subject=52%20Love%20Cards%20bug%20report"
                if let url = URL(string: mail) { UIApplication.shared.open(url) }
            }
            Spacer()
        }
        .padding(.horizontal, 12)
    }

    func row(_ title: String, _ subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundStyle(.white).bold()
                Text(subtitle).font(.footnote).foregroundStyle(muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
}

struct LegalView: View {
    @EnvironmentObject var model: AppModel
    var title: String
    var copy: String
    var url: String

    var body: some View {
        VStack(alignment: .leading) {
            header(title: title, back: { model.backFromSettings() })
            ScrollView {
                Text(copy).foregroundStyle(.white.opacity(0.9)).padding(20)
            }
            if let link = URL(string: url) {
                Link("Open on the web", destination: link)
                    .foregroundStyle(pinkHi)
                    .padding()
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct PackDetailView: View {
    @EnvironmentObject var model: AppModel
    @State private var offset: CGFloat = 0
    @State private var busy = false

    var packCards: [Card] { model.cardsInPack(model.selectedPackId) }
    var name: String { model.packName(model.selectedPackId) }

    var body: some View {
        let card = packCards.indices.contains(model.packIndex) ? packCards[model.packIndex] : nil
        let peek = packCards.indices.contains(model.packIndex + 1) ? packCards[model.packIndex + 1] : nil
        VStack(spacing: 0) {
            header(title: name, back: { model.goHome() }) {
                if let card {
                    ShareLink(item: "\(name)\n\n\(card.text)") {
                        Image(systemName: "square.and.arrow.up").foregroundStyle(.white)
                    }
                }
            }
            progress(model.packIndex + 1, max(packCards.count, 1))
            Spacer()
            if let card {
                SwipeCardStack(
                    frontText: card.text,
                    frontBadge: name,
                    peekText: peek?.text,
                    peekBadge: name,
                    offset: offset
                )
                .padding(.horizontal, 24)
            } else {
                Text("No cards yet. Create one.").foregroundStyle(.white)
            }
            Spacer()
            HStack {
                Button("Back") { swipe(false) { model.backFromPack() } }.buttonStyle(GhostButton())
                Button("Next") { swipe(true) { model.nextPackCard() } }.buttonStyle(PrimaryButton())
            }
            .padding(16)
            Button("Play this pack") { model.startGame() }.foregroundStyle(pink)
                .padding(.bottom, 12)
        }
    }

    func swipe(_ right: Bool, then: @escaping () -> Void) {
        if busy { return }
        if right && model.packIndex >= packCards.count - 1 { return }
        busy = true
        withAnimation(.easeIn(duration: 0.28)) { offset = right ? 520 : -520 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            then()
            offset = 0
            busy = false
        }
    }
}

struct CreateView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header(title: "Create", back: { model.goHome() })
                HStack {
                    Spacer()
                    Text("Create").foregroundStyle(pink).bold()
                    Button("Game") { model.startGame() }.foregroundStyle(.white.opacity(0.45))
                }
                Text("New cards go into Our cards — a pack just for yours.").foregroundStyle(.white.opacity(0.55)).font(.footnote)
                QuestionCard(text: model.createText.isEmpty ? "Your question will show here." : model.createText, badge: "Our cards")
                TextField("Question", text: $model.createText).textFieldStyle(.roundedBorder)
                if let error = model.error { Text(error).foregroundStyle(pink) }
                HStack {
                    chip("Romantic", model.createMood == "romantic") { model.createMood = "romantic" }
                    chip("Challenge", model.createMood == "challenge") { model.createMood = "challenge" }
                }
                HStack {
                    chip("Know me", model.createRound == "know_me") { model.createRound = "know_me" }
                    chip("Your turn", model.createRound == "your_turn") { model.createRound = "your_turn" }
                }
                Button("Save to Our cards") { model.saveCustom() }.buttonStyle(PrimaryButton())
            }
            .padding(20)
        }
    }

    func chip(_ title: String, _ on: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(on ? pink : Color.white.opacity(0.08))
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}

struct SetupView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header(title: "New game", back: { model.goHome() })
                Text("Names").foregroundStyle(.white).bold()
                TextField("Player A", text: $model.nameA).textFieldStyle(.roundedBorder)
                TextField("Player B", text: $model.nameB).textFieldStyle(.roundedBorder)
                Text("Number of cards").foregroundStyle(.white).bold()
                HStack {
                    ForEach([4, 6, 8, 10, 12], id: \.self) { n in
                        chip("\(n)", model.cardCount == n) { model.cardCount = n }
                    }
                }
                Text("Type of cards").foregroundStyle(.white).bold()
                chip("Mix all packs", model.selectedPackId == nil) { model.selectedPackId = nil }
                ForEach(model.displayPacks()) { pack in
                    chip(pack.name, model.selectedPackId == pack.id) { model.selectedPackId = pack.id }
                }
                Text("Mood").foregroundStyle(.white).bold()
                HStack {
                    ForEach(Mode.allCases) { mode in
                        chip(mode.rawValue, model.tab == mode) { model.setTab(mode) }
                    }
                }
                Text("You take turns. After each card, type a mark from 1 to 10. That mark is added to the player whose turn it is. Totals show at the end.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.55))
                Button("Start \(model.cardCount) cards") { model.beginSession() }.buttonStyle(PrimaryButton())
            }
            .padding(20)
        }
    }

    func chip(_ title: String, _ on: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(on ? pink : Color.white.opacity(0.08))
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}

struct PlayView: View {
    @EnvironmentObject var model: AppModel
    @State private var offset: CGFloat = 0
    @State private var busy = false

    var body: some View {
        if model.deck.indices.contains(model.index) {
            let play = model.deck[model.index]
            let peek = model.deck.indices.contains(model.index + 1) ? model.deck[model.index + 1] : nil
            let holder = play.holderIsA ? model.nameA : model.nameB
            VStack {
                header(title: play.card.packName, back: { model.goHome() }) {
                    ShareLink(item: "\(play.card.packName)\n\n\(play.card.text)") {
                        Image(systemName: "square.and.arrow.up").foregroundStyle(.white)
                    }
                }
                progress(model.index + 1, model.deck.count)
                Text("\(holder)’s turn  ·  \(model.scoreA)–\(model.scoreB)")
                    .foregroundStyle(pink)
                    .padding(.bottom, 8)
                SwipeCardStack(
                    frontText: play.card.text,
                    frontBadge: play.card.packName,
                    peekText: peek?.card.text,
                    peekBadge: peek?.card.packName ?? play.card.packName,
                    offset: offset
                )
                .padding(.horizontal, 22)
                Spacer()
                HStack {
                    TextField("Mark 1–10", text: Binding(
                        get: { model.playAnswer },
                        set: { model.setPlayAnswer($0) }
                    ))
                    .keyboardType(.numberPad)
                    .padding(12)
                    Button {
                        swipe(true) { model.submitMark() }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(model.currentMark == nil ? pink.opacity(0.4) : pink)
                            .clipShape(Circle())
                    }
                    .disabled(model.currentMark == nil)
                }
                .background(darkBtn)
                .clipShape(Capsule())
                .padding(.horizontal, 20)
                HStack {
                    Button("Skip") { swipe(false) { model.skipCard() } }.buttonStyle(GhostButton())
                    Button("Next") { swipe(true) { model.submitMark() } }.buttonStyle(PrimaryButton())
                }
                .padding(16)
            }
        }
    }

    func swipe(_ right: Bool, then: @escaping () -> Void) {
        if busy { return }
        if right && model.currentMark == nil { return }
        busy = true
        withAnimation(.easeIn(duration: 0.28)) { offset = right ? 520 : -520 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            then()
            offset = 0
            busy = false
        }
    }
}

struct RecapView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Final marks").font(.largeTitle.bold()).foregroundStyle(.white)
            Text("\(model.deck.count) cards  ·  \(model.skips) skipped").foregroundStyle(.white.opacity(0.55))
            scoreRow(model.nameA, model.scoreA)
            scoreRow(model.nameB, model.scoreB)
            Text(model.scoreA == model.scoreB ? "It's a tie" : (model.scoreA > model.scoreB ? "\(model.nameA) leads" : "\(model.nameB) leads"))
                .foregroundStyle(pink).bold()
            Button("Play again") { model.beginSession() }.buttonStyle(PrimaryButton())
            Button("Home") { model.goHome() }.buttonStyle(GhostButton())
        }
        .padding(24)
    }

    func scoreRow(_ name: String, _ score: Int) -> some View {
        HStack {
            Text(name).foregroundStyle(.white).bold()
            Spacer()
            Text("\(score)").font(.title.bold()).foregroundStyle(pink)
        }
        .padding(18)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

func header<Trailing: View>(title: String, back: @escaping () -> Void, @ViewBuilder trailing: () -> Trailing) -> some View {
    HStack {
        Button(action: back) {
            Image(systemName: "chevron.left")
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(darkBtn)
                .clipShape(Circle())
        }
        Spacer()
        Text(title).foregroundStyle(.white).bold()
        Spacer()
        trailing().frame(width: 40, height: 40)
    }
    .padding(.horizontal, 12)
}

func header(title: String, back: @escaping () -> Void) -> some View {
    header(title: title, back: back) { Color.clear }
}

func progress(_ current: Int, _ total: Int) -> some View {
    HStack {
        ProgressView(value: Double(current), total: Double(max(total, 1)))
            .tint(pink)
        Text("\(current) / \(total)").foregroundStyle(.white.opacity(0.5)).font(.caption)
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 8)
}

struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(LinearGradient(colors: [pinkHi, pink], startPoint: .leading, endPoint: .trailing))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct GhostButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(darkBtn)
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.2)))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
