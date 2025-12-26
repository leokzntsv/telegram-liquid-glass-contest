import Foundation
import UIKit
import Display
import ComponentFlow
import ComponentDisplayAdapters
import UIKitRuntimeUtils
import CoreImage
import AppBundle

private final class ContentContainer: UIView {
    private let maskContentView: UIView
    
    init(maskContentView: UIView) {
        self.maskContentView = maskContentView
        
        super.init(frame: CGRect())
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let result = super.hitTest(point, with: event) else {
            return nil
        }
        if result === self {
            if let gestureRecognizers = self.gestureRecognizers, !gestureRecognizers.isEmpty {
                return result
            }
            return nil
        }
        return result
    }
    
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        
        if let subview = subview as? GlassBackgroundView.ContentView {
            self.maskContentView.addSubview(subview.tintMask)
        }
    }
    
    override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        
        if let subview = subview as? GlassBackgroundView.ContentView {
            subview.tintMask.removeFromSuperview()
        }
    }
}

public class GlassBackgroundView: UIView {
    public protocol ContentView: UIView {
        var tintMask: UIView { get }
    }
    
    open class ContentLayer: SimpleLayer {
        public var targetLayer: CALayer?
        
        override init() {
            super.init()
        }
        
        override init(layer: Any) {
            super.init(layer: layer)
        }
        
        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override public var position: CGPoint {
            get {
                return super.position
            } set(value) {
                if let targetLayer = self.targetLayer {
                    targetLayer.position = value
                }
                super.position = value
            }
        }
        
        override public var bounds: CGRect {
            get {
                return super.bounds
            } set(value) {
                if let targetLayer = self.targetLayer {
                    targetLayer.bounds = value
                }
                super.bounds = value
            }
        }
        
        override public var anchorPoint: CGPoint {
            get {
                return super.anchorPoint
            } set(value) {
                if let targetLayer = self.targetLayer {
                    targetLayer.anchorPoint = value
                }
                super.anchorPoint = value
            }
        }
        
        override public var anchorPointZ: CGFloat {
            get {
                return super.anchorPointZ
            } set(value) {
                if let targetLayer = self.targetLayer {
                    targetLayer.anchorPointZ = value
                }
                super.anchorPointZ = value
            }
        }
        
        override public var opacity: Float {
            get {
                return super.opacity
            } set(value) {
                if let targetLayer = self.targetLayer {
                    targetLayer.opacity = value
                }
                super.opacity = value
            }
        }
        
        override public var sublayerTransform: CATransform3D {
            get {
                return super.sublayerTransform
            } set(value) {
                if let targetLayer = self.targetLayer {
                    targetLayer.sublayerTransform = value
                }
                super.sublayerTransform = value
            }
        }
        
        override public var transform: CATransform3D {
            get {
                return super.transform
            } set(value) {
                if let targetLayer = self.targetLayer {
                    targetLayer.transform = value
                }
                super.transform = value
            }
        }
        
        override public func add(_ animation: CAAnimation, forKey key: String?) {
            if let targetLayer = self.targetLayer {
                targetLayer.add(animation, forKey: key)
            }
            
            super.add(animation, forKey: key)
        }
        
        override public func removeAllAnimations() {
            if let targetLayer = self.targetLayer {
                targetLayer.removeAllAnimations()
            }
            
            super.removeAllAnimations()
        }
        
        override public func removeAnimation(forKey: String) {
            if let targetLayer = self.targetLayer {
                targetLayer.removeAnimation(forKey: forKey)
            }
            
            super.removeAnimation(forKey: forKey)
        }
    }
    
    public final class ContentColorView: UIView, ContentView {
        override public static var layerClass: AnyClass {
            return ContentLayer.self
        }
        
        public let tintMask: UIView
        
        override public init(frame: CGRect) {
            self.tintMask = UIView()
            
            super.init(frame: CGRect())
            
            self.tintMask.tintColor = .black
        }
        
        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    public final class ContentImageView: UIImageView, ContentView {
        override public static var layerClass: AnyClass {
            return ContentLayer.self
        }
        
        private let tintImageView: UIImageView
        public var tintMask: UIView {
            return self.tintImageView
        }
        
        override public var image: UIImage? {
            didSet {
                self.tintImageView.image = self.image
            }
        }
        
        override public var tintColor: UIColor? {
            didSet {
                if self.tintColor != oldValue {
                    self.setMonochromaticEffect(tintColor: self.tintColor)
                }
            }
        }
        
        override public init(frame: CGRect) {
            self.tintImageView = UIImageView()
            
            super.init(frame: CGRect())
            
            self.tintImageView.tintColor = .black
        }
        
        override public init(image: UIImage?) {
            self.tintImageView = UIImageView()
            
            super.init(image: image)
            
            self.tintImageView.image = image
            self.tintImageView.tintColor = .black
        }
        
        override public init(image: UIImage?, highlightedImage: UIImage?) {
            self.tintImageView = UIImageView()
            
            super.init(image: image, highlightedImage: highlightedImage)
            
            self.tintImageView.image = image
            self.tintImageView.tintColor = .black
        }
        
        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    public struct TintColor: Equatable {
        public enum Kind {
            case panel
            case custom
        }
        
        public let kind: Kind
        public let color: UIColor
        public let innerColor: UIColor?
        
        public init(kind: Kind, color: UIColor, innerColor: UIColor? = nil) {
            self.kind = kind
            self.color = color
            self.innerColor = innerColor
        }
    }
    
    public enum Shape: Equatable {
        case roundedRect(cornerRadius: CGFloat)
    }
    
    private final class ClippingShapeContext {
        let view: UIView
        
        private(set) var shape: Shape?
        
        init(view: UIView) {
            self.view = view
        }
        
        func update(shape: Shape, size: CGSize, transition: ComponentTransition) {
            self.shape = shape
            
            switch shape {
            case let .roundedRect(cornerRadius):
                transition.setCornerRadius(layer: self.view.layer, cornerRadius: cornerRadius)
            }
        }
    }
    
    public struct Params: Equatable {
        public let shape: Shape
        public let isDark: Bool
        public let tintColor: TintColor
        public let isInteractive: Bool
        
        init(shape: Shape, isDark: Bool, tintColor: TintColor, isInteractive: Bool) {
            self.shape = shape
            self.isDark = isDark
            self.tintColor = tintColor
            self.isInteractive = isInteractive
        }
    }
    
    private let backgroundNode: NavigationBackgroundNode?
    
    private let nativeView: UIVisualEffectView?
    private let nativeViewClippingContext: ClippingShapeContext?
    private let nativeParamsView: EffectSettingsContainerView?
    
    private let foregroundView: UIImageView?
    private let shadowView: UIImageView?
    
    private let maskContainerView: UIView
    public let maskContentView: UIView
    private let contentContainer: ContentContainer
    
    private var innerBackgroundView: UIView?
    
    public var contentView: UIView {
        if let nativeView = self.nativeView {
            return nativeView.contentView
        } else {
            return self.contentContainer
        }
    }
    
    public private(set) var params: Params?
        
    public static var useCustomGlassImpl: Bool = false
    
    public override init(frame: CGRect) {
        if #available(iOS 26.0, *), !GlassBackgroundView.useCustomGlassImpl {
            self.backgroundNode = nil
            
            let glassEffect = UIGlassEffect(style: .regular)
            glassEffect.isInteractive = false
            let nativeView = UIVisualEffectView(effect: glassEffect)
            self.nativeViewClippingContext = ClippingShapeContext(view: nativeView)
            self.nativeView = nativeView
            
            let nativeParamsView = EffectSettingsContainerView(frame: CGRect())
            self.nativeParamsView = nativeParamsView
            
            nativeParamsView.addSubview(nativeView)
            
            self.foregroundView = nil
            self.shadowView = nil
        } else {
            let backgroundNode = NavigationBackgroundNode(color: .black, enableBlur: true, customBlurRadius: 8.0)
            self.backgroundNode = backgroundNode
            self.nativeView = nil
            self.nativeViewClippingContext = nil
            self.nativeParamsView = nil
            self.foregroundView = UIImageView()
            
            self.shadowView = UIImageView()
        }
        
        self.maskContainerView = UIView()
        self.maskContainerView.backgroundColor = .white
        if let filter = CALayer.luminanceToAlpha() {
            self.maskContainerView.layer.filters = [filter]
        }
        
        self.maskContentView = UIView()
        self.maskContainerView.addSubview(self.maskContentView)
        
        self.contentContainer = ContentContainer(maskContentView: self.maskContentView)
        
        super.init(frame: frame)
        
        if let shadowView = self.shadowView {
            self.addSubview(shadowView)
        }
        if let nativeParamsView = self.nativeParamsView {
            self.addSubview(nativeParamsView)
        }
        if let backgroundNode = self.backgroundNode {
            self.addSubview(backgroundNode.view)
        }
        if let foregroundView = self.foregroundView {
            self.addSubview(foregroundView)
            foregroundView.mask = self.maskContainerView
        }
        self.addSubview(self.contentContainer)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let nativeView = self.nativeView {
            if let result = nativeView.hitTest(self.convert(point, to: nativeView), with: event) {
                return result
            }
        } else {
            if let result = self.contentContainer.hitTest(self.convert(point, to: self.contentContainer), with: event) {
                return result
            }
        }
        return nil
    }
        
    public func update(size: CGSize, cornerRadius: CGFloat, isDark: Bool, tintColor: TintColor, isInteractive: Bool = false, transition: ComponentTransition) {
        self.update(size: size, shape: .roundedRect(cornerRadius: cornerRadius), isDark: isDark, tintColor: tintColor, isInteractive: isInteractive, transition: transition)
    }
    
    public func update(size: CGSize, shape: Shape, isDark: Bool, tintColor: TintColor, isInteractive: Bool = false, transition: ComponentTransition) {
        if let nativeView = self.nativeView, let nativeViewClippingContext = self.nativeViewClippingContext, (nativeView.bounds.size != size || nativeViewClippingContext.shape != shape) {
            
            nativeViewClippingContext.update(shape: shape, size: size, transition: transition)
            if transition.animation.isImmediate {
                nativeView.frame = CGRect(origin: CGPoint(), size: size)
            } else {
                let nativeFrame = CGRect(origin: CGPoint(), size: size)
                transition.setFrame(view: nativeView, frame: nativeFrame)
            }
        }
        if let backgroundNode = self.backgroundNode {
            backgroundNode.updateColor(color: .clear, forceKeepBlur: tintColor.color.alpha != 1.0, transition: transition.containedViewLayoutTransition)
            
            switch shape {
            case let .roundedRect(cornerRadius):
                backgroundNode.update(size: size, cornerRadius: cornerRadius, transition: transition.containedViewLayoutTransition)
            }
            transition.setFrame(view: backgroundNode.view, frame: CGRect(origin: CGPoint(), size: size))
        }
        
        let shadowInset: CGFloat = 32.0
        
        if let innerColor = tintColor.innerColor {
            let innerBackgroundFrame = CGRect(origin: CGPoint(), size: size).insetBy(dx: 3.0, dy: 3.0)
            let innerBackgroundRadius = min(innerBackgroundFrame.width, innerBackgroundFrame.height) * 0.5
            
            let innerBackgroundView: UIView
            var innerBackgroundTransition = transition
            var animateIn = false
            if let current = self.innerBackgroundView {
                innerBackgroundView = current
            } else {
                innerBackgroundView = UIView()
                innerBackgroundTransition = innerBackgroundTransition.withAnimation(.none)
                self.innerBackgroundView = innerBackgroundView
                self.contentView.insertSubview(innerBackgroundView, at: 0)
                
                innerBackgroundView.frame = innerBackgroundFrame
                innerBackgroundView.layer.cornerRadius = innerBackgroundRadius
                animateIn = true
            }
            
            innerBackgroundView.backgroundColor = innerColor
            innerBackgroundTransition.setFrame(view: innerBackgroundView, frame: innerBackgroundFrame)
            innerBackgroundTransition.setCornerRadius(layer: innerBackgroundView.layer, cornerRadius: innerBackgroundRadius)
            
            if animateIn {
                transition.animateAlpha(view: innerBackgroundView, from: 0.0, to: 1.0)
                transition.animateScale(view: innerBackgroundView, from: 0.001, to: 1.0)
            }
        } else if let innerBackgroundView = self.innerBackgroundView {
            self.innerBackgroundView = nil
            
            transition.setAlpha(view: innerBackgroundView, alpha: 0.0, completion: { [weak innerBackgroundView] _ in
                innerBackgroundView?.removeFromSuperview()
            })
            transition.setScale(view: innerBackgroundView, scale: 0.001)
            
            innerBackgroundView.removeFromSuperview()
        }
        
        let params = Params(shape: shape, isDark: isDark, tintColor: tintColor, isInteractive: isInteractive)
        if self.params != params {
            self.params = params
            
            let outerCornerRadius: CGFloat
            switch shape {
            case let .roundedRect(cornerRadius):
                outerCornerRadius = cornerRadius
            }
            
            if let shadowView = self.shadowView {
                let shadowInnerInset: CGFloat = 0.5
                shadowView.image = generateImage(CGSize(width: shadowInset * 2.0 + outerCornerRadius * 2.0, height: shadowInset * 2.0 + outerCornerRadius * 2.0), rotatedContext: { size, context in
                    context.clear(CGRect(origin: CGPoint(), size: size))
                    
                    context.setFillColor(UIColor.black.cgColor)
                    context.setShadow(offset: CGSize(width: 0.0, height: 1.0), blur: 40.0, color: UIColor(white: 0.0, alpha: 0.04).cgColor)
                    context.fillEllipse(in: CGRect(origin: CGPoint(x: shadowInset + shadowInnerInset, y: shadowInset + shadowInnerInset), size: CGSize(width: size.width - shadowInset * 2.0 - shadowInnerInset * 2.0, height: size.height - shadowInset * 2.0 - shadowInnerInset * 2.0)))
                    
                    context.setFillColor(UIColor.clear.cgColor)
                    context.setBlendMode(.copy)
                    context.fillEllipse(in: CGRect(origin: CGPoint(x: shadowInset + shadowInnerInset, y: shadowInset + shadowInnerInset), size: CGSize(width: size.width - shadowInset * 2.0 - shadowInnerInset * 2.0, height: size.height - shadowInset * 2.0 - shadowInnerInset * 2.0)))
                })?.stretchableImage(withLeftCapWidth: Int(shadowInset + outerCornerRadius), topCapHeight: Int(shadowInset + outerCornerRadius))
            }
            
            if let foregroundView = self.foregroundView {
                foregroundView.image = GlassBackgroundView.generateLegacyGlassImage(size: CGSize(width: outerCornerRadius * 2.0, height: outerCornerRadius * 2.0), inset: shadowInset, isDark: isDark, fillColor: tintColor.color)
            } else {
                if let nativeParamsView = self.nativeParamsView, let nativeView = self.nativeView {
                    if #available(iOS 26.0, *) {
                        let glassEffect = UIGlassEffect(style: .regular)
                        switch tintColor.kind {
                        case .panel:
                            glassEffect.tintColor = nil
                        case .custom:
                            glassEffect.tintColor = tintColor.color
                        }
                        glassEffect.isInteractive = params.isInteractive
                        
                        if transition.animation.isImmediate {
                            nativeView.effect = glassEffect
                        } else {
                            UIView.animate(withDuration: 0.2, animations: {
                                nativeView.effect = glassEffect
                            })
                        }
                        
                        if isDark {
                            nativeParamsView.lumaMin = 0.0
                            nativeParamsView.lumaMax = 0.15
                        } else {
                            nativeParamsView.lumaMin = 0.25
                            nativeParamsView.lumaMax = 1.0
                        }
                    }
                }
            }
        }
        
        transition.setFrame(view: self.maskContainerView, frame: CGRect(origin: CGPoint(), size: CGSize(width: size.width + shadowInset * 2.0, height: size.height + shadowInset * 2.0)))
        transition.setFrame(view: self.maskContentView, frame: CGRect(origin: CGPoint(x: shadowInset, y: shadowInset), size: size))
        if let foregroundView = self.foregroundView {
            transition.setFrame(view: foregroundView, frame: CGRect(origin: CGPoint(), size: size).insetBy(dx: -shadowInset, dy: -shadowInset))
        }
        if let shadowView = self.shadowView {
            transition.setFrame(view: shadowView, frame: CGRect(origin: CGPoint(), size: size).insetBy(dx: -shadowInset, dy: -shadowInset))
        }
        transition.setFrame(view: self.contentContainer, frame: CGRect(origin: CGPoint(), size: size))
    }
}

public final class GlassBackgroundContainerView: UIView {
    private final class ContentView: UIView {
    }
    
    private let legacyView: ContentView?
    private let nativeParamsView: EffectSettingsContainerView?
    private let nativeView: UIVisualEffectView?
    
    public var contentView: UIView {
        if let nativeView = self.nativeView {
            return nativeView.contentView
        } else {
            return self.legacyView!
        }
    }
    
    public override init(frame: CGRect) {
        if #available(iOS 26.0, *) {
            let effect = UIGlassContainerEffect()
            effect.spacing = 7.0
            let nativeView = UIVisualEffectView(effect: effect)
            self.nativeView = nativeView
            
            let nativeParamsView = EffectSettingsContainerView(frame: CGRect())
            self.nativeParamsView = nativeParamsView
            nativeParamsView.addSubview(nativeView)
            
            self.legacyView = nil
        } else {
            self.nativeView = nil
            self.nativeParamsView = nil
            self.legacyView = ContentView()
        }
        
        super.init(frame: frame)
        
        if let nativeParamsView = self.nativeParamsView {
            self.addSubview(nativeParamsView)
        } else if let legacyView = self.legacyView {
            self.addSubview(legacyView)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        
        if subview !== self.nativeParamsView && subview !== self.legacyView {
            assertionFailure()
        }
    }
    
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let result = self.contentView.hitTest(point, with: event) else {
            return nil
        }
        return result
    }
    
    public func update(size: CGSize, isDark: Bool, transition: ComponentTransition) {
        if let nativeParamsView = self.nativeParamsView, let nativeView = self.nativeView {
            nativeView.overrideUserInterfaceStyle = isDark ? .dark : .light
            
            if isDark {
                nativeParamsView.lumaMin = 0.0
                nativeParamsView.lumaMax = 0.15
            } else {
                nativeParamsView.lumaMin = 0.25
                nativeParamsView.lumaMax = 1.0
            }
            
            transition.setFrame(view: nativeView, frame: CGRect(origin: CGPoint(), size: size))
        } else if let legacyView = self.legacyView {
            transition.setFrame(view: legacyView, frame: CGRect(origin: CGPoint(), size: size))
        }
    }
}

private extension CGContext {
    func addBadgePath(in rect: CGRect) {
        saveGState()
        translateBy(x: rect.minX, y: rect.minY)
        scaleBy(x: rect.width / 78.0, y: rect.height / 78.0)
        
        // M 0 39
        move(to: CGPoint(x: 0, y: 39))
        
        // C 0 17.4609 17.4609 0 39 0
        addCurve(to: CGPoint(x: 39, y: 0),
                 control1: CGPoint(x: 0,       y: 17.4609),
                 control2: CGPoint(x: 17.4609, y: 0))
        
        // H 42
        addLine(to: CGPoint(x: 42, y: 0))
        
        // C 61.8823 0 78 16.1177 78 36
        addCurve(to: CGPoint(x: 78, y: 36),
                 control1: CGPoint(x: 61.8823, y: 0),
                 control2: CGPoint(x: 78,      y: 16.1177))
        
        // V 39
        addLine(to: CGPoint(x: 78, y: 39))
        
        // C 78 60.5391 60.5391 78 39 78
        addCurve(to: CGPoint(x: 39, y: 78),
                 control1: CGPoint(x: 78,      y: 60.5391),
                 control2: CGPoint(x: 60.5391, y: 78))
        
        // H 36
        addLine(to: CGPoint(x: 36, y: 78))
        
        // C 16.1177 78 0 61.8823 0 42
        addCurve(to: CGPoint(x: 0, y: 42),
                 control1: CGPoint(x: 16.1177, y: 78),
                 control2: CGPoint(x: 0,       y: 61.8823))
        
        // V 39 / Z
        addLine(to: CGPoint(x: 0, y: 39))
        closePath()
        
        restoreGState()
    }
}

public extension GlassBackgroundView {
    static func generateLegacyGlassImage(size: CGSize, inset: CGFloat, isDark: Bool, fillColor: UIColor) -> UIImage {
        var size = size
        if size == .zero {
            size = CGSize(width: 2.0, height: 2.0)
        }
        let innerSize = size
        size.width += inset * 2.0
        size.height += inset * 2.0
        
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let context = ctx.cgContext
            
            context.clear(CGRect(origin: CGPoint(), size: size))

            let addShadow: (CGContext, Bool, CGPoint, CGFloat, CGFloat, UIColor, CGBlendMode) -> Void = { context, isOuter, position, blur, spread, shadowColor, blendMode in
                var blur = blur
                
                if isOuter {
                    blur += abs(spread)
                    
                    context.beginTransparencyLayer(auxiliaryInfo: nil)
                    context.saveGState()
                    defer {
                        context.restoreGState()
                        context.endTransparencyLayer()
                    }

                    let spreadRect = CGRect(origin: CGPoint(x: inset, y: inset), size: innerSize).insetBy(dx: 0.25, dy: 0.25)
                    let spreadPath = UIBezierPath(
                        roundedRect: spreadRect,
                        cornerRadius: min(spreadRect.width, spreadRect.height) * 0.5
                    ).cgPath

                    context.setShadow(offset: CGSize(width: position.x, height: position.y), blur: blur, color: shadowColor.cgColor)
                    context.setFillColor(UIColor.black.withAlphaComponent(1.0).cgColor)
                    context.addPath(spreadPath)
                    context.fillPath()
                    
                    let cleanRect = CGRect(origin: CGPoint(x: inset, y: inset), size: innerSize)
                    let cleanPath = UIBezierPath(
                        roundedRect: cleanRect,
                        cornerRadius: min(cleanRect.width, cleanRect.height) * 0.5
                    ).cgPath
                    context.setBlendMode(.copy)
                    context.setFillColor(UIColor.clear.cgColor)
                    context.addPath(cleanPath)
                    context.fillPath()
                    context.setBlendMode(.normal)
                } else {
                    let image = UIGraphicsImageRenderer(size: size).image(actions: { ctx in
                        let context = ctx.cgContext
                        
                        context.clear(CGRect(origin: CGPoint(), size: size))
                        let spreadRect = CGRect(origin: CGPoint(x: inset, y: inset), size: innerSize).insetBy(dx: -spread - 0.33, dy: -spread - 0.33)

                        context.setShadow(offset: CGSize(width: position.x, height: position.y), blur: blur, color: shadowColor.cgColor)
                        context.setFillColor(shadowColor.cgColor)
                        let enclosingRect = spreadRect.insetBy(dx: -10000.0, dy: -10000.0)
                        context.addPath(UIBezierPath(rect: enclosingRect).cgPath)
                        context.addBadgePath(in: spreadRect)
                        context.fillPath(using: .evenOdd)
                    })
                    
                    UIGraphicsPushContext(context)
                    image.draw(in: CGRect(origin: .zero, size: size), blendMode: blendMode, alpha: 1.0)
                    UIGraphicsPopContext()
                }
            }
            
            addShadow(context, true, CGPoint(), 10.0, 0.0, UIColor(white: 0.0, alpha: 0.06), .normal)
            addShadow(context, true, CGPoint(), 20.0, 0.0, UIColor(white: 0.0, alpha: 0.06), .normal)
            
            var a: CGFloat = 0.0
            var b: CGFloat = 0.0
            var s: CGFloat = 0.0
            fillColor.getHue(nil, saturation: &s, brightness: &b, alpha: &a)
            
            let innerImage: UIImage
            if size == CGSize(width: 40.0 + inset * 2.0, height: 40.0 + inset * 2.0), b >= 0.2 {
                innerImage = UIGraphicsImageRenderer(size: size).image { ctx in
                    let context = ctx.cgContext
                    
                    context.setFillColor(fillColor.cgColor)
                    context.fill(CGRect(origin: CGPoint(), size: size))
                    
                    if let image = UIImage(bundleImageName: "Item List/GlassEdge40x40") {
                        let imageInset = (image.size.width - 40.0) * 0.5
                        
                        if s == 0.0 && abs(a - 0.7) < 0.1 && !isDark {
                            image.draw(in: CGRect(origin: CGPoint(), size: size).insetBy(dx: inset - imageInset, dy: inset - imageInset), blendMode: .normal, alpha: 1.0)
                        } else if s <= 0.3 && !isDark {
                            image.draw(in: CGRect(origin: CGPoint(), size: size).insetBy(dx: inset - imageInset, dy: inset - imageInset), blendMode: .normal, alpha: 0.7)
                        } else if b >= 0.2 {
                            let maxAlpha: CGFloat = isDark ? 0.7 : 0.8
                            image.draw(in: CGRect(origin: CGPoint(), size: size).insetBy(dx: inset - imageInset, dy: inset - imageInset), blendMode: .overlay, alpha: max(0.5, min(1.0, maxAlpha * s)))
                        } else {
                            image.draw(in: CGRect(origin: CGPoint(), size: size).insetBy(dx: inset - imageInset, dy: inset - imageInset), blendMode: .normal, alpha: 0.5)
                        }
                    }
                }
            } else {
                innerImage = UIGraphicsImageRenderer(size: size).image { ctx in
                    let context = ctx.cgContext
                    
                    context.setFillColor(fillColor.cgColor)
                    context.fill(CGRect(origin: CGPoint(), size: size).insetBy(dx: inset, dy: inset).insetBy(dx: 0.1, dy: 0.1))
                    
                    addShadow(context, true, CGPoint(x: 0.0, y: 0.0), 20.0, 0.0, UIColor(white: 0.0, alpha: 0.04), .normal)
                    addShadow(context, true, CGPoint(x: 0.0, y: 0.0), 5.0, 0.0, UIColor(white: 0.0, alpha: 0.04), .normal)
                    
                    if s <= 0.3 && !isDark {
                        addShadow(context, false, CGPoint(x: 0.0, y: 0.0), 8.0, 0.0, UIColor(white: 0.0, alpha: 0.4), .overlay)
                        
                        let edgeAlpha: CGFloat = max(0.8, min(1.0, a))
                        
                        for _ in 0 ..< 2 {
                            addShadow(context, false, CGPoint(x: -0.64, y: -0.64), 0.8, 0.0, UIColor(white: 1.0, alpha: edgeAlpha), .normal)
                            addShadow(context, false, CGPoint(x: 0.64, y: 0.64), 0.8, 0.0, UIColor(white: 1.0, alpha: edgeAlpha), .normal)
                        }
                    } else if b >= 0.2 {
                        let edgeAlpha: CGFloat = max(0.2, min(isDark ? 0.5 : 0.7, a * a * a))
                        
                        addShadow(context, false, CGPoint(x: -0.64, y: -0.64), 0.5, 0.0, UIColor(white: 1.0, alpha: edgeAlpha), .plusLighter)
                        addShadow(context, false, CGPoint(x: 0.64, y: 0.64), 0.5, 0.0, UIColor(white: 1.0, alpha: edgeAlpha), .plusLighter)
                    } else {
                        let edgeAlpha: CGFloat = max(0.4, min(isDark ? 0.5 : 0.7, a * a * a))
                        
                        addShadow(context, false, CGPoint(x: -0.64, y: -0.64), 1.2, 0.0, UIColor(white: 1.0, alpha: edgeAlpha), .normal)
                        addShadow(context, false, CGPoint(x: 0.64, y: 0.64), 1.2, 0.0, UIColor(white: 1.0, alpha: edgeAlpha), .normal)
                    }
                }
            }
            
            context.addEllipse(in: CGRect(origin: CGPoint(x: inset, y: inset), size: innerSize))
            context.clip()
            innerImage.draw(in: CGRect(origin: CGPoint(), size: size))
        }.stretchableImage(withLeftCapWidth: Int(size.width * 0.5), topCapHeight: Int(size.height * 0.5))
    }
    
    static func generateForegroundImage(size: CGSize, isDark: Bool, fillColor: UIColor) -> UIImage {
        var size = size
        if size == .zero {
            size = CGSize(width: 1.0, height: 1.0)
        }
        
        return generateImage(size, rotatedContext: { size, context in
            context.clear(CGRect(origin: CGPoint(), size: size))
            
            let maxColor = UIColor(white: 1.0, alpha: isDark ? 0.2 : 0.9)
            let minColor = UIColor(white: 1.0, alpha: 0.0)
            
            context.setFillColor(fillColor.cgColor)
            context.fillEllipse(in: CGRect(origin: CGPoint(), size: size))
            
            let lineWidth: CGFloat = isDark ? 0.33 : 0.66
            
            context.saveGState()
            
            let darkShadeColor = UIColor(white: isDark ? 1.0 : 0.0, alpha: isDark ? 0.0 : 0.035)
            let lightShadeColor = UIColor(white: isDark ? 0.0 : 1.0, alpha: isDark ? 0.0 : 0.035)
            let innerShadowBlur: CGFloat = 24.0
            
            context.resetClip()
            context.addEllipse(in: CGRect(origin: CGPoint(), size: size).insetBy(dx: lineWidth * 0.5, dy: lineWidth * 0.5))
            context.clip()
            context.addRect(CGRect(origin: CGPoint(), size: size).insetBy(dx: -100.0, dy: -100.0))
            context.addEllipse(in: CGRect(origin: CGPoint(), size: size))
            context.setFillColor(UIColor.black.cgColor)
            context.setShadow(offset: CGSize(width: 10.0, height: -10.0), blur: innerShadowBlur, color: darkShadeColor.cgColor)
            context.fillPath(using: .evenOdd)
            
            context.resetClip()
            context.addEllipse(in: CGRect(origin: CGPoint(), size: size).insetBy(dx: lineWidth * 0.5, dy: lineWidth * 0.5))
            context.clip()
            context.addRect(CGRect(origin: CGPoint(), size: size).insetBy(dx: -100.0, dy: -100.0))
            context.addEllipse(in: CGRect(origin: CGPoint(), size: size))
            context.setFillColor(UIColor.black.cgColor)
            context.setShadow(offset: CGSize(width: -10.0, height: 10.0), blur: innerShadowBlur, color: lightShadeColor.cgColor)
            context.fillPath(using: .evenOdd)
            
            context.restoreGState()
            
            context.setLineWidth(lineWidth)
            
            context.addRect(CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: size.width * 0.5, height: size.height)))
            context.clip()
            context.addEllipse(in: CGRect(origin: CGPoint(), size: size).insetBy(dx: lineWidth * 0.5, dy: lineWidth * 0.5))
            context.replacePathWithStrokedPath()
            context.clip()
            
            do {
                var locations: [CGFloat] = [0.0, 0.5, 0.5 + 0.2, 1.0 - 0.1, 1.0]
                let colors: [CGColor] = [maxColor.cgColor, maxColor.cgColor, minColor.cgColor, minColor.cgColor, maxColor.cgColor]
                
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: &locations)!
                
                context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: 0.0, y: size.height), options: CGGradientDrawingOptions())
            }
            
            context.resetClip()
            context.addRect(CGRect(origin: CGPoint(x: size.width - size.width * 0.5, y: 0.0), size: CGSize(width: size.width * 0.5, height: size.height)))
            context.clip()
            context.addEllipse(in: CGRect(origin: CGPoint(), size: size).insetBy(dx: lineWidth * 0.5, dy: lineWidth * 0.5))
            context.replacePathWithStrokedPath()
            context.clip()
            
            do {
                var locations: [CGFloat] = [0.0, 0.1, 0.5 - 0.2, 0.5, 1.0]
                let colors: [CGColor] = [maxColor.cgColor, minColor.cgColor, minColor.cgColor, maxColor.cgColor, maxColor.cgColor]
                
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: &locations)!
                
                context.drawLinearGradient(gradient, start: CGPoint(x: 0.0, y: 0.0), end: CGPoint(x: 0.0, y: size.height), options: CGGradientDrawingOptions())
            }
        })!.stretchableImage(withLeftCapWidth: Int(size.width * 0.5), topCapHeight: Int(size.height * 0.5))
    }
}

public final class GlassBackgroundComponent: Component {
    private let size: CGSize
    private let cornerRadius: CGFloat
    private let isDark: Bool
    private let tintColor: GlassBackgroundView.TintColor
    
    public init(size: CGSize, cornerRadius: CGFloat, isDark: Bool, tintColor: GlassBackgroundView.TintColor) {
        self.size = size
        self.cornerRadius = cornerRadius
        self.isDark = isDark
        self.tintColor = tintColor
    }
    
    public static func == (lhs: GlassBackgroundComponent, rhs: GlassBackgroundComponent) -> Bool {
        if lhs.size != rhs.size {
            return false
        }
        if lhs.cornerRadius != rhs.cornerRadius {
            return false
        }
        if lhs.isDark != rhs.isDark {
            return false
        }
        if lhs.tintColor != rhs.tintColor {
            return false
        }
        return true
    }
    
    public final class View: GlassBackgroundView {
        func update(component: GlassBackgroundComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
            self.update(size: component.size, cornerRadius: component.cornerRadius, isDark: component.isDark, tintColor: component.tintColor, transition: transition)
            
            return component.size
        }
    }
    
    public func makeView() -> View {
        return View()
    }
    
    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}

public final class GlassBackgroundView2: UIView {
    public protocol ContentView: UIView {
        var tintMask: UIView { get }
    }

    public enum Shape: Equatable {
        case roundedRect(cornerRadius: CGFloat)
    }

    private final class ClippingShapeContext {
        let view: UIView

        private(set) var shape: Shape?

        init(view: UIView) {
            self.view = view
        }

        func update(shape: Shape, size: CGSize, transition: ComponentTransition) {
            self.shape = shape

            switch shape {
            case let .roundedRect(cornerRadius):
                transition.setCornerRadius(layer: self.view.layer, cornerRadius: cornerRadius)
            }
        }
    }

    public struct Params: Equatable {
        public let shape: Shape
        public let isDark: Bool
        public let tintColor: GlassBackgroundView.TintColor
        public let isInteractive: Bool
        public let sampleView: UIView

        init(shape: Shape, isDark: Bool, tintColor: GlassBackgroundView.TintColor, isInteractive: Bool, sampleView: UIView) {
            self.shape = shape
            self.isDark = isDark
            self.tintColor = tintColor
            self.isInteractive = isInteractive
            self.sampleView = sampleView
        }

        public static func == (lhs: Params, rhs: Params) -> Bool {
            if lhs.shape != rhs.shape {
                return false
            }
            if lhs.isDark != rhs.isDark {
                return false
            }
            if lhs.tintColor != rhs.tintColor {
                return false
            }
            if lhs.isInteractive != rhs.isInteractive {
                return false
            }
            if lhs.sampleView !== rhs.sampleView {
                return false
            }
            return true
        }
    }

    public private(set) var params: Params?
    private weak var pendingSampleView: UIView?
    private var pendingSize: CGSize?
    private var pendingOrigin: CGPoint?
    private var pendingCornerRadius: CGFloat?
    private weak var lastSampleView: UIView?
    private var lastSampleOrigin: CGPoint?
    private var lastSampleSize: CGSize?
    private var lastSampleViewBounds: CGSize?
    private var lastSampleViewCornerRadius: CGFloat?
    private var glassPortalLayers: [CALayer] = []
    private var glassMaskLayer: CALayer?
    private var blurView: BlurView?
    private var blurMaskLayer: CAShapeLayer?
    private let portalContainerLayer = CALayer()

    private let nativeView: UIVisualEffectView?
    private let nativeViewClippingContext: ClippingShapeContext?
    private let nativeParamsView: EffectSettingsContainerView?

    private let maskContainerView: UIView
    public let maskContentView: UIView
    private let contentContainer: ContentContainer

    public var contentView: UIView {
        if let nativeView = self.nativeView {
            return nativeView.contentView
        } else {
            return self.contentContainer
        }
    }

    public override init(frame: CGRect) {
        if #available(iOS 26.0, *), !GlassBackgroundView.useCustomGlassImpl {
//            self.backgroundNode = nil

            let glassEffect = UIGlassEffect(style: .regular)
            glassEffect.isInteractive = false
            let nativeView = UIVisualEffectView(effect: glassEffect)
            self.nativeViewClippingContext = ClippingShapeContext(view: nativeView)
            self.nativeView = nativeView

            let nativeParamsView = EffectSettingsContainerView(frame: CGRect())
            self.nativeParamsView = nativeParamsView

            nativeParamsView.addSubview(nativeView)

            self.blurView = nil
//            self.foregroundView = nil
//            self.shadowView = nil
        } else {
            self.nativeView = nil
            self.nativeViewClippingContext = nil
            self.nativeParamsView = nil
        }

        self.maskContainerView = UIView()
        self.maskContainerView.backgroundColor = .white
        if let filter = CALayer.luminanceToAlpha() {
            self.maskContainerView.layer.filters = [filter]
        }

        self.maskContentView = UIView()
        self.maskContainerView.addSubview(self.maskContentView)

        self.contentContainer = ContentContainer(maskContentView: self.maskContentView)

        super.init(frame: frame)

//        if let shadowView = self.shadowView {
//            self.addSubview(shadowView)
//        }
        if let nativeParamsView = self.nativeParamsView {
            self.addSubview(nativeParamsView)
        }
//        if let backgroundNode = self.backgroundNode {
//            self.addSubview(backgroundNode.view)
//        }
//        if let foregroundView = self.foregroundView {
//            self.addSubview(foregroundView)
//            foregroundView.mask = self.maskContainerView
//        }
        self.addSubview(self.contentContainer)
        self.portalContainerLayer.frame = self.bounds
        self.layer.insertSublayer(self.portalContainerLayer, below: self.contentContainer.layer)

        if self.nativeView == nil {
            self.blurView = BlurView(maxBlurRadius: 17)
            self.contentContainer.insertSubview(blurView!, at: 0)
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()

        guard self.window != nil else {
            return
        }
        self.tryCreatePendingGlassElement()
    }

    private func tryCreatePendingGlassElement() {
        guard let sampleView = self.pendingSampleView, let size = self.pendingSize, let radius = self.pendingCornerRadius else {
            return
        }
        guard sampleView.window != nil else {
            return
        }

        let origin = self.pendingOrigin ?? self.sampleOrigin(in: sampleView, usePresentation: false)
        createGlassElement(
            sampleFrom: sampleView,
            installIn: self,
            originX: origin.x,
            originY: origin.y,
            height: size.height,
            width: size.width,
            cornerRadius: radius,
            outerLayerThickness: 2,
            innerLayerThickness: 2
        )
        self.lastSampleView = sampleView
        self.lastSampleOrigin = origin
        self.lastSampleSize = size
        self.lastSampleViewBounds = sampleView.bounds.size
        self.lastSampleViewCornerRadius = radius
        self.pendingSampleView = nil
        self.pendingSize = nil
        self.pendingOrigin = nil
        self.pendingCornerRadius = nil
    }

    private func sampleOrigin(in sampleView: UIView, usePresentation: Bool) -> CGPoint {
        let sourceLayer = usePresentation ? (self.layer.presentation() ?? self.layer) : self.layer
        let targetLayer = usePresentation ? (sampleView.layer.presentation() ?? sampleView.layer) : sampleView.layer
        return sourceLayer.convert(CGPoint(), to: targetLayer)
    }

    private func resetGlassLayers(in container: UIView) {
        for layer in self.glassPortalLayers {
            layer.removeFromSuperlayer()
        }
        self.glassPortalLayers.removeAll()
        if self.portalContainerLayer.mask === self.glassMaskLayer {
            self.portalContainerLayer.mask = nil
        }
        self.glassMaskLayer = nil
//        self.blurView?.removeFromSuperview()
    }

    public func update(size: CGSize, sampleFrom sampleView: UIView, originX: CGFloat, originY: CGFloat, cornerRadius: CGFloat, isDark: Bool, tintColor: GlassBackgroundView.TintColor, isInteractive: Bool = false, transition: ComponentTransition) {
        self.update(size: size, sampleFrom: sampleView, originX: originX, originY: originY, shape: .roundedRect(cornerRadius: cornerRadius), isDark: isDark, tintColor: tintColor, isInteractive: isInteractive, transition: transition)
    }

//    public func update(size: CGSize, sampleFrom sampleView: UIView, cornerRadius: CGFloat, isDark: Bool, tintColor: GlassBackgroundView.TintColor, isInteractive: Bool = false, transition: ComponentTransition) {
//        self.update(size: size, sampleFrom: sampleView, shape: .roundedRect(cornerRadius: cornerRadius), isDark: isDark, tintColor: tintColor, isInteractive: isInteractive, transition: transition)
//    }

    public func update(size: CGSize, sampleFrom sampleView: UIView, originX: CGFloat, originY: CGFloat, shape: Shape, isDark: Bool, tintColor: GlassBackgroundView.TintColor, isInteractive: Bool = false, transition: ComponentTransition) {
        if self.pendingSampleView != nil {
            self.tryCreatePendingGlassElement()
        }

        if self.portalContainerLayer.bounds.size != size {
            self.portalContainerLayer.frame = CGRect(origin: CGPoint(), size: size)
        }

        if let nativeView = self.nativeView, let nativeViewClippingContext = self.nativeViewClippingContext, (nativeView.bounds.size != size || nativeViewClippingContext.shape != shape) {

            nativeViewClippingContext.update(shape: shape, size: size, transition: transition)
            if transition.animation.isImmediate {
                nativeView.frame = CGRect(origin: CGPoint(), size: size)
            } else {
                let nativeFrame = CGRect(origin: CGPoint(), size: size)
                transition.setFrame(view: nativeView, frame: nativeFrame)
            }
        }
        let outerCornerRadius: CGFloat
        switch shape {
        case let .roundedRect(cornerRadius):
            outerCornerRadius = cornerRadius
        }

        if let blurView = self.blurView {
            blurView.frame = CGRect(origin: CGPoint(), size: size)
            let maskLayer = self.blurMaskLayer ?? CAShapeLayer()
            maskLayer.frame = CGRect(origin: CGPoint(), size: size)
            maskLayer.path = UIBezierPath(roundedRect: CGRect(origin: CGPoint(), size: size), cornerRadius: outerCornerRadius).cgPath
            blurView.layer.mask = maskLayer
            self.blurMaskLayer = maskLayer
        }

        let params = Params(shape: shape, isDark: isDark, tintColor: tintColor, isInteractive: isInteractive, sampleView: sampleView)
        let sampleOrigin = CGPoint(x: originX, y: originY)
        let sampleViewBounds = sampleView.bounds.size
        let needsRecreate = self.lastSampleView !== sampleView
        || self.lastSampleOrigin != sampleOrigin
        || self.lastSampleSize != size
        || self.lastSampleViewBounds != sampleViewBounds
        || self.lastSampleViewCornerRadius != outerCornerRadius

        if self.params != params || needsRecreate {
            self.params = params

            if let nativeParamsView = self.nativeParamsView, let nativeView = self.nativeView {
                if #available(iOS 26.0, *) {
                    let glassEffect = UIGlassEffect(style: .regular)
                    switch tintColor.kind {
                    case .panel:
                        glassEffect.tintColor = nil
                    case .custom:
                        glassEffect.tintColor = tintColor.color
                    }
                    glassEffect.isInteractive = params.isInteractive

                    if transition.animation.isImmediate {
                        nativeView.effect = glassEffect
                    } else {
                        UIView.animate(withDuration: 0.2, animations: {
                            nativeView.effect = glassEffect
                        })
                    }

                    if isDark {
                        nativeParamsView.lumaMin = 0.0
                        nativeParamsView.lumaMax = 0.15
                    } else {
                        nativeParamsView.lumaMin = 0.25
                        nativeParamsView.lumaMax = 1.0
                    }
                }
            } else {
                if self.window == nil || sampleView.window == nil {
                    self.pendingSampleView = sampleView
                    self.pendingSize = size
                    self.pendingOrigin = sampleOrigin
                    self.pendingCornerRadius = outerCornerRadius
                } else {
                    createGlassElement(
                        sampleFrom: sampleView,
                        installIn: self,
                        originX: originX,
                        originY: originY,
                        height: size.height,
                        width: size.width,
                        cornerRadius: outerCornerRadius,
                        outerLayerThickness: 2,
                        innerLayerThickness: 2
                    )
                    self.lastSampleView = sampleView
                    self.lastSampleOrigin = sampleOrigin
                    self.lastSampleSize = size
                    self.lastSampleViewBounds = sampleViewBounds
                    self.lastSampleViewCornerRadius = outerCornerRadius
                }
            }
        }

//        let shadowInset: CGFloat = 32.0
//        transition.setFrame(view: self.maskContainerView, frame: CGRect(origin: CGPoint(), size: CGSize(width: size.width + shadowInset * 2.0, height: size.height + shadowInset * 2.0)))
//        transition.setFrame(view: self.maskContentView, frame: CGRect(origin: CGPoint(x: shadowInset, y: shadowInset), size: size))

//        if let foregroundView = self.foregroundView {
//            transition.setFrame(view: foregroundView, frame: CGRect(origin: CGPoint(), size: size).insetBy(dx: -shadowInset, dy: -shadowInset))
//        }
//        if let shadowView = self.shadowView {
//            transition.setFrame(view: shadowView, frame: CGRect(origin: CGPoint(), size: size).insetBy(dx: -shadowInset, dy: -shadowInset))
//        }
        transition.setFrame(view: self.contentContainer, frame: CGRect(origin: CGPoint(), size: size))

        if let blurView {
            transition.setFrame(view: blurView, frame: CGRect(origin: CGPoint(), size: size))
        }
    }

//    public func update(size: CGSize, sampleFrom sampleView: UIView, shape: Shape, isDark: Bool, tintColor: GlassBackgroundView.TintColor, isInteractive: Bool = false, transition: ComponentTransition) {
//        let usePresentation = transition.animation.isImmediate
//        let origin = self.sampleOrigin(in: sampleView, usePresentation: usePresentation)
//        self.update(size: size, sampleFrom: sampleView, originX: origin.x, originY: origin.y, shape: shape, isDark: isDark, tintColor: tintColor, isInteractive: isInteractive, transition: transition)
//    }

    private func createGlassElement(
        sampleFrom view: UIView,
        installIn container: UIView,
        originX: CGFloat,
        originY: CGFloat,
        height elementHeight: CGFloat,
        width elementWidth: CGFloat,
        cornerRadius: CGFloat,
        outerLayerThickness: CGFloat,
        innerLayerThickness: CGFloat
    ) {
        guard let portalClass = NSClassFromString("CAPortalLayer") as? CALayer.Type else { return }
        self.resetGlassLayers(in: container)

        // MARK: outer portal border

        let bottomOffset: CGFloat = view.bounds.height - originY - elementHeight

        let outerPortalLayer = portalClass.init()
        outerPortalLayer.setValue(view.layer, forKey: "sourceLayer")

        outerPortalLayer.bounds = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        outerPortalLayer.position = .init(x: view.bounds.width * 0.5, y: view.bounds.height * 0.5)
        outerPortalLayer.transform = CATransform3DMakeScale(1, -1, 1)
        outerPortalLayer.opacity = 1

        let maskLayer = CAShapeLayer()
//        maskLayer.frame = portalLayer.bounds

        let maskPath = UIBezierPath(
            roundedRect: .init(
                x: originX,
                y: originY,
                width: elementWidth,
                height: elementHeight
            ),
            cornerRadius: cornerRadius
        )
        let frameWidth: CGFloat = outerLayerThickness
        let innerPath = UIBezierPath(
            roundedRect: .init(
                x: originX + frameWidth,
                y: originY + frameWidth,
                width: elementWidth - frameWidth * 2,
                height: elementHeight - frameWidth * 2
            ),
            cornerRadius: max(0.0, cornerRadius - frameWidth)//(elementHeight - frameWidth * 2) * 0.5
        )
        maskPath.append(innerPath)
        maskPath.usesEvenOddFillRule = true
        maskLayer.path = maskPath.cgPath
        maskLayer.fillRule = .evenOdd
        outerPortalLayer.mask = maskLayer
        outerPortalLayer.frame.origin.y = outerPortalLayer.frame.origin.y + (view.bounds.height - 2 * bottomOffset - elementHeight)

        self.portalContainerLayer.addSublayer(outerPortalLayer)
        self.glassPortalLayers.append(outerPortalLayer)
        outerPortalLayer.frame.origin.x = outerPortalLayer.frame.origin.x - originX
        outerPortalLayer.frame.origin.y = outerPortalLayer.frame.origin.y - originY
//        container.layer.borderColor = UIColor.black.cgColor
//        container.layer.borderWidth = 2


        // MARK: internal left portal

        // place inside container to apply pill mask
        let leftPillContainer = CALayer()
        leftPillContainer.frame = container.bounds
        self.portalContainerLayer.addSublayer(leftPillContainer)
        self.glassPortalLayers.append(leftPillContainer)
//        container.layer.insertSublayer(leftPillContainer, below: portalLayer)

        let leftPillMaskLayer = CAShapeLayer()
        leftPillMaskLayer.frame = leftPillContainer.bounds
        let leftPillMaskPath = UIBezierPath(
            roundedRect: leftPillContainer.bounds.insetBy(dx: outerLayerThickness, dy: outerLayerThickness),
            cornerRadius: max(0.0, cornerRadius - outerLayerThickness) //leftPillContainer.bounds.insetBy(dx: outerLayerThickness, dy: outerLayerThickness).height * 0.5
        )
        let leftInnerPillMaskPath = UIBezierPath(
            roundedRect: leftPillContainer.bounds.insetBy(dx: outerLayerThickness + innerLayerThickness, dy: outerLayerThickness + innerLayerThickness),
            cornerRadius: max(0.0, cornerRadius - (outerLayerThickness + innerLayerThickness)) //leftPillContainer.bounds.insetBy(dx: outerLayerThickness + innerLayerThickness, dy: outerLayerThickness + innerLayerThickness).height * 0.5
        )
        leftPillMaskPath.append(leftInnerPillMaskPath)
        leftPillMaskPath.usesEvenOddFillRule = true
        leftPillMaskLayer.path = leftPillMaskPath.cgPath
        leftPillMaskLayer.fillRule = .evenOdd
        leftPillContainer.mask = leftPillMaskLayer

        let cornerDiameter = min(elementHeight, cornerRadius * 2.0)
        let cornerWidth = cornerDiameter * 0.5

        // pieces

        let internalLeftPortalHeight: CGFloat = elementHeight
        let internalLeftPortalWidth: CGFloat = cornerWidth
        let internalLeftRegularRefractionOriginX = originX + internalLeftPortalWidth * 0.5

        // regular reflection

        let leftPortalRegularPieceLayer = portalClass.init()
        leftPortalRegularPieceLayer.setValue(view.layer, forKey: "sourceLayer")
        leftPortalRegularPieceLayer.bounds = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        leftPortalRegularPieceLayer.position = .init(x: view.bounds.width * 0.5, y: view.bounds.height * 0.5)
        leftPortalRegularPieceLayer.opacity = 1

        let leftPortalRegularPieceMaskLayer = CAShapeLayer()
        let leftPortalRegularPieceMaskPath = UIBezierPath(
            rect: .init(
                x: originX + internalLeftRegularRefractionOriginX,
                y: originY,
                width: internalLeftPortalWidth,
                height: internalLeftPortalHeight
            )
        )
        leftPortalRegularPieceMaskLayer.path = leftPortalRegularPieceMaskPath.cgPath
        leftPortalRegularPieceLayer.mask = leftPortalRegularPieceMaskLayer

        // place in container + align
//        leftPillContainer.addSublayer(leftPortalRegularPieceLayer)
        leftPortalRegularPieceLayer.frame.origin.x = leftPortalRegularPieceLayer.frame.origin.x - originX - internalLeftRegularRefractionOriginX // `- internalLeftPortalWidth * 0.5` – place at leftmost semicircle
        leftPortalRegularPieceLayer.frame.origin.y = leftPortalRegularPieceLayer.frame.origin.y - originY

        // upside down reflection

        let leftPortalUpsideDownPieceLayer = portalClass.init()
        leftPortalUpsideDownPieceLayer.setValue(view.layer, forKey: "sourceLayer")
        leftPortalUpsideDownPieceLayer.bounds = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        leftPortalUpsideDownPieceLayer.position = .init(x: view.bounds.width * 0.5, y: view.bounds.height * 0.5)
        leftPortalUpsideDownPieceLayer.transform = CATransform3DMakeScale(1, -1, 1)
        leftPortalUpsideDownPieceLayer.opacity = 1

        let leftPortalUpsideDownPieceMaskLayer = CAShapeLayer()
        let leftPortalUpsideDownPieceMaskPath = UIBezierPath(
            rect: .init(
                x: originX + internalLeftPortalWidth,
                y: view.bounds.height - (bottomOffset + elementHeight),
                width: internalLeftPortalWidth,
                height: internalLeftPortalHeight
            )
        )
        leftPortalUpsideDownPieceMaskLayer.path = leftPortalUpsideDownPieceMaskPath.cgPath
        leftPortalUpsideDownPieceLayer.mask = leftPortalUpsideDownPieceMaskLayer
        leftPortalUpsideDownPieceLayer.frame.origin.y = leftPortalUpsideDownPieceLayer.frame.origin.y + (view.bounds.height - 2 * bottomOffset - internalLeftPortalHeight)

        // place in container + align
        leftPillContainer.addSublayer(leftPortalUpsideDownPieceLayer)
        leftPortalUpsideDownPieceLayer.frame.origin.x = leftPortalUpsideDownPieceLayer.frame.origin.x - originX - internalLeftPortalWidth // `- internalLeftPortalWidth` – place at leftmost semicircle
        leftPortalUpsideDownPieceLayer.frame.origin.y = leftPortalUpsideDownPieceLayer.frame.origin.y - (view.bounds.height - 2 * bottomOffset - internalLeftPortalHeight) - bottomOffset


        // MARK: internal right portal

        // place inside container to apply pill mask
        let rightPillContainer = CALayer()
        rightPillContainer.frame = container.bounds
        self.portalContainerLayer.addSublayer(rightPillContainer)
        self.glassPortalLayers.append(rightPillContainer)
//        container.layer.insertSublayer(rightPillContainer, below: portalLayer)

        let rightPillMaskLayer = CAShapeLayer()
        rightPillMaskLayer.frame = rightPillContainer.bounds
        let rightPillMaskPath = UIBezierPath(
            roundedRect: rightPillContainer.bounds.insetBy(dx: outerLayerThickness, dy: outerLayerThickness),
            cornerRadius: max(0.0, cornerRadius - outerLayerThickness) //rightPillContainer.bounds.insetBy(dx: outerLayerThickness, dy: outerLayerThickness).height * 0.5
        )
        let rightInnerPillMaskPath = UIBezierPath(
            roundedRect: rightPillContainer.bounds.insetBy(dx: outerLayerThickness + innerLayerThickness, dy: outerLayerThickness + innerLayerThickness),
            cornerRadius: max(0.0, cornerRadius - (outerLayerThickness + innerLayerThickness)) //rightPillContainer.bounds.insetBy(dx: outerLayerThickness + innerLayerThickness, dy: outerLayerThickness + innerLayerThickness).height * 0.5
        )
        rightPillMaskPath.append(rightInnerPillMaskPath)
        rightPillMaskPath.usesEvenOddFillRule = true
        rightPillMaskLayer.path = rightPillMaskPath.cgPath
        rightPillMaskLayer.fillRule = .evenOdd
        rightPillContainer.mask = rightPillMaskLayer

        // pieces

        let internalRightPortalHeight: CGFloat = elementHeight
        let internalRightPortalWidth: CGFloat = cornerWidth

        // regular reflection

        let rightPortalRegularPieceLayer = portalClass.init()
        rightPortalRegularPieceLayer.setValue(view.layer, forKey: "sourceLayer")
        rightPortalRegularPieceLayer.bounds = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        rightPortalRegularPieceLayer.position = .init(x: view.bounds.width * 0.5, y: view.bounds.height * 0.5)
        rightPortalRegularPieceLayer.opacity = 1

        let rightPortalRegularPieceMaskLayer = CAShapeLayer()
        let rightPortalRegularPieceMaskPath = UIBezierPath(
            rect: .init(
                x: originX + elementWidth - 2 * internalRightPortalWidth * 0.5,
                y: originY,
                width: internalRightPortalWidth,
                height: internalRightPortalHeight
            )
        )
        rightPortalRegularPieceMaskLayer.path = rightPortalRegularPieceMaskPath.cgPath
        rightPortalRegularPieceLayer.mask = rightPortalRegularPieceMaskLayer

        // place in container + align
//        rightPillContainer.addSublayer(rightPortalRegularPieceLayer)
        rightPortalRegularPieceLayer.frame.origin.x = rightPortalRegularPieceLayer.frame.origin.x - originX + internalRightPortalWidth * 0.5 // `+ internalRightPortalWidth * 0.5` – place at leftmost semicircle
        rightPortalRegularPieceLayer.frame.origin.y = rightPortalRegularPieceLayer.frame.origin.y - originY

        // upside down reflection

        let rightPortalUpsideDownPieceLayer = portalClass.init()
        rightPortalUpsideDownPieceLayer.setValue(view.layer, forKey: "sourceLayer")
        rightPortalUpsideDownPieceLayer.bounds = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        rightPortalUpsideDownPieceLayer.position = .init(x: view.bounds.width * 0.5, y: view.bounds.height * 0.5)
        rightPortalUpsideDownPieceLayer.transform = CATransform3DMakeScale(1, -1, 1)
        rightPortalUpsideDownPieceLayer.opacity = 1

        let rightPortalUpsideDownPieceMaskLayer = CAShapeLayer()
        let rightPortalUpsideDownPieceMaskPath = UIBezierPath(
            rect: .init(
                x: originX + elementWidth - internalRightPortalWidth * 2,
                y: view.bounds.height - (bottomOffset + elementHeight),
                width: internalRightPortalWidth,
                height: internalRightPortalHeight
            )
        )
        rightPortalUpsideDownPieceMaskLayer.path = rightPortalUpsideDownPieceMaskPath.cgPath
        rightPortalUpsideDownPieceLayer.mask = rightPortalUpsideDownPieceMaskLayer
        rightPortalUpsideDownPieceLayer.frame.origin.y = rightPortalUpsideDownPieceLayer.frame.origin.y + (view.bounds.height - 2 * bottomOffset - internalRightPortalHeight)

        // place in container + align
        rightPillContainer.addSublayer(rightPortalUpsideDownPieceLayer)
        rightPortalUpsideDownPieceLayer.frame.origin.x = rightPortalUpsideDownPieceLayer.frame.origin.x - originX + internalRightPortalWidth // `+ internalRightPortalWidth` – place at rightmost semicircle
        rightPortalUpsideDownPieceLayer.frame.origin.y = rightPortalUpsideDownPieceLayer.frame.origin.y - (view.bounds.height - 2 * bottomOffset - internalRightPortalHeight) - bottomOffset


        // MARK: internal top portal

        let topPieceLayer = portalClass.init()
        topPieceLayer.setValue(view.layer, forKey: "sourceLayer")
        topPieceLayer.bounds = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        topPieceLayer.position = .init(x: view.bounds.width * 0.5, y: view.bounds.height * 0.5)
        topPieceLayer.transform = CATransform3DMakeScale(1, -1, 1)
        topPieceLayer.opacity = 1

        let topPieceHeight: CGFloat = 8//min(pillHeight * 0.125, 6)
        let topPieceWidth = elementWidth - cornerWidth
        let topPiecePadding = topPieceHeight + frameWidth * 1.5

        let topPieceMaskLayer = CAShapeLayer()
        let topPieceMaskPath = UIBezierPath(
            rect: .init(
                x: originX + cornerWidth * 0.5,
                y: originY + topPiecePadding + topPieceHeight,//originY + (pillHeight - topPieceHeight - topPieceHeight),
                width: topPieceWidth,
                height: topPieceHeight
            )
        )
        topPieceMaskLayer.path = topPieceMaskPath.cgPath
        topPieceLayer.mask = topPieceMaskLayer
//        topPieceLayer.frame.origin.y = topPieceLayer.frame.origin.y + (view.bounds.height - 2 * bottomOffset - 2 * pillHeight) + (pillHeight - topPieceHeight) /*+ topPieceHeight*/

        topPieceLayer.frame.origin.y = topPieceLayer.frame.origin.y + (view.bounds.height - 2 * elementHeight - 2 * bottomOffset) + (2 * topPiecePadding + topPieceHeight)
//        topPieceLayer.frame.origin.y = topPieceLayer.frame.origin.y +
//        leftPortalUpsideDownPieceLayer.frame.origin.y = leftPortalUpsideDownPieceLayer.frame.origin.y + (view.bounds.height - 2 * bottomOffset - internalLeftPortalHeight)

//        topPieceLayer.borderWidth = 2; topPieceLayer.borderColor = UIColor.red.cgColor; topPieceLayer.backgroundColor =
//            UIColor.red.withAlphaComponent(0.1).cgColor
//        view.layer.addSublayer(topPieceLayer)

        // place in container + align
//        container.layer.addSublayer(topPieceLayer)
//        self.glassPortalLayers.append(topPieceLayer)

//        leftPortalUpsideDownPieceLayer.frame.origin.x = leftPortalUpsideDownPieceLayer.frame.origin.x - originX - internalLeftPortalWidth // `- internalLeftPortalWidth` – place at leftmost semicircle
//        leftPortalUpsideDownPieceLayer.frame.origin.y = leftPortalUpsideDownPieceLayer.frame.origin.y - (view.bounds.height - 2 * bottomOffset - internalLeftPortalHeight) - bottomOffset

        topPieceLayer.frame.origin.x = topPieceLayer.frame.origin.x - originX
//        topPieceLayer.frame.origin.y = topPieceLayer.frame.origin.y - (bottomOffset + (pillHeight - topPieceHeight - topPieceHeight))
        topPieceLayer.frame.origin.y = topPieceLayer.frame.origin.y - (bottomOffset + topPiecePadding) + 40 // WRONG

//        print(topPieceLayer.frame)


        // MARK: add blur

//        if let blurView = self.blurView, blurView.superview == nil {
//            container.addSubview(blurView)
//            blurView.frame = container.bounds
//        }

        let containerMaskLayer = CAShapeLayer()
        containerMaskLayer.frame = container.bounds
        containerMaskLayer.path = UIBezierPath(roundedRect: container.bounds, cornerRadius: cornerRadius).cgPath
        self.portalContainerLayer.mask = containerMaskLayer
        self.glassMaskLayer = containerMaskLayer

//        let innerShadowLayer = CAShapeLayer()
//        innerShadowLayer.frame = container.bounds
//
//        innerShadowLayer.shadowColor = UIColor.black.cgColor
//        innerShadowLayer.shadowOffset = CGSize(width: 0, height: 0)
//        innerShadowLayer.shadowOpacity = 0.3
//        innerShadowLayer.shadowRadius = 2
//        innerShadowLayer.fillRule = .evenOdd
//
//        let shadowPath = CGMutablePath()
//        shadowPath.addPath(UIBezierPath(roundedRect: container.bounds.insetBy(dx: -6, dy: -6), cornerRadius: (container.bounds.height - 12) * 0.5).cgPath)
//        shadowPath.addPath(UIBezierPath(roundedRect: container.bounds, cornerRadius: container.bounds.height * 0.5).cgPath)
//        innerShadowLayer.path = shadowPath
//
//        let shadowMaskLayer = CAShapeLayer()
//        let topHalfRect = CGRect(x: 0, y: 0, width: container.bounds.width, height: container.bounds.height * 0.5)
//        shadowMaskLayer.path = UIBezierPath(rect: topHalfRect).cgPath
//        innerShadowLayer.mask = shadowMaskLayer
//
//        container.layer.addSublayer(innerShadowLayer)
    }

}

private final class BlurView: UIVisualEffectView {
    private let maxBlurRadius: CGFloat

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height * 0.5
        resetEffect()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *),
           traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            resetEffect()
            if self.subviews.indices.contains(1) {
                let tintOverlayView = subviews[1]
                tintOverlayView.alpha = 0
            }
        }
    }

    init(maxBlurRadius: CGFloat = 20) {
        self.maxBlurRadius = maxBlurRadius
        super.init(effect: UIBlurEffect(style: .light))
//        clipsToBounds = true
//        layer.cornerRadius = bounds.height * 0.5
        resetEffect()
        if self.subviews.indices.contains(1) {
            let tintOverlayView = subviews[1]
            tintOverlayView.alpha = 0
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func resetEffect() {
        let filterClassStringEncoded = "Q0FGaWx0ZXI="
        let filterClassString: String = {
            if let data = Data(base64Encoded: filterClassStringEncoded),
               let string = String(data: data, encoding: .utf8) {
                return string
            }
            return ""
        }()
        let filterWithTypeStringEncoded = "ZmlsdGVyV2l0aFR5cGU6"
        let filterWithTypeString: String = {
            if let data = Data(base64Encoded: filterWithTypeStringEncoded),
               let string = String(data: data, encoding: .utf8) {
                return string
            }
            return ""
        }()

        let filterWithTypeSelector = Selector(filterWithTypeString)

        guard let filterClass = NSClassFromString(filterClassString) as AnyObject as? NSObjectProtocol,
              filterClass.responds(to: filterWithTypeSelector) else {
            return
        }

        let result = filterClass.perform(filterWithTypeSelector, with: "variableBlur")
        guard let variableBlur = result?.takeUnretainedValue() as? NSObject else {
            return
        }

        variableBlur.setValue(maxBlurRadius, forKey: "inputRadius")
        variableBlur.setValue(true, forKey: "inputNormalizeEdges")

        if let maskImage = makeUniformMask(size: CGSize(width: 64, height: 64)) {
            variableBlur.setValue(maskImage, forKey: "inputMaskImage")
        }

        if let backdropLayer = subviews.first?.layer {
            backdropLayer.filters = [variableBlur]
            backdropLayer.setValue(UIScreen.main.scale, forKey: "scale")
        }
    }

    private func makeUniformMask(size: CGSize) -> CGImage? {
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat)
        let image = renderer.image { context in
            let cgContext = context.cgContext

            cgContext.saveGState()
            cgContext.setFillColor(UIColor.white.withAlphaComponent(0.1).cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))

//            cgContext.translateBy(x: size.width * 0.5, y: size.height * 0.5)
//            cgContext.scaleBy(x: size.width * 0.5, y: size.height * 0.5)
//            cgContext.clear(CGRect(origin: .zero, size: size))
//
//            let colors = [
//                UIColor.white.withAlphaComponent(0).cgColor,
//                UIColor.white.withAlphaComponent(0.3).cgColor,
////                UIColor.white.withAlphaComponent(0).cgColor,
////                UIColor.white.withAlphaComponent(0).cgColor,
////                UIColor.white.withAlphaComponent(0.1).cgColor,
////                UIColor.white.withAlphaComponent(0.2).cgColor,
////                UIColor.white.withAlphaComponent(0.3).cgColor,
////                UIColor.white.withAlphaComponent(0.4).cgColor,
//            ] as CFArray
//            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, /*0.25, 0.5, 0.65, 0.75, 0.85, 0.95,*/ 1]) else {
//                return
//            }
//
//            cgContext.drawRadialGradient(gradient, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 1, options: .drawsAfterEndLocation)
            cgContext.restoreGState()
        }
        return image.cgImage
    }

//    private func makeRadialGradientMask(size: CGSize) -> CGImage? {
//        let rendererFormat = UIGraphicsImageRendererFormat()
//        rendererFormat.scale = UIScreen.main.scale
//        let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat)
//        let image = renderer.image { context in
//            let cgContext = context.cgContext
//
//            cgContext.saveGState()
//            cgContext.translateBy(x: size.width * 0.5, y: size.height * 0.5)
//            cgContext.scaleBy(x: size.width * 0.5, y: size.height * 0.5)
//            cgContext.clear(CGRect(origin: .zero, size: size))
//
//            let colors = [
//                UIColor.white.withAlphaComponent(0).cgColor,
//                UIColor.white.withAlphaComponent(0.3).cgColor,
////                UIColor.white.withAlphaComponent(0).cgColor,
////                UIColor.white.withAlphaComponent(0).cgColor,
////                UIColor.white.withAlphaComponent(0.1).cgColor,
////                UIColor.white.withAlphaComponent(0.2).cgColor,
////                UIColor.white.withAlphaComponent(0.3).cgColor,
////                UIColor.white.withAlphaComponent(0.4).cgColor,
//            ] as CFArray
//            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, /*0.25, 0.5, 0.65, 0.75, 0.85, 0.95,*/ 1]) else {
//                return
//            }
//
//            cgContext.drawRadialGradient(gradient, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 1, options: .drawsAfterEndLocation)
//            cgContext.restoreGState()
//        }
//        return image.cgImage
//    }
}
