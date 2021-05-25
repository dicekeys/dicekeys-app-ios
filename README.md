# dicekeys-app-ios

# How to launch the project

1. Clone the project:

`git clone --recurse-submodules https://github.com/dicekeys/dicekeys-app-ios` 

or init submodules manually:

`git submodule update --init --recursive`

2. Install pods (use latest CocoaPods version, tested with 1.10.0)

`pod install`

3. Open `DiceKeys/DiceKeys.xcworkspace`

4. Select `DiceKeys` → `iOS Device` scheme

5. Select `Product` → `Run` in menu (or press `⌘` + `R`)


## Testing the app

To test the app, you'll need a DiceKey, which is a box of 25 dice, to scan using the camera.

If you don't have a DiceKey, go to https://dicekeys.app, use the feature to generate a random DiceKey, and then print a picture of arrangement of 25 dice to scan from the app. (Or, you can just scan them from one device's screen to another device's camera.

## Security Key Seed Writer

The command-line utility writes a 32-byte seed to a security key for use with [DiceKeys/SoloKeys standard for seeding authenticators](https://github.com/dicekeys/seeding-webauthn).

It takes one parameter: a hex format 32-byte seed (64 hex characters) optionally preceded by "0x".  For example, for seed `0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f`:

```
seed-security-key 0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f
```

 (DO NOT USE THE ABOVE SEED!)

### Build Security Key Seed Writer
```
xcodebuild -workspace DiceKeys.xcworkspace -scheme seed-security-key -configuration Release clean build SYMROOT=$(PWD)/build
```
Get built executable binary at `$(PWD)/build/Release/seed-security-key`.
