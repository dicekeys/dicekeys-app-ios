//
//  CustomDiceFaceView.swift
//  DiceKeys
//
//  Created by Kevin Shah on 16/01/21.
//

import SwiftUI
//
/// DiceFaceManager
class EditableDiceKeyState: ObservableObject {
    @Published var faces: [PartialFace]
    @Published var faceSelectedIndex: Int = 0  { didSet { objectWillChange.send() } }
    
    init() {
        faces = (0...24).map { PartialFace(index: $0) }
    }

    var faceSelected: PartialFace? {
        get { faces[faceSelectedIndex] }
        set { if let value = newValue, faceSelectedIndex >= 0 && faceSelectedIndex < 25 { faces[faceSelectedIndex] = value } }
    }

    var nextEmptyDieIndex: Int? {
        faces.first { !$0.isDiceFaceModelValid }?.index
    }
    
    func moveNext() {
        faceSelectedIndex = min(24, faceSelectedIndex + 1)
    }
    
    func movePrev() {
        faceSelectedIndex = max(0, faceSelectedIndex - 1)
    }
    
    func moveDown() {
        faceSelectedIndex = (faceSelectedIndex + 5) % 25
    }

    func moveUp() {
        faceSelectedIndex = (faceSelectedIndex + 20) % 25
    }

}

struct EditableDiceKeyView: View {
    @ObservedObject var editableDiceKeyState: EditableDiceKeyState
    
    var body: some View {
        GeometryReader { (geo) in
            let width: CGFloat = geo.size.width / 5
            let height: CGFloat = geo.size.height / 5
            LazyVGrid(columns: Array(repeating: GridItem(), count: 5), spacing: 4, content: {
                ForEach(editableDiceKeyState.faces) { face  in
                    DieFaceView(face: face, dieSize: CGFloat(max(1, min(width, height) - 4)), faceSurfaceColor: (editableDiceKeyState.faceSelectedIndex == face.index) ? .green : .white)
                        .frame(width: width, height: height)
                        .cornerRadius(12)
                        .onTapGesture {
                            editableDiceKeyState.faceSelectedIndex = face.index
                        }
                }
            })
//            .frame(width: geo.size.width, height: geo.size.height)
        }.aspectRatio(contentMode: .fit)
    }
}
