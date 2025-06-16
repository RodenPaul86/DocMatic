//
//  DocMatic_widget.swift
//  DocMatic.widget
//
//  Created by Paul  on 6/15/25.
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    @MainActor
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), scannedDocs: [], family: context.family)
    }
    
    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let docs = getScannedDocumentSnapshots()
        completion(SimpleEntry(date: Date(), scannedDocs: docs, family: context.family))
    }
    
    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let docs = getScannedDocumentSnapshots()
        let entry = SimpleEntry(date: .now, scannedDocs: docs, family: context.family)
        let timeline = Timeline(entries: [entry], policy: .after(.now.advanced(by: 60 * 5)))
        completion(timeline)
    }
    
    @MainActor
    private func getScannedDocumentSnapshots() -> [DocumentSnapshot] {
        guard let modelContainer = try? ModelContainer(for: Document.self) else {
            return []
        }
        
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Document>(sortBy: [SortDescriptor(\Document.createdAt, order: .reverse)])
        
        guard let documents = try? context.fetch(descriptor) else {
            return []
        }
        
        return documents.map {
            DocumentSnapshot(
                id: $0.uniqueViewID,
                name: $0.name,
                createdAt: $0.createdAt
            )
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let scannedDocs: [DocumentSnapshot]
    let family: WidgetFamily
}

struct DocumentSnapshot: Identifiable, Hashable {
    let id: String
    let name: String
    let createdAt: Date
}

struct DocMatic_widgetEntryView: View {
    var entry: SimpleEntry

    var maxDocumentsToShow: Int {
        switch entry.family {
        case .systemSmall: return 1
        case .systemMedium: return 2
        case .systemLarge: return 8
        default: return 1
        }
    }

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.family == .systemSmall ? "Recent Docs" : "Recents Documents")
                    .font(.headline.bold())
                Spacer()
                Image(systemName: "viewfinder.circle.fill")
                    .font(.largeTitle)
                    .clipShape(Circle())
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(entry.scannedDocs.prefix(maxDocumentsToShow)) { doc in
                    DocumentCard(doc: doc)
                }
            }

            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

struct DocumentCard: View {
    let doc: DocumentSnapshot
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .padding(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(doc.name)
                    .font(.caption.bold())
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray5))
        )
    }
    
    var icon: Image {
        // Replace with actual logic based on file type
        if doc.name.lowercased().hasSuffix(".pdf") {
            return Image(systemName: "doc.richtext")
        } else if doc.name.lowercased().hasSuffix(".txt") {
            return Image(systemName: "doc.text")
        } else if doc.name.lowercased().hasSuffix(".jpg") || doc.name.lowercased().hasSuffix(".png") {
            return Image(systemName: "photo")
        } else {
            return Image(systemName: "doc")
        }
    }
}

struct DocMaticWidget: Widget {
    let kind: String = "DocMatic_widget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                DocMatic_widgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                DocMatic_widgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Recent Documents")
        .description("Quick access to your recent scanned documents.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    DocMaticWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        scannedDocs: [
            DocumentSnapshot(id: "1", name: "Simple PDF", createdAt: Date(timeIntervalSinceNow: -86400)),
            DocumentSnapshot(id: "2", name: "Simple TXT", createdAt: Date(timeIntervalSinceNow: -172800)),
            DocumentSnapshot(id: "3", name: "Image Note", createdAt: Date(timeIntervalSinceNow: -259200)),
            DocumentSnapshot(id: "4", name: "Checklist", createdAt: Date(timeIntervalSinceNow: -345600))
        ],
        family: .systemMedium
    )
}
