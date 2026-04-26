import Flutter
import UIKit
import AVFoundation
import WebRTC

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Initialize Native WebRTC Pipeline
    let registrar = self.registrar(forPlugin: "NativeFrontCamera")!
    NativeMultiCam.shared.setup(messenger: registrar.messenger())
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NativeMultiCam — Dual-camera WebRTC pipeline in native Swift
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


class NativeMultiCam: NSObject, RTCPeerConnectionDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    static let shared = NativeMultiCam()

    private var channel: FlutterMethodChannel?
    private var factory: RTCPeerConnectionFactory?
    
    // Capture state
    private var captureSession: AVCaptureSession?
    private let frontCaptureQueue = DispatchQueue(label: "com.taxi.multicam.front", qos: .userInteractive)
    private let backCaptureQueue = DispatchQueue(label: "com.taxi.multicam.back", qos: .userInteractive)
    
    // Two Sources & Tracks
    private var frontSource: RTCVideoSource?
    private var backSource: RTCVideoSource?
    private var frontTrack: RTCVideoTrack?
    private var backTrack: RTCVideoTrack?
    private var frontConnection: AVCaptureConnection?
    private var backConnection: AVCaptureConnection?
    private var frontOutput: AVCaptureVideoDataOutput?
    private var backOutput: AVCaptureVideoDataOutput?
    
    private let token = RTCVideoCapturer()

    // Connection mapping
    private var peerConnections: [String: RTCPeerConnection] = [:]
    private var connectionStreamTypes: [String: String] = [:]

    private var isCapturing = false
    private var frameCountFront = 0
    private var frameCountBack = 0
    private var hasReceivedFrontFrame = false
    private var hasReceivedBackFrame = false
    private var retryCount = 0

    func setup(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "com.taxi.native_front_camera", binaryMessenger: messenger)
        channel?.setMethodCallHandler { [weak self] call, result in
            self?.handleCall(call, result: result)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: .AVCaptureSessionRuntimeError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        RTCInitializeSSL()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        factory = RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
        
        // Persistent Sources & Tracks to survive session restarts
        frontSource = factory?.videoSource()
        backSource = factory?.videoSource()
        frontTrack = factory?.videoTrack(with: frontSource!, trackId: "front_track")
        backTrack = factory?.videoTrack(with: backSource!, trackId: "back_track")
        
        print("✅ [NATIVE] NativeMultiCam initialized and logging active")
    }

    @objc private func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        print("❌ [NATIVE] Capture session runtime error: \(error.localizedDescription) (code: \(error.code.rawValue))")
        
        if isCapturing {
            // Attempt recovery for common errors
            if error.code == .mediaServicesWereReset || error.code == .sessionConfigurationChanged || error.code.rawValue == -11873 {
                retryCount += 1
                if retryCount > 5 {
                    print("🚨 [NATIVE] Too many retries. Falling back to Single Cam.")
                    DispatchQueue.main.async { [weak self] in
                        self?.stopCapture(result: nil)
                        self?.startSingleCamSession(result: nil)
                    }
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                    self?.stopCapture(result: nil)
                    self?.startCapture(result: nil)
                }
            }
        }
    }

    private func handleCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "startCapture": startCapture(result: result)
        case "stopCapture":  stopCapture(result: result)
        case "createOffer":
            let connId = args["connectionId"] as? String ?? UUID().uuidString
            let streamType = args["streamType"] as? String ?? ""
            createOffer(connectionId: connId, streamType: streamType, result: result)
        case "setAnswer":
            let connId = args["connectionId"] as? String ?? ""
            let sdp = args["sdp"] as? String ?? ""
            setAnswer(connectionId: connId, sdp: sdp, result: result)
        case "addIceCandidate":
            let connId = args["connectionId"] as? String ?? ""
            let sdp = args["candidate"] as? String ?? ""
            let sdpMid = args["sdpMid"] as? String ?? ""
            let sdpMLineIndex = args["sdpMLineIndex"] as? Int32 ?? 0
            let candidate = RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
            peerConnections[connId]?.add(candidate) { _ in }
            result(true)
        case "disposeConnection":
            let connId = args["connectionId"] as? String ?? ""
            disposeConnection(connectionId: connId, result: result)
        default: result(FlutterMethodNotImplemented)
        }
    }

    // MARK: — Dual Camera Capture (AVCaptureMultiCamSession)
    
    private func startCapture(result: FlutterResult?) {
        if isCapturing && result != nil { result?(true); return }
        isCapturing = true
        retryCount = 0

        // Start capture on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if AVCaptureMultiCamSession.isMultiCamSupported {
                self.startMultiCamSession(result: result)
            } else {
                self.startSingleCamSession(result: result)
            }
        }
    }

    @available(iOS 13.0, *)
    private func startMultiCamSession(result: FlutterResult?) {
        hasReceivedFrontFrame = false
        hasReceivedBackFrame = false
        
        // Stop and nil out old session if any
        if let oldSession = captureSession {
            oldSession.stopRunning()
            captureSession = nil
        }

        let session = AVCaptureMultiCamSession()
        
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified
        )
        
        guard let frontDevice = discovery.devices.first(where: { $0.position == .front }),
              let backDevice = discovery.devices.first(where: { $0.position == .back }) else {
            result?(FlutterError(code: "CAM_MISSING", message: "Front or back camera missing", details: nil))
            return
        }

        do {
            // Let the system pick the best formats for MultiCam to avoid "Cannot Record" errors
            // Only set orientation and orientation-related settings
            
            session.beginConfiguration()
            
            // Setup Front
            let frontIn = try AVCaptureDeviceInput(device: frontDevice)
            let fOut = AVCaptureVideoDataOutput()
            fOut.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
            fOut.setSampleBufferDelegate(self, queue: frontCaptureQueue)
            fOut.alwaysDiscardsLateVideoFrames = true
            frontOutput = fOut
            
            if session.canAddInput(frontIn) { session.addInputWithNoConnections(frontIn) }
            if session.canAddOutput(fOut) { session.addOutputWithNoConnections(fOut) }
            
            if let port = frontIn.ports.first(where: { $0.mediaType == .video }) {
                let conn = AVCaptureConnection(inputPorts: [port], output: fOut)
                conn.videoOrientation = .portrait
                if session.canAddConnection(conn) { 
                    session.addConnection(conn) 
                    frontConnection = conn
                }
            }
            
            // Setup Back
            let backIn = try AVCaptureDeviceInput(device: backDevice)
            let bOut = AVCaptureVideoDataOutput()
            bOut.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
            bOut.setSampleBufferDelegate(self, queue: backCaptureQueue)
            bOut.alwaysDiscardsLateVideoFrames = true
            backOutput = bOut
            
            if session.canAddInput(backIn) { session.addInputWithNoConnections(backIn) }
            if session.canAddOutput(bOut) { session.addOutputWithNoConnections(bOut) }
            
            if let port = backIn.ports.first(where: { $0.mediaType == .video }) {
                let conn = AVCaptureConnection(inputPorts: [port], output: bOut)
                conn.videoOrientation = .portrait
                if session.canAddConnection(conn) { 
                    session.addConnection(conn) 
                    backConnection = conn
                }
            }
            
            session.commitConfiguration()
            
            captureSession = session
            // Run session start on a high priority background thread
            DispatchQueue.global(qos: .userInteractive).async {
                session.startRunning()
                print("✅ [NATIVE] MultiCam session RUNNING")
            }
            
            result?(true)
            
        } catch {
            isCapturing = false
            print("❌ [NATIVE] Setup Error: \(error.localizedDescription)")
            let nsError = error as NSError
            if nsError.code == -11873 || nsError.domain == "AVFoundationErrorDomain" && nsError.code == -11837 {
                print("♻️ [NATIVE] Device busy or background - retrying in 1s...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.startCapture(result: result)
                }
            } else {
                result?(FlutterError(code: "ERR", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func startSingleCamSession(result: FlutterResult?) {
        // Simple fallback
        print("⚠️ [NATIVE] MultiCam not supported. Using Front only.")
        let session = AVCaptureSession()
        session.sessionPreset = .vga640x480
        
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        guard let device = discovery.devices.first, let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) { session.addInput(input) }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: frontCaptureQueue)
        if session.canAddOutput(output) { session.addOutput(output) }
        
        captureSession = session
        frontCaptureQueue.async { session.startRunning() }
        isCapturing = true
        result?(true)
    }

    private func stopCapture(result: FlutterResult?) {
        isCapturing = false
        captureSession?.stopRunning()
        captureSession = nil
        frontConnection = nil
        backConnection = nil
        frontOutput = nil
        backOutput = nil
        result?(true)
    }

    // MARK: — WebRTC Offer
    
    private func createOffer(connectionId: String, streamType: String, result: @escaping FlutterResult) {
        guard let factory = factory else { return }
        
        let pc = factory.peerConnection(with: RTCConfiguration(), constraints: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil), delegate: self)
        guard let peerConnection = pc else { return }

        // Route correctly based on full stream type names
        let transceiverInit = RTCRtpTransceiverInit()
        transceiverInit.direction = .sendOnly
        
        if streamType == "tablet_main" || streamType == "phone_interior" {
            // Front/Interior camera
            let trackId = "front_track_\(connectionId)"
            let track = factory.videoTrack(with: frontSource!, trackId: trackId)
            transceiverInit.streamIds = ["stream_front_\(connectionId)"]
            if let transceiver = peerConnection.addTransceiver(with: track, init: transceiverInit) {
                let params = transceiver.sender.parameters
                if let encoding = params.encodings.first {
                    encoding.maxBitrateBps = NSNumber(value: 500_000)
                }
                transceiver.sender.parameters = params
                print("📺 [NATIVE] Added Front Track (\(trackId)) to \(connectionId) with 500kbps limit")
            }
        } else {
            // Back/Road camera
            let trackId = "back_track_\(connectionId)"
            let track = factory.videoTrack(with: backSource!, trackId: trackId)
            transceiverInit.streamIds = ["stream_back_\(connectionId)"]
            if let transceiver = peerConnection.addTransceiver(with: track, init: transceiverInit) {
                let params = transceiver.sender.parameters
                if let encoding = params.encodings.first {
                    encoding.maxBitrateBps = NSNumber(value: 500_000)
                }
                transceiver.sender.parameters = params
                print("📺 [NATIVE] Added Back Track (\(trackId)) to \(connectionId) with 500kbps limit")
            }
        }

        peerConnections[connectionId] = peerConnection
        connectionStreamTypes[connectionId] = streamType

        // Tiny delay to ensure transceivers are fully registered in the SDP engine
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self, let pc = self.peerConnections[connectionId] else { return }
            
            print("📤 [NATIVE] Generating offer for \(streamType)...")
            pc.offer(for: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)) { sdp, error in
                if let sdp = sdp {
                    pc.setLocalDescription(sdp) { error in
                        if let error = error {
                            print("❌ [NATIVE] setLocalDescription failed: \(error.localizedDescription)")
                            return
                        }
                        print("📤 [NATIVE] Offer sent for \(streamType) (ID: \(connectionId))")
                        result(["sdp": sdp.sdp, "type": RTCSessionDescription.string(for: sdp.type)])
                    }
                } else if let error = error {
                    print("❌ [NATIVE] Offer generation failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func setAnswer(connectionId: String, sdp: String, result: @escaping FlutterResult) {
        print("📥 [NATIVE] Received Answer for \(connectionId)")
        peerConnections[connectionId]?.setRemoteDescription(RTCSessionDescription(type: .answer, sdp: sdp)) { _ in result(true) }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        autoreleasepool {
            guard let pixels = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let timestampNs = Int64(CMTimeGetSeconds(timestamp) * 1_000_000_000)
            
            let rtcBuffer = RTCCVPixelBuffer(pixelBuffer: pixels)
            let frame = RTCVideoFrame(buffer: rtcBuffer, rotation: ._0, timeStampNs: timestampNs)
            
            if output === frontOutput {
                if !hasReceivedFrontFrame {
                    hasReceivedFrontFrame = true
                    print("✨ [NATIVE] First Front Frame received!")
                }
                frameCountFront += 1
                if frameCountFront % 120 == 0 { print("📹 [NATIVE] Front Frames: \(frameCountFront)") }
                frontSource?.capturer(token, didCapture: frame)
            } else if output === backOutput {
                if !hasReceivedBackFrame {
                    hasReceivedBackFrame = true
                    print("✨ [NATIVE] First Back Frame received!")
                }
                frameCountBack += 1
                if frameCountBack % 120 == 0 { print("📹 [NATIVE] Back Frames: \(frameCountBack)") }
                backSource?.capturer(token, didCapture: frame)
            }
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        guard let connId = peerConnections.first(where: { $0.value === peerConnection })?.key else { return }
        print("🧊 [NATIVE] Generated ICE candidate for \(connId)")
        
        let args: [String: Any] = [
            "connectionId": connId,
            "candidate": candidate.sdp,
            "sdpMid": candidate.sdpMid ?? "",
            "sdpMLineIndex": Int(candidate.sdpMLineIndex)
        ]
        
        DispatchQueue.main.async { 
            self.channel?.invokeMethod("onIceCandidate", arguments: args) 
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        var stateStr = ""
        switch newState {
        case .new: stateStr = "new"
        case .checking: stateStr = "checking"
        case .connected: stateStr = "connected"
        case .completed: stateStr = "completed"
        case .failed: stateStr = "failed"
        case .disconnected: stateStr = "disconnected"
        case .closed: stateStr = "closed"
        @unknown default: stateStr = "unknown"
        }
        
        print("🧊 [NATIVE] ICE State for \(peerConnection.hashValue): \(stateStr) (\(newState.rawValue))")
        
        if newState == .failed || newState == .disconnected || newState == .closed {
            guard let connId = peerConnections.first(where: { $0.value === peerConnection })?.key else { return }
            let streamType = connectionStreamTypes[connId] ?? ""
            print("⚠️ [NATIVE] Reporting connection failure/close: \(connId) -> \(stateStr)")
            DispatchQueue.main.async { self.channel?.invokeMethod("onIceStateChange", arguments: ["connectionId": connId, "state": stateStr, "streamType": streamType]) }
        }
    }

    private func disposeConnection(connectionId: String, result: @escaping FlutterResult) {
        print("🗑️ [NATIVE] Disposing connection: \(connectionId)")
        peerConnections[connectionId]?.close()
        peerConnections.removeValue(forKey: connectionId)
        result(true)
    }

    @objc private func appDidEnterBackground() {
        print("💤 [NATIVE] App entered background")
        stopCapture(result: nil)
    }

    @objc private func appWillEnterForeground() {
        print("🌅 [NATIVE] App entering foreground")
        // Delay restart to ensure OS has released camera from background state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.startCapture(result: nil)
        }
    }

    // MARK: — PeerConnection Delegates (Empty implementations for unused methods)
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd receiver: RTCRtpReceiver, streams: [RTCMediaStream]) {}
}
