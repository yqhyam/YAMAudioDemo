//
//  YAMOpusCodec.swift
//  YAMAudioDemo
//
//  Created by 杨清晖 on 2018/4/12.
//  Copyright © 2018年 杨清晖. All rights reserved.
//

import Foundation

class YAMOpusCodec {
    
    private var dec: OpaquePointer!
    private var enc: OpaquePointer!
    
    static var sharedInstance = YAMOpusCodec()
    
    static let kMaxFrameSize: Int32 = 6 * 2048
    
    init() {
        
        let fs: Int32 = 48000
        var error: Int32 = 0
        let application: Int32 = OPUS_APPLICATION_VOIP
        
        dec = opus_decoder_create(fs, 1, &error)
        enc = opus_encoder_create(fs, 1, application, &error)
        
    }
    
    func encoder(with data: Data) -> Data? {
        
        if data.count < 0 { return nil }
//        let count = data.count
//        let packet = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
//        packet.initialize(from: [UInt8](data), count: count)
//        var nbBytes: opus_int32 = 0
//        let cbits = UnsafeMutablePointer<UInt8>.allocate(capacity: 480)
//        var decodedData = Data(capacity: 20)
//        let input_frame = UnsafeMutablePointer<CShort>.allocate(capacity: 160)
//        memset(input_frame, 0, 320)
//        memcpy(input_frame, packet, 320)
//        nbBytes = opus_encode(enc, input_frame, 160, cbits, 480)
//        if nbBytes > 0 {
//            decodedData.append(cbits, count: Int(nbBytes))
//            return decodedData
//        }

        
        let frame_size: Int32 = 480
        let audio_frame = Array<opus_int16>(repeating: 0, count: Int(frame_size) * MemoryLayout<opus_int16>.size)

        var mutData = data
        let count = mutData.count
        let packet = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        packet.initialize(from: [UInt8](data), count: count)

        let max_packet: opus_int32 = 4000
        let len = opus_encode(enc, audio_frame, frame_size, packet, max_packet)

        if len > 0 {
            let data = Data(bytes: packet, count: Int(len))
            return data
        }
        
        return nil
    }
    
    func decoder(with data: Data?) -> Data? {
        
        guard let data = data else { return nil }
        if data.count < 0 { return nil }
        
        let packet = [UInt8](data)
        let len = data.count

        let cbits = UnsafeMutablePointer<CChar>.allocate(capacity: 200)
        memcpy(cbits, packet, len)
        let decoded = UnsafeMutablePointer<CShort>.allocate(capacity: 2048)
        let frame_size = opus_decode(dec, packet, opus_int32(len), decoded, YAMOpusCodec.kMaxFrameSize, 0)
        if frame_size > 0 {
            let data = Data(bytes: decoded, count: Int(frame_size))
            return data
        }
        
//        let packet = [UInt8](data)
//        let len = opus_int32(data.count)
//        let max_size: Int32 = YAMOpusCodec.kMaxFrameSize
//        var decoded = Array<opus_int16>(repeating: 0, count: Int(max_size) * MemoryLayout<opus_int16>.size)
//
//        let frame_size = opus_decode(dec, packet, len, &decoded, max_size, 0)
//
//        if frame_size > 0 {
//            let data = Data(bytes: decoded, count: Int(frame_size))
//            return data
//        }
        
        return nil
    }
    
}
