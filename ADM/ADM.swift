/////////////////////////////////////////////////////////////////////////////////////////
// MIT License
//
// Copyright (c) 2024 ultraschall.fm
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import ArgumentParser

@main
struct ADM: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "ADM - A CLI utility for managing audio devices.",
        version: "1.0.0-preview2",
        subcommands: [List.self, Defaults.self],
        defaultSubcommand: List.self)

    mutating func run() throws {
    }

    static func printDevices(devices: [AudioDevice]) {
        let padding = AudioDeviceManager.shared.padding
        for device in devices {
            if let name = device.name, let uid = device.uid {
                let isDefault = device.flags.contains(.defaultInput) || device.flags.contains(.defaultOutput)
                print(String(format: "   %3d: \(name.padding(toLength: padding, withPad: " ", startingAt: 0)) [uid = \(uid)\(isDefault ? ", default" : "")]", device.id))
            }
        }
    }
}

extension ADM {
    struct List: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Print available audio devices.")

        struct Options: ParsableArguments {
            @Flag(name: [.long, .customShort("o")], help: "Print output audio devices.")
            var output = false

            @Flag(name: [.long, .customShort("i")], help: "Print input audio devices.")
            var input = false

            @Flag(name: [.long, .customShort("s")], help: "Print system output audio device.")
            var system = false
        }

        @OptionGroup var options: Options

        mutating func run() {
            if options.output == false && options.input == false && options.system == false {
                options.output = true
                options.input = true
                options.system = true
            }

            let manager = AudioDeviceManager.shared
            if options.input == true {
                print("Input devices:")
                printDevices(devices: manager.devices.filter({ $0.flags.contains(.input)}))
            }
            if options.output == true {
                print("Output devices:")
                printDevices(devices: manager.devices.filter({ $0.flags.contains(.output)}))
            }
            if options.system == true {
                print("System output device:")
                printDevices(devices: manager.devices.filter({ $0.flags.contains(.system)}))
            }
        }
    }

    struct Defaults: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Set or get default input and output devices.",
                                                        subcommands: [Get.self, Set.self])

        struct Options: ParsableArguments {
            @Flag(name: [.long, .customShort("i")], help: "Set or get default input audio device.")
            var input = false

            @Flag(name: [.long, .customShort("o")], help: "Set or get default output audio device.")
            var output = false

            @Flag(name: [.long, .customShort("s")], help: "Set or get system output audio device.")
            var system = false
        }

        @OptionGroup var options: Options

        mutating func run() {
        }

        struct Get: ParsableCommand {
            static let configuration = CommandConfiguration(abstract: "Get default input or output device.")

            @OptionGroup var options: Defaults.Options

            mutating func run() {
                if options.output == false && options.input == false {
                    options.output = true
                    options.input = true
                }

                let manager = AudioDeviceManager.shared
                if options.input == true {
                    print("Default input device:")
                    printDevices(devices: manager.devices.filter({ $0.flags.contains(.defaultInput)}))
                }
                if options.output == true {
                    print("Default output device:")
                    printDevices(devices: manager.devices.filter({ $0.flags.contains(.defaultOutput)}))
                }
            }
        }

        struct Set: ParsableCommand {
            static let configuration = CommandConfiguration(abstract: "Set default input or output device.")

            struct Options: ParsableArguments {
                @Flag(name: [.long, .customShort("f")], help: "Also set system output device when setting the default output device.")
                var force = false

                @Flag(name: [.long, .customShort("n")], help: "Specify audio device name instead of audio device id.")
                var name = false

                @Flag(name: [.long, .customShort("u")], help: "Specify audio device uid instead of audio device id.")
                var uid = false

                @Argument(help: "An audio device id, name or uid to operate on.")
                var value: String
            }

            @OptionGroup var options: Options
            @OptionGroup var superOptions: Defaults.Options

            mutating func run() {
                let manager = AudioDeviceManager.shared
                var selectedDevice: AudioDevice? = nil
                if options.name == true {
                    selectedDevice = manager.devices.first(where: {$0.name?.lowercased() == options.value.lowercased()} )
                }
                else if options.uid == true {
                    selectedDevice = manager.devices.first(where: {$0.uid?.lowercased() == options.value.lowercased()} )
                }
                else {
                    selectedDevice = manager.devices.first(where: {$0.id == UInt32(options.value) } )
                }

                if let selectedDevice = selectedDevice {
                    if superOptions.input {
                        if selectedDevice.flags.contains(.input) {
                            if !manager.setDefaultInput(id: selectedDevice.id) {
                                print("The selected device can't be selected as default input device.")
                            }
                        }
                        else {
                            print("The selected device has no input channels.")
                        }
                    }
                    if superOptions.output {
                        if selectedDevice.flags.contains(.output) {
                            if !manager.setDefaultOutput(id: selectedDevice.id) {
                                print("The selected device can't be selected as default output device.")
                            }
                            if options.force {
                                if !manager.setSystemOutput(id: selectedDevice.id) {
                                    print("The selected device can't be selected as system output device.")
                                }
                            }
                        }
                        else {
                            print("The selected device has no output channels.")
                        }
                    }
                    if superOptions.system {
                        if selectedDevice.flags.contains(.output) {
                            if !manager.setSystemOutput(id: selectedDevice.id) {
                                print("The selected device can't be selected as system output device.")
                            }
                        }
                        else {
                            print("The selected device has no output channels.")
                        }
                    }
                }
                else {
                    print("Can't find audio device \(options.value)")
                }
            }
        }
    }
}
