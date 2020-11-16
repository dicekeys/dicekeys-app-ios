# Uncomment the next line to define a global platform for your project
platform :ios, '14.1'

target 'DiceKeys' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for DiceKeys
  pod "ReadDiceKey", :path => "../read-dicekey-ios/ReadDiceKey.podspec"
  pod 'SeededCrypto', :git => 'https://github.com/dicekeys/seeded-crypto-ios.git', :submodules => true

  target 'DiceKeysTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'DiceKeysUITests' do
    # Pods for testing
  end

end
