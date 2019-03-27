//
//  YAMAudioRecord.swift
//  hangge_772
//
//  Created by 杨清晖 on 2018/4/3.
//  Copyright © 2018年 hangge.com. All rights reserved.
//

import UIKit
import AudioUnit

class YAMAudioRecord: NSObject {

    static let kQueueBufferSize = 3 // 输出队列缓冲个数
    static let kDefaultBufferDurationSeconds = 0.03 // 调整这个值使得录音的缓冲区大小为960，实际会小于960
    static let kDefaultSampleRate: Float64 = 44100 // 定义采样率为16000
    static var isRecording = false
    
    var audioQueue: AudioQueueRef!
    var recordFormat: AudioStreamBasicDescription!
    var audioBuffers = Array<AudioQueueBufferRef?>(repeating: nil, count: kQueueBufferSize)
    var isRecording = false

    // 外部数据回调
    open var progressHanlder: ((_ data: Data) -> Void)?
    
    // callback回调
    private var inputCallback: AudioQueueInputCallback = {(
        inUserData: UnsafeMutableRawPointer?,
        inAQ: AudioQueueRef,
        inBuffer: AudioQueueBufferRef,
        inStartTime: UnsafePointer<AudioTimeStamp>,
        inNumPackets: UInt32,
        inPacketDesc: UnsafePointer<AudioStreamPacketDescription>?) -> Void in
        
        if inNumPackets > 0 {
            
//             let recorder = Unmanaged<YAMAudioRecord>.fromOpaque(inUserData!).takeUnretainedValue()
            let recorder = unsafeBitCast(inUserData!, to: YAMAudioRecord.self)
            recorder.process(audioQueueBufferRef: inBuffer, with: inAQ)
            
        }
        
        if YAMAudioRecord.isRecording {
            
            AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil)
        }
        
    }
    
    override init() {
        
        super.init()
        
//        memset(&recordFormat, 0, sizeof(recordFormat!))
        recordFormat = AudioStreamBasicDescription()
        recordFormat.mSampleRate = YAMAudioRecord.kDefaultSampleRate
        recordFormat.mChannelsPerFrame = 1
        recordFormat.mFormatID = kAudioFormatLinearPCM
        
        recordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger
        recordFormat.mBitsPerChannel = 16
        recordFormat.mBytesPerPacket = recordFormat.mBitsPerChannel/8 * recordFormat.mChannelsPerFrame
        recordFormat.mBytesPerFrame = recordFormat.mBytesPerPacket
        recordFormat.mFramesPerPacket = 1
        
        // 初始化音频输入队列
        var queue: AudioQueueRef? = nil
        AudioQueueNewInput(&recordFormat!, inputCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self), nil, nil, 0, &queue)
        
        // 计算估值的缓存区大小
        let frames = UInt32(ceil(YAMAudioRecord.kDefaultBufferDurationSeconds * recordFormat.mSampleRate))
        let bufferByteSize = frames * recordFormat.mBytesPerFrame
//        let bufferByteSize = deriveBufferSize(seconds: 0.5)

        print("缓存区大小:\(bufferByteSize)")
        
        // 创建缓冲区
        for i in 0..<3 {
            var buffer: AudioQueueBufferRef? = nil
            AudioQueueAllocateBuffer(queue!, bufferByteSize, &buffer)
            AudioQueueEnqueueBuffer(queue!, buffer!, 0, nil)
            if let buffer = buffer {
                audioBuffers[i] = buffer
            }
            
        }
        
        self.audioQueue = queue
        
    }
    
    private func deriveBufferSize(seconds: Float64) -> UInt32 {
        guard let queue = audioQueue else { return 0 }
        let maxBufferSize = UInt32(0x50000)
        var maxPacketSize = recordFormat.mBytesPerPacket
        if maxPacketSize == 0 {
            var maxVBRPacketSize = UInt32(MemoryLayout<UInt32>.stride)
            AudioQueueGetProperty(
                queue,
                kAudioQueueProperty_MaximumOutputPacketSize,
                &maxPacketSize,
                &maxVBRPacketSize
            )
        }
        
        let numBytesForTime = UInt32(recordFormat.mSampleRate * Float64(maxPacketSize) * seconds)
        let bufferSize = (numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize)
        return bufferSize
    }
    
    // 数据回调进度
    private func process(audioQueueBufferRef: AudioQueueBufferRef, with audioQueueRef: AudioQueueRef) {
        
        let dataM = NSMutableData(bytes: audioQueueBufferRef.pointee.mAudioData, length: Int(audioQueueBufferRef.pointee.mAudioDataByteSize))
        
        if dataM.length < 960 {
            let byte: [UInt8] = [0x00]
            let zeroData = Data(bytes: byte, count: 1)
            
            for _ in dataM.length..<960 {
                dataM.append(zeroData)
            }
            
        }
        
        // 通过闭包传输局
        if progressHanlder != nil {
            progressHanlder!(dataM as Data)
        }
        
    }
 
    // 开始录音
    open func statrRecording() {
        
        AudioQueueStart(audioQueue, nil)
        isRecording = true
        YAMAudioRecord.isRecording = true
    }
    
    // 停止录音
    open func stopRecording() {
        
        if isRecording {
            isRecording = false
            YAMAudioRecord.isRecording = false
            //停止录音队列和移除缓冲区,以及关闭session，这里无需考虑成功与否
            AudioQueueStop(audioQueue, true)
            //移除缓冲区,true代表立即结束录制，false代表将缓冲区处理完再结束
            AudioQueueDispose(audioQueue, true)
        }
        print("停止录音")
    }

}
