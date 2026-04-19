//
//  AppSettingsView.swift
//  PlayCover
//
//  Created by lbxia on 2021/11/18.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct AppSettingsView: View {
    
    @State var selectedDevice: Int
    @State var screenWidth: Double
    @State var screenHeight: Double
    @State var version: String
    @State var key: String
    @State var selectedIndex: Int = 0
    
    @State var showImportSuccess: Bool = false
    
    @ObservedObject var app: BaseApp
    @ObservedObject var viewModel: AppSettingsViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    init(app: BaseApp) {
        self.app = app
        self.viewModel = AppSettingsViewModel(app: app)
        
        let settings = AppSettings.get(for: app.info.bundleIdentifier)
        
        _selectedDevice = State(initialValue: settings.deviceType)
        _screenWidth = State(initialValue: settings.screenWidth)
        _screenHeight = State(initialValue: settings.screenHeight)
        _version = State(initialValue: settings.version)
        _key = State(initialValue: settings.gamePadKey)
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("App Settings")
                    .font(.title)
                    .padding()
                Spacer()
            }
            
            TabView(selection: $selectedIndex) {
                VStack {
                    HStack {
                        Text("Device Settings")
                            .font(.title2)
                        Spacer()
                    }
                    
                    Picker("Device Type", selection: $selectedDevice) {
                        Text("iPad Pro (12.9-inch) (1st gen) | A9X | 4GB").tag(0)
                        Text("iPad Pro (12.9-inch) (3rd gen) | A12X | 4GB").tag(1)
                        Text("iPad Pro (12.9-inch) (5th gen) | M1 | 8GB").tag(2)
                        Text("iPad Pro (12.9-inch) (6th gen) | M2 | 8GB").tag(3)
                        Text("iPad Pro (13-inch) (7th gen) | M4 | 8GB").tag(4)
                        Text("iPad Pro (13-inch) (8th gen) | M5 | 12GB").tag(5)
                        Text("iPhone 13 Pro Max | A15 | 6GB").tag(6)
                        Text("iPhone 14 Pro Max | A16 | 6GB").tag(7)
                        Text("iPhone 15 Pro Max | A17 Pro | 8GB").tag(8)
                        Text("iPhone 16 Pro Max | A18 Pro | 8GB").tag(9)
                        Text("iPhone 17 Pro Max | A19 Pro | 8GB").tag(10)
                    }
                    .onChange(of: selectedDevice) { tag in
                        let device = PlayTools.deviceList[tag]
                        screenWidth = device.screenWidth
                        screenHeight = device.screenHeight
                        version = device.osVersion
                    }
                    
                    HStack {
                        TextField("Screen Width", value: $screenWidth, formatter: NumberFormatter())
                        Text("x")
                        TextField("Screen Height", value: $screenHeight, formatter: NumberFormatter())
                    }
                    
                    TextField("iOS Version", text: $version)
                    
                    HStack {
                        Spacer()
                        Button("Reset") {
                            let settings = AppSettings.defaultSettings
                            selectedDevice = settings.deviceType
                            screenWidth = settings.screenWidth
                            screenHeight = settings.screenHeight
                            version = settings.version
                        }
                    }
                }
                .tabItem {
                    Image(systemName: "iphone")
                    Text("Device")
                }
                .tag(0)
                
                VStack {
                    HStack {
                        Text("Keymapping")
                            .font(.title2)
                        Spacer()
                    }
                    
                    HStack {
                        Text("GamePad Sensitivity")
                        TextField("Sensitivity", text: $key)
                    }
                    
                    HStack {
                        Spacer()
                        Button("Import Keymap") {
                            let panel = NSOpenPanel()
                            panel.allowsMultipleSelection = false
                            panel.canChooseDirectories = false
                            panel.canChooseFiles = true
                            panel.allowedContentTypes = [UTType.json]
                            
                            if panel.runModal() == .OK {
                                do {
                                    let data = try Data(contentsOf: panel.url!)
                                    let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [String: Any]
                                    
                                    let keymap = Keymap(
                                        name: json["name"] as! String,
                                        bundleId: app.info.bundleIdentifier,
                                        keyCodes: json["keyCodes"] as! [Int],
                                        pointers: json["pointers"] as! [Int],
                                        mouseArea: json["mouseArea"] as! [Int],
                                        pageIndex: json["pageIndex"] as! Int,
                                        sensitivity: json["sensitivity"] as! Float
                                    )
                                    
                                    KeymapManager.shared.addKeymap(keymap)
                                    showImportSuccess = true
                                } catch {
                                    Log.shared.error(error)
                                }
                            }
                        }
                        .alert("Import Success", isPresented: $showImportSuccess) {
                            Button("OK", role: .cancel) { }
                        }
                    }
                }
                .tabItem {
                    Image(systemName: "keyboard")
                    Text("Keymap")
                }
                .tag(1)
                
                VStack {
                    HStack {
                        Text("Other Settings")
                            .font(.title2)
                        Spacer()
                    }
                    
                    Toggle("Disable Library Validation", isOn: $viewModel.disableLibraryValidation)
                    Toggle("Disable AMFI", isOn: $viewModel.disableAMFI)
                    Toggle("Enable Debug Log", isOn: $viewModel.enableDebugLog)
                    Toggle("Inject PlayTools", isOn: $viewModel.injectPlayTools)
                }
                .tabItem {
                    Image(systemName: "gear")
                    Text("Other")
                }
                .tag(2)
            }
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Spacer()
                
                Button("OK") {
                    let settings = AppSettings(
                        deviceType: selectedDevice,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        version: version,
                        gamePadKey: key,
                        disableLibraryValidation: viewModel.disableLibraryValidation,
                        disableAMFI: viewModel.disableAMFI,
                        enableDebugLog: viewModel.enableDebugLog,
                        injectPlayTools: viewModel.injectPlayTools
                    )
                    
                    AppSettings.set(settings, for: app.info.bundleIdentifier)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
        }
        .padding()
        .frame(width: 600, height: 500)
    }
}
