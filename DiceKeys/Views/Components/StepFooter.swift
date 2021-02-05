//
//  StepFooter.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/16.
//

import SwiftUI

struct StepFooterView: View {
    let goTo: (Int) -> Void
    let prevPrev: (() -> Void)?
    let prev: (() -> Void)?
    let next: (() -> Void)?
    let nextNext: (() -> Void)?
    let setMaySkip: (() -> Void)?
    let isLastStep: Bool

    init(goTo: @escaping (Int) -> Void,
         prevPrev: (() -> Void)? = nil,
         prev: (() -> Void)? = nil,
         next: (() -> Void)? = nil,
         nextNext: (() -> Void)? = nil,
         setMaySkip: (() -> Void)? = nil,
         isLastStep: Bool
    ) {
        self.goTo = goTo
        self.prevPrev = prevPrev
        self.prev = prev
        self.next = next
        self.nextNext = nextNext
        self.setMaySkip = setMaySkip
        self.isLastStep = isLastStep
    }

    init(goTo: @escaping (Int) -> Void,
         step: Int,
         prevPrev: Int? = nil,
         prev: Int? = nil,
         next: Int? = nil,
         nextNext: Int? = nil,
         setMaySkip: (() -> Void)? = nil,
         isLastStep: Bool
    ) {
        self.goTo = goTo
        func goToIfDefined(_ condition: Bool, _ dest: Int?) -> (() -> Void)? {
            guard let dest = dest, condition == true else { return nil }
            return { goTo(dest) }
        }
        self.prevPrev = goToIfDefined(prevPrev != nil && prev != nil && prev! < step && prevPrev! < prev!, prevPrev)
        self.prev = goToIfDefined(prev != nil && prev! < step, prev)
        self.next = goToIfDefined(next != nil && next! > step, next)
        self.nextNext = goToIfDefined(nextNext != nil && next != nil && next! > step && nextNext! > next!, nextNext)
        self.setMaySkip = setMaySkip
        self.isLastStep = isLastStep
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { setMaySkip?() },
                    label: { Text("Let me skip this step").font(.body) }
                ).padding(.bottom, 7).showIf( setMaySkip != nil )
                Spacer()
            }
            HStack {
                Button(action: { prevPrev?() }) {
                    HStack {
                        Image(systemName: "chevron.backward.2")
                    }
                }.showIf( prevPrev != nil )
                Button(action: { prev?() }) {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Previous").font(.title2)
                    }
                }.showIf( prev != nil )
                Button(action: { next?() }) {
                    HStack {
                        Text( isLastStep ? "Done" : "Next").font(.title2)
                        Image(systemName: "chevron.forward")
                    }
                }.disabled( setMaySkip != nil ).showIf( next != nil )
                Button(action: { nextNext?() }) {
                    HStack {
                        Image(systemName: "chevron.forward.2")
                    }
                }.showIf( nextNext != nil )
            }
            .frame(alignment: .center)
        }
    }
}

//struct StepFooter_Previews: PreviewProvider {
//    static var previews: some View {
//        StepFooter()
//    }
//}
