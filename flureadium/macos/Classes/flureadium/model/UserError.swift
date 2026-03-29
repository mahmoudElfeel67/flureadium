//
//  Copyright 2025 Readium Foundation. All rights reserved.
//  Use of this source code is governed by the BSD-style license
//  available in the top-level LICENSE file of the project.
//

import Foundation
import SwiftUI
import AppKit

/// An error that should be displayed to the user.
struct UserError: LocalizedError {
    let message: String
    let cause: Error?

    init(_ error: Error) {
        if let error = error as? UserErrorConvertible {
            self = error.userError()
        } else {
            self.init("error".localized, cause: error)
        }
    }

    init(
        _ message: String,
        cause: Error? = nil
    ) {
        self.message = message
        self.cause = cause
    }

    init(
        cause: Error? = nil,
        message: () -> String
    ) {
        self.init(message(), cause: cause)
    }

    var errorDescription: String? { message }
}

protocol UserErrorConvertible {
    func userError() -> UserError
}

extension UserError: UserErrorConvertible {
    func userError() -> UserError {
        self
    }
}

// macOS: NSViewController + NSAlert instead of UIViewController + UIAlertController
extension NSViewController {
    func alert<T: UserErrorConvertible>(_ error: T) {
        let error = error.userError()

        var dumpDescription = ""
        dump(error, to: &dumpDescription)
        print(dumpDescription)

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = error.message
            alert.informativeText = dumpDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Close")
            alert.runModal()
        }
    }
}

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func localized(_ values: CVarArg...) -> String {
        localized(values)
    }

    func localized(_ values: [CVarArg]) -> String {
        var string = localized
        if !values.isEmpty {
            string = String(format: string, locale: Locale.current, arguments: values)
        }
        return string
    }
}
