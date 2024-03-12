import Foundation;

struct APIKeyProvider {
    static func getApiKey() -> String {
        print(ProcessInfo.processInfo.environment["API_KEY"]!)
        return ProcessInfo.processInfo.environment["API_KEY"]!;
    }
}
