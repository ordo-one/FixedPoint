import Testing
import Foundation
import FixedPointDecimal

@Suite("Codable")
struct CodableTests {

    // MARK: - JSON Encoding/Decoding

    @Test("Encode as String in JSON")
    func encodeJSON() throws {
        let value: FixedPointDecimal = 123.45
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8)!
        // Should encode as human-readable string
        #expect(json == "\"123.45\"")
    }

    @Test("Decode from JSON integer as face value")
    func decodeFromInt64() throws {
        // JSON integer 123 should decode as the number 123.0, not rawValue 123
        let json = "123"
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(FixedPointDecimal.self, from: data)
        #expect(value == 123 as FixedPointDecimal)
    }

    @Test("Decode from String in JSON")
    func decodeFromString() throws {
        let json = "\"123.45\""
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(FixedPointDecimal.self, from: data)
        #expect(value == 123.45 as FixedPointDecimal)
    }

    @Test("Decode invalid string throws")
    func decodeInvalidString() throws {
        let json = "\"not-a-number\""
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(FixedPointDecimal.self, from: data)
        }
    }

    @Test("Decode invalid type throws")
    func decodeInvalidType() throws {
        let json = "true"
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(FixedPointDecimal.self, from: data)
        }
    }

    // MARK: - Round-Trip

    @Test("JSON encode+decode round-trip")
    func jsonRoundTrip() throws {
        let values: [FixedPointDecimal] = [
            0, 1, -1, 123.45, -99.99, 0.00000001,
        ]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for value in values {
            let data = try encoder.encode(value)
            let decoded = try decoder.decode(FixedPointDecimal.self, from: data)
            #expect(decoded == value, "Round-trip failed for \(value)")
        }
    }

    @Test("NaN JSON round-trip")
    func nanRoundTrip() throws {
        let nan = FixedPointDecimal.nan
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(nan)
        let decoded = try decoder.decode(FixedPointDecimal.self, from: data)
        #expect(decoded.isNaN)
    }

    // MARK: - In Container

    @Test("Array encoding and decoding")
    func arrayRoundTrip() throws {
        let values: [FixedPointDecimal] = [10, 20, 30.5]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(values)
        let decoded = try decoder.decode([FixedPointDecimal].self, from: data)
        #expect(decoded == values)
    }

    @Test("Dictionary encoding and decoding")
    func dictRoundTrip() throws {
        struct Container: Codable, Equatable {
            let price: FixedPointDecimal
            let quantity: FixedPointDecimal
        }
        let c = Container(price: 99.95, quantity: 100)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(c)
        let decoded = try decoder.decode(Container.self, from: data)
        #expect(decoded == c)
    }

    // MARK: - Codable Edge Cases

    @Test("Encode and decode .zero")
    func zeroRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(FixedPointDecimal.zero)
        let decoded = try decoder.decode(FixedPointDecimal.self, from: data)
        #expect(decoded == .zero)
    }

    @Test("Encode and decode .max")
    func maxRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(FixedPointDecimal.max)
        let decoded = try decoder.decode(FixedPointDecimal.self, from: data)
        #expect(decoded == .max)
    }

    @Test("Encode and decode .min")
    func minRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(FixedPointDecimal.min)
        let decoded = try decoder.decode(FixedPointDecimal.self, from: data)
        #expect(decoded == .min)
    }

    @Test("Decode from JSON integer — face value semantics")
    func decodeFromJSONInteger() throws {
        // JSON integer 12345 should decode as the number 12345.0 (face value)
        let json = "12345"
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(FixedPointDecimal.self, from: data)
        #expect(value == 12345 as FixedPointDecimal)
    }

    @Test("Decode NaN from string")
    func decodeNaNFromString() throws {
        let json = "\"nan\""
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FixedPointDecimal.self, from: data)
        #expect(decoded.isNaN)
    }

    @Test("NaN encodes and decodes correctly")
    func nanEncodesDecode() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(FixedPointDecimal.nan)
        let decoded = try decoder.decode(FixedPointDecimal.self, from: data)
        #expect(decoded.isNaN)
    }

    // MARK: - NaN Encoding Format

    @Test("NaN encodes as the string \"nan\", not as Int64.min")
    func nanEncodesAsString() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(FixedPointDecimal.nan)
        let json = String(data: data, encoding: .utf8)!
        // Must be the JSON string "nan", not the raw sentinel integer
        #expect(json == "\"nan\"")
    }

    // MARK: - Decoding Int64.min (overflow as face value)

    @Test("Decoding Int64.min throws — overflow as face value")
    func decodeInt64MinThrows() throws {
        // Int64.min interpreted as a face-value integer overflows when
        // multiplied by scaleFactor, so decoding should throw.
        let json = "\(Int64.min)"
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(FixedPointDecimal.self, from: data)
        }
    }

    // MARK: - Double Decode Path

    @Test("Decode from actual JSON Double with decimal point")
    func decodeFromActualDouble() throws {
        let json = "123.45"
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(FixedPointDecimal.self, from: data)
        #expect(value == 123.45 as FixedPointDecimal)
    }

    @Test("Decode from negative JSON Double")
    func decodeFromNegativeDouble() throws {
        let json = "-42.5"
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(FixedPointDecimal.self, from: data)
        #expect(value == -42.5 as FixedPointDecimal)
    }

    @Test("Decode from very small JSON Double")
    func decodeFromVerySmallDouble() throws {
        let json = "0.00000001"
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(FixedPointDecimal.self, from: data)
        #expect(value == 0.00000001 as FixedPointDecimal)
    }

    // MARK: - Face-Value Integer Decoding

    @Test("Decode JSON integer 0 as zero")
    func decodeJSONIntegerZero() throws {
        let json = "0"
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(FixedPointDecimal.self, from: data)
        #expect(value == .zero)
    }

    @Test("Decode negative JSON integer as face value")
    func decodeNegativeJSONInteger() throws {
        let json = "-42"
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(FixedPointDecimal.self, from: data)
        #expect(value == -42 as FixedPointDecimal)
    }

    @Test("Decode JSON integer exceeding max throws")
    func decodeOverflowJSONInteger() throws {
        // 92233720369 exceeds max integer part (92233720368)
        let json = "92233720369"
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(FixedPointDecimal.self, from: data)
        }
    }

    @Test("Encoding produces JSON string, not number")
    func encodingProducesString() throws {
        let encoder = JSONEncoder()

        let value: FixedPointDecimal = 123.45
        let data1 = try encoder.encode(value)
        let json1 = String(data: data1, encoding: .utf8)!
        #expect(json1.hasPrefix("\""))
        #expect(json1.hasSuffix("\""))

        let data2 = try encoder.encode(FixedPointDecimal.zero)
        let json2 = String(data: data2, encoding: .utf8)!
        #expect(json2 == "\"0\"")

        let data3 = try encoder.encode(FixedPointDecimal.max)
        let json3 = String(data: data3, encoding: .utf8)!
        #expect(json3 == "\"92233720368.54775807\"")

        let data4 = try encoder.encode(FixedPointDecimal.min)
        let json4 = String(data: data4, encoding: .utf8)!
        #expect(json4 == "\"-92233720368.54775807\"")
    }

    // MARK: - JSON Double Decode (Rounding)

    @Test("Decode JSON double with sub-tick precision rounds correctly")
    func decodeJsonDoubleRounds() throws {
        // JSON number 0.000000009 should round to 0.00000001 (not reject)
        let json = Data("0.000000009".utf8)
        let decoded = try JSONDecoder().decode(FixedPointDecimal.self, from: json)
        #expect(decoded == FixedPointDecimal("0.00000001")!)
    }

    @Test("Decode JSON double with exact value preserves it")
    func decodeJsonDoubleExact() throws {
        let json = Data("0.5".utf8)
        let decoded = try JSONDecoder().decode(FixedPointDecimal.self, from: json)
        #expect(decoded.description == "0.5")
    }

    @Test("Decode out-of-range JSON double throws instead of crashing")
    func decodeJsonDoubleOutOfRange() throws {
        let json = Data("1e40".utf8)
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(FixedPointDecimal.self, from: json)
        }
    }

    @Test("Decode negative out-of-range JSON double throws")
    func decodeJsonDoubleNegativeOutOfRange() throws {
        let json = Data("-1e40".utf8)
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(FixedPointDecimal.self, from: json)
        }
    }

    @Test("Decode JSON double at negative edge does not produce NaN sentinel")
    func decodeJsonDoubleNegativeEdgeNotNaN() throws {
        // -92233720368.54776 maps to Int64.min (NaN sentinel) due to Double
        // precision — must throw, not silently produce NaN
        let json = Data("-92233720368.54776".utf8)
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(FixedPointDecimal.self, from: json)
        }
    }
}
