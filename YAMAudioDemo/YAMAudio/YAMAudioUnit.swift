//
//  YAMAudioUnit.swift
//  YAMAudioDemo
//
//  Created by 杨清晖 on 2018/4/11.
//  Copyright © 2018年 杨清晖. All rights reserved.
//

import Foundation
import AVFoundation

class YAMAudioUnit {

    static let kInputBus: UInt32 = 1
    static let kOutputBus: UInt32 = 0
    static let kSampleRate: Float64 = 44100
    
    public var onMicrophoneData: ((Data) -> Void)?
    
    var recordBufferList: AudioBufferList!
    var audioUnit: AudioComponentInstance?
    var receiveData: Data!
    
    var isRecording = false
    var isPlaying = false
    var isUnitWorking = false
    
    // record
    private let recordCallback: AudioToolbox.AURenderCallback = {
        inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData in
        
        let audioProcessor: YAMAudioUnit = Unmanaged<YAMAudioUnit>.fromOpaque(inRefCon).takeRetainedValue()

        var status = noErr
        
        let channelCount : UInt32 = 1
        
        var bufferList = AudioBufferList()
        bufferList.mNumberBuffers = channelCount
        let buffers = UnsafeMutableBufferPointer<AudioBuffer>(start: &bufferList.mBuffers,
                                                              count: Int(bufferList.mNumberBuffers))
        buffers[0].mNumberChannels = 1
        buffers[0].mDataByteSize = inNumberFrames * 2
        buffers[0].mData = nil
        
        // get the recorded samples
        status = AudioUnitRender(audioProcessor.audioUnit!,
                                 ioActionFlags,
                                 inTimeStamp,
                                 inBusNumber,
                                 inNumberFrames,
                                 UnsafeMutablePointer<AudioBufferList>(&bufferList))
        if (status != noErr) {
            return status;
        }
        
        let data = Data(bytes: buffers[0].mData!, count: Int(buffers[0].mDataByteSize))
        audioProcessor.onMicrophoneData?(data)
        
        return noErr
    }
    
    // play
    private let playCallback: AudioToolbox.AURenderCallback = {
            inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData in
            
            
            return noErr
    }
    
    init() {
        setupAudioComponet()
        setupBuffer()
        setupFormatAndProperty()
        setupCallback()
    }
    
    fileprivate func setupBuffer() {
        
        var flag: UInt32 = 0
        AudioUnitSetProperty(audioUnit!,
                             kAudioUnitProperty_ShouldAllocateBuffer,
                             kAudioUnitScope_Output,
                             YAMAudioUnit.kInputBus,
                             &flag,
                             sizeof(flag))
        
    }
    
    fileprivate func setupAudioComponet() {
        
        var audioDesc = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_VoiceProcessingIO,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0)
        
        let inputComponent = AudioComponentFindNext(nil, &audioDesc)
        
        AudioComponentInstanceNew(inputComponent!, &audioUnit)
        AudioUnitInitialize(audioUnit!)
        
    }
    
    fileprivate func setupFormatAndProperty() {
        
        var audioFormat = AudioStreamBasicDescription(
            mSampleRate: YAMAudioUnit.kSampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 1,
            mFramesPerPacket: 1,
            mBytesPerFrame: 1,
            mChannelsPerFrame: 16,
            mBitsPerChannel: 2,
            mReserved: 2)
        
        AudioUnitSetProperty(audioUnit!,
                             kAudioUnitProperty_StreamFormat,
                             kAudioUnitScope_Input,
                             YAMAudioUnit.kOutputBus,
                             &audioFormat,
                             sizeof(audioFormat))
        
        AudioUnitSetProperty(audioUnit!,
                             kAudioUnitProperty_StreamFormat,
                             kAudioUnitScope_Output,
                             YAMAudioUnit.kInputBus,
                             &audioFormat,
                             sizeof(audioFormat))
        

        
        var flag: UInt32 = 1
        AudioUnitSetProperty(audioUnit!,
                             kAudioOutputUnitProperty_EnableIO,
                             kAudioUnitScope_Input,
                             YAMAudioUnit.kInputBus,
                             &flag,
                             sizeof(flag));
        AudioUnitSetProperty(audioUnit!,
                             kAudioOutputUnitProperty_EnableIO,
                             kAudioUnitScope_Output,
                             YAMAudioUnit.kOutputBus,
                             &flag,
                             sizeof(flag));
        
    }
    
    fileprivate func setupCallback() {
        
        // recordCallback
        var recordCallBack = AURenderCallbackStruct(
            inputProc: self.recordCallback,
            inputProcRefCon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        
        AudioUnitSetProperty(audioUnit!,
                             kAudioOutputUnitProperty_SetInputCallback,
                             kAudioUnitScope_Global,
                             YAMAudioUnit.kInputBus,
                             &recordCallBack,
                             sizeof(recordCallBack));
        
        var playCallback = AURenderCallbackStruct(
            inputProc: self.playCallback,
            inputProcRefCon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        
        AudioUnitSetProperty(audioUnit!,
                             kAudioUnitProperty_SetRenderCallback,
                             kAudioUnitScope_Global,
                             YAMAudioUnit.kOutputBus,
                             &playCallback,
                             sizeof(playCallback));
    }
    
    fileprivate func prepareToRecord() {
    
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error {
            print("设置失败：\(error)")
        }
        // clean ehco  0 = open, 1 = close
        var echo: UInt32 = 0
        AudioUnitSetProperty(audioUnit!,
                             kAUVoiceIOProperty_BypassVoiceProcessing,
                             kAudioUnitScope_Global,
                             0,
                             &echo,
                             sizeof(echo))
    }
    
    public func startRecording() {
        guard !isRecording else { return }

        isRecording = true
        prepareToRecord()
        AudioOutputUnitStart(audioUnit!) 
        
    }
    
    public func stopRecording() {
        guard isRecording else { return }

        isRecording = false
        AudioOutputUnitStop(audioUnit!)
        
    }
    
    fileprivate func sizeof <T> (_ : T.Type) -> UInt32
    {
        return (UInt32(MemoryLayout<T>.size))
    }
    
    fileprivate func sizeof <T> (_ : T) -> UInt32
    {
        return (UInt32(MemoryLayout<T>.size))
    }
    
    fileprivate func sizeof <T> (_ value : [T]) -> UInt32
    {
        return (UInt32(MemoryLayout<T>.size * value.count))
    }
    
}
