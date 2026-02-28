//
//  ScheduleView.swift
//  AcuMobile
//

import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var app: AppState
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(app.departurePlans) { plan in
                    NavigationLink {
                        EditDeparturePlanView(plan: plan) { updated in
                            app.updateDeparturePlan(updated)
                        } onDelete: {
                            app.removeDeparturePlan(id: plan.id)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.label)
                                    .font(.headline)
                                Text(weekdaySummary(plan.weekdays))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(timeString(plan.time))
                                .font(.subheadline.monospacedDigit())
                        }
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        app.removeDeparturePlan(id: app.departurePlans[i].id)
                    }
                }
            }
            .navigationTitle("Schedule")
            .onAppear { app.refreshDeparturePlans() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAdd = true
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddDeparturePlanView { plan in
                    app.addDeparturePlan(plan)
                    showAdd = false
                } onCancel: {
                    showAdd = false
                }
            }
        }
    }

    private func weekdaySummary(_ weekdays: Set<Int>?) -> String {
        guard let w = weekdays, !w.isEmpty else { return "Every day" }
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sorted = w.sorted()
        if sorted.count == 7 { return "Every day" }
        return sorted.map { names[$0 - 1] }.joined(separator: ", ")
    }

    private func timeString(_ t: TimeOfDay) -> String {
        let h = t.hour, m = t.minute
        let period = h >= 12 ? "PM" : "AM"
        let hour12 = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", hour12, m, period)
    }
}

// MARK: - Add plan

struct AddDeparturePlanView: View {
    @State private var label = ""
    @State private var time = Date()
    @State private var weekdays: Set<Int> = Set(1...7)
    @State private var useAllDays = true
    let onSave: (DeparturePlan) -> Void
    let onCancel: () -> Void

    private let weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Label", text: $label)
                    .textInputAutocapitalization(.words)
                DatePicker("Departure time", selection: $time, displayedComponents: .hourAndMinute)
                Toggle("Every day", isOn: $useAllDays)
                if !useAllDays {
                    ForEach(1...7, id: \.self) { day in
                        Toggle(weekdayNames[day - 1], isOn: Binding(
                            get: { weekdays.contains(day) },
                            set: { if $0 { weekdays.insert(day) } else { weekdays.remove(day) } }
                        ))
                    }
                }
            }
            .navigationTitle("New departure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let plan = DeparturePlan(
                            label: label.isEmpty ? "Departure" : label,
                            weekdays: useAllDays ? nil : weekdays,
                            time: TimeOfDay.from(time)
                        )
                        onSave(plan)
                    }
                }
            }
        }
    }
}

// MARK: - Edit plan

struct EditDeparturePlanView: View {
    let plan: DeparturePlan
    let onSave: (DeparturePlan) -> Void
    let onDelete: () -> Void

    @State private var label: String = ""
    @State private var time: Date = Date()
    @State private var weekdays: Set<Int> = Set(1...7)
    @State private var useAllDays = true
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss

    private let weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        Form {
            TextField("Label", text: $label)
            DatePicker("Departure time", selection: $time, displayedComponents: .hourAndMinute)
            Toggle("Every day", isOn: $useAllDays)
            if !useAllDays {
                ForEach(1...7, id: \.self) { day in
                    Toggle(weekdayNames[day - 1], isOn: Binding(
                        get: { weekdays.contains(day) },
                        set: { if $0 { weekdays.insert(day) } else { weekdays.remove(day) } }
                    ))
                }
            }
            Section {
                Button(role: .destructive) { showDeleteConfirm = true } label: {
                    Text("Delete departure")
                }
            }
        }
        .navigationTitle("Edit departure")
        .onAppear {
            label = plan.label
            var comp = DateComponents()
            comp.hour = plan.time.hour
            comp.minute = plan.time.minute
            time = Calendar.current.date(from: comp) ?? Date()
            if let w = plan.weekdays {
                weekdays = w
                useAllDays = w.count == 7
            }
        }
        .onChange(of: label) { _, _ in saveIfNeeded() }
        .onChange(of: time) { _, _ in saveIfNeeded() }
        .onChange(of: weekdays) { _, _ in saveIfNeeded() }
        .onChange(of: useAllDays) { _, _ in saveIfNeeded() }
        .alert("Delete departure?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
        } message: {
            Text("This cannot be undone.")
        }
    }

    private func saveIfNeeded() {
        var updated = plan
        updated.label = label
        updated.time = TimeOfDay.from(time)
        updated.weekdays = useAllDays ? nil : weekdays
        onSave(updated)
    }
}

#Preview {
    ScheduleView()
        .environmentObject(AppState())
}
