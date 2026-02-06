default_platform(:ios)

platform :ios do
  desc "Build and upload to TestFlight"
  lane :beta do
    # Increment build number
    increment_build_number(xcodeproj: "HeadshotAirBattle.xcodeproj")
    
    # Build the app
    build_app(
      scheme: "HeadshotAirBattle",
      export_method: "app-store",
      skip_codesigning: false
    )
    
    # Upload to TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: false,
      api_key_path: "~/.appstoreconnect/api_key.json"
    )
  end
end
