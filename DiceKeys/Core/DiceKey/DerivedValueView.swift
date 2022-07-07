//
//  DerivedValueView.swift
//  DiceKeys
//
//  Created by Angelos Veglektsis on 7/6/22.
//

import SeededCrypto

enum DerivedValueView: Int, CaseIterable, Identifiable  {
    case JSON
    case Password
    case Hex
    case HexSigningKey
    case HexUnsealing
    case HexSealing
    case BIP39
    case OpenPGPPrivateKey
    case OpenSSHPrivateKey
    case OpenSSHPublicKey
    
    var id: Int { self.rawValue }
    
    var description: String {
        switch self{
            case .JSON : return "JSON"
            case .Password : return "Password"
            case .Hex: return "HEX"
            case .HexSigningKey : return "HEX (Signing Key)"
            case .HexUnsealing : return "HEX (Unsealing Key)"
            case .HexSealing: return "HEX (Sealing Key)"
            case .BIP39: return "BIP39"
            case .OpenPGPPrivateKey: return "OpenPGP Private Key"
            case .OpenSSHPrivateKey:return "OpenSSH Private Key"
            case .OpenSSHPublicKey:return "OpenSSH Public Key"
        }
    }
}


protocol SerializableProtocol{
    func toJson() -> String
}
    
extension Password: SerializableProtocol{
    
}

protocol DerivedValue{
    
    var views: [DerivedValueView] { get }
    func valueForView(view: DerivedValueView) -> String
}

extension DerivedValue{
    func valueForView(view: DerivedValueView) -> String {
        return ""
    }
}

struct DerivedValuePassword : DerivedValue {
    let password : Password
    
    var views: [DerivedValueView] = [.Password, .JSON]
    
    func valueForView(view: DerivedValueView) -> String {
        switch view{
        case .Password: return password.password
        default: return password.toJson()
        }
    }
}

struct DerivedValueSecret : DerivedValue {
    let secret : Secret
    
    var views: [DerivedValueView] = [.JSON, .Hex, .BIP39]
    
    func valueForView(view: DerivedValueView) -> String {
        switch view{
        case .Hex: return secret.secretBytes().asHexString
        case .BIP39: return "BIP"
        default: return secret.toJson()
        }
    }
}

struct DerivedValueSigningKey : DerivedValue {
    let signingKey : SigningKey
    
    var views: [DerivedValueView] = [.JSON, .OpenPGPPrivateKey, .OpenSSHPrivateKey, .OpenSSHPublicKey, .HexSigningKey]
    
    func valueForView(view: DerivedValueView) -> String {
        switch view{
        case .OpenPGPPrivateKey: return signingKey.openPgpPemFormatSecretKey
        case .OpenSSHPrivateKey: return signingKey.openSshPemPrivateKey
        case .OpenSSHPublicKey: return signingKey.openSshPublicKey
        case .HexSigningKey: return signingKey.signingKeyBytes.asHexString
        default: return signingKey.toJson()
        }
    }
}

struct DerivedValueSymmetricKey : DerivedValue {
    let symmetricKey : SymmetricKey
    
    var views: [DerivedValueView] = [.JSON, .Hex]
    
    func valueForView(view: DerivedValueView) -> String {
        switch view{
        case .Hex: return symmetricKey.keyBytes.asHexString
        default: return symmetricKey.toJson()
        }
    }
}

struct DerivedValueUnsealingKey : DerivedValue {
    let unsealingKey : UnsealingKey
    
    var views: [DerivedValueView] = [.JSON, .HexUnsealing, .HexSealing]
    
    func valueForView(view: DerivedValueView) -> String {
        switch view{
        case .HexUnsealing: return unsealingKey.unsealingKeyBytes.asHexString
        case .HexSealing: return unsealingKey.sealingKeyBytes.asHexString
        default: return unsealingKey.toJson()
        }
    }
}
