//
//  ItemListItemView.swift
//  ReadyKit
//
//  Created by Luis Wu on 2025/8/15.
//

import SwiftUI

/// Reusable list item component for displaying item information
struct ItemListItemView: View {
    let item: Item
    let expirationStatus: (text: String, color: Color)
    let onTap: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    @State private var showingPhotoViewer = false

    var body: some View {
        HStack(spacing: AppConstants.UI.Spacing.medium) {
            // Emergency kit photo or placeholder
            if let photoData = item.photo,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: AppConstants.UI.Thumbnail.width, height: AppConstants.UI.Thumbnail.height)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.UI.cornerRadius))
                    .onTapGesture {
                        showingPhotoViewer = true
                    }
            } else {
                RoundedRectangle(cornerRadius:AppConstants.UI.Thumbnail.height)
                    .fill(Color.gray.opacity(AppConstants.UI.opacity))
                    .frame(width: AppConstants.UI.Thumbnail.width, height: AppConstants.UI.Thumbnail.height)
                    .overlay {
                        Image(systemName: "cube")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
            }
            VStack(alignment: .leading, spacing: AppConstants.UI.Spacing.small) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)

                Text("\(item.quantityValue) \(item.quantityUnitName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(expirationStatus.text)
                    .font(.caption)
                    .foregroundColor(expirationStatus.color)

                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, AppConstants.UI.Spacing.small)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                onDuplicate()
            } label: {
                Label(String(localized: "Copy"), systemImage: "doc.on.doc")
            }
            .tint(.blue)
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(String(localized: "Delete"), systemImage: "trash")
            }
        }
        .fullScreenCover(isPresented: $showingPhotoViewer) {
            if let photoData = item.photo {
                PhotoViewerView(imageData: photoData)
            }
        }
    }
}

#Preview("Expired Food Item") {
    let expiredItem = try! Item(
        name: "Canned Beans",
        expirationDate: Calendar.current.date(byAdding: .day, value: -15, to: Date()),
        notes: "Protein-rich emergency food supply",
        quantityValue: 6,
        quantityUnitName: "cans"
    )

    ItemListItemView(
        item: expiredItem,
        expirationStatus: (text: "Expired 15 days ago", color: .red),
        onTap: { print("Tapped expired item: \(expiredItem.name)") },
        onDuplicate: { print("Duplicated expired item: \(expiredItem.name)") },
        onDelete: { print("Deleted expired item: \(expiredItem.name)") }
    )
    .padding()
}

#Preview("Expiring Soon Medical") {
    let expiringSoonItem = try! Item(
        name: "Pain Relief Medication",
        expirationDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
        notes: "Keep in first aid kit. Check temperature storage requirements.",
        quantityValue: 24,
        quantityUnitName: "tablets"
    )

    ItemListItemView(
        item: expiringSoonItem,
        expirationStatus: (text: "Expires in 7 days", color: .orange),
        onTap: { print("Tapped expiring item: \(expiringSoonItem.name)") },
        onDuplicate: { print("Duplicated expiring item: \(expiringSoonItem.name)") },
        onDelete: { print("Deleted expiring item: \(expiringSoonItem.name)") }
    )
    .padding()
}

#Preview("Fresh Item") {
    let freshItem = try! Item(
        name: "Bottled Water",
        expirationDate: Calendar.current.date(byAdding: .year, value: 2, to: Date()),
        notes: nil,
        quantityValue: 12,
        quantityUnitName: "bottles"
    )

    ItemListItemView(
        item: freshItem,
        expirationStatus: (text: "Expires in 2 years", color: .green),
        onTap: { print("Tapped fresh item: \(freshItem.name)") },
        onDuplicate: { print("Duplicated fresh item: \(freshItem.name)") },
        onDelete: { print("Deleted fresh item: \(freshItem.name)") }
    )
    .padding()
}

#Preview("No Expiration") {
    let noExpirationItem = try! Item(
        name: "Emergency Radio",
        expirationDate: nil,
        notes: "Solar powered with hand crank backup. Weather alerts enabled.",
        quantityValue: 1,
        quantityUnitName: "piece"
    )

    ItemListItemView(
        item: noExpirationItem,
        expirationStatus: (text: "No expiration", color: .secondary),
        onTap: { print("Tapped non-expiring item: \(noExpirationItem.name)") },
        onDuplicate: { print("Duplicated non-expiring item: \(noExpirationItem.name)") },
        onDelete: { print("Deleted non-expiring item: \(noExpirationItem.name)") }
    )
    .padding()
}

#Preview("Item Without Notes") {
    let itemWithoutNotes = try! Item(
        name: "Flashlight Batteries",
        expirationDate: Calendar.current.date(byAdding: .year, value: 5, to: Date()),
        notes: nil,
        quantityValue: 8,
        quantityUnitName: "pieces"
    )

    ItemListItemView(
        item: itemWithoutNotes,
        expirationStatus: (text: "Expires in 5 years", color: .green),
        onTap: { print("Tapped item without notes: \(itemWithoutNotes.name)") },
        onDuplicate: { print("Duplicated item without notes: \(itemWithoutNotes.name)") },
        onDelete: { print("Deleted item without notes: \(itemWithoutNotes.name)") }
    )
    .padding()
}

#Preview("List of Items") {
    let items: [(Item, (String, Color))] = [
        (try! Item(name: "First Aid Bandages", expirationDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()), notes: "Sterile adhesive bandages", quantityValue: 20, quantityUnitName: "pieces"), ("Expired 5 days ago", .red)),
        (try! Item(name: "Energy Bars", expirationDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()), notes: "High calorie emergency food", quantityValue: 12, quantityUnitName: "bars"), ("Expires in 30 days", .orange)),
        (try! Item(name: "Water Purification Tablets", expirationDate: Calendar.current.date(byAdding: .year, value: 3, to: Date()), notes: nil, quantityValue: 50, quantityUnitName: "tablets"), ("Expires in 3 years", .green)),
        (try! Item(name: "Multi-tool", expirationDate: nil, notes: "Swiss army knife with essential tools", quantityValue: 1, quantityUnitName: "piece"), ("No expiration", .secondary))
    ]

    List {
        ForEach(Array(items.enumerated()), id: \.offset) { index, itemData in
            let (item, status) = itemData
            ItemListItemView(
                item: item,
                expirationStatus: status,
                onTap: { print("Tapped item \(index): \(item.name)") },
                onDuplicate: { print("Duplicated item \(index): \(item.name)") },
                onDelete: { print("Deleted item \(index): \(item.name)") }
            )
        }
    }
}
