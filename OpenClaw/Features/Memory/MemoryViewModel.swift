import Foundation
import Observation

@Observable
@MainActor
final class MemoryViewModel {
    var files: [MemoryFile] = []
    var isLoadingFiles = false
    var fileError: Error?

    var skills: [SkillFile] = []
    var isLoadingSkills = false
    var skillError: Error?

    var skillFiles: [SkillFileEntry] = []
    var isLoadingSkillFiles = false
    var skillFilesError: Error?

    var fileContent: MemoryFileContent?
    var isLoadingContent = false
    var contentError: Error?

    var comments: [MemoryComment] = []

    var isSubmitting = false
    var submitResult: String?
    var submitError: Error?

    private let repository: MemoryRepository
    private let client: GatewayClientProtocol

    init(repository: MemoryRepository, client: GatewayClientProtocol) {
        self.repository = repository
        self.client = client
    }

    // MARK: - File List

    func loadFiles() async {
        isLoadingFiles = true
        do {
            files = try await repository.listFiles()
            fileError = nil
        } catch {
            fileError = error
        }
        isLoadingFiles = false
    }

    // MARK: - Skills List

    func loadSkills() async {
        isLoadingSkills = true
        do {
            skills = try await repository.listSkills()
            skillError = nil
        } catch {
            skillError = error
        }
        isLoadingSkills = false
    }

    // MARK: - Skill Files

    func loadSkillFiles(_ skill: SkillFile) async {
        skillFiles = []
        isLoadingSkillFiles = true
        skillFilesError = nil
        do {
            skillFiles = try await repository.listSkillFiles(skillId: skill.id)
        } catch {
            skillFilesError = error
        }
        isLoadingSkillFiles = false
    }

    // MARK: - Skill File Content (via stats/exec)

    func loadSkillFileContent(_ entry: SkillFileEntry) async {
        fileContent = nil
        isLoadingContent = true
        contentError = nil
        do {
            let text = try await repository.readSkillFile(skillId: entry.skillId, relativePath: entry.id)
            fileContent = MemoryFileContent(path: entry.absolutePath, text: text)
        } catch {
            contentError = error
        }
        isLoadingContent = false
    }

    // MARK: - File Content

    func loadFile(_ file: MemoryFile) async {
        fileContent = nil
        isLoadingContent = true
        contentError = nil
        comments = []
        submitResult = nil
        submitError = nil
        do {
            let content = try await repository.readFile(path: file.path)
            if content.isEmpty {
                contentError = MemoryError.fileNotFound(file.path)
            } else {
                fileContent = content
            }
        } catch {
            contentError = error
        }
        isLoadingContent = false
    }

    // MARK: - Comments

    func addComment(paragraphId: String, lineStart: Int, lineEnd: Int, text: String, preview: String) {
        comments.append(MemoryComment(
            id: UUID(),
            paragraphId: paragraphId,
            lineStart: lineStart,
            lineEnd: lineEnd,
            text: text,
            paragraphPreview: String(preview.prefix(300))
        ))
        Haptics.shared.success()
    }

    func removeComment(_ id: UUID) {
        comments.removeAll { $0.id == id }
    }

    func commentsForParagraph(_ id: String) -> [MemoryComment] {
        comments.filter { $0.paragraphId == id }
    }

    func clearComments() {
        comments.removeAll()
        submitResult = nil
        submitError = nil
    }

    // MARK: - Page Comment

    var pageCommentResult: String?
    var isSubmittingPageComment = false
    var pageCommentError: Error?

    func submitPageComment(path: String, instruction: String) async {
        let prompt = PromptTemplates.pageComment(path: path, instruction: instruction)
        await submitAgentComment(prompt: prompt)
    }

    func submitSkillComment(skill: SkillFile, files: [String], instruction: String) async {
        let prompt = PromptTemplates.skillComment(
            skillId: skill.id,
            skillName: skill.displayName,
            files: files,
            instruction: instruction
        )
        await submitAgentComment(prompt: prompt)
    }

    private func submitAgentComment(prompt: (system: String, user: String)) async {
        isSubmittingPageComment = true
        pageCommentError = nil
        pageCommentResult = nil

        let request = ChatCompletionRequest(system: prompt.system, user: prompt.user)

        do {
            let response = try await client.chatCompletion(request, sessionKey: SessionKeys.main)
            pageCommentResult = response.text ?? "Agent returned no content."
            Haptics.shared.success()
        } catch {
            pageCommentError = error
            Haptics.shared.error()
        }
        isSubmittingPageComment = false
    }

    func clearPageComment() {
        pageCommentResult = nil
        pageCommentError = nil
    }

    // MARK: - Maintenance Actions

    var maintenanceResult: String?
    var isRunningMaintenance = false
    var maintenanceError: Error?

    func runMaintenanceAction(prompt: (system: String, user: String)) async {
        isRunningMaintenance = true
        maintenanceError = nil
        maintenanceResult = nil

        let request = ChatCompletionRequest(system: prompt.system, user: prompt.user)

        do {
            let response = try await client.chatCompletion(request, sessionKey: SessionKeys.main)
            maintenanceResult = response.text ?? "Agent returned no content."
            Haptics.shared.success()
        } catch {
            maintenanceError = error
            Haptics.shared.error()
        }
        isRunningMaintenance = false
    }

    // MARK: - Submit Edits

    func submitEdits(for file: MemoryFile) async {
        guard let content = fileContent else { return }
        isSubmitting = true
        submitError = nil

        let prompt = PromptTemplates.editMemoryFile(
            path: file.path,
            fullText: content.text,
            comments: comments
        )

        let request = ChatCompletionRequest(system: prompt.system, user: prompt.user)

        do {
            let response = try await client.chatCompletion(
                request,
                sessionKey: SessionKeys.main
            )
            submitResult = response.text ?? "Agent returned no content."
            Haptics.shared.success()
        } catch {
            submitError = error
            Haptics.shared.error()
        }
        isSubmitting = false
    }
}

enum MemoryError: LocalizedError {
    case fileNotFound(String)
    case commandFailed(command: String, exitCode: Int, stderr: String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            "File not found: \(path)"
        case .commandFailed(let command, let exitCode, let stderr):
            "Command '\(command)' failed (exit \(exitCode))\(stderr.isEmpty ? "" : ": \(stderr)")"
        }
    }
}
