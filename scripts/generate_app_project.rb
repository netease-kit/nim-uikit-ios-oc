#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "xcodeproj"

root = File.expand_path("..", __dir__)
app_dir = File.join(root, "app")
project_path = File.join(root, "app.xcodeproj")
scheme_dir = File.join(project_path, "xcshareddata", "xcschemes")
workspace_dir = File.join(root, "app.xcworkspace")

FileUtils.rm_rf(project_path)
FileUtils.rm_rf(workspace_dir)

project = Xcodeproj::Project.new(project_path)
target = project.new_target(:application, "app", :ios, "13.0")

app_group = project.main_group.new_group("app", "app")

def add_tree(group, target, dir)
  Dir.children(dir).sort.each do |entry|
    next if entry.start_with?(".")

    path = File.join(dir, entry)
    if File.directory?(path)
      if entry.end_with?(".xcassets")
        ref = group.new_file(entry)
        target.resources_build_phase.add_file_reference(ref)
      elsif entry.end_with?(".lproj")
        ref = group.new_file(entry)
        target.resources_build_phase.add_file_reference(ref)
      else
        child = group.new_group(entry, entry)
        add_tree(child, target, path)
      end
      next
    end

    ref = group.new_file(entry)
    case File.extname(entry)
    when ".m", ".mm", ".c", ".cc", ".cpp"
      target.source_build_phase.add_file_reference(ref)
    when ".storyboard", ".xcprivacy", ".plist"
      target.resources_build_phase.add_file_reference(ref) unless entry == "Info.plist"
    end
  end
end

add_tree(app_group, target, app_dir)

%w[UIKit Foundation UserNotifications PushKit].each { |framework| target.add_system_framework(framework) }

target.build_configurations.each do |config|
  settings = config.build_settings
  settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
  settings["CODE_SIGN_ENTITLEMENTS"] = "app/app.entitlements"
  settings["CODE_SIGN_IDENTITY"] = "Apple Development"
  settings["CODE_SIGN_STYLE"] = "Automatic"
  settings["CURRENT_PROJECT_VERSION"] = "1"
  settings["DEVELOPMENT_TEAM"] = "7C9A6NRV5L"
  settings["GCC_C_LANGUAGE_STANDARD"] = "gnu11"
  settings["INFOPLIST_FILE"] = "app/Info.plist"
  settings["IPHONEOS_DEPLOYMENT_TARGET"] = "13.0"
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.netease.yunxin.app.im.uikit.oc"
  settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  settings["TARGETED_DEVICE_FAMILY"] = "1,2"
  settings["CLANG_ENABLE_MODULES"] = "YES"
  settings["CLANG_ENABLE_OBJC_ARC"] = "YES"
  settings["FRAMEWORK_SEARCH_PATHS"] = ["$(inherited)", "$(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)"]
  settings["HEADER_SEARCH_PATHS"] = ["$(inherited)"]
  settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
  settings["ONLY_ACTIVE_ARCH"] = config.name == "Debug" ? "YES" : "NO"
  settings["SWIFT_VERSION"] = "5.0"
end

project.build_configurations.each do |config|
  settings = config.build_settings
  settings["ALWAYS_SEARCH_USER_PATHS"] = "NO"
  settings["CLANG_ENABLE_MODULES"] = "YES"
  settings["CLANG_ENABLE_OBJC_ARC"] = "YES"
  settings["GCC_C_LANGUAGE_STANDARD"] = "gnu11"
  settings["IPHONEOS_DEPLOYMENT_TARGET"] = "13.0"
  settings["SDKROOT"] = "iphoneos"
end

project.save

FileUtils.mkdir_p(scheme_dir)
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(project_path, "app", true)

FileUtils.mkdir_p(workspace_dir)
File.write(File.join(workspace_dir, "contents.xcworkspacedata"), <<~XML)
  <?xml version="1.0" encoding="UTF-8"?>
  <Workspace
     version = "1.0">
     <FileRef
        location = "group:app.xcodeproj">
     </FileRef>
     <FileRef
        location = "group:Pods/Pods.xcodeproj">
     </FileRef>
  </Workspace>
XML

puts "Generated #{project_path}"
