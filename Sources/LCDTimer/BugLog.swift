import BugKit
import Foundation

/// Story 014: each launch's JSONL session log and the crash files, under Application Support. bug-kit defaults to
/// Documents, which for an unsandboxed Mac app is the user's real ~/Documents (bug-kit#29).
enum BugLog {
    static let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("LCD Timer", isDirectory: true)

    /// Opened on first use, which the App makes early: writes `session_start`, then installs the crash handlers,
    /// which announce any crash an earlier run left as `crash_report`.
    static let session: SessionLog = {
        let info = Bundle.main.infoDictionary
        let log = SessionLog(
            prefix: "lcdtimer", documents: folder,
            fields: [
                "version": .string(info?["CFBundleShortVersionString"] as? String ?? "dev"),
                "build": .string(info?["CFBundleVersion"] as? String ?? "dev"),
                "system": .string(ProcessInfo.processInfo.operatingSystemVersionString),
            ])
        let crashes = folder.appendingPathComponent("crashes", isDirectory: true)
        CrashReports.shared.install(folder: crashes, logger: log.logger)
        return log
    }()
}
