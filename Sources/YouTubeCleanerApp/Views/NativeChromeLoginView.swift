import SwiftUI

struct NativeChromeLoginView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.12))
                    .frame(width: 76, height: 76)
                Image(systemName: "person.crop.circle.badge.key")
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)
            }

            VStack(spacing: 7) {
                Text("Sign in with Chrome")
                    .font(.title2.bold())
                Text("A dedicated Google Chrome window is open for YouTube Cleaner.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 13) {
                LoginStep(number: 1, text: "Sign in to YouTube in the Chrome window.")
                LoginStep(number: 2, text: "Select the YouTube profile you want to manage.")
                LoginStep(number: 3, text: "Return here and click Finish Login.")
            }
            .padding(16)
            .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))

            Text("You do not need to quit Chrome or press Command-Q. The app will close only its dedicated Chrome window and verify the profile automatically.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let error = model.nativeLoginError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.leading)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }

            HStack {
                Button("Cancel", role: .cancel) {
                    model.cancelNativeChromeLogin()
                }
                .disabled(model.nativeLoginFinishing)

                Spacer()

                Button {
                    model.finishNativeChromeLogin()
                } label: {
                    if model.nativeLoginLaunching {
                        HStack(spacing: 7) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Opening Chrome…")
                        }
                    } else if model.nativeLoginFinishing {
                        HStack(spacing: 7) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Closing Chrome…")
                        }
                    } else {
                        Text(model.nativeLoginError == nil ? "Finish Login" : "Try Again")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(model.nativeLoginLaunching || model.nativeLoginFinishing)
            }
        }
        .padding(28)
        .frame(width: 500)
    }
}

private struct LoginStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 11) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(.blue, in: Circle())
            Text(text)
            Spacer()
        }
    }
}
