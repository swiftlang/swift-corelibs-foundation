// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif



class TestUnitConverter: XCTestCase {
    
    static var allTests: [(String, (TestUnitConverter) -> () throws -> Void)] {
        return [
            ("test_baseUnit", test_linearity),
            ("test_linearity", test_linearity),
            ("test_bijectivity", test_bijectivity),
        ]
    }
    
    func test_baseUnit() {
        XCTAssertEqual(UnitAcceleration.baseUnit().symbol,
                       UnitAcceleration.metersPerSecondSquared.symbol)
        XCTAssertEqual(UnitAngle.baseUnit().symbol,
                       UnitAngle.degrees.symbol)
        XCTAssertEqual(UnitArea.baseUnit().symbol,
                       UnitArea.squareMeters.symbol)
        XCTAssertEqual(UnitConcentrationMass.baseUnit().symbol,
                       UnitConcentrationMass.gramsPerLiter.symbol)
        XCTAssertEqual(UnitDispersion.baseUnit().symbol,
                       UnitDispersion.partsPerMillion.symbol)
        XCTAssertEqual(UnitDuration.baseUnit().symbol,
                       UnitDuration.seconds.symbol)
        XCTAssertEqual(UnitElectricCharge.baseUnit().symbol,
                       UnitElectricCharge.coulombs.symbol)
        XCTAssertEqual(UnitElectricCurrent.baseUnit().symbol,
                       UnitElectricCurrent.amperes.symbol)
        XCTAssertEqual(UnitElectricPotentialDifference.baseUnit().symbol,
                       UnitElectricPotentialDifference.volts.symbol)
        XCTAssertEqual(UnitElectricResistance.baseUnit().symbol,
                       UnitElectricResistance.ohms.symbol)
        XCTAssertEqual(UnitEnergy.baseUnit().symbol,
                       UnitEnergy.joules.symbol)
        XCTAssertEqual(UnitFrequency.baseUnit().symbol,
                       UnitFrequency.hertz.symbol)
        XCTAssertEqual(UnitFuelEfficiency.baseUnit().symbol,
                       UnitFuelEfficiency.litersPer100Kilometers.symbol)
        XCTAssertEqual(UnitLength.baseUnit().symbol,
                       UnitLength.meters.symbol)
        XCTAssertEqual(UnitIlluminance.baseUnit().symbol,
                       UnitIlluminance.lux.symbol)
        XCTAssertEqual(UnitMass.baseUnit().symbol,
                       UnitMass.kilograms.symbol)
        XCTAssertEqual(UnitPower.baseUnit().symbol,
                       UnitPower.watts.symbol)
        XCTAssertEqual(UnitPressure.baseUnit().symbol,
                       UnitPressure.newtonsPerMetersSquared.symbol)
        XCTAssertEqual(UnitSpeed.baseUnit().symbol,
                       UnitSpeed.metersPerSecond.symbol)
        XCTAssertEqual(UnitTemperature.baseUnit().symbol,
                       UnitTemperature.kelvin.symbol)
        XCTAssertEqual(UnitVolume.baseUnit().symbol,
                       UnitVolume.liters.symbol)
    }
    
    func test_linearity() {
        let coefficient = 7.0
        let baseUnitConverter = UnitConverterLinear(coefficient: coefficient)
        XCTAssertEqual(baseUnitConverter.value(fromBaseUnitValue: coefficient), 1.0)
        XCTAssertEqual(baseUnitConverter.baseUnitValue(fromValue: 1), coefficient)
    }
    
    func test_bijectivity() {
        let delta = 1e-9
        let testIdentity: (Dimension) -> Double = { dimension in
            let converter = dimension.converter
            return converter.value(fromBaseUnitValue: converter.baseUnitValue(fromValue: 1))
        }
        
        XCTAssertEqualWithAccuracy(testIdentity(UnitAcceleration.metersPerSecondSquared), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitAcceleration.gravity), 1, accuracy: delta)
        
        XCTAssertEqualWithAccuracy(testIdentity(UnitAngle.degrees), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitAngle.arcMinutes), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitAngle.arcSeconds), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitAngle.radians), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitAngle.gradians), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitAngle.revolutions), 1, accuracy: delta)
        
        XCTAssertEqualWithAccuracy(testIdentity(UnitArea.squareMegameters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitArea.squareKilometers), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitArea.squareMeters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitArea.squareCentimeters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitArea.squareMillimeters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitArea.squareMicrometers), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitArea.squareNanometers), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitArea.squareInches), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitArea.squareFeet), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitArea.squareYards), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitArea.squareMiles), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitArea.acres), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitArea.ares), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitArea.hectares), 1, accuracy: delta)
        
        XCTAssertEqualWithAccuracy(testIdentity(UnitConcentrationMass.gramsPerLiter), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitConcentrationMass.milligramsPerDeciliter), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(
            testIdentity(UnitConcentrationMass.millimolesPerLiter(withGramsPerMole: 1)), 1, accuracy: delta)
        
        XCTAssertEqualWithAccuracy(testIdentity(UnitDispersion.partsPerMillion), 1, accuracy: delta)
        
        XCTAssertEqualWithAccuracy(testIdentity(UnitDuration.seconds), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitDuration.minutes), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitDuration.hours), 1, accuracy: delta)

        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricCharge.coulombs), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricCharge.megaampereHours), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricCharge.kiloampereHours), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricCharge.ampereHours), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricCharge.milliampereHours), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricCharge.microampereHours), 1, accuracy: delta)

        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricCurrent.megaamperes), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricCurrent.kiloamperes), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricCurrent.amperes), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricCurrent.milliamperes), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricCurrent.microamperes), 1, accuracy: delta)
        
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricPotentialDifference.megavolts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricPotentialDifference.kilovolts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricPotentialDifference.volts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricPotentialDifference.millivolts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricPotentialDifference.microvolts), 1, accuracy: delta)

        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricResistance.megaohms), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricResistance.kiloohms), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricResistance.ohms), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricResistance.milliohms), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitElectricResistance.microohms), 1, accuracy: delta)
        
        XCTAssertEqualWithAccuracy(testIdentity(UnitEnergy.kilojoules), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitEnergy.joules), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitEnergy.kilocalories), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitEnergy.calories), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitEnergy.kilowattHours), 1, accuracy: delta)

        XCTAssertEqualWithAccuracy(testIdentity(UnitFrequency.terahertz), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitFrequency.gigahertz), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitFrequency.megahertz), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitFrequency.kilohertz), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitFrequency.hertz), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitFrequency.millihertz), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitFrequency.microhertz), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitFrequency.nanohertz), 1, accuracy: delta)
        
        XCTAssertEqualWithAccuracy(testIdentity(UnitFuelEfficiency.litersPer100Kilometers), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitFuelEfficiency.milesPerImperialGallon), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitFuelEfficiency.milesPerGallon), 1, accuracy: delta)

        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.megameters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.kilometers), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.hectometers), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.decameters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.meters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.decimeters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.centimeters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.millimeters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.micrometers), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.nanometers), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.picometers), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.inches), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.feet), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.yards), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.miles), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.scandinavianMiles), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.nauticalMiles), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.fathoms), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.furlongs), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.astronomicalUnits), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitLength.parsecs), 1, accuracy: delta)
        
        XCTAssertEqualWithAccuracy(testIdentity(UnitIlluminance.lux), 1, accuracy: delta)
        
        XCTAssertEqualWithAccuracy(testIdentity(UnitMass.kilograms), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitMass.grams), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitMass.decigrams), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitMass.milligrams), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitMass.nanograms), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitMass.picograms), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitMass.ounces), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitMass.pounds), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitMass.stones), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitMass.metricTons), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitMass.carats), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitMass.ouncesTroy), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitMass.slugs), 1, accuracy: delta)
        
        XCTAssertEqualWithAccuracy(testIdentity(UnitPower.terawatts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPower.gigawatts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPower.megawatts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPower.kilowatts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPower.watts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPower.milliwatts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPower.microwatts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPower.nanowatts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPower.picowatts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPower.femtowatts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPower.horsepower), 1, accuracy: delta)
        
        XCTAssertEqualWithAccuracy(testIdentity(UnitPressure.newtonsPerMetersSquared), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPressure.gigapascals), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPressure.megapascals), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPressure.kilopascals), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPressure.hectopascals), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPressure.inchesOfMercury), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPressure.bars), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPressure.millibars), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPressure.millimetersOfMercury), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitPressure.poundsForcePerSquareInch), 1, accuracy: delta)

        XCTAssertEqualWithAccuracy(testIdentity(UnitSpeed.metersPerSecond), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitSpeed.kilometersPerHour), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitSpeed.milesPerHour), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitSpeed.knots), 1, accuracy: delta)
        
        XCTAssertEqualWithAccuracy(testIdentity(UnitTemperature.kelvin), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitTemperature.celsius), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitTemperature.fahrenheit), 1, accuracy: delta)

        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.megaliters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.kiloliters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.liters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.deciliters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.milliliters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.cubicKilometers), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.cubicMeters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.cubicDecimeters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.cubicCentimeters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.cubicMillimeters), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.cubicInches), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.cubicFeet), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.cubicYards), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.cubicMiles), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.acreFeet), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.bushels), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.teaspoons), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.tablespoons), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.fluidOunces), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.cups), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.pints), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.quarts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.gallons), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.imperialTeaspoons), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.imperialTablespoons), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.imperialFluidOunces), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.imperialPints), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.imperialQuarts), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.imperialGallons), 1, accuracy: delta)
        XCTAssertEqualWithAccuracy(testIdentity(UnitVolume.metricCups), 1, accuracy: delta)
    }
    
}
