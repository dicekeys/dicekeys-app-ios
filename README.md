# dicekeys-app-ios

# How to launch the project

1. Clone the project:

`git clone --recurse-submodules https://github.com/dicekeys/dicekeys-app-ios` 

or init submodules manually:

`git submodule update --init --recursive`

2. Build OpenCV framework (https://docs.opencv.org/master/d5/da3/tutorial_ios_install.html)

`cd deps && ./build_opencv.sh`

3. Open `DiceKeys/DiceKeys.xcodeproj`

4. Select `DiceKeys` → `iOS Device` scheme

5. Select `Product` → `Run` in menu (or press `⌘` + `R`)
