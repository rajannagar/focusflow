//
//  TasksSyncEngine.swift
//  FocusFlow
//
//  Syncs FFTaskItem ↔ tasks table
//  Syncs completedOccurrenceKeys ↔ task_completions table
//

import Foundation
import Combine
import Supabase

// MARK: - Remote Models

/// Matches the `tasks` table schema
struct TaskDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var title: String
    var notes: String?
    var reminderDate: Date?
    var repeatRule: String
    var customWeekdays: [Int]
    var durationMinutes: Int
    var convertToPreset: Bool
    var presetCreated: Bool
    var excludedDayKeys: [String]
    var sortIndex: Int
    var isArchived: Bool
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case notes
        case reminderDate = "reminder_date"
        case repeatRule = "repeat_rule"
        case customWeekdays = "custom_weekdays"
        case durationMinutes = "duration_minutes"
        case convertToPreset = "convert_to_preset"
        case presetCreated = "preset_created"
        case excludedDayKeys = "excluded_day_keys"
        case sortIndex = "sort_index"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Matches the `task_completions` table schema
struct TaskCompletionDTO: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let taskId: UUID
    let dayKey: String
    var completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case taskId = "task_id"
        case dayKey = "day_key"
        case completedAt = "completed_at"
    }
}

// MARK: - Sync Engine

@MainActor
final class TasksSyncEngine {
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    private var userId: UUID?
    
    private var isApplyingRemote = false
    
    // MARK: - Start/Stop
    
    func start(userId: UUID) async throws {
        self.userId = userId
        self.isRunning = true
        
        // Initial pull
        try await pullFromRemote(userId: userId)
        
        // Observe local changes
        observeLocalChanges()
    }
    
    func stop() {
        isRunning = false
        userId = nil
        cancellables.removeAll()
    }
    
    // MARK: - Pull from Remote
    
    func pullFromRemote(userId: UUID) async throws {
        let db = SupabaseManager.shared.database
        
        // Fetch tasks
        let remoteTasks: [TaskDTO] = try await db
            .from("tasks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("is_archived", value: false)
            .order("sort_index", ascending: true)
            .execute()
            .value
        
        // Fetch completions
        let remoteCompletions: [TaskCompletionDTO] = try await db
            .from("task_completions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        applyRemoteToLocal(tasks: remoteTasks, completions: remoteCompletions)
        
        #if DEBUG
        print("[TasksSyncEngine] Pulled \(remoteTasks.count) tasks, \(remoteCompletions.count) completions")
        #endif
    }
    
    // MARK: - Push to Remote
    
    private func pushToRemote() async {
        guard isRunning, let userId = userId else { return }
        guard !isApplyingRemote else { return }
        
        let store = TasksStore.shared
        let db = SupabaseManager.shared.database
        
        // Convert local tasks to DTOs
        let taskDTOs = store.tasks.map { task -> TaskDTO in
            TaskDTO(
                id: task.id,
                userId: userId,
                title: task.title,
                notes: task.notes,
                reminderDate: task.reminderDate,
                repeatRule: task.repeatRule.rawValue,
                customWeekdays: Array(task.customWeekdays),
                durationMinutes: task.durationMinutes,
                convertToPreset: task.convertToPreset,
                presetCreated: task.presetCreated,
                excludedDayKeys: Array(task.excludedDayKeys),
                sortIndex: task.sortIndex,
                isArchived: false
            )
        }
        
        do {
            // Upsert tasks
            if !taskDTOs.isEmpty {
                try await db
                    .from("tasks")
                    .upsert(taskDTOs, onConflict: "id")
                    .execute()
            }
            
            // For completions, we need to handle adds/removes
            // First, get existing remote completions
            let existingRemote: [TaskCompletionDTO] = try await db
                .from("task_completions")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            let existingKeys = Set(existingRemote.map { "\($0.taskId.uuidString)|\($0.dayKey)" })
            let localKeys = store.completedOccurrenceKeys
            
            // Add new completions
            let toAdd = localKeys.subtracting(existingKeys)
            if !toAdd.isEmpty {
                var newCompletions: [TaskCompletionDTO] = []
                for key in toAdd {
                    let parts = key.split(separator: "|")
                    guard parts.count == 2,
                          let taskId = UUID(uuidString: String(parts[0])) else { continue }
                    newCompletions.append(TaskCompletionDTO(
                        id: UUID(),
                        userId: userId,
                        taskId: taskId,
                        dayKey: String(parts[1])
                    ))
                }
                if !newCompletions.isEmpty {
                    try await db
                        .from("task_completions")
                        .insert(newCompletions)
                        .execute()
                }
            }
            
            // Remove deleted completions
            let toRemove = existingKeys.subtracting(localKeys)
            for key in toRemove {
                let parts = key.split(separator: "|")
                guard parts.count == 2,
                      let taskId = UUID(uuidString: String(parts[0])) else { continue }
                let dayKey = String(parts[1])
                
                try await db
                    .from("task_completions")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("task_id", value: taskId.uuidString)
                    .eq("day_key", value: dayKey)
                    .execute()
            }
            
            #if DEBUG
            print("[TasksSyncEngine] Pushed tasks and completions to remote")
            #endif
        } catch {
            #if DEBUG
            print("[TasksSyncEngine] Push error: \(error)")
            #endif
        }
    }
    
    // MARK: - Delete Task
    
    func deleteTaskRemote(taskId: UUID) async {
        guard isRunning, let userId = userId else { return }
        
        do {
            // Archive instead of hard delete (preserves data)
            try await SupabaseManager.shared.database
                .from("tasks")
                .update(["is_archived": true])
                .eq("id", value: taskId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            #if DEBUG
            print("[TasksSyncEngine] Archived task \(taskId)")
            #endif
        } catch {
            #if DEBUG
            print("[TasksSyncEngine] Delete error: \(error)")
            #endif
        }
    }
    
    // MARK: - Apply Remote to Local
    
    private func applyRemoteToLocal(tasks: [TaskDTO], completions: [TaskCompletionDTO]) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }
        
        let store = TasksStore.shared
        
        // Convert DTOs to local models
        var localTasks: [FFTaskItem] = []
        for dto in tasks {
            // Use FFTaskRepeatRule (the actual enum name in your project)
            let repeatRule = FFTaskRepeatRule(rawValue: dto.repeatRule) ?? .none
            
            let task = FFTaskItem(
                id: dto.id,
                sortIndex: dto.sortIndex,
                title: dto.title,
                notes: dto.notes,
                reminderDate: dto.reminderDate,
                repeatRule: repeatRule,
                customWeekdays: Set(dto.customWeekdays),
                durationMinutes: dto.durationMinutes,
                convertToPreset: dto.convertToPreset,
                presetCreated: dto.presetCreated,
                excludedDayKeys: Set(dto.excludedDayKeys),
                createdAt: dto.createdAt ?? Date()
            )
            localTasks.append(task)
        }
        
        // Build completion keys
        var completionKeys = Set<String>()
        for dto in completions {
            let key = "\(dto.taskId.uuidString)|\(dto.dayKey)"
            completionKeys.insert(key)
        }
        
        // Merge strategy: remote wins for now (can be made smarter with timestamps)
        store.applyRemoteState(tasks: localTasks, completionKeys: completionKeys)
        
        #if DEBUG
        print("[TasksSyncEngine] Applied \(localTasks.count) tasks, \(completionKeys.count) completions to local")
        #endif
    }
    
    // MARK: - Observe Local Changes
    
    private func observeLocalChanges() {
        let store = TasksStore.shared
        
        // Observe task list changes
        store.$tasks
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, self.isRunning, !self.isApplyingRemote else { return }
                Task {
                    await self.pushToRemote()
                }
            }
            .store(in: &cancellables)
        
        // Observe completion changes
        store.$completedOccurrenceKeys
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, self.isRunning, !self.isApplyingRemote else { return }
                Task {
                    await self.pushToRemote()
                }
            }
            .store(in: &cancellables)
    }
}
