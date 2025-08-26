//
// Copyright © 2025 Apple Inc. All rights reserved.
//

extension Base {
    public static func parseTagVMDeviceInformation(_ tllv: FPSServerTLLV, _ spcContainer: inout FPSServerSPCContainer) throws {
        var offset = 0
        let tllvVersion = try readBigEndianU32(tllv.value, 0)
        offset += 4

        if tllvVersion == 1 {
            var vmDeviceInfo: VMDeviceInfo = VMDeviceInfo.init();

            // 4B Host Device Class
            vmDeviceInfo.hostDeviceClass = base_constants.FPSDeviceClass(rawValue: try readBigEndianU32(tllv.value, offset)) ?? base_constants.FPSDeviceClass.unknown
            offset += 4

            // 4B Host OS Version
            vmDeviceInfo.hostOSVersion = try readBigEndianU32(tllv.value, offset)
            offset += 4

            // 4B Host VM Protocol Version
            vmDeviceInfo.hostVMProtocolVersion = try readBigEndianU32(tllv.value, offset)
            offset += 4

            // 4B Guest Device Class
            vmDeviceInfo.guestDeviceClass = base_constants.FPSDeviceClass(rawValue: try readBigEndianU32(tllv.value, offset)) ?? base_constants.FPSDeviceClass.unknown
            offset += 4

            // 4B Guest OS Version
            vmDeviceInfo.guestOSVersion = try readBigEndianU32(tllv.value, offset)
            offset += 4

            // 4B Guest VM Protocol Version
            vmDeviceInfo.guestVMProtocolVersion = try readBigEndianU32(tllv.value, offset)

            spcContainer.spcData.vmDeviceInfo = Optional.some(vmDeviceInfo)
        }
        else {
            spcContainer.spcData.vmDeviceInfo = Optional.none
        }
    }
}
