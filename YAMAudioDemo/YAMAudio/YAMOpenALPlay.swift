//
//  YAMOpenALPlay.swift
//  hangge_772
//
//  Created by 杨清晖 on 2018/4/4.
//  Copyright © 2018年 hangge.com. All rights reserved.
//

import UIKit
import OpenAL
import AVFoundation

class YAMOpenALPlay: NSObject {
    
    var mContext: OpaquePointer!
    var mDevice: OpaquePointer!
    var outSourceID: ALuint = 0
//    var soundDictionart: [String: Any] = [:]
//    var bufferStroageArray: [Any] = []
    var buff: ALuint = 0
//    var updateBufferTimer: Timer!
    private let once: Void = {
        
        var error: NSError?
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryMultiRoute)
        } catch let error {
            print("设置声音环境失败\n\(error)")
            return
        }
        
        // 启用audio session
        do{
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error{
            print("启动失败\n\(error)")
            return
        }
        
    }()
    
    override init() {
        
        super.init()
        
        _ = once
        
        if let mDevice = alcOpenDevice(nil) {
            
            mContext = alcCreateContext(mDevice, nil)
            alcMakeContextCurrent(mContext)
            self.mDevice = mDevice
        }
        
        alGenSources(1, &outSourceID)
        alSpeedOfSound(1.0)
        alDopplerVelocity(1.0)
        alDopplerFactor(1.0)
        alSourcef(outSourceID, AL_PITCH, 1.0)
        alSourcef(outSourceID, AL_GAIN, 1.0)
        alSourcef(outSourceID, AL_LOOPING, ALfloat(AL_FALSE))
        alSourcef(outSourceID, AL_SOURCE_TYPE, ALfloat(AL_STREAMING))

    }
    
    func openAudio(form tmpData: NSData) {
        
        let ticketCondition = NSCondition()
        
        var bufferID: ALuint = 0
        alGenBuffers(1, &bufferID)
        
//        let
        
        let aSampleRate = 44100
        let aBit = 16
        let aChannel = 1
        var format: ALenum = 0
        
        if aBit == 8 {
            
            if aChannel == 1 {
                format = AL_FORMAT_MONO8
            }
            else if aChannel == 2 {
                format = AL_FORMAT_STEREO8
            }
            else if alIsExtensionPresent("AL_EXT_MCFORMATS") == 1 {
                if aChannel == 4 {
                    format = alGetEnumValue("AL_FORMAT_QUAD8")
                }
                else if aChannel == 6 {
                    format = alGetEnumValue("AL_FORMAT_51CHN8")
                }
            }
                
        }
        else if aBit == 16 {
            
            if aChannel == 1 {
                format = AL_FORMAT_MONO16
            }
            else if aChannel == 2 {
                format = AL_FORMAT_STEREO16
            }
            else if alIsExtensionPresent("AL_EXT_MCFORMATS") == 1 {
                if aChannel == 4 {
                    format = alGetEnumValue("AL_FORMAT_QUAD8")
                }
                else if aChannel == 6 {
                    format = alGetEnumValue("AL_FORMAT_51CHN8")
                }
            }
            
        }
        
        alBufferData(bufferID, format, tmpData.bytes, ALsizei(tmpData.length), ALsizei(aSampleRate))
        alSourceQueueBuffers(outSourceID, 1, &bufferID)
        
        _ = updateQueueBuffer()
        
        var stateVaue: ALint = 0
        alGetSourcei(outSourceID, AL_SOURCE_STATE, &stateVaue)
        ticketCondition.unlock()
        
        
    }
    
    func updateQueueBuffer() -> Bool {
        
        var stateVaue: ALint = 0
        var processed: ALint = 0
        var queued: ALint = 0
        
        alGetSourcei(outSourceID, AL_BUFFERS_PROCESSED, &processed)
        alGetSourcei(outSourceID, AL_BUFFERS_QUEUED, &queued)
        alGetSourcei(outSourceID, AL_SOURCE_STATE, &stateVaue)
        
        if stateVaue == AL_STOPPED || stateVaue == AL_PAUSED || stateVaue == AL_INITIAL {
            
            if queued < processed || queued == 0 || (queued == 1 && processed == 1) {
                stop()
                clean()
            }
            
            play()
            return false
        }
        
        while processed > 0 {
            
            alSourceUnqueueBuffers(outSourceID, 1, &buff)
            alDeleteBuffers(1, &buff)
            processed -= 1
        }
        
        return true
    }
    
    func stop() {
        alSourceStop(outSourceID)
    }
    
    func clean() {
//        updateBufferTimer.invalidate()
//        updateBufferTimer = nil
        alDeleteSources(1, &outSourceID)
        alDeleteBuffers(1, &buff)
        alcDestroyContext(mContext)
        alcCloseDevice(mDevice)
    }
    
    func play() {
        alSourcePlay(outSourceID)
    }
}
