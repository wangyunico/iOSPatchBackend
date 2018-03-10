inhibit_all_warnings!
workspace 'PatchDemo'

target 'PatchDemo' do 
     pod 'Patch', :path => './Patch/Patch.podspec'
     pod 'ReactiveCocoa', '2.5'
end
post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['CLANG_ENABLE_OBJC_WEAK'] ||= 'YES'
        end
    end
end
