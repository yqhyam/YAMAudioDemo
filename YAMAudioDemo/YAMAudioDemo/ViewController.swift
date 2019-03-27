//
//  ViewController.swift
//  YAMAudioDemo
//
//  Created by 杨清晖 on 2018/4/9.
//  Copyright © 2018年 杨清晖. All rights reserved.
//

import UIKit
import SocketRocket

class ViewController: UIViewController {

    @IBOutlet weak var reopenBtn: UIButton! // 重新连接
    @IBOutlet weak var recorderBtn: UIButton! // 录音按钮
    @IBOutlet weak var consoleView: UITextView! // 打印行
    
    var socket: SRWebSocket! // websocket
    var recorder: Recorder! // 录音
    var player: YAMOpenALPlay! // 播放
    
    var isEndRecorder: Bool = false
    let layer = YAMVolCricleLayer(size: CGSize(width: 50, height: 50))
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        recorderBtn.layer.cornerRadius = 25
        recorderBtn.layer.masksToBounds = true
        
        layer.frame = recorderBtn.frame
        self.view.layer.addSublayer(layer)
        self.view.bringSubview(toFront: recorderBtn)
        
        player = YAMOpenALPlay()
        
//        AudioController.sharedInstance.prepare(specifiedSampleRate: 44100)
//        AudioController.sharedInstance.delegate = self
        
        recorder = Recorder()
        recorder.onMicrophoneData = { [unowned self] data in
            
            let test = YAMOpusCodec.sharedInstance.encoder(with: data)
            let a = YAMOpusCodec.sharedInstance.decoder(with: test)
            print(a)
            if self.socket.readyState != SRReadyState.OPEN {
                return
            }
            
            self.socket.send(data)
            self.console("对讲数据大小：\(data.count)")
            
            
        }
        
        recorder.onPowerData = { power in
            
            self.console("vol:\(power)")
//            self.layer.zPosition = 0.5
//            self.layer.position = self.recorderBtn.center
            self.layer.startRecorder(with: power)

        }
        
        socket = SRWebSocket(url: URL(string: "ws://192.168.2.65/echo"))
        socket.delegate = self
        socket.open()
        
    }

    @IBAction func touchBegin(_ sender: Any) {
        
        if socket.readyState != SRReadyState.OPEN {
            return
        }
        
        if !recorder.isRecording {
            layer.begin()
            isEndRecorder = false
            socket.send("speaklock")
        }
     
    }
    
    @IBAction func touchEnd(_ sender: Any) {
        stopRecording()
    }
    
    @IBAction func touchOut(_ sender: Any) {
        stopRecording()
    }
    
    @IBAction func reopen(_ sender: Any) {
        
        if socket.readyState != SRReadyState.OPEN {
            socket.close()
            socket.delegate = nil
            socket = nil
            
            socket = SRWebSocket(url: URL(string: "ws://192.168.2.65/echo"))
            socket.delegate = self
            socket.open()
        }
        
    }
    
    func stopRecording() {
        
        if socket.readyState != SRReadyState.OPEN {
            return
        }
        
        if recorder.isRecording {
            
            try! recorder.stopRecording()
            
            layer.endRecorder(size: CGSize(width: 50, height: 50))
            isEndRecorder = true
            console("结束对讲")
            socket.send("speakend")
            
        }
        
    }
    
    func receiveTextHandler(_ text: String) {
        
        if text.hasPrefix("speaknow") {
            console("有人正在说话")
        }
        else if text == "success" {
            
            if isEndRecorder {
                return
            }
            try! recorder.startRecording()
            console("开始对讲")
        }
        else {
            console("收到文字:\(text)")
        }
        
    }
    
    func receiveDataHandler(_ data: Data) {
        
        console("收到数据:\(data.count)")
        
        if data.count <= 0 {
            return
        }
//        let out = YAMOpusCodec.sharedInstance.decoder(with: data)

        player.openAudio(form: data as NSData)
        
    }
    
    func console(_ str: String) {
        
        DispatchQueue.main.async { [conView = self.consoleView] in
            conView?.text = str + "\n" + conView!.text
            print(str)
        }

    }

}

extension ViewController: SRWebSocketDelegate {
    
    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        
        if case let text as String = message {
            receiveTextHandler(text)
        }
        else if case let data as Data = message {
            receiveDataHandler(data)
        }
        
    }


    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        console("socket连接成功")
        recorderBtn.isEnabled = true
        reopenBtn.isHidden = true
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        console("socket连接关闭,reason: \(reason)")
        recorderBtn.isEnabled = false
        reopenBtn.isHidden = false
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        console("socket连接失败（超时）:\(error)")
        recorderBtn.isEnabled = false
        reopenBtn.isHidden = false
    }
    
    func webSocketShouldConvertTextFrame(toString webSocket: SRWebSocket!) -> Bool {
        return true
    }
    
}
