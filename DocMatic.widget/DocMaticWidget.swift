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
        var entries: [SimpleEntry] = []
        let entry = SimpleEntry(date: .now, scannedDocs: docs, family: context.family)
        entries.append(entry)
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
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
                createdAt: $0.createdAt,
                isLocked: $0.isLocked
            )
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let scannedDocs: [DocumentSnapshot]
    let family: WidgetFamily
}

struct DocumentSnapshot: Identifiable {
    let id: String
    let name: String
    let createdAt: Date
    let isLocked: Bool
}

struct DocMatic_widgetEntryView: View {
    var entry: SimpleEntry
    
    var maxDocumentsToShow: Int {
        switch entry.family {
        case .systemSmall: return 1
        case .systemMedium: return 2
        case .systemLarge: return 8
        case .systemExtraLarge: return 12
        default: return 1
        }
    }
    
    let singleColumn = [GridItem(.flexible())]
    let twoColumns = [GridItem(.flexible()), GridItem(.flexible())]
    let threeColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ZStack {
            if entry.scannedDocs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: entry.family == .systemMedium ? "" : "doc.text")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.gray.opacity(0.6))
                    
                    Text("No Documents Yet!")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("Scan your first document to get started.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.family == .systemSmall ? "Recent Docs" : "Recent Documents")
                        .font(.headline.bold())
                    Spacer()
                    Image(systemName: "viewfinder.circle.fill")
                        .foregroundStyle(Color("Default"))
                        .font(.title)
                        .clipShape(Circle())
                }
                
                if !entry.scannedDocs.isEmpty {
                    LazyVGrid(
                        columns: entry.family == .systemExtraLarge
                        ? threeColumns
                        : (entry.family == .systemMedium || entry.family == .systemLarge
                           ? twoColumns
                           : singleColumn),
                        spacing: 10
                    ) {
                        ForEach(entry.scannedDocs.prefix(maxDocumentsToShow)) { doc in
                            DocumentCard(doc: doc)
                        }
                    }
                }
            }
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
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray5))
        )
    }
    
    var icon: Image {
        if doc.isLocked {
            return Image(systemName: "lock.doc")
        } else if doc.name.lowercased().hasSuffix(".pdf") {
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
            DocMatic_widgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .modelContainer(for: Document.self)
        }
        .configurationDisplayName("Recent Documents")
        .description("Quick access to your recently scanned documents.")
        .supportedFamilies([.systemSmall,.systemMedium, .systemLarge, .systemExtraLarge])
    }
}

#Preview(as: .systemLarge) {
    DocMaticWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        scannedDocs: [
            DocumentSnapshot(id: "1", name: "Simple", createdAt: Date(timeIntervalSinceNow: -86400), isLocked: false),
            DocumentSnapshot(id: "2", name: "Simple 2", createdAt: Date(timeIntervalSinceNow: -172800), isLocked: false),
            DocumentSnapshot(id: "3", name: "Image", createdAt: Date(timeIntervalSinceNow: -259200), isLocked: false),
            DocumentSnapshot(id: "4", name: "Checklist", createdAt: Date(timeIntervalSinceNow: -345600), isLocked: false),
            DocumentSnapshot(id: "5", name: "Simple Doc", createdAt: Date(timeIntervalSinceNow: -86400), isLocked: true),
            DocumentSnapshot(id: "6", name: "Simple Doc 2", createdAt: Date(timeIntervalSinceNow: -172800), isLocked: false),
            DocumentSnapshot(id: "7", name: "Image Note", createdAt: Date(timeIntervalSinceNow: -259200), isLocked: false)
        ],
        family: .systemLarge
    )
}
