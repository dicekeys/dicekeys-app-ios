
abstract_target 'DiceKeys' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

#  # Pods for DiceKeys (iOS)
#  # Comment the next line if you don't want to use dynamic frameworks
#  use_frameworks!

  pod 'SwiftLint'

  # Pods for DiceKeys
  pod 'SeededCrypto', :git => 'https://github.com/dicekeys/seeded-crypto-ios.git', :submodules => true
  pod 'OpenCVXF', :git => 'https://github.com/dicekeys/opencv-xf.git'
  pod "ReadDiceKey", :git => 'https://github.com/dicekeys/read-dicekey-ios.git', :submodules => true

  target 'DiceKeys (iOS)' do
    platform :ios, '14.0'
    target 'Tests iOS' do
      inherit! :complete
    end
  end
  
  target 'DiceKeys (macOS)' do
    platform :osx, '11.0'
    target 'Tests macOS' do
      inherit! :complete
    end
  end
end

#target 'DiceKeys (macOS)' do
#  platform :osx, '11.0'
#  # Comment the next line if you don't want to use dynamic frameworks
#  use_frameworks!
#
#  # Pods for DiceKeys (macOS)
#
#  pod 'SwiftLint'
#
#  # Pods for DiceKeys
#  pod 'SeededCrypto', :git => 'https://github.com/dicekeys/seeded-crypto-ios.git', :submodules => true
#  pod 'OpenCVXF', :git => 'https://github.com/dicekeys/opencv-xf.git'
#  pod "ReadDiceKey", :git => 'https://github.com/dicekeys/read-dicekey-ios.git', :submodules => true
#end
