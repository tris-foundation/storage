/******************************************************************************
 *                                                                            *
 * Tris Foundation disclaims copyright to this source code.                   *
 * In place of a legal notice, here is a blessing:                            *
 *                                                                            *
 *     May you do good and not evil.                                          *
 *     May you find forgiveness for yourself and forgive others.              *
 *     May you share freely, never taking more than you give.                 *
 *                                                                            *
 ******************************************************************************/

import Test
import File
import HTTP
import Fiber
import Stream
import MessagePack
import struct Foundation.UUID

@testable import Async
@testable import Server

extension String: Swift.Error {}

final class ServerTests: TestCase {
    let temp = Path(string: "/tmp/ServerTests")

    override func setUp() {
        async.setUp(Fiber.self)
    }

    func testServer() {
        scope {
            let storage = try Storage(at: temp.appending(#function))
            assertNotNil(try Server(for: storage))
        }
    }
}
