
import Foundation
import CoreGraphics

func arc4random <T: ExpressibleByIntegerLiteral> (_ type: T.Type) -> T {
	var r: T = 0
	arc4random_buf(&r, Int(MemoryLayout<T>.size))
	return r
}

extension Float {
	var radians: Float {
		return self / 180 * Float.pi
	}
	var degrees: Float {
		return self / Float.pi * 180
	}
}

extension CGFloat {
	var radians: CGFloat {
		return self / 180 * CGFloat.pi
	}
	var degrees: CGFloat {
		return self / CGFloat.pi * 180
	}
}

extension Double {
	var radians: Double {
		return self / 180 * Double.pi
	}
	var degrees: Double {
		return self / Double.pi * 180
	}
	static func random(min: Double, max: Double) -> Double {
		let r64 = Double(arc4random(UInt64.self)) / Double(UInt64.max)
		return (r64 * (max - min)) + min
	}
}
