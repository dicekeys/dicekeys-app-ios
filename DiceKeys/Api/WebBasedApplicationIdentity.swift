//
//  File.swift
//  
//
//  Created by Stuart Schechter on 2020/11/12.
//

import Foundation

struct WebBasedApplicationIdentity: Codable {
 /**
 * The host, which is the same as a hostname unless a non-standard https port is used (not recommended).
 * Start it with a "*." to match a domain and any of its subdomains.
 *
 * > origin = <scheme> "://" <hostname> [ ":" <port> ] = <scheme> "://" <host> = "https://" <host>
 * So, `host = origin.substr(8)`
 */
    var host: String
    var paths: [String]?
}


protocol AuthenticationRequirements {
  /**
   * On Apple platforms, applications are specified by a URL containing a domain name
   * from the Internet's Domain Name System (DNS).
   *
   * If this value is specified, applications must come from clients that have a URL prefix
   * starting with one of the items on this list if they are to use a derived key.
   *
   * Since some platforms, including iOS, do not allow the DiceKeys app to authenticate
   * the sender of an API request, the app may perform a cryptographic operation
   * only if it has been instructed to send the result to a URL that starts with
   * one of the permitted prefixes.
   */
    var allow: [WebBasedApplicationIdentity]? { get set }

  /**
   * When set, clients will need to issue a handshake request to the API,
   * and receive an authorization token (a random shared secret), before
   * issuing other requests where the URL at which they received the token
   * starts with one of the authorized prefixes.
   *
   * The DiceKeys app will map the authorization token to that URL and,
   * when requests include that token, validate that the URL associated
   * with the token has a valid prefix. The DiceKeys app will continue to
   * validate that responses are also sent to a valid prefix.
   *
   */
    var requireAuthenticationHandshake: Bool? { get set }

  
  /**
   * In Android, client applications are identified by their package name,
   * which must be cryptographically signed before an application can enter the
   * Google play store.
   *
   * If this value is specified, Android apps must have a package name that begins
   * with one of the provided prefixes if they are to use a derived key.
   *
   * Note that all prefixes, and the client package names they are compared to,
   * have an implicit '.' appended to to prevent attackers from registering the
   * suffix of a package name.  Hence the package name "com.example.app" is treated
   * as "com.example.app." and the prefix "com.example" is treated as
   * "com.example." so that an attacker cannot generate a key by registering
   * "com.examplesignedbyattacker".
   */
    var allowAndroidPrefixes: [String]? { get set }
}
