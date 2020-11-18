//
//  PermissionChecks.swift
//  
//
//  Created by Stuart Schechter on 2020/11/14.
//

import Foundation


let DefaultPermittedPathPrefix = "/--derived-secret-api--/"
let DefaultPathRequirement = DefaultPermittedPathPrefix + "*"


class RequestContext {
    let validatedByAuthToken: Bool
    let host: String
    let path: String

    init (url: URL, validatedByAuthToken: Bool = false) {
        // self.url = url
        self.host = url.host ?? ""
        self.path = url.path
        self.validatedByAuthToken = validatedByAuthToken
    }
    
    private func satisfiesPathRequirement(of pathRequirement: String) -> Bool {
        let pathExpected = (pathRequirement.hasPrefix("/")) ? pathRequirement :
            // Paths must start with a "/".  If the path requirement didn't start with a "/",
            // we'll insert one assuming this was a mistake by the developer of the client software
            // that created the derivationOptionsJson string.
            "/" + pathRequirement
        if (pathExpected.hasSuffix("/*")) {
            return
                self.path.hasPrefix(pathExpected.prefix(pathExpected.count - 1)) ||
                self.path == pathExpected.prefix(pathExpected.count - 2)
        } else if (pathExpected.hasSuffix("*")) {
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
        allowNullRequirement: Bool = false
    ) -> Bool {
        if (requirements.requireAuthenticationHandshake == true && !validatedByAuthToken) {
            // Auth token required but not present
            return false
        }
        if let allow = requirements.allow {
            return allow.contains() { webBasedApplicationIdentity in
                if (!satisfiesHostRequirement(of: webBasedApplicationIdentity.host)) {
                    return false
                }
                if let paths = webBasedApplicationIdentity.paths {
                    return paths.contains() { pathRequirement in
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
    
//    func throwUnlessSatisfiesAuthenticationRequirements(
//        of requirements: AuthenticationRequirements,
//        allowNullRequirement: Bool = false
//    ) throws -> Void {
//        if (!satisfiesAuthenticationRequirements(of: requirements, allowNullRequirement: allowNullRequirement)) {
//            throw ClientNotAuthorizedException();
//        }
//    }
    
}


// To convert from Kotlin

//
//package org.dicekeys.trustedapp.apicommands.permissionchecked
//
//import kotlinx.coroutines.Deferred
//import org.dicekeys.api.ApiDerivationOptions
//import org.dicekeys.api.AuthenticationRequirements
//import org.dicekeys.api.ClientMayNotRetrieveKeyException
//import org.dicekeys.api.UnsealingInstructions
//import org.dicekeys.crypto.seeded.ClientNotAuthorizedException
//
///**
// * Abstract away all permissions checks for the DiceKeys API
// *
// * @param requestUsersConsent You must pass this function, which is
// * called if a message must be shown to the user which will allow them to choose whether
// * to return unsealed data or not.  Your function should return true if the user has
// * already authorized the action, false if they rejected the action, or throw an exception
// * if waiting for the action to complete.
// */
//abstract class ApiPermissionChecks(
//  private val requestUsersConsent: (UnsealingInstructions.RequestForUsersConsent
//    ) -> Deferred<UnsealingInstructions.RequestForUsersConsent.UsersResponse>
//) {
//
//  /**
//   * Those inheriting this class must implement this test of whether
//   * a client is authorized.
//   */
//  abstract fun doesClientMeetAuthenticationRequirements(
//    authenticationRequirements: AuthenticationRequirements
//  ): Boolean
//
//  abstract fun throwIfClientNotAuthorized(
//    authenticationRequirements: AuthenticationRequirements
//  )
//
//  /**
//   * Verify that the client is authorized to use a key or secret derived using
//   * the [derivationOptions] and, if the client is not authorized,
//   * throw a [ClientNotAuthorizedException].
//   *
//   * @throws ClientNotAuthorizedException
//   */
////  fun throwIfClientNotAuthorized(
////    derivationOptions: ApiDerivationOptions
////  ): Unit = throwIfClientNotAuthorized(derivationOptions)
//
//
//  /**
//   * Verify that UnsealingInstructions do not forbid the client from using
//   * unsealing a message.  If the client is not authorized,
//   * throw a [ClientNotAuthorizedException].
//   *
//   * @throws ClientNotAuthorizedException
//   */
//  suspend fun throwIfUnsealingInstructionsViolated(
//    unsealingInstructions: UnsealingInstructions
//  ) {
//    throwIfClientNotAuthorized(unsealingInstructions)
//    val requireUsersConsent = unsealingInstructions.requireUsersConsent ?: return;
//    if (requestUsersConsent(requireUsersConsent).await() != UnsealingInstructions.RequestForUsersConsent.UsersResponse.Allow) {
//      throw ClientMayNotRetrieveKeyException("Operation declined by user")
//    }
//  }
//
//  /**
//   * Verify that UnsealingInstructions do not forbid the client from using
//   * unsealing a message.  If the client is not authorized,
//   * throw a [ClientNotAuthorizedException].
//   *
//   * @throws ClientNotAuthorizedException
//   */
//  suspend fun throwIfUnsealingInstructionsViolated(
//    unsealingInstructions: String?
//  ): Unit {
//    if (unsealingInstructions != null && unsealingInstructions.isNotEmpty())
//      throwIfUnsealingInstructionsViolated(UnsealingInstructions(unsealingInstructions)
//    )
//  }
//
//}
//
//
//package org.dicekeys.trustedapp.apicommands.permissionchecked
//
//import kotlinx.coroutines.Deferred
//import android.net.Uri
//import org.dicekeys.api.*
//
//
///**
// * This class performs permission checks
// */
//open class ApiPermissionChecksForUrls(
//  private val replyToUrlString: String,
//  private val handshakeAuthenticatedUrlString: String?,
//  requestUsersConsent: (UnsealingInstructions.RequestForUsersConsent
//  ) -> Deferred<UnsealingInstructions.RequestForUsersConsent.UsersResponse>
//): ApiPermissionChecks(requestUsersConsent) {
//
//  private val replyToUri = Uri.parse(replyToUrlString)
//  private val handshakeAuthenticatedUri: Uri? = if (handshakeAuthenticatedUrlString == null) null else Uri.parse(handshakeAuthenticatedUrlString)
//
//  private fun doesPathMatchRequirement(pathExpectedSlashOptional: String, pathObserved: String): Boolean {
//    // Paths must start with a "/".  If the path requirement didn't start with a "/",
//    // we'll insert one assuming this was a mistake by the developer of the client software
//    // that created the derivationOptionsJson string.
//    val pathExpected = if (pathExpectedSlashOptional.isEmpty() || pathExpectedSlashOptional[0] == '/')
//      pathExpectedSlashOptional else "/$pathExpectedSlashOptional"
//
//    return when {
//      pathExpected.endsWith("/*") -> {
//        // exact prefix match but without the closing "/"
//        pathObserved === pathExpected.substring(0, pathExpected.length - 2) ||
//          // exact prefix match including the closing "/", with an arbitrary-length suffix
//          // as permitted by the "*"
//          pathObserved.startsWith(pathExpected.substring(0, pathExpected.length -1))
//      }
//      pathExpected.endsWith("*") -> {
//        // The path requirement specifies a prefix, so test for a prefix match
//        pathObserved.startsWith(pathExpected.substring(0, pathExpected.length -1))
//      }
//      else -> {
//        // This path requirement does not specify a prefix, so test for exact match
//        pathExpected === pathObserved
//      }
//    }
//  }
//  private fun matchesWebBasedApplicationIdentity(
//    webBasedApplicationIdentity: WebBasedApplicationIdentity,
//    uri: Uri,
//  ): Boolean {
//    val pathObserved = uri.path ?: ""
//    val host = webBasedApplicationIdentity.host;
//    val paths = webBasedApplicationIdentity.paths;
//    if (host != webBasedApplicationIdentity.host) return false;
//    return if (paths == null) {
//      doesPathMatchRequirement("/--derived-secret-api--/*", pathObserved)
//    } else {
//      paths.any { pathExpected -> doesPathMatchRequirement(pathExpected, pathObserved) }
//    }
//  }
//
//  override fun doesClientMeetAuthenticationRequirements(
//    authenticationRequirements: AuthenticationRequirements
//  ): Boolean =
//      authenticationRequirements.allow.let { allow ->
//        allow != null &&
//        allow.any { hostAndPaths ->
//          // If the prefix appears in the URL associated with the authentication token
//          (handshakeAuthenticatedUri != null && matchesWebBasedApplicationIdentity(hostAndPaths, handshakeAuthenticatedUri)) ||
//          // Or no handshake is required and the replyUrl starts with the prefix
//          (authenticationRequirements.requireAuthenticationHandshake != true && matchesWebBasedApplicationIdentity(hostAndPaths, replyToUri))
//        }
//      }
//
//  override fun throwIfClientNotAuthorized(
//    authenticationRequirements: AuthenticationRequirements
//  ): Unit {
//    if (!doesClientMeetAuthenticationRequirements(authenticationRequirements)) {
//      // The client application id does not start with any of the specified prefixes
//      throw ClientUriNotAuthorizedException(
//        if (authenticationRequirements.requireAuthenticationHandshake == true) (handshakeAuthenticatedUrlString ?: "") else replyToUrlString,
//        authenticationRequirements.allow ?: listOf<WebBasedApplicationIdentity>())
//    }
//  }
//}
