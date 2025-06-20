//
//  DocMatic_widget.swift
//  DocMatic.widget
//
//  Created by Paul  on 6/15/25.
//

import WidgetKit
import SwiftUI
import SwiftData

struct DocumentProvider: TimelineProvider {
    @MainActor
    func placeholder(in context: Context) -> DocumentEntry {
        DocumentEntry(date: Date(), scannedDocs: [], family: context.family)
    }
    
    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (DocumentEntry) -> ()) {
        let docs = getScannedDocumentSnapshots()
        completion(DocumentEntry(date: Date(), scannedDocs: docs, family: context.family))
    }
    
    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<DocumentEntry>) -> ()) {
        let docs = getScannedDocumentSnapshots()
        var entries: [DocumentEntry] = []
        
        let entry = DocumentEntry(date: .now, scannedDocs: docs, family: context.family)
        entries.append(entry)
        
        // MARK: Refresh the widget 60 seconds later
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date().addingTimeInterval(60)
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        
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

struct DocumentEntry: TimelineEntry {
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

struct DocumentEntryView: View {
    var entry: DocumentEntry
    
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
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text(entry.family == .systemSmall ? "Recent" : "Recent Documents")
                        .font(.headline.bold())
                        .widgetAccentable()
                    Spacer()
                    Image(systemName: "viewfinder.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color("AccentColor").gradient)
                        .widgetAccentable()
                        .clipShape(Circle())
                }
                .padding(.leading, 10)
                
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
                Spacer()
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .frame(width: 35, height: 35)
                .padding(5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(doc.name)
                    .font(.caption.bold())
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
                .widgetAccentable()
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

struct DocViewerWidget: Widget {
    let kind: String = "app.DocMatic.DocViewer_Widget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DocumentProvider()) { entry in
            DocumentEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
                .modelContainer(for: Document.self)
        }
        .configurationDisplayName("Recent Documents")
        .description("Quick access to your recently scanned documents.")
        .supportedFamilies([.systemSmall,.systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    DocViewerWidget()
} timeline: {
    DocumentEntry(
        date: .now,
        scannedDocs: [
            DocumentSnapshot(id: "1", name: "Simple", createdAt: Date(timeIntervalSinceNow: -86400), isLocked: false)
        ],
        family: .systemSmall
    )
}

#Preview(as: .systemMedium) {
    DocViewerWidget()
} timeline: {
    DocumentEntry(
        date: .now,
        scannedDocs: [
            DocumentSnapshot(id: "1", name: "Simple", createdAt: Date(timeIntervalSinceNow: -86400), isLocked: false),
            DocumentSnapshot(id: "2", name: "Simple 2", createdAt: Date(timeIntervalSinceNow: -172800), isLocked: false)
        ],
        family: .systemMedium
    )
}

#Preview(as: .systemLarge) {
    DocViewerWidget()
} timeline: {
    DocumentEntry(
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
