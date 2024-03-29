//
//  DerivationRecipeTemplates
//
//  Auto-generated by recipe.ts in the DiceKeys specification TypeScript project.
//  Tue, 02 Feb 2021 22:44:35 GMT
//
//  These templates are hard coded because the recipe (also known as
//  recipeJon) is an input to the hash function used to derive
//  passwords and other secrets, and so even a single-character change
//  to the recipe will change the entire contents of the password/secret.
//
//  Thus, we generate these strings from TypeScript, generate code that contains
//  them, and only ever modify them with deterministic functions that insert
//  new fields before the closing "}" with no spaces.
//  (e.g., inserting ","lengthInBytes":64".)
//
  
import Foundation

let derivationRecipeTemplates: [DerivationRecipe] = [
	DerivationRecipe(type: .Password, name: "1Password", recipe: """
{"allow":[{"host":"*.1password.com"}]}
"""),
	DerivationRecipe(type: .Password, name: "Apple", recipe: """
{"allow":[{"host":"*.apple.com"},{"host":"*.icloud.com"}],"lengthInChars":64}
"""),
	DerivationRecipe(type: .Password, name: "Authy", recipe: """
{"allow":[{"host":"*.authy.com"}]}
"""),
	DerivationRecipe(type: .Password, name: "Bitwarden", recipe: """
{"allow":[{"host":"*.bitwarden.com"}]}
"""),
	DerivationRecipe(type: .Password, name: "Facebook", recipe: """
{"allow":[{"host":"*.facebook.com"}]}
"""),
	DerivationRecipe(type: .Password, name: "Google", recipe: """
{"allow":[{"host":"*.google.com"}]}
"""),
	DerivationRecipe(type: .Password, name: "Keeper", recipe: """
{"allow":[{"host":"*.keepersecurity.com"},{"host":"*.keepersecurity.eu"}]}
"""),
	DerivationRecipe(type: .Password, name: "LastPass", recipe: """
{"allow":[{"host":"*.lastpass.com"}]}
"""),
	DerivationRecipe(type: .Password, name: "Microsoft", recipe: """
{"allow":[{"host":"*.microsoft.com"},{"host":"*.live.com"}]}
"""),
    DerivationRecipe(type: .SigningKey, name: "SSH", recipe: """
{"purpose":"ssh"}
"""),
    DerivationRecipe(type: .SigningKey, name: "PGP", recipe: """
{"purpose":"pgp"}
"""),
    DerivationRecipe(type: .Secret, name: "Cryptocurrency wallet seed", recipe: """
{"purpose":"wallet"}
""")
];
