//
//  SequenceNumberField.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/18.
//

import SwiftUI

struct SequenceNumberView: View {
    @Binding var sequenceNumber: Int

    var sequenceNumberString: Binding<String> {
        return Binding<String>(
            get: { String(sequenceNumber) },
            set: { newValue in
                if let newIntValue = Int(newValue.filter { "0123456789".contains($0) }) {
                    sequenceNumber = newIntValue
                }
            }
        )
    }

    var body: some View {
        HStack {
            VStack(alignment: .center, spacing: 0) {
                TextField("1", text: sequenceNumberString)
                    .font(.title)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center).frame(maxWidth: 40).padding(.leading, 10)
                    .padding(.top, 2)
                Text("Sequence").font(.footnote).foregroundColor(.gray)
                Text("Number").font(.footnote).foregroundColor(.gray)
            }
            VStack {
                Button(action: { sequenceNumber += 1 },
                    label: {
                        Image(systemName: "arrow.up.square")
                            .resizable().aspectRatio(contentMode: .fit).frame(height: 28)
                    }
                ).buttonStyle(PlainButtonStyle())
                Button(action: { sequenceNumber = max(1, sequenceNumber - 1) },
                    label: {
                        Image(systemName: "arrow.down.square")
                            .resizable().aspectRatio(contentMode: .fit).frame(height: 28)
                    }
                ).buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct SequenceNumberField: View {
    @Binding var sequenceNumber: Int

    var body: some View {
        HStack {
            Spacer()
            SequenceNumberView(sequenceNumber: $sequenceNumber)
            Spacer(minLength: 30)
            Text("If you need multiple passwords for a single website or service, change the sequence number to create additional passwords.")
                .foregroundColor(Color.formInstructions)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.01)
                .scaledToFit()
                .lineLimit(4)
            Spacer()
        }
    }
}
//
//struct SequenceNumberField_Previews: PreviewProvider {
//    static var previews: some View {
//        SequenceNumberField()
//    }
//}
