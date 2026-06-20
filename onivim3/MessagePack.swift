import Foundation

enum MessagePackValue: Equatable, Sendable {
    case nilValue
    case bool(Bool)
    case int(Int64)
    case uint(UInt64)
    case string(String)
    case binary(Data)
    case ext(Int8, Data)
    case array([MessagePackValue])
    case map([(MessagePackValue, MessagePackValue)])

    static func == (lhs: MessagePackValue, rhs: MessagePackValue) -> Bool {
        switch (lhs, rhs) {
        case (.nilValue, .nilValue):
            true
        case let (.bool(lhs), .bool(rhs)):
            lhs == rhs
        case let (.int(lhs), .int(rhs)):
            lhs == rhs
        case let (.uint(lhs), .uint(rhs)):
            lhs == rhs
        case let (.string(lhs), .string(rhs)):
            lhs == rhs
        case let (.binary(lhs), .binary(rhs)):
            lhs == rhs
        case let (.ext(lhsType, lhsData), .ext(rhsType, rhsData)):
            lhsType == rhsType && lhsData == rhsData
        case let (.array(lhs), .array(rhs)):
            lhs == rhs
        case let (.map(lhs), .map(rhs)):
            lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { $0.0 == $1.0 && $0.1 == $1.1 }
        default:
            false
        }
    }

    var intValue: Int? {
        switch self {
        case .int(let value): return Int(value)
        case .uint(let value): return Int(value)
        default: return nil
        }
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var arrayValue: [MessagePackValue]? {
        if case .array(let value) = self { return value }
        return nil
    }
}

struct MessagePackEncoder {
    func encode(_ value: MessagePackValue) -> Data {
        var data = Data()
        append(value, to: &data)
        return data
    }

    private func append(_ value: MessagePackValue, to data: inout Data) {
        switch value {
        case .nilValue:
            data.append(0xc0)
        case .bool(let value):
            data.append(value ? 0xc3 : 0xc2)
        case .int(let value):
            appendSigned(value, to: &data)
        case .uint(let value):
            appendUnsigned(value, to: &data)
        case .string(let value):
            appendString(value, to: &data)
        case .binary(let value):
            appendBinary(value, to: &data)
        case let .ext(type, value):
            appendExt(type: type, value: value, to: &data)
        case .array(let values):
            appendArrayHeader(count: values.count, to: &data)
            for value in values { append(value, to: &data) }
        case .map(let pairs):
            appendMapHeader(count: pairs.count, to: &data)
            for (key, value) in pairs {
                append(key, to: &data)
                append(value, to: &data)
            }
        }
    }

    private func appendSigned(_ value: Int64, to data: inout Data) {
        if value >= 0 {
            appendUnsigned(UInt64(value), to: &data)
        } else if value >= -32 {
            data.append(UInt8(bitPattern: Int8(value)))
        } else if value >= Int64(Int8.min) {
            data.append(0xd0)
            data.append(UInt8(bitPattern: Int8(value)))
        } else if value >= Int64(Int16.min) {
            data.append(0xd1)
            appendBigEndian(Int16(value), to: &data)
        } else if value >= Int64(Int32.min) {
            data.append(0xd2)
            appendBigEndian(Int32(value), to: &data)
        } else {
            data.append(0xd3)
            appendBigEndian(value, to: &data)
        }
    }

    private func appendUnsigned(_ value: UInt64, to data: inout Data) {
        if value <= 0x7f {
            data.append(UInt8(value))
        } else if value <= UInt64(UInt8.max) {
            data.append(0xcc)
            data.append(UInt8(value))
        } else if value <= UInt64(UInt16.max) {
            data.append(0xcd)
            appendBigEndian(UInt16(value), to: &data)
        } else if value <= UInt64(UInt32.max) {
            data.append(0xce)
            appendBigEndian(UInt32(value), to: &data)
        } else {
            data.append(0xcf)
            appendBigEndian(value, to: &data)
        }
    }

    private func appendString(_ value: String, to data: inout Data) {
        let bytes = Data(value.utf8)
        if bytes.count <= 31 {
            data.append(0xa0 | UInt8(bytes.count))
        } else if bytes.count <= Int(UInt8.max) {
            data.append(0xd9)
            data.append(UInt8(bytes.count))
        } else if bytes.count <= Int(UInt16.max) {
            data.append(0xda)
            appendBigEndian(UInt16(bytes.count), to: &data)
        } else {
            data.append(0xdb)
            appendBigEndian(UInt32(bytes.count), to: &data)
        }
        data.append(bytes)
    }

    private func appendBinary(_ value: Data, to data: inout Data) {
        if value.count <= Int(UInt8.max) {
            data.append(0xc4)
            data.append(UInt8(value.count))
        } else if value.count <= Int(UInt16.max) {
            data.append(0xc5)
            appendBigEndian(UInt16(value.count), to: &data)
        } else {
            data.append(0xc6)
            appendBigEndian(UInt32(value.count), to: &data)
        }
        data.append(value)
    }

    private func appendExt(type: Int8, value: Data, to data: inout Data) {
        if value.count <= Int(UInt8.max) {
            data.append(0xc7)
            data.append(UInt8(value.count))
        } else if value.count <= Int(UInt16.max) {
            data.append(0xc8)
            appendBigEndian(UInt16(value.count), to: &data)
        } else {
            data.append(0xc9)
            appendBigEndian(UInt32(value.count), to: &data)
        }
        data.append(UInt8(bitPattern: type))
        data.append(value)
    }

    private func appendArrayHeader(count: Int, to data: inout Data) {
        if count <= 15 {
            data.append(0x90 | UInt8(count))
        } else if count <= Int(UInt16.max) {
            data.append(0xdc)
            appendBigEndian(UInt16(count), to: &data)
        } else {
            data.append(0xdd)
            appendBigEndian(UInt32(count), to: &data)
        }
    }

    private func appendMapHeader(count: Int, to data: inout Data) {
        if count <= 15 {
            data.append(0x80 | UInt8(count))
        } else if count <= Int(UInt16.max) {
            data.append(0xde)
            appendBigEndian(UInt16(count), to: &data)
        } else {
            data.append(0xdf)
            appendBigEndian(UInt32(count), to: &data)
        }
    }

    private func appendBigEndian<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var bigEndian = value.bigEndian
        withUnsafeBytes(of: &bigEndian) { data.append(contentsOf: $0) }
    }
}

struct MessagePackDecoder {
    enum DecodeError: Error, Equatable {
        case incomplete
        case invalidMarker(UInt8)
        case invalidUTF8
    }

    mutating func decodeOne(from buffer: inout Data) throws -> MessagePackValue? {
        guard !buffer.isEmpty else { return nil }
        do {
            let (value, offset) = try decodeValue(in: buffer, at: 0)
            buffer.removeSubrange(0..<offset)
            return value
        } catch DecodeError.incomplete {
            return nil
        }
    }

    private func decodeValue(in data: Data, at offset: Int) throws -> (MessagePackValue, Int) {
        guard offset < data.count else { throw DecodeError.incomplete }
        let marker = data[offset]
        let next = offset + 1

        if marker <= 0x7f { return (.uint(UInt64(marker)), next) }
        if marker >= 0xe0 { return (.int(Int64(Int8(bitPattern: marker))), next) }
        if (0xa0...0xbf).contains(marker) {
            return try decodeString(length: Int(marker & 0x1f), in: data, at: next)
        }
        if (0x90...0x9f).contains(marker) {
            return try decodeArray(count: Int(marker & 0x0f), in: data, at: next)
        }
        if (0x80...0x8f).contains(marker) {
            return try decodeMap(count: Int(marker & 0x0f), in: data, at: next)
        }

        switch marker {
        case 0xc0: return (.nilValue, next)
        case 0xc2: return (.bool(false), next)
        case 0xc3: return (.bool(true), next)
        case 0xc4:
            let (length, start) = try readUInt8(in: data, at: next)
            return try decodeBinary(length: Int(length), in: data, at: start)
        case 0xc5:
            let (length, start) = try readUInt16(in: data, at: next)
            return try decodeBinary(length: Int(length), in: data, at: start)
        case 0xc6:
            let (length, start) = try readUInt32(in: data, at: next)
            return try decodeBinary(length: Int(length), in: data, at: start)
        case 0xc7:
            let (length, typeOffset) = try readUInt8(in: data, at: next)
            return try decodeExt(length: Int(length), in: data, at: typeOffset)
        case 0xc8:
            let (length, typeOffset) = try readUInt16(in: data, at: next)
            return try decodeExt(length: Int(length), in: data, at: typeOffset)
        case 0xc9:
            let (length, typeOffset) = try readUInt32(in: data, at: next)
            return try decodeExt(length: Int(length), in: data, at: typeOffset)
        case 0xcc:
            let (value, end) = try readUInt8(in: data, at: next)
            return (.uint(UInt64(value)), end)
        case 0xcd:
            let (value, end) = try readUInt16(in: data, at: next)
            return (.uint(UInt64(value)), end)
        case 0xce:
            let (value, end) = try readUInt32(in: data, at: next)
            return (.uint(UInt64(value)), end)
        case 0xcf:
            let (value, end) = try readUInt64(in: data, at: next)
            return (.uint(value), end)
        case 0xd0:
            let (value, end) = try readUInt8(in: data, at: next)
            return (.int(Int64(Int8(bitPattern: value))), end)
        case 0xd1:
            let (value, end) = try readUInt16(in: data, at: next)
            return (.int(Int64(Int16(bitPattern: value))), end)
        case 0xd2:
            let (value, end) = try readUInt32(in: data, at: next)
            return (.int(Int64(Int32(bitPattern: value))), end)
        case 0xd3:
            let (value, end) = try readUInt64(in: data, at: next)
            return (.int(Int64(bitPattern: value)), end)
        case 0xd4:
            return try decodeExt(length: 1, in: data, at: next)
        case 0xd5:
            return try decodeExt(length: 2, in: data, at: next)
        case 0xd6:
            return try decodeExt(length: 4, in: data, at: next)
        case 0xd7:
            return try decodeExt(length: 8, in: data, at: next)
        case 0xd8:
            return try decodeExt(length: 16, in: data, at: next)
        case 0xd9:
            let (length, start) = try readUInt8(in: data, at: next)
            return try decodeString(length: Int(length), in: data, at: start)
        case 0xda:
            let (length, start) = try readUInt16(in: data, at: next)
            return try decodeString(length: Int(length), in: data, at: start)
        case 0xdb:
            let (length, start) = try readUInt32(in: data, at: next)
            return try decodeString(length: Int(length), in: data, at: start)
        case 0xdc:
            let (count, start) = try readUInt16(in: data, at: next)
            return try decodeArray(count: Int(count), in: data, at: start)
        case 0xdd:
            let (count, start) = try readUInt32(in: data, at: next)
            return try decodeArray(count: Int(count), in: data, at: start)
        case 0xde:
            let (count, start) = try readUInt16(in: data, at: next)
            return try decodeMap(count: Int(count), in: data, at: start)
        case 0xdf:
            let (count, start) = try readUInt32(in: data, at: next)
            return try decodeMap(count: Int(count), in: data, at: start)
        default:
            throw DecodeError.invalidMarker(marker)
        }
    }

    private func decodeString(length: Int, in data: Data, at offset: Int) throws -> (MessagePackValue, Int) {
        guard offset + length <= data.count else { throw DecodeError.incomplete }
        guard let string = String(data: data[offset..<offset + length], encoding: .utf8) else {
            throw DecodeError.invalidUTF8
        }
        return (.string(string), offset + length)
    }

    private func decodeBinary(length: Int, in data: Data, at offset: Int) throws -> (MessagePackValue, Int) {
        guard offset + length <= data.count else { throw DecodeError.incomplete }
        return (.binary(Data(data[offset..<offset + length])), offset + length)
    }

    private func decodeExt(length: Int, in data: Data, at offset: Int) throws -> (MessagePackValue, Int) {
        guard offset + 1 + length <= data.count else { throw DecodeError.incomplete }
        let type = Int8(bitPattern: data[offset])
        let start = offset + 1
        return (.ext(type, Data(data[start..<start + length])), start + length)
    }

    private func decodeArray(count: Int, in data: Data, at offset: Int) throws -> (MessagePackValue, Int) {
        var values: [MessagePackValue] = []
        values.reserveCapacity(count)
        var cursor = offset
        for _ in 0..<count {
            let (value, next) = try decodeValue(in: data, at: cursor)
            values.append(value)
            cursor = next
        }
        return (.array(values), cursor)
    }

    private func decodeMap(count: Int, in data: Data, at offset: Int) throws -> (MessagePackValue, Int) {
        var pairs: [(MessagePackValue, MessagePackValue)] = []
        pairs.reserveCapacity(count)
        var cursor = offset
        for _ in 0..<count {
            let (key, afterKey) = try decodeValue(in: data, at: cursor)
            let (value, afterValue) = try decodeValue(in: data, at: afterKey)
            pairs.append((key, value))
            cursor = afterValue
        }
        return (.map(pairs), cursor)
    }

    private func readUInt8(in data: Data, at offset: Int) throws -> (UInt8, Int) {
        guard offset < data.count else { throw DecodeError.incomplete }
        return (data[offset], offset + 1)
    }

    private func readUInt16(in data: Data, at offset: Int) throws -> (UInt16, Int) {
        guard offset + 2 <= data.count else { throw DecodeError.incomplete }
        let value = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
        return (value, offset + 2)
    }

    private func readUInt32(in data: Data, at offset: Int) throws -> (UInt32, Int) {
        guard offset + 4 <= data.count else { throw DecodeError.incomplete }
        var value: UInt32 = 0
        for index in 0..<4 { value = (value << 8) | UInt32(data[offset + index]) }
        return (value, offset + 4)
    }

    private func readUInt64(in data: Data, at offset: Int) throws -> (UInt64, Int) {
        guard offset + 8 <= data.count else { throw DecodeError.incomplete }
        var value: UInt64 = 0
        for index in 0..<8 { value = (value << 8) | UInt64(data[offset + index]) }
        return (value, offset + 8)
    }
}
