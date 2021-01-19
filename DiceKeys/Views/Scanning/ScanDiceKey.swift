//
//  ScanDiceKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI
import AVFoundation

struct ScanDiceKey: View {
    #if os(iOS)
    @State var cameraAuthorized: Bool = true
    #else
    @State var cameraAuthorized: Bool = false
    #endif
    
    var stickers: Bool = false
    let onDiceKeyRead: ((_ diceKey: DiceKey) -> Void)?

    init(stickers: Bool = false, onDiceKeyRead: ((_ diceKey: DiceKey) -> Void)? = nil) {
        self.stickers = stickers
        self.onDiceKeyRead = onDiceKeyRead
        getAvailableCameras()
    }

    @State var frameCount: Int = 0
    @State var facesRead: [FaceRead]?
    @State var processedImageFrameSize: CGSize?
    @State var selectedCameraIndex: Int = 0
    private var availableCameras = [AVCaptureDevice]()

    func onFrameProcessed(_ processedImageFrameSize: CGSize, _ facesRead: [FaceRead]?) {
        self.frameCount += 1
        self.processedImageFrameSize = processedImageFrameSize
        self.facesRead = facesRead
        if facesRead?.count == 25 && facesRead?.allSatisfy({ faceRead in faceRead.errors.count == 0 }) == true {
            try? onDiceKeyRead?(DiceKey(facesRead!).rotatedClockwise90Degrees())
        }
    }
    
    mutating func getAvailableCameras() {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes:
                                                                    [AVCaptureDevice.DeviceType.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video, position: .unspecified)
        for device in discoverySession.devices {
            if (device.hasMediaType(.video) && device.isConnected && !device.isSuspended) {
                availableCameras.append(device)
            }
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if cameraAuthorized {
                Text("Place the DiceKey so that the \(stickers ? "stickers" : "dice") fill the camera view. Then hold steady.").font(.title2)
                VStack(alignment: .center, spacing: 0) {
                    HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 0) {
                        Spacer()
                            GeometryReader { reader in
                                ZStack {
                                    DiceKeysCameraView(availableCameras[selectedCameraIndex], onFrameProcessed: onFrameProcessed, size: reader.size)
                                    FacesReadOverlay(
                                        renderedSize: reader.size,
                                        imageFrameSize: processedImageFrameSize ?? reader.size,
                                        facesRead: self.facesRead
                                    )
                                }
                            }.aspectRatio(1, contentMode: .fit)
                        Spacer()
                    }
                    if availableCameras.count > 1 {
                        Picker("Cameras", selection: $selectedCameraIndex) {
                            ForEach(availableCameras.indices) { index in
                                Text(self.availableCameras[index].localizedName)
                            }
                        }
                    }
                    Text("\(frameCount) frames processed").font(.footnote).foregroundColor(.white).padding(.top, 3)
                }.background(Color.black).padding(.vertical, 5)
            } else {
                Text("Allow camera access, please")
            }
        }.onAppear {
            #if os(macOS)
            switch AVCaptureDevice.authorizationStatus(for: .video) {
                case .authorized: // The user has previously granted access to the camera.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        cameraAuthorized = true
                    }
                case .notDetermined: // The user has not yet been asked for camera access.
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        if granted {
                            cameraAuthorized = true                  }
                    }
                
                case .denied: // The user has previously denied access.
                    return

                case .restricted: // The user can't grant access due to restrictions.
                    return
            }
            #endif
        }
    }
}

struct ScanDiceKey_Previews: PreviewProvider {
    static var previews: some View {
        #if os(iOS)
        ScanDiceKey().previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
        #else
        ScanDiceKey()
        #endif
    }
}
