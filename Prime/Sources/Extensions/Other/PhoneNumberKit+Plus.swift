import PhoneNumberKit

extension PhoneNumberKit {
    public func parse(
        _ numberString: String,
        addPlusIfFails: Bool,
        withRegion region: String = PhoneNumberKit.defaultRegionCode(),
        ignoreType: Bool = false
    ) throws -> PhoneNumber {
        let hasPlus = numberString.hasPrefix("+")
        if hasPlus || !addPlusIfFails {
            return try self.parse(numberString, withRegion: region, ignoreType: ignoreType)
        }

        do {
            let result = try self.parse(numberString, withRegion: region, ignoreType: ignoreType)
            return result
        } catch {
            let plusedNumberString = "+" + numberString
            return try self.parse(plusedNumberString, withRegion: region, ignoreType: ignoreType)
        }
    }
}
