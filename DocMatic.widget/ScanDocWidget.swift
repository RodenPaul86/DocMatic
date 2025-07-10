//
//  ScanDocument.swift
//  DocMatic.widgetExtension
//
//  Created by Paul  on 6/18/25.
//

import WidgetKit
import SwiftUI

// MARK: Provides timeline entries for the widget
struct ScanDocProvider: TimelineProvider {
    // Provides a placeholder view for the widget when data is loading
    func placeholder(in context: Context) -> ScanDocEntry {
        ScanDocEntry(date: Date(), family: context.family)
    }
    
    // Provides a single entry for the widget gallery preview
    func getSnapshot(in context: Context, completion: @escaping (ScanDocEntry) -> ()) {
        let entry = ScanDocEntry(date: Date(), family: context.family)
        completion(entry)
    }
    
    // Provides a timeline of entries for the widget to display over time
    func getTimeline(in context: Context, completion: @escaping (Timeline<ScanDocEntry>) -> Void) { // 1.4.3, 1.4.4
        var entries: [ScanDocEntry] = []
        
        // Generate a timeline with one entry for the current time
        let currentDate = Date()
        let entry = ScanDocEntry(date: currentDate, family: context.family)
        entries.append(entry)
        
        // Define the timeline with a reload policy (e.g., .atEnd)
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: Defines a timeline entry with the data to display
struct ScanDocEntry: TimelineEntry {
    let date: Date
    let family: WidgetFamily
}

// MAEK: The SwiftUI view that displays the widget content
struct YourWidgetEntryView : View {
    var entry: ScanDocEntry
    
    var body: some View {
        switch entry.family {
        case .systemSmall: smallWidget()
        case .systemMedium: EmptyView()
        case .systemLarge: EmptyView()
        case .systemExtraLarge: EmptyView()
        case .accessoryCircular: circularWidget()
        case .accessoryRectangular: EmptyView()
        case .accessoryInline: EmptyView()
        @unknown default: EmptyView()
        }
    }
}

// MARK: Small Widget
struct smallWidget: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "document.viewfinder")
                    .font(.system(size: 50))
                    .foregroundStyle(Color("AccentColor").gradient)
                    .widgetAccentable()
                
                Spacer()
            }
            
            Spacer()
            
            Text("Scan a new")
                .fontWeight(.bold)
                .widgetAccentable()
            
            Text("Document")
                .fontWeight(.bold)
                .widgetAccentable()
        }
        .padding(15)
    }
}

// MARK: Accessory Circular Widget
struct circularWidget: View {
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .fill(.ultraThinMaterial)
            VStack {
                Image(systemName: "document.viewfinder")
                    .font(.system(size: 35))
            }
        }
    }
}

// MARK: Entry point for the widget
struct ScanDocWidget: Widget {
    let kind: String = "app.DocMatic.scanDocWidget"
    
    // MARK: Configures the widget
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScanDocProvider()) { entry in
            Link(destination: URL(string: "docmatic://scan")!) {
                YourWidgetEntryView(entry: entry)
                    .containerBackground(Color("WidgetBackground"), for: .widget)
            }
        }
        .configurationDisplayName("Quick Scan")
        .description("Scan a document from your lock/home screen.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
        .contentMarginsDisabled()
    }
}

// MARK: SwiftUI previews for different widget sizes
#Preview(as: .systemSmall) {
    ScanDocWidget()
} timeline: {
    ScanDocEntry(date: .now, family: .systemSmall)
}

#Preview(as: .accessoryCircular) {
    ScanDocWidget()
} timeline: {
    ScanDocEntry(date: .now, family: .accessoryCircular)
}
