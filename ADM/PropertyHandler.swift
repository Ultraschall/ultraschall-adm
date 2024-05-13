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

class PropertyHandler {
    static func allDevices() -> [AudioDevice] {
        var devices = [AudioDevice]()
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var dataSize = UInt32(MemoryLayout<CFString?>.size)
        var status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize)
        if (status == 0) {
            let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size;
            let data = UnsafeMutablePointer<AudioDeviceID>.allocate(capacity: Int(deviceCount))
            status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, data);
            if(status == 0) {
                let defaultInput = PropertyHandler.defaultInput()
                let defaultOutput = PropertyHandler.defaultOutput()
                let systemOutput = PropertyHandler.systemOutput()

                for i in 0..<deviceCount {
                    let device = AudioDevice(from: data[i])
                    device.name = PropertyHandler.name(id: device.id) ?? ""
                    device.uid = PropertyHandler.uid(id: device.id) ?? ""
                    if PropertyHandler.numberOfInputChannels(id: device.id) > 0 {
                        device.flags.update(with: .input)
                    }
                    if PropertyHandler.numberOfOutputChannels(id: device.id) > 0 {
                        device.flags.update(with: .output)
                    }
                    if defaultInput == device.id {
                        device.flags.update(with: .defaultInput)
                    }
                    if defaultOutput == device.id {
                        device.flags.update(with: .defaultOutput)
                    }
                    if systemOutput == device.id {
                        device.flags.update(with: .system)
                    }
                    devices.append(device)
                }
            }
            data.deallocate()
        }
        return devices
    }

    static func numberOfInputChannels(id: UInt32) -> UInt32 {
        var numberOfChannels: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain)
        var dataSize = UInt32(MemoryLayout<AudioBufferList?>.size);
        var status = AudioObjectGetPropertyDataSize(id, &address, 0, nil, &dataSize);
        if (status == 0) {
            let data = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(dataSize))
            status = AudioObjectGetPropertyData(id, &address, 0, nil, &dataSize, data);
            if (status == 0) {
                let buffers = UnsafeMutableAudioBufferListPointer(data)
                for i in 0..<buffers.count {
                    numberOfChannels = buffers[i].mNumberChannels
                    break
                }
            }
            data.deallocate()
        }
        return numberOfChannels
    }

    static func numberOfOutputChannels(id: UInt32) -> UInt32 {
        var numberOfChannels: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
        var dataSize = UInt32(MemoryLayout<AudioBufferList?>.size);
        var status = AudioObjectGetPropertyDataSize(id, &address, 0, nil, &dataSize);
        if (status == 0) {
            let data = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(dataSize))
            status = AudioObjectGetPropertyData(id, &address, 0, nil, &dataSize, data);
            if (status == 0) {
                let buffers = UnsafeMutableAudioBufferListPointer(data)
                for i in 0..<buffers.count {
                    numberOfChannels = buffers[i].mNumberChannels
                    break
                }
            }
            data.deallocate()
        }
        return numberOfChannels
    }

    static func name(id: UInt32) -> String? {
        var name: CFString? = nil
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var dataSize = UInt32(MemoryLayout<CFString?>.size)
        var status = AudioObjectGetPropertyDataSize(id, &address, 0, nil, &dataSize)
        if status == 0 {
            let data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<CFString>.alignment)
            status = AudioObjectGetPropertyData(id, &address, 0, nil, &dataSize, data)
            if status == 0 {
                name = data.load(as: CFString.self)
            }
            data.deallocate()
        }
        return name as String?
    }

    static func uid(id: UInt32) -> String? {
        var uid: CFString? = nil;
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID, // CFString
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var dataSize = UInt32(MemoryLayout<CFString?>.size)
        var status = AudioObjectGetPropertyDataSize(id, &address, 0, nil, &dataSize)
        if(status == 0) {
            let data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<CFString>.alignment)
            status = AudioObjectGetPropertyData(id, &address, 0, nil, &dataSize, data)
            if (status == 0) {
                uid = data.load(as: CFString.self)
            }
            data.deallocate()
        }
        return uid as String?
    }

    static func defaultInput() -> UInt32 {
        var id: UInt32 = 0
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
                id = deviceId
            }
        }
        return id
    }

    static func setDefaultInput(id: UInt32) -> Bool {
        var result = false
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize)
        if status == 0 {
            var deviceId = id
            status = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, dataSize, &deviceId)
            result = (status == 0)
        }
        return result
    }

    static func defaultOutput() -> UInt32 {
        var id: UInt32 = 0
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
                id = deviceId
            }
        }
        return id
    }

    static func setDefaultOutput(id: UInt32) -> Bool {
        var result = false
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize)
        if status == 0 {
            var deviceId = id
            status = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, dataSize, &deviceId)
            if status == 0 {
                result = (status == 0)
            }
        }
        return result
    }

    static func systemOutput() -> UInt32 {
        var id: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultSystemOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize)
        if status == 0 {
            var deviceId: UInt32 = 0
            status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &deviceId)
            if status == 0 {
                id = deviceId
            }
        }
        return id
    }

    static func setSystemOutput(id: UInt32) -> Bool {
        var result = false
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultSystemOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize)
        if status == 0 {
            var deviceId = id
            status = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, dataSize, &deviceId)
            result = (status == 0)
        }
        return result
    }
}
