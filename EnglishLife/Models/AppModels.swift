import SwiftUI

enum EnglishLevel: String, CaseIterable, Identifiable {
  case beginner = "Beginner"
  case intermediate = "Intermediate"
  case advanced = "Advanced"
  var id: String { rawValue }
  var icon: String {
    self == .beginner ? "leaf.fill" : self == .intermediate ? "flame.fill" : "crown.fill"
  }
}

struct Situation: Identifiable, Hashable {
  let id: Int
  let chapter: String
  let title: String
  let subtitle: String
  let icon: String
  let color: Color
  let goals: [String]
  let reward: Int
  let unlock: String
  let story: String
}

struct AdventureChapter: Identifiable, Hashable {
  let id: Int
  let title: String
  let subtitle: String
  let icon: String
  let color: Color
}

enum SituationProgress: Equatable {
  case locked, available, completed

  var label: String {
    switch self {
    case .locked: "Locked"
    case .available: "Ready to play"
    case .completed: "Ready to play"
    }
  }

  var icon: String {
    switch self {
    case .locked: "lock.fill"
    case .available: "play.fill"
    case .completed: "checkmark"
    }
  }
}

struct Character: Identifiable, Hashable {
  let id: UUID
  var name: String
  var situationTitle: String
  var vibe: String
  var hair: String
  var accessory: String
  var color: Color
  var avatar: String
}

struct ChatSession: Identifiable {
  let id = UUID()
  let character: Character
  let situation: Situation?
}

extension Situation {
  static let chapters = [
    AdventureChapter(
      id: 1, title: "Café Corner", subtitle: "10 everyday café conversations",
      icon: "cup.and.saucer.fill", color: ThemeApp.Colors.coral),
    AdventureChapter(
      id: 2, title: "City Explorer", subtitle: "10 missions around the city",
      icon: "building.2.fill", color: ThemeApp.Colors.mint),
    AdventureChapter(
      id: 3, title: "Market Day", subtitle: "10 shopping and food missions", icon: "basket.fill",
      color: ThemeApp.Colors.accentPink),
    AdventureChapter(
      id: 4, title: "Social Club", subtitle: "10 ways to connect with people",
      icon: "person.3.fill", color: ThemeApp.Colors.roadmapLine),
    AdventureChapter(
      id: 5, title: "Travel Quest", subtitle: "10 travel English adventures", icon: "airplane",
      color: Color(hex: "#9CC7E8")),
  ]

  private static let firstSituations = [
    Situation(
      id: 1, chapter: "Chapter 1 · Café Corner", title: "Order a coffee",
      subtitle: "Meet a friendly barista and order your favorite drink.",
      icon: "cup.and.saucer.fill", color: ThemeApp.Colors.coral,
      goals: ["order", "please", "medium", "thank you"], reward: 50, unlock: "Introduce yourself",
      story:
        "A warm little café is buzzing with people. The barista looks up and smiles — but they need a name for their apron."
    ),
    Situation(
      id: 2, chapter: "Chapter 1 · Café Corner", title: "Introduce yourself",
      subtitle: "Start a friendly conversation with another guest.", icon: "hand.wave.fill",
      color: ThemeApp.Colors.coral, goals: ["my name is", "nice to meet you", "from", "too"],
      reward: 55, unlock: "Ask for directions",
      story: "A traveler is sitting by the café window. They smile and make room at their table."),
    Situation(
      id: 3, chapter: "Chapter 1 · Café Corner", title: "Choose your drink",
      subtitle: "Ask what is on the menu.", icon: "menucard.fill", color: ThemeApp.Colors.coral,
      goals: ["what", "recommend", "drink", "today"], reward: 60, unlock: "Ask for oat milk",
      story: "The menu has lots of choices. The barista is happy to recommend something."),
    Situation(
      id: 4, chapter: "Chapter 1 · Café Corner", title: "Ask for oat milk",
      subtitle: "Make a simple custom request.", icon: "drop.fill", color: ThemeApp.Colors.coral,
      goals: ["can I", "oat milk", "instead", "sure"], reward: 65, unlock: "Find a seat",
      story: "Your drink is almost ready, and you want to get comfortable."),
    Situation(
      id: 5, chapter: "Chapter 1 · Café Corner", title: "Find a seat",
      subtitle: "Ask if a table is free.", icon: "chair.fill", color: ThemeApp.Colors.coral,
      goals: ["is", "seat", "free", "mind"], reward: 70, unlock: "Ask for the Wi-Fi",
      story: "The café is busy, but a guest waves you over to an empty chair."),
    Situation(
      id: 6, chapter: "Chapter 1 · Café Corner", title: "Ask for the Wi-Fi",
      subtitle: "Connect before you start studying.", icon: "wifi", color: ThemeApp.Colors.coral,
      goals: ["Wi-Fi", "password", "connect", "thanks"], reward: 75, unlock: "Make small talk",
      story: "A friendly regular notices you setting up your laptop."),
    Situation(
      id: 7, chapter: "Chapter 1 · Café Corner", title: "Make small talk",
      subtitle: "Talk about your day with a new friend.", icon: "bubble.left.and.bubble.right.fill",
      color: ThemeApp.Colors.coral, goals: ["how", "day", "busy", "today"], reward: 80,
      unlock: "Order a snack", story: "Someone at the next table asks how your day is going."),
    Situation(
      id: 8, chapter: "Chapter 1 · Café Corner", title: "Order a snack",
      subtitle: "Add something tasty to your order.", icon: "takeoutbag.and.cup.and.straw.fill",
      color: ThemeApp.Colors.coral, goals: ["could I", "have", "sandwich", "also"], reward: 85,
      unlock: "Ask for the bill",
      story: "The display case is full of pastries and fresh sandwiches."),
    Situation(
      id: 9, chapter: "Chapter 1 · Café Corner", title: "Ask for the bill",
      subtitle: "Finish your café order confidently.", icon: "doc.text.fill",
      color: ThemeApp.Colors.coral, goals: ["bill", "ready", "pay", "please"], reward: 90,
      unlock: "Thank the barista",
      story: "You have enjoyed your time at the café and are ready to settle up."),
    Situation(
      id: 10, chapter: "Chapter 1 · Café Corner", title: "Thank the barista",
      subtitle: "Finish your café visit with warmth.", icon: "heart.fill",
      color: ThemeApp.Colors.coral, goals: ["thank you", "help", "lovely", "see you"], reward: 95,
      unlock: "City Explorer",
      story: "Your new café friends wave as you get ready to explore the city."),
  ]

  // Chapters 2...5. Chapter 1 is defined explicitly above so it can start at ID 1.
  private static let chapterSituations: [[(String, String, String, [String])]] = [
    [
      (
        "Find the museum", "Ask a local to guide you downtown.", "map.fill",
        ["excuse me", "where", "museum", "please"]
      ),
      (
        "Buy a bus ticket", "Get on the right bus.", "ticket.fill",
        ["one ticket", "to", "how much", "here you are"]
      ),
      (
        "Read the timetable", "Check when the next bus leaves.", "clock.fill",
        ["when", "leaves", "platform", "minutes"]
      ),
      (
        "Ask for a taxi", "Call a ride to your next stop.", "car.fill",
        ["taxi", "pick up", "address", "please"]
      ),
      (
        "Cross the street", "Understand a safety instruction.", "figure.walk",
        ["cross", "wait", "light", "careful"]
      ),
      (
        "Visit the library", "Ask where to find a book.", "books.vertical.fill",
        ["looking for", "section", "borrow", "card"]
      ),
      (
        "Mail a postcard", "Send a note home.", "envelope.fill",
        ["stamp", "postcard", "send", "please"]
      ),
      (
        "Report a lost item", "Describe something you cannot find.", "magnifyingglass",
        ["lost", "bag", "color", "help"]
      ),
      (
        "Ask about opening hours", "Plan your next visit.", "door.left.hand.open",
        ["open", "close", "today", "tomorrow"]
      ),
      (
        "Meet at the station", "Find your friend in a busy place.", "tram.fill",
        ["meet", "entrance", "waiting", "there"]
      ),
    ],
    [
      (
        "Buy fresh fruit", "Pick perfect fruit at the market.", "basket.fill",
        ["how much", "kilos", "fresh", "great"]
      ),
      (
        "Choose an outfit", "Find the right color and size.", "tshirt.fill",
        ["try on", "size", "blue", "fits"]
      ),
      (
        "Order lunch", "Choose a meal from the menu.", "fork.knife",
        ["menu", "would like", "without", "please"]
      ),
      (
        "Pay at the counter", "Complete your purchase.", "creditcard.fill",
        ["card", "cash", "receipt", "thank you"]
      ),
      (
        "Ask for a discount", "Practice a polite negotiation.", "tag.fill",
        ["discount", "price", "cheaper", "deal"]
      ),
      (
        "Return an item", "Explain a problem with your purchase.", "arrow.uturn.backward",
        ["return", "wrong", "size", "exchange"]
      ),
      (
        "Buy a gift", "Ask for a recommendation.", "gift.fill",
        ["gift", "recommend", "friend", "birthday"]
      ),
      (
        "Choose ingredients", "Shop for a simple recipe.", "carrot.fill",
        ["need", "ingredients", "recipe", "enough"]
      ),
      (
        "Order dessert", "End the meal with something sweet.", "birthday.cake.fill",
        ["dessert", "recommend", "sweet", "delicious"]
      ),
      (
        "Leave a review", "Share your shopping experience.", "star.fill",
        ["service", "excellent", "recommend", "again"]
      ),
    ],
    [
      (
        "Make weekend plans", "Invite a new friend to join you.", "calendar.badge.plus",
        ["are you free", "would you like", "Saturday", "sounds good"]
      ),
      (
        "Talk about hobbies", "Discover what you have in common.", "paintpalette.fill",
        ["I like", "favorite", "often", "me too"]
      ),
      (
        "Join a club", "Ask about an activity group.", "person.3.fill",
        ["join", "meeting", "member", "interested"]
      ),
      (
        "Introduce a friend", "Help two people meet.", "person.2.fill",
        ["this is", "meet", "works", "nice"]
      ),
      (
        "Accept an invitation", "Reply positively to a plan.", "checkmark.seal.fill",
        ["love to", "thank you", "what time", "see you"]
      ),
      (
        "Decline politely", "Say no kindly while keeping the conversation warm.",
        "hand.raised.fill", ["sorry", "cannot", "maybe", "next time"]
      ),
      (
        "Plan a picnic", "Decide what to bring.", "leaf.fill", ["bring", "food", "weather", "idea"]
      ),
      (
        "Give a compliment", "Make someone smile.", "sparkles",
        ["love", "looks", "great", "really"]
      ),
      (
        "Ask for advice", "Get a friend’s opinion.", "lightbulb.fill",
        ["think", "should", "advice", "maybe"]
      ),
      (
        "Celebrate together", "Share good news with your group.", "party.popper.fill",
        ["congratulations", "celebrate", "proud", "cheers"]
      ),
    ],
    [
      (
        "Check in at a hotel", "Book your room for a new adventure.", "bed.double.fill",
        ["reservation", "nights", "passport", "thank you"]
      ),
      (
        "Ask about breakfast", "Find out when and where to eat.", "sunrise.fill",
        ["breakfast", "served", "floor", "time"]
      ),
      (
        "Find the airport gate", "Get directions before boarding.", "airplane",
        ["gate", "flight", "boarding", "where"]
      ),
      (
        "Go through security", "Follow airport instructions.", "shield.fill",
        ["bag", "liquids", "passport", "tray"]
      ),
      (
        "Rent a car", "Choose the right vehicle.", "car.fill",
        ["rent", "automatic", "insurance", "days"]
      ),
      (
        "Ask for a room change", "Solve a hotel problem politely.", "key.fill",
        ["room", "noisy", "change", "please"]
      ),
      (
        "Order room service", "Ask for a late meal.", "bell.fill",
        ["room service", "order", "bring", "please"]
      ),
      (
        "Buy a souvenir", "Pick a memorable present.", "shippingbox.fill",
        ["souvenir", "local", "price", "gift"]
      ),
      (
        "Tell a travel story", "Share your most memorable journey.", "globe.americas.fill",
        ["last year", "went", "because", "amazing"]
      ),
      (
        "Say goodbye", "End your journey with confidence.", "figure.wave",
        ["goodbye", "wonderful", "keep in touch", "safe trip"]
      ),
    ],
  ]

  static let demo: [Situation] =
    firstSituations
    + chapterSituations.enumerated().flatMap { chapterOffset, situations in
      let chapter = chapters[chapterOffset + 1]
      return situations.enumerated().map { offset, item in
        let id = 11 + chapterOffset * 10 + offset
        let nextTitle = id == 50 ? "English Life Mastery" : "the next situation"
        return Situation(
          id: id, chapter: "Chapter \(chapter.id) · \(chapter.title)", title: item.0,
          subtitle: item.1, icon: item.2, color: chapter.color, goals: item.3, reward: 100 + id * 5,
          unlock: nextTitle,
          story:
            "A new moment awaits in \(chapter.title). Speak up and make this part of your story.")
      }
    }
}
