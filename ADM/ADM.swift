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
import AVFoundation

@main
struct ADM: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "ADM - A CLI utility for managing audio devices.",
        version: "1.0.0-preview1",
        subcommands: [List.self, Defaults.self],
        defaultSubcommand: List.self)

    mutating func run() throws {
    }

    static func printDevices(audioDevices: [AudioDevice]) {
        let padding = audioDevices.max(by: {
            if let lhs = $0.name, let rhs = $1.name {
                return rhs.count > lhs.count
            }
            return false
        })?.name?.count ?? 0

        for audioDevice in audioDevices {
            if let name = audioDevice.name, let uid = audioDevice.uid {
                print(String(format: "   %3d: \(name.padding(toLength: padding, withPad: " ", startingAt: 0)) [uid = \(uid)]", audioDevice.id))
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
        }
        @OptionGroup var options: Options


        mutating func run() {
            if options.output == false && options.input == false {
                options.output = true
                options.input = true
            }

            let audioDevices = AudioDeviceManager.findDevices()
            if options.output == true {
                print("Output devices:")
                printDevices(audioDevices: audioDevices.filter({$0.hasOutput == true }))
            }
            if options.input == true {
                print("Input devices:")
                printDevices(audioDevices: audioDevices.filter({$0.hasInput == true }))
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

                let audioDevices = AudioDeviceManager.findDevices()
                if options.output == true {
                    print("Default output device:")
                    printDevices(audioDevices: audioDevices.filter({$0.defaultOutput == true }))
                }
                if options.input == true {
                    print("Default input device:")
                    printDevices(audioDevices: audioDevices.filter({$0.defaultInput == true }))
                }
            }
        }

        struct Set: ParsableCommand {
            static let configuration = CommandConfiguration(abstract: "Set default input or output device.")

            struct Options: ParsableArguments {
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
                if superOptions.input == true && superOptions.output == true {
                }
                else if superOptions.input == false && superOptions.output == false {
                }
                else if options.name == true && options.uid == true {
                }
                else {
                    let audioDevices = AudioDeviceManager.findDevices()
                    if options.name == true {
                        if let audioDevice = audioDevices.first(where: {$0.name?.lowercased() == options.value.lowercased()}) {
                            if superOptions.input {
                                audioDevice.defaultInput = true
                            }
                            else {
                                audioDevice.defaultOutput = true
                            }
                        }
                    }
                    else if options.uid == true {
                        if let audioDevice = audioDevices.first(where: {$0.uid?.lowercased() == options.value.lowercased()}) {
                            if superOptions.input {
                                audioDevice.defaultInput = true
                            }
                            else {
                                audioDevice.defaultOutput = true
                            }
                        }
                    }
                    else {
                        if let deviceId = UInt32(options.value) as AudioDeviceID? {
                            if let audioDevice = audioDevices.first(where: {$0.id == deviceId}) {
                                if superOptions.input {
                                    audioDevice.defaultInput = true
                                }
                                else {
                                    audioDevice.defaultOutput = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
