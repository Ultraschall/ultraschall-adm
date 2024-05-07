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

import AVFoundation

class AudioDevice {
    var id: AudioDeviceID

    init(from: AudioDeviceID) {
        self.id = from
    }

    var hasOutput: Bool {
        get {
            var hasOutput = false

            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreamConfiguration,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain)

            var dataSize = UInt32(MemoryLayout<AudioBufferList?>.size);
            var status = AudioObjectGetPropertyDataSize(self.id, &address, 0, nil, &dataSize);
            if (status == 0) {
                let data = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(dataSize))
                status = AudioObjectGetPropertyData(self.id, &address, 0, nil, &dataSize, data);
                if (status == 0) {
                    let buffers = UnsafeMutableAudioBufferListPointer(data)
                    for i in 0..<buffers.count {
                        if buffers[i].mNumberChannels > 0 {
                            hasOutput = true
                            break
                        }
                    }
                }
                data.deallocate()
            }

            return hasOutput
        }
    }

    var hasInput: Bool {
        get {
            var hasInput = false

            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreamConfiguration,
                mScope: kAudioDevicePropertyScopeInput,
                mElement: kAudioObjectPropertyElementMain)

            var dataSize = UInt32(MemoryLayout<AudioBufferList?>.size);
            var status = AudioObjectGetPropertyDataSize(self.id, &address, 0, nil, &dataSize);
            if (status == 0) {
                let data = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(dataSize))
                status = AudioObjectGetPropertyData(self.id, &address, 0, nil, &dataSize, data);
                if (status == 0) {
                    let buffers = UnsafeMutableAudioBufferListPointer(data)
                    for i in 0..<buffers.count {
                        if buffers[i].mNumberChannels > 0 {
                            hasInput = true
                            break
                        }
                    }
                }
                data.deallocate()
            }

            return hasInput
        }
    }

    var uid: String? {
        get {
            var uid: CFString? = nil;

            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceUID, // CFString
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain)

            var dataSize = UInt32(MemoryLayout<CFString?>.size)
            var status = AudioObjectGetPropertyDataSize(self.id, &address, 0, nil, &dataSize)
            if(status == 0) {
                let data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<CFString>.alignment)
                status = AudioObjectGetPropertyData(self.id, &address, 0, nil, &dataSize, data)
                if (status == 0) {
                    uid = data.load(as: CFString.self)
                }
                data.deallocate()
            }

            return uid as String?
        }
    }

    var name: String? {
        get {
            var name: CFString? = nil

            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceNameCFString,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain)

            var dataSize = UInt32(MemoryLayout<CFString?>.size)
            var status = AudioObjectGetPropertyDataSize(self.id, &address, 0, nil, &dataSize)
            if status == 0 {
                let data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<CFString>.alignment)
                status = AudioObjectGetPropertyData(self.id, &address, 0, nil, &dataSize, data)
                if status == 0 {
                    name = data.load(as: CFString.self)
                }
                data.deallocate()
            }

            return name as String?
        }
    }

    var defaultOutput: Bool {
        get {
            var isDefault = false

            var address = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain)

            var dataSize: UInt32 = 0
            var status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize)
            if status == 0 {
                var deviceId: UInt32 = 0
                status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &deviceId)
                if status == 0 {
                    if deviceId == self.id {
                        isDefault = true
                    }
                }
            }

            return isDefault
        }

        set {
            if (newValue == true) && self.hasOutput {
                var address = AudioObjectPropertyAddress(
                    mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain)

                var dataSize: UInt32 = 0
                var status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize)
                if status == 0 {
                    var deviceId = self.id
                    status = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, dataSize, &deviceId)
                    if status == 0 {
                        address.mSelector = kAudioHardwarePropertyDefaultSystemOutputDevice
                        dataSize = 0
                        status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize)
                        if status == 0 {
                            var deviceId = self.id
                            status = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, dataSize, &deviceId)
                            if status == 0 {
                            }
                        }
                    }
                }
            }
        }
    }

    var defaultInput: Bool {
        get {
            var isDefault = false

            var address = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultInputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain)

            var dataSize: UInt32 = 0
            var status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize)
            if status == 0 {
                var deviceId: UInt32 = 0
                status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &deviceId)
                if status == 0 {
                    if deviceId == self.id {
                        isDefault = true
                    }
                }
            }

            return isDefault
        }

        set {
            if (newValue == true) && self.hasInput {
                var address = AudioObjectPropertyAddress(
                    mSelector: kAudioHardwarePropertyDefaultInputDevice,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain)

                var dataSize: UInt32 = 0
                var status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize)
                if status == 0 {
                    var deviceId = self.id
                    status = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, dataSize, &deviceId)
                    if status == 0 {
                    }
                }
            }
        }
    }
}
