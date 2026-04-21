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
    private let captureQueue = DispatchQueue(label: "com.taxi.multicam.capture", qos: .userInteractive)
    
    // Two Sources & Tracks
    private var frontSource: RTCVideoSource?
    private var backSource: RTCVideoSource?
    private var frontTrack: RTCVideoTrack?
    private var backTrack: RTCVideoTrack?
    
    private let token = RTCVideoCapturer()

    // Connection mapping
    private var peerConnections: [String: RTCPeerConnection] = [:]
    private var connectionStreamTypes: [String: String] = [:]

    private var isCapturing = false

    func setup(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "com.taxi.native_front_camera", binaryMessenger: messenger)
        channel?.setMethodCallHandler { [weak self] call, result in
            self?.handleCall(call, result: result)
        }

        RTCInitializeSSL()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        factory = RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
        print("✅ [NATIVE] NativeMultiCam initialized")
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
            addIceCandidate(connectionId: connId, args: args, result: result)
        case "disposeConnection":
            let connId = args["connectionId"] as? String ?? ""
            disposeConnection(connectionId: connId, result: result)
        default: result(FlutterMethodNotImplemented)
        }
    }

    // MARK: — Dual Camera Capture (AVCaptureMultiCamSession)
    
    private func startCapture(result: @escaping FlutterResult) {
        if isCapturing { result(true); return }

        // Start capture on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if #available(iOS 13.0, *), AVCaptureMultiCamSession.isMultiCamSupported {
                self.startMultiCamSession(result: result)
            } else {
                // Fallback to separate sessions if MultiCam is not supported
                self.startSingleCamSession(result: result)
            }
        }
    }

    @available(iOS 13.0, *)
    private func startMultiCamSession(result: @escaping FlutterResult) {
        let session = AVCaptureMultiCamSession()
        
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified
        )
        
        guard let frontDevice = discovery.devices.first(where: { $0.position == .front }),
              let backDevice = discovery.devices.first(where: { $0.position == .back }) else {
            result(FlutterError(code: "CAM_MISSING", message: "Front or back camera missing", details: nil))
            return
        }

        do {
            // Setup Front
            let frontIn = try AVCaptureDeviceInput(device: frontDevice)
            let frontOut = AVCaptureVideoDataOutput()
            frontOut.setSampleBufferDelegate(self, queue: captureQueue)
            
            if session.canAddInput(frontIn) { session.addInputWithNoConnections(frontIn) }
            if session.canAddOutput(frontOut) { session.addOutputWithNoConnections(frontOut) }
            
            if let port = frontIn.ports.first(where: { $0.mediaType == .video }) {
                let conn = AVCaptureConnection(inputPorts: [port], output: frontOut)
                conn.videoOrientation = .portrait
                if session.canAddConnection(conn) { session.addConnection(conn) }
            }
            
            // Setup Back
            let backIn = try AVCaptureDeviceInput(device: backDevice)
            let backOut = AVCaptureVideoDataOutput()
            backOut.setSampleBufferDelegate(self, queue: captureQueue)
            
            if session.canAddInput(backIn) { session.addInputWithNoConnections(backIn) }
            if session.canAddOutput(backOut) { session.addOutputWithNoConnections(backOut) }
            
            if let port = backIn.ports.first(where: { $0.mediaType == .video }) {
                let conn = AVCaptureConnection(inputPorts: [port], output: backOut)
                conn.videoOrientation = .portrait
                if session.canAddConnection(conn) { session.addConnection(conn) }
            }
            
            frontSource = factory?.videoSource()
            backSource = factory?.videoSource()
            frontTrack = factory?.videoTrack(with: frontSource!, trackId: "front_track")
            backTrack = factory?.videoTrack(with: backSource!, trackId: "back_track")
            
            captureSession = session
            captureQueue.async {
                session.startRunning()
                print("✅ [NATIVE] MultiCam session RUNNING")
            }
            
            isCapturing = true
            result(true)
            
        } catch {
            result(FlutterError(code: "ERR", message: error.localizedDescription, details: nil))
        }
    }
    
    private func startSingleCamSession(result: @escaping FlutterResult) {
        // Simple fallback
        print("⚠️ [NATIVE] MultiCam not supported. Using Front only.")
        let session = AVCaptureSession()
        session.sessionPreset = .vga640x480
        
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        guard let device = discovery.devices.first, let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) { session.addInput(input) }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: captureQueue)
        if session.canAddOutput(output) { session.addOutput(output) }
        
        frontSource = factory?.videoSource()
        frontTrack = factory?.videoTrack(with: frontSource!, trackId: "front_track")
        
        captureSession = session
        captureQueue.async { session.startRunning() }
        isCapturing = true
        result(true)
    }

    private func stopCapture(result: @escaping FlutterResult) {
        captureSession?.stopRunning()
        captureSession = nil
        frontSource = nil
        backSource = nil
        frontTrack = nil
        backTrack = nil
        isCapturing = false
        for (_, pc) in peerConnections { pc.close() }
        peerConnections.removeAll()
        result(true)
    }

    // MARK: — WebRTC Offer
    
    private func createOffer(connectionId: String, streamType: String, result: @escaping FlutterResult) {
        guard let factory = factory else { return }
        
        let pc = factory.peerConnection(with: RTCConfiguration(), constraints: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil), delegate: self)
        guard let peerConnection = pc else { return }

        // Route correctly:
        // tablet_main / phone_interior -> front
        // phone_front_road -> back
        if streamType == "phone_front_road" {
            if let track = backTrack { peerConnection.add(track, streamIds: [streamType]) }
        } else {
            if let track = frontTrack { peerConnection.add(track, streamIds: [streamType]) }
        }

        peerConnections[connectionId] = peerConnection
        connectionStreamTypes[connectionId] = streamType

        peerConnection.offer(for: RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveVideo": "false"], optionalConstraints: nil)) { sdp, _ in
            peerConnection.setLocalDescription(sdp!) { _ in
                print("📤 [NATIVE] Offer sent for \(streamType)")
                result(["sdp": sdp!.sdp, "type": RTCSessionDescription.string(for: sdp!.type)])
            }
        }
    }

    private func setAnswer(connectionId: String, sdp: String, result: @escaping FlutterResult) {
        peerConnections[connectionId]?.setRemoteDescription(RTCSessionDescription(type: .answer, sdp: sdp)) { _ in result(true) }
    }

    private func addIceCandidate(connectionId: String, args: [String: Any], result: @escaping FlutterResult) {
        let candidate = RTCIceCandidate(sdp: args["candidate"] as! String, sdpMLineIndex: Int32(args["sdpMLineIndex"] as! Int), sdpMid: args["sdpMid"] as? String)
        peerConnections[connectionId]?.add(candidate) { _ in }
        result(true)
    }

    private func disposeConnection(connectionId: String, result: @escaping FlutterResult) {
        peerConnections[connectionId]?.close()
        peerConnections.removeValue(forKey: connectionId)
        result(true)
    }

    // MARK: — Delegates
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixels = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let rtcBuffer = RTCCVPixelBuffer(pixelBuffer: pixels)
        let frame = RTCVideoFrame(buffer: rtcBuffer, rotation: ._0, timeStampNs: Int64(CACurrentMediaTime() * 1_000_000_000))
        
        // Detect source by finding the connection device position if possible
        // Actually, we can check which output the sample came from by checking the connection.
        // Or check device position of input.
        
        for port in connection.inputPorts {
            if let input = (captureSession?.inputs as? [AVCaptureDeviceInput])?.first(where: { $0.ports.contains(port) }) {
                if #available(iOS 13.0, *) {
                    if input.device.position == AVCaptureDevice.Position.front {
                        frontSource?.capturer(token, didCapture: frame)
                    } else if input.device.position == AVCaptureDevice.Position.back {
                        backSource?.capturer(token, didCapture: frame)
                    }
                } else {
                    frontSource?.capturer(token, didCapture: frame)
                }
                break
            }
        }

    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        guard let connId = peerConnections.first(where: { $0.value === peerConnection })?.key else { return }
        DispatchQueue.main.async { self.channel?.invokeMethod("onIceCandidate", arguments: ["connectionId": connId, "candidate": candidate.sdp, "sdpMid": candidate.sdpMid ?? "", "sdpMLineIndex": candidate.sdpMLineIndex]) }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("🧊 [NATIVE] ICE State: \(newState.rawValue)")
        if newState == .failed {
            guard let connId = peerConnections.first(where: { $0.value === peerConnection })?.key else { return }
            let streamType = connectionStreamTypes[connId] ?? ""
            DispatchQueue.main.async { self.channel?.invokeMethod("onIceStateChange", arguments: ["connectionId": connId, "state": "failed", "streamType": streamType]) }
        }
    }

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

