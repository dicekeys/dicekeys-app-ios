//
//  BlankView.swift
//  DiceKeys
//
//  Created by Kevin Shah on 16/01/21.
//

import SwiftUI

/// BlankViewModel
class BlankViewModel: ObservableObject {
    
    @Published var isSelected: Bool
    
    init(_ isSelected: Bool) {
        self.isSelected = isSelected
    }
}

/// BlankView
struct BlankView: View {
    
    @ObservedObject var blankViewModel: BlankViewModel
    
    var body: some View {
        GeometryReader { (geo) in
            VStack {
                
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            .background(blankViewModel.isSelected ? Color.green : .white)
            .cornerRadius(12)
        }
    }
}
