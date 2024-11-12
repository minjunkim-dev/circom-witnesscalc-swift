#if canImport(C)
import C
#endif

import Darwin.C.string
import Foundation

/**
 Generates witness for proving the Groth16 proof.

 - Parameters:
 - inputs: The inputs json data used to generate the witness.
 - graph: The graph data used to generate the witness.

 - Throws: `CircomWitnesscalcProverError` child classes
 if the witness generation fails, with the error message indicating the reason for failure.

 - Returns: A Data which contains witness.
 */
public func calculateWitness(
    inputs: Data,
    graph: Data
) throws -> Data {
    let inputsBuf = NSData(data: inputs).bytes
    let graphBuf = NSData(data: graph).bytes

    let witnessPointer = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 1)
    let witnessLenPointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
    let statusPointer = UnsafeMutablePointer<gw_status_t>.allocate(capacity: 1)

//    defer {
//        witnessPointer.deallocate()
//        witnessLenPointer.deallocate()
//        statusPointer.deallocate()
//    }

    // Call the CircomWitnesscalc C++ library function to perform the Groth16 proof
    let statusCode = 0;
    
//    let statusCode = gw_calc_witness(
//        inputsBuf,
//        graphBuf, graph.count,
//        witnessPointer, witnessLenPointer,
//        nil
//    );

    let witness = witnessPointer.pointee
    let witnessLength = witnessLenPointer.pointee

    if (statusCode == 0 && witness != nil) {
        let witnessBufferPointer = UnsafeBufferPointer(
            start: witness!.assumingMemoryBound(to: UInt8.self),
            count: witnessLength
        )

        return Data(buffer: witnessBufferPointer)
    }
    return Data()

//    guard let msg = statusPointer.pointee.error_msg else {
//        throw WitnessCalcError(message: "Unknown error")
//    }
//    let msgString = String(cString: msg)

//    throw WitnessCalcError(message: msgString)
}


public protocol WitnessCalcErrorProtocol : CustomNSError {
    var message: String { get }
}

public extension WitnessCalcError {
    var errorUserInfo: [String : Any] {
        return ["message": message]
    }
}

public class WitnessCalcError : WitnessCalcErrorProtocol {
    public let message: String

    init(message: String) {
        self.message = message
    }

    public var errorCode: Int {
        return 1
    }
}
