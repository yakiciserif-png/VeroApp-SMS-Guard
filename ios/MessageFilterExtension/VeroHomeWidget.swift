import WidgetKit
import SwiftUI

struct VeroWidgetEntry: TimelineEntry {
    let date: Date
    let blockedToday: Int
    let blockedWeek: Int
    let isShieldActive: Bool
}

struct VeroHomeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> VeroWidgetEntry {
        VeroWidgetEntry(date: Date(), blockedToday: 14, blockedWeek: 89, isShieldActive: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (VeroWidgetEntry) -> ()) {
        let entry = VeroWidgetEntry(date: Date(), blockedToday: 14, blockedWeek: 89, isShieldActive: true)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let defaults = UserDefaults(suiteName: "group.com.veroapp.smsguard")
        let today = defaults?.integer(forKey: "vero_stat_today") ?? 14
        let week = defaults?.integer(forKey: "vero_stat_week") ?? 89

        let entry = VeroWidgetEntry(date: Date(), blockedToday: today, blockedWeek: week, isShieldActive: true)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct VeroHomeWidgetEntryView : View {
    var entry: VeroHomeWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color(red: 11/255, green: 16/255, blue: 32/255) // #0B1020

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(Color(red: 0/255, green: 229/255, blue: 255/255)) // #00E5FF
                    Text("VeroApp")
                        .font(.custom("Book Antiqua", size: 14))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Text("%100 AKTİF")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(Color(red: 0/255, green: 230/255, blue: 118/255))
                }

                Spacer()

                Text("\(entry.blockedToday)")
                    .font(.custom("Book Antiqua", size: 26))
                    .fontWeight(.black)
                    .foregroundColor(Color(red: 0/255, green: 229/255, blue: 255/255))

                Text("Bugün Engellenen Spam")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)

                Text("Bu Hafta: \(entry.blockedWeek) tehdit")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
        }
    }
}

struct VeroHomeWidget: Widget {
    let kind: String = "VeroHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VeroHomeWidgetProvider()) { entry in
            VeroHomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("VeroApp SMS Guard")
        .description("100% Çevrimdışı ve gizlilik odaklı canlı spam engelleme göstergesi.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
