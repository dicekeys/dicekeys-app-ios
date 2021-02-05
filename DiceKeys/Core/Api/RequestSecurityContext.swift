//
//  RequestContext.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/04.
//

import Foundation

protocol RequestSecurityContext {
    var validatedByAuthToken: Bool { get }
    var host: String { get }
    var path: String { get }

    func satisfiesAuthenticationRequirements(
        of requirements: AuthenticationRequirements,
        allowNullRequirement: Bool
    ) -> Bool
}

let DefaultPermittedPathPrefix = "/--derived-secret-api--/"
let DefaultPathRequirement = DefaultPermittedPathPrefix + "*"

extension RequestSecurityContext {
    private func satisfiesPathRequirement(of pathRequirement: String) -> Bool {
        let pathExpected = (pathRequirement.hasPrefix("/")) ? pathRequirement :
            // Paths must start with a "/".  If the path requirement didn't start with a "/",
            // we'll insert one assuming this was a mistake by the developer of the client software
            // that created the derivationOptionsJson string.
            "/" + pathRequirement
        if pathExpected.hasSuffix("/*") {
            return
                self.path.hasPrefix(pathExpected.prefix(pathExpected.count - 1)) ||
                self.path == pathExpected.prefix(pathExpected.count - 2)
        } else if pathExpected.hasSuffix("*") {
            // The path requirement specifies a prefix, so test for a prefix match
            return self.path.hasPrefix(pathExpected.prefix(pathExpected.count - 1))
        } else {
            // This path requirement does not specify a prefix, so test for exact match
            return self.path == pathExpected
        }
    }

    private func satisfiesHostRequirement(of hostRequirement: String) -> Bool {
        // (A)
        // There is no "*." prefix in the hostExpected specification so an exact
        // match is required
        return self.host == hostRequirement ||
        // (B)
        // The host requirement specification has a wildcard subdomain prefix ".*"
        (
          hostRequirement.hasPrefix("*.") && // and
          (
            // The host is not a subdomain, but the parent domain
            // (e.g. "example.com" satisfies "*.example.com" with
            //  hostExpected is "*.example.com" and hostObserved is "example.com")
            self.host == hostRequirement.suffix(hostRequirement.count - 2) ||
            // Or the host is a valid subdomain, with a prefix that ends in a "."
            // (e.g. "sub.example.com" ends in (".example.com" with
            //  hostExpected of "*.example.com" and hostObserved of "example.com")
            self.host.hasSuffix(hostRequirement.suffix(hostRequirement.count - 1))
          )
        )
    }

    func satisfiesAuthenticationRequirements(
        of requirements: AuthenticationRequirements,
        allowNullRequirement: Bool
    ) -> Bool {
        if requirements.requireAuthenticationHandshake == true && !validatedByAuthToken {
            // Auth token required but not present
            return false
        }
        if let allow = requirements.allow {
            return allow.contains { webBasedApplicationIdentity in
                if !satisfiesHostRequirement(of: webBasedApplicationIdentity.host) {
                    return false
                }
                if let paths = webBasedApplicationIdentity.paths {
                    return paths.contains { pathRequirement in
                        satisfiesPathRequirement(of: pathRequirement)
                    }
                } else {
                    return satisfiesPathRequirement(of: DefaultPathRequirement)
                }
            }
        } else {
            return allowNullRequirement
        }
    }
}
