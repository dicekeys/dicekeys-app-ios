//
//  MnemonicsUnitTests.swift
//  Tests iOS
//
//  Created by Angelos Veglektsis on 7/12/22.
//

import XCTest
import DiceKeys

extension StringProtocol {
    var hexAsByteArray: [UInt8] { .init(hexa) }
    private var hexa: UnfoldSequence<UInt8, Index> {
        sequence(state: startIndex) { startIndex in
            guard startIndex < self.endIndex else { return nil }
            let endIndex = self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
}

class MnemonicsUnitTests: XCTestCase {
    
    func testWordlist() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
                
        XCTAssertEqual(Wordlist.english.count, 2048)
    }
    
    func testByte(){
        XCTAssertEqual("abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about", try! Mnemonic.toMnemonic("00000000000000000000000000000000".hexAsByteArray).joined(separator: " "))
        
        XCTAssertEqual("legal winner thank year wave sausage worth useful legal winner thank yellow", try! Mnemonic.toMnemonic("7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f".hexAsByteArray).joined(separator: " "))
        
        XCTAssertEqual("all hour make first leader extend hole alien behind guard gospel lava path output census museum junior mass reopen famous sing advance salt reform", try! Mnemonic.toMnemonic("066dca1a2bb7e8a1db2832148ce9933eea0f3ac9548d793112d9a95c9407efad".hexAsByteArray).joined(separator: " "))
        
        XCTAssertEqual("vessel ladder alter error federal sibling chat ability sun glass valve picture", try! Mnemonic.toMnemonic("f30f8c1da665478f49b001d94c5fc452".hexAsByteArray).joined(separator: " "))
        
        XCTAssertEqual("scissors invite lock maple supreme raw rapid void congress muscle digital elegant little brisk hair mango congress clump", try! Mnemonic.toMnemonic("c10ec20dc3cd9f652c7fac2f1230f7a3c828389a14392f05".hexAsByteArray).joined(separator: " "))
        
        XCTAssertEqual("void come effort suffer camp survey warrior heavy shoot primary clutch crush open amazing screen patrol group space point ten exist slush involve unfold", try! Mnemonic.toMnemonic("f585c11aec520db57dd353c69554b21a89b20fb0650966fa0a9d6f74fd989d8f".hexAsByteArray).joined(separator: " "))
    }
}
