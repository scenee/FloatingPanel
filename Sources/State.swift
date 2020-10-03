// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import Foundation

/// An object that represents the display state of a panel in a screen.
@objc
public class FloatingPanelState: NSObject, NSCopying, RawRepresentable {
    public typealias RawValue = String

    required public init?(rawValue: RawValue) {
        self.order = 0
        self.rawValue = rawValue
        super.init()
    }

    public init(rawValue: RawValue, order: Int) {
        self.rawValue = rawValue
        self.order = order
        super.init()
    }

    /// The corresponding value of the raw type.
    public let rawValue: RawValue
    /// The sorting order for states
    public let order: Int

    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }

    public override var description: String {
        return rawValue
    }

    public override var debugDescription: String {
        return description
    }

    /// A panel state indicates the entire panel is shown.
    @objc(Full) public static let full: FloatingPanelState = FloatingPanelState(rawValue: "full", order: 1000)
    /// A panel state indicates the half of a panel is shown.
    @objc(Half) public static let half: FloatingPanelState = FloatingPanelState(rawValue: "half", order: 500)
    /// A panel state indicates the tip of a panel is shown.
    @objc(Tip) public static let tip: FloatingPanelState = FloatingPanelState(rawValue: "tip", order: 100)
    /// A panel state indicates it is hidden.
    @objc(Hidden) public static let hidden: FloatingPanelState = FloatingPanelState(rawValue: "hidden", order: 0)
}

extension FloatingPanelState {
    func next(in states: [FloatingPanelState]) -> FloatingPanelState {
        if let index = states.firstIndex(of: self), states.indices.contains(index + 1) {
            return states[index + 1]
        }
        return self
    }

    func pre(in states: [FloatingPanelState]) -> FloatingPanelState {
        if let index = states.firstIndex(of: self), states.indices.contains(index - 1) {
            return states[index - 1]
        }
        return self
    }
}
