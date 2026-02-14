import SwiftUI

struct SettingsView: View {
    @StateObject private var excludeStore = ExcludeListStore.shared
    @State private var newWord = ""

    var body: some View {
        TabView {
            ExcludeListView(store: excludeStore, newWord: $newWord)
                .tabItem { Label("Exclude คำ", systemImage: "list.bullet") }

            AboutTab()
                .tabItem { Label("เกี่ยวกับ", systemImage: "info.circle") }
        }
        .frame(minWidth: 400, minHeight: 320)
    }
}

struct ExcludeListView: View {
    @ObservedObject var store: ExcludeListStore
    @Binding var newWord: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("คำที่ไม่ต้องการให้ PimPid แก้ไข")
                .font(.headline)

            Text("เพิ่มคำหรือวลีที่ต้องการยกเว้น (ไม่แปลงภาษา)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                TextField("พิมพ์คำแล้วกด Add", text: $newWord)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { addWord() }
                    .accessibilityLabel("คำที่ต้องการยกเว้น")
                    .accessibilityHint("พิมพ์คำหรือวลีที่ไม่ต้องการให้ PimPid แปลง แล้วกด Add")
                Button("Add") { addWord() }
                    .accessibilityLabel("เพิ่มคำ")
                    .accessibilityHint("เพิ่มคำนี้เข้ารายการยกเว้น")
            }

            List {
                ForEach(Array(store.words).sorted(), id: \.self) { word in
                    HStack {
                        Text(word)
                        Spacer()
                        Button(role: .destructive) {
                            store.remove(word)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("ลบคำ \(word)")
                        .accessibilityHint("เอาคำนี้ออกจากรายการยกเว้น")
                    }
                }
            }
            .listStyle(.inset)
        }
        .padding()
    }

    private func addWord() {
        let w = newWord.trimmingCharacters(in: .whitespaces)
        guard !w.isEmpty else { return }
        store.add(w)
        newWord = ""
    }
}

struct AboutTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PimPid")
                .font(.title2.bold())
            Text("สลับภาษาข้อความที่เลือก (ไทย↔อังกฤษ ตามตำแหน่งปุ่มคีย์บอร์ด)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Shortcut: ⌘⇧L — เลือกข้อความที่ผิดภาษา แล้วกดเพื่อแปลง")
                .font(.caption)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}
