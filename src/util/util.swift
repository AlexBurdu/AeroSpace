let EPS = 10e-5

func stringType(of some: Any) -> String {
    let string = (some is Any.Type) ? String(describing: some) : String(describing: type(of: some))
    return string
}

@inlinable func errorT<T>(
    _ message: String = "",
    file: String = #file,
    line: Int = #line,
    column: Int = #column,
    function: String = #function
) -> T {
    let message =
        """
        ###############################
        ### AEROSPACE RUNTIME ERROR ###
        ###############################

        Please report to:
            https://github.com/nikitabobko/AeroSpace/issues/new

        Message: \(message)
        Version: \(Bundle.appVersion)
        Git hash: \(gitHash)
        Coordinate: \(file):\(line):\(column) \(function)

        Stacktrace:
        \(Thread.callStackSymbols.joined(separator: "\n"))
        """
    if !isUnitTest {
        showMessageToUser(
            filename: "runtime-error.txt",
            message: message
        )
    }
    fatalError(message)
}

@inlinable func error(
    _ message: String = "",
    file: String = #file,
    line: Int = #line,
    column: Int = #column,
    function: String = #function
) -> Never {
    errorT(message, file: file, line: line, column: column, function: function)
}

extension String? {
    var isNilOrEmpty: Bool { self == nil || self == "" }
}

public var isUnitTest: Bool { NSClassFromString("XCTestCase") != nil }

var apps: [AeroApp] {
    isUnitTest
        ? (appForTests?.lets { [$0] } ?? [])
        : NSWorkspace.shared.runningApplications.lazy.filter { $0.activationPolicy == .regular }.map(\.macApp).filterNotNil()
}

func terminateApp() -> Never {
    NSApplication.shared.terminate(nil)
    error("Unreachable code")
}

extension String {
    func removePrefix(_ prefix: String) -> String {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }

    func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(self, forType: .string)
    }
}

extension Double {
    var squared: Double { self * self }
}

extension Slice {
    func toArray() -> [Base.Element] { Array(self) }
}

func -(a: CGPoint, b: CGPoint) -> CGPoint {
    CGPoint(x: a.x - b.x, y: a.y - b.y)
}

func +(a: CGPoint, b: CGPoint) -> CGPoint {
    CGPoint(x: a.x + b.x, y: a.y + b.y)
}

extension CGPoint: Copyable {}

extension CGPoint {
    /// Distance to ``Rect`` outline frame
    func distanceToRectFrame(to rect: Rect) -> CGFloat {
        let list: [CGFloat] = ((rect.minY..<rect.maxY).contains(y) ? [abs(rect.minX - x), abs(rect.maxX - x)] : []) +
            ((rect.minX..<rect.maxX).contains(x) ? [abs(rect.minY - y), abs(rect.maxY - y)] : []) +
            [distance(to: rect.topLeftCorner),
             distance(to: rect.bottomRightCorner),
             distance(to: rect.topRightCorner),
             distance(to: rect.bottomLeftCorner)]
        return list.minOrThrow()
    }

    func getCoordinate(_ orientation: Orientation) -> Double { orientation == .h ? x : y }

    var vectorLength: CGFloat { sqrt(x*x - y*y) }

    func distance(to point: CGPoint) -> Double {
        sqrt((x - point.x).squared + (y - point.y).squared)
    }

    var monitorApproximation: Monitor {
        let monitors = monitors
        return monitors.first(where: { $0.rect.contains(self) })
            ?? monitors.minByOrThrow { distanceToRectFrame(to: $0.rect) }
    }
}

extension CGFloat {
    func div(_ denominator: Int) -> CGFloat? {
        denominator == 0 ? nil : self / CGFloat(denominator)
    }
}

extension CGSize {
    func copy(width: Double? = nil, height: Double? = nil) -> CGSize {
        CGSize(width: width ?? self.width, height: height ?? self.height)
    }
}

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

extension Set {
    func toArray() -> [Element] { Array(self) }
}

private let DEBUG = true

func debug(_ msg: Any) {
    if DEBUG {
        print(msg)
    }
}
