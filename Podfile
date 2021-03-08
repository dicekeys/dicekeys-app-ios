
abstract_target 'DiceKeys' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

#  # Pods for DiceKeys (iOS)
#  # Comment the next line if you don't want to use dynamic frameworks
#  use_frameworks!

  pod 'SwiftLint'

  # Pods for DiceKeys
  pod 'SeededCrypto', :git => 'https://github.com/dicekeys/seeded-crypto-ios.git', :submodules => true, :branch => 'replace-all-derivation-options-with-recipe'
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

  post_integrate do |installer|
    file_name = project_file = "Pods/Pods.xcodeproj/project.pbxproj"
    lines = File.readlines(file_name)
    for line in lines
      if line.include?( "opencv2.xcframework/ios-arm64_armv7/opencv2.framework/Versions/A/Headers/Core.h") and line.include?("lastKnownFileType = sourcecode.c.h")
          line.sub!("lastKnownFileType = sourcecode.c.h", "explicitFileType = sourcecode.c.objc")
          f = File.open(file_name, "w")
          f << lines.join("\n")
          f.close
        break
      end
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
