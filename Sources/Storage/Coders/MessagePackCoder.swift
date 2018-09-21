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

import File
import Stream
import MessagePack

final class MessagePackCoder: StreamCoder {
    func next<T>(_ type: T.Type, from reader: StreamReader) throws -> T?
        where T: Decodable
    {
        do {
            return try MessagePack.decode(type, from: reader)
        } catch let error as StreamError where error == .insufficientData {
            return nil
        }
    }

    func write<T>(_ record: T, to writer: StreamWriter) throws
        where T: Encodable
    {
        try MessagePack.encode(encodable: record, to: writer)
    }
}
