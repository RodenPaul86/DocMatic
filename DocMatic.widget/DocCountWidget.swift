//
//  DocCountingWidget.swift
//  DocMatic
//
//  Created by Paul  on 6/19/25.
//

import WidgetKit
import SwiftUI

// MARK: Provides timeline entries for the widget
struct DocCountProvider: TimelineProvider {
    // Provides a placeholder view for the widget when data is loading
    func placeholder(in context: Context) -> DocCountEntry {
        DocCountEntry(date: Date(), sharedText: "Loading…")
    }

    // Provides a single entry for the widget gallery preview
    func getSnapshot(in context: Context, completion: @escaping (DocCountEntry) -> ()) {
        let sharedText = UserDefaults(suiteName: "group.com.studio4design.DocMatic")?.string(forKey: "scanCount") ?? "0"
        let entry = DocCountEntry(date: Date(), sharedText: sharedText)
        completion(entry)
    }

    // Provides a timeline of entries for the widget to display over time
    func getTimeline(in context: Context, completion: @escaping (Timeline<DocCountEntry>) -> Void) {
        let sharedText = UserDefaults(suiteName: "group.com.studio4design.DocMatic")?.string(forKey: "scanCount") ?? "0"
        var entries: [DocCountEntry] = []

        // Generate a timeline with one entry for the current time
        let currentDate = Date()
        let entry = DocCountEntry(date: currentDate, sharedText: sharedText)
        entries.append(entry)

        // Define the timeline with a reload policy (e.g., .atEnd)
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: Defines a timeline entry with the data to display
struct DocCountEntry: TimelineEntry {
    let date: Date
    let sharedText: String
}

// MAEK: The SwiftUI view that displays the widget content
struct DocCountingView : View {
    var entry: DocCountEntry
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Image(systemName: "scanner")
                .font(.caption)
            
            Text(entry.sharedText)
                .font(.title)
            
            Text(Int(entry.sharedText) == 1 ? "Scan" : "Scans")
                .font(.caption)
        }
    }
}

// MARK: Entry point for the widget
struct DocCountWidget: Widget {
    let kind: String = "app.DocMatic.scanCountWidget"

    // MARK: Configures the widget
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DocCountProvider()) { entry in
            DocCountingView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Scan Counter")
        .description("Keep track of your total scans right from your lock screen.")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: SwiftUI previews for different widget sizes
#Preview(as: .accessoryCircular) {
    DocCountWidget()
} timeline: {
    DocCountEntry(date: .now, sharedText: "0")
}
