//
//  ScanDiceKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI
import AVFoundation

// Extend AVCaptureDevice to make it Identifiable by allowing the uniqueID field
// to be accessed via the ID alias.
extension AVCaptureDevice: Identifiable {
    var ID: String { self.uniqueID }
    
    var canBeDisplayed: Bool {
        self.hasMediaType(.video) && self.isConnected && !self.isSuspended
    }
}

#if os(iOS)
private let defaultCameraAuthorized: Bool = true
#else
private let defaultCameraAuthorized: Bool = false
#endif

enum LoadDiceKeyEntryMethod {
    case byCamera
    case manual
}

struct ScanDiceKey: View {
    @State var cameraAuthorized: Bool = defaultCameraAuthorized
    
    var stickers: Bool = false
    let onDiceKeyRead: ((_ diceKey: DiceKey) -> Void)?

    init(stickers: Bool = false, onDiceKeyRead: ((_ diceKey: DiceKey) -> Void)? = nil) {
        self.stickers = stickers
        self.onDiceKeyRead = onDiceKeyRead
        self.selectedCameraUniqueId = activeCameras.first?.ID ?? ""
//        self.selectedCamera = activeCameras.first
    }

    @State var selectedCameraUniqueId: String = ""

    var cameraFrameCountModel: CameraFrameCountModel = CameraFrameCountModel()
    var facesReadOverlayModel: FacesReadOverlayModel = FacesReadOverlayModel()
    
//    @State var selectedCamera: AVCaptureDevice?
 
    var selectedCamera: AVCaptureDevice? {
        activeCameras.first { $0.ID == selectedCameraUniqueId }
    }
    
    var activeCameras: [AVCaptureDevice] { ActiveCameras.get() }    
    
    var selectedOrNextBestCameraDisplayableCamera: AVCaptureDevice? {
        if let selectedCamera = self.selectedCamera, selectedCamera.canBeDisplayed {
            return selectedCamera
        } else {
            return activeCameras.first
        }
    }

    func onFrameProcessed(_ processedImageFrameSize: CGSize, _ facesRead: [FaceRead]?) {
        DispatchQueue.main.async {
            cameraFrameCountModel.frameCount += 1
            facesReadOverlayModel.facesRead = facesRead ?? []
            if facesReadOverlayModel.imageFrameSize != processedImageFrameSize {
                facesReadOverlayModel.imageFrameSize = processedImageFrameSize
            }
        }

        if facesRead?.count == 25 && facesRead?.allSatisfy({ faceRead in faceRead.errors.count == 0 }) == true {
            try? onDiceKeyRead?(DiceKey(facesRead!).rotatedClockwise90Degrees())
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if cameraAuthorized {
                Text("Place the DiceKey so that the \(stickers ? "stickers" : "dice") fill the camera view. Then hold steady.").font(.title2)
                VStack(alignment: .center, spacing: 0) {
                    // For debugging: remove
                    Text("Selected camera: \(selectedOrNextBestCameraDisplayableCamera?.localizedName ?? "nil")")
                    HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 0) {
                        Spacer()
                        GeometryReader { reader in
                            ZStack {
                                DiceKeysCameraView(selectedCamera: selectedOrNextBestCameraDisplayableCamera, onFrameProcessed: onFrameProcessed, size: reader.size)
                                FacesReadOverlay(renderedSize: reader.size,
                                                 facesReadOverlayModel: facesReadOverlayModel)
                            }
                        }
                    }
                    CameraFrameCountView(cameraFrameCountModel: self.cameraFrameCountModel)
                }
                .background(Color.black)
                .padding(.vertical, 5)
            } else {
                Text("Permission to access the camera is required to scan your DiceKey")
            }
        }.onAppear {
            #if os(macOS)
            switch AVCaptureDevice.authorizationStatus(for: .video) {
                case .authorized: // The user has previously granted access to the camera.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        cameraAuthorized = true
                        if (self.selectedCamera == nil) {
                            self.selectedCameraUniqueId = activeCameras.first?.ID ?? ""
                            // self.selectedCamera = activeCameras.first
                        }
                    }
                    case .notDetermined: // The user has not yet been asked for camera access.
                        AVCaptureDevice.requestAccess(for: .video) { granted in
                            if granted {
                                cameraAuthorized = true                  }
                            if (self.selectedCamera == nil) {
                                self.selectedCameraUniqueId = activeCameras.first?.ID ?? ""
                                // self.selectedCamera = activeCameras.first
                            }
                        }
                    
                    case .denied: // The user has previously denied access.
                        return

                    case .restricted: // The user can't grant access due to restrictions.
                        return
                @unknown default:
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
