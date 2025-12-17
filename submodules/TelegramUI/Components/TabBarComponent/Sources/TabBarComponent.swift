import Foundation
import UIKit
import Display
import TelegramPresentationData
import ComponentFlow
import ComponentDisplayAdapters
import GlassBackgroundComponent
import MultilineTextComponent
import LottieComponent
import SwiftSignalKit
import UIKitRuntimeUtils
import BundleIconComponent
import TextBadgeComponent

public final class TabBarComponent: Component {
    public final class Item: Equatable {
        public enum ActionTriggerMethod {
            case tap
            case longTap
            case pan
        }

        public let item: UITabBarItem
        public let action: (ActionTriggerMethod) -> Void
        public let contextAction: ((ContextGesture, ContextExtractedContentContainingView) -> Void)?
        
        fileprivate var id: AnyHashable {
            return AnyHashable(ObjectIdentifier(self.item))
        }
        
        public init(item: UITabBarItem, action: @escaping (ActionTriggerMethod) -> Void, contextAction: ((ContextGesture, ContextExtractedContentContainingView) -> Void)?) {
            self.item = item
            self.action = action
            self.contextAction = contextAction
        }
        
        public static func ==(lhs: Item, rhs: Item) -> Bool {
            if lhs === rhs {
                return true
            }
            if lhs.item !== rhs.item {
                return false
            }
            if (lhs.contextAction == nil) != (rhs.contextAction == nil) {
                return false
            }
            return true
        }
    }
    
    public let theme: PresentationTheme
    public let items: [Item]
    public let selectedId: AnyHashable?
    public var hoveredId: AnyHashable?
    public let isTablet: Bool
    
    public init(
        theme: PresentationTheme,
        items: [Item],
        selectedId: AnyHashable?,
        isTablet: Bool
    ) {
        self.theme = theme
        self.items = items
        self.selectedId = selectedId
        self.hoveredId = selectedId
        self.isTablet = isTablet
    }
    
    public static func ==(lhs: TabBarComponent, rhs: TabBarComponent) -> Bool {
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.items != rhs.items {
            return false
        }
        if lhs.selectedId != rhs.selectedId {
            return false
        }
        if lhs.isTablet != rhs.isTablet {
            return false
        }
        return true
    }
    
    public final class View: UIView, UITabBarDelegate, UIGestureRecognizerDelegate {
        private final class BlurredSelectionView: UIView {
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
                    clipsToBounds = true
                    layer.cornerRadius = bounds.height * 0.5
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

                    if let maskImage = makeRadialGradientMask(size: CGSize(width: 64, height: 64)) {
                        variableBlur.setValue(maskImage, forKey: "inputMaskImage")
                    }

                    if let backdropLayer = subviews.first?.layer {
                        backdropLayer.filters = [variableBlur]
                        backdropLayer.setValue(UIScreen.main.scale, forKey: "scale")
                    }
                }

                private func makeRadialGradientMask(size: CGSize) -> CGImage? {
                    let rendererFormat = UIGraphicsImageRendererFormat()
                    rendererFormat.scale = UIScreen.main.scale
                    let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat)
                    let image = renderer.image { context in
                        let cgContext = context.cgContext

                        cgContext.saveGState()
                        cgContext.translateBy(x: size.width * 0.5, y: size.height * 0.5)
                        cgContext.scaleBy(x: size.width * 0.5, y: size.height * 0.5)
                        cgContext.clear(CGRect(origin: .zero, size: size))

                        let colors = [
                            UIColor.white.withAlphaComponent(0).cgColor,
                            UIColor.white.withAlphaComponent(0).cgColor,
                            UIColor.white.withAlphaComponent(0).cgColor,
                            UIColor.white.withAlphaComponent(0).cgColor,
                            UIColor.white.withAlphaComponent(0.1).cgColor,
                            UIColor.white.withAlphaComponent(0.2).cgColor,
                            UIColor.white.withAlphaComponent(0.3).cgColor,
                            UIColor.white.withAlphaComponent(0.4).cgColor,
                        ] as CFArray
                        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.25, 0.5, 0.65, 0.75, 0.85, 0.95, 1]) else {
                            return
                        }

                        cgContext.drawRadialGradient(gradient, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 1, options: .drawsAfterEndLocation)
                        cgContext.restoreGState()
                    }
                    return image.cgImage
                }
            }

            private let blurView: BlurView
            private let rimImage: UIImageView
            private let outerShadowLayer: CAShapeLayer
            private let outerShadowMaskLayer: CAShapeLayer

            init(maxBlurRadius: CGFloat) {
                self.blurView = BlurView(maxBlurRadius: maxBlurRadius)
                self.rimImage = UIImageView()
                self.outerShadowLayer = CAShapeLayer()
                self.outerShadowMaskLayer = CAShapeLayer()
                super.init(frame: .zero)

                addSubview(self.blurView)
                addSubview(self.rimImage)

                layer.insertSublayer(outerShadowLayer, at: 0)
                outerShadowLayer.fillColor = UIColor.clear.cgColor
                outerShadowLayer.shadowColor = UIColor.black.cgColor
                outerShadowLayer.shadowOpacity = 0.12
                outerShadowLayer.shadowRadius = 20
                outerShadowLayer.shadowOffset = .zero
                outerShadowLayer.mask = outerShadowMaskLayer
            }

            required public init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }

            func removeAnimations() {
                blurView.layer.removeAllAnimations()
                rimImage.layer.removeAllAnimations()
            }

            func updateLayout(size: CGSize, transition: ComponentTransition) {
                let frame = CGRect(origin: CGPoint(), size: size)
                transition.setFrame(view: rimImage, frame: frame)

                let currentBounds = (blurView.layer.presentation() ?? blurView.layer).bounds
                let isShrinking = currentBounds.width > size.width || currentBounds.height > size.height

                blurView.alpha = isShrinking ? 0.0 : 1.0
                blurView.frame = frame

                transition.setFrame(layer: outerShadowLayer, frame: frame)
                transition.setFrame(layer: outerShadowMaskLayer, frame: frame)

                let shadowPath = UIBezierPath(roundedRect: frame, cornerRadius: frame.height * 0.5).cgPath
                let previousShadowPath = (outerShadowLayer.presentation() ?? outerShadowLayer).shadowPath
                outerShadowLayer.shadowPath = shadowPath
                outerShadowLayer.path = shadowPath

                let targetOpacity: Float = isShrinking ? 0.0 : 0.12
                let previousOpacity = (outerShadowLayer.presentation() ?? outerShadowLayer).shadowOpacity
                outerShadowLayer.shadowOpacity = targetOpacity

                let outerRect = frame.insetBy(dx: -40, dy: -40)
                let maskPath = UIBezierPath(rect: outerRect)
                maskPath.append(UIBezierPath(roundedRect: frame, cornerRadius: frame.height * 0.5))
                maskPath.usesEvenOddFillRule = true
                let previousMaskPath = (outerShadowMaskLayer.presentation() ?? outerShadowMaskLayer).path
                outerShadowMaskLayer.fillRule = .evenOdd
                outerShadowMaskLayer.path = maskPath.cgPath

                if case let .curve(duration, curve) = transition.animation {
                    if let previousShadowPath {
                        outerShadowLayer.animate(
                            from: previousShadowPath,
                            to: shadowPath,
                            keyPath: "shadowPath",
                            duration: duration,
                            delay: 0.0,
                            curve: curve,
                            removeOnCompletion: true,
                            additive: false
                        )
                    }

                    outerShadowLayer.animate(
                        from: previousOpacity as NSNumber,
                        to: targetOpacity as NSNumber,
                        keyPath: "shadowOpacity",
                        duration: duration,
                        delay: 0.0,
                        curve: curve,
                        removeOnCompletion: true,
                        additive: false
                    )

                    if let previousMaskPath {
                        outerShadowMaskLayer.animate(
                            from: previousMaskPath,
                            to: maskPath.cgPath,
                            keyPath: "path",
                            duration: duration,
                            delay: 0.0,
                            curve: curve,
                            removeOnCompletion: true,
                            additive: false
                        )
                    }
                }
            }

            func update(size: CGSize, isDark: Bool) {
                self.rimImage.image = createRimImage(size: size)
            }

            private func createRimImage(size: CGSize) -> UIImage {
                let inset: CGFloat = 1.0
                var size = size
                let innerSize = size
                size.width += inset * 2.0
                size.height += inset * 2.0

                return UIGraphicsImageRenderer(size: size).image { ctx in
                    let context = ctx.cgContext

                    context.clear(CGRect(origin: CGPoint(), size: size))

                    let addShadow: (CGContext, Bool, CGPoint, CGFloat, CGFloat, UIColor, CGBlendMode) -> Void = { context, isOuter, position, blur, spread, shadowColor, blendMode in
                        let image = UIGraphicsImageRenderer(size: size).image(actions: { ctx in
                            let context = ctx.cgContext

                            context.clear(CGRect(origin: CGPoint(), size: size))
                            let spreadRect = CGRect(origin: CGPoint(x: inset, y: inset), size: innerSize).insetBy(dx: -spread - 0.33, dy: -spread - 0.33)

                            context.setShadow(offset: CGSize(width: position.x, height: position.y), blur: blur, color: shadowColor.cgColor)
                            context.setFillColor(shadowColor.cgColor)
                            let enclosingRect = spreadRect.insetBy(dx: -10000.0, dy: -10000.0)
                            context.addPath(UIBezierPath(rect: enclosingRect).cgPath)
                            let spreadPath = UIBezierPath(roundedRect: spreadRect, cornerRadius: spreadRect.height * 0.5).cgPath
                            context.addPath(spreadPath)
                            context.fillPath(using: .evenOdd)
                        })

                        UIGraphicsPushContext(context)
                        image.draw(in: CGRect(origin: .zero, size: size), blendMode: blendMode, alpha: 1.0)
                        UIGraphicsPopContext()
                    }

                    let innerImage = UIGraphicsImageRenderer(size: size).image { ctx in
                        let context = ctx.cgContext

//                        let edgeAlpha: CGFloat = max(0.2, min(isDark ? 0.5 : 0.7, a * a * a))
                        let edgeAlpha: CGFloat = 0.4

                        // blur 3-4 for light theme

//                        addShadow(context, false, CGPoint(x: -1, y: -1), 4, 0, UIColor(white: 1.0, alpha: edgeAlpha), .plusLighter)
                        addShadow(context, false, CGPoint(x: 0, y: 0), 4, 0, UIColor(white: 1.0, alpha: edgeAlpha), .plusLighter)
                    }

                    let shapeRect = CGRect(origin: .zero, size: innerSize)
                    let shapePath = UIBezierPath(roundedRect: shapeRect, cornerRadius: shapeRect.height * 0.5).cgPath

                    context.saveGState()
                    context.addPath(shapePath)
                    context.clip()
                    innerImage.draw(in: CGRect(origin: CGPoint(), size: size))
                    context.restoreGState()

                    let shapeRect2 = CGRect(origin: CGPoint(x: inset * 2.0, y: inset * 2.0), size: innerSize)
                    let shapePath2 = UIBezierPath(roundedRect: shapeRect2, cornerRadius: shapeRect2.height * 0.5).cgPath

                    context.saveGState()
                    context.addPath(shapePath2)
                    context.clip()
                    innerImage.draw(in: CGRect(origin: .zero, size: size))
                    context.restoreGState()
                }.stretchableImage(withLeftCapWidth: Int(size.width * 0.5), topCapHeight: Int(size.height * 0.5))
            }
        }

        private let backgroundView: GlassBackgroundView
        private let collapsedSelectionView: GlassBackgroundView.ContentImageView
        private let expandedSelectionView: BlurredSelectionView

        private let selectedItemsContainerView: UIView
        private let expandedSelectionMaskView: UIView

        private let contextGestureContainerView: ContextControllerSourceView
        private let nativeTabBar: UITabBar?

        private var itemViews: [AnyHashable: ComponentView<Empty>] = [:]
        private var selectedItemViews: [AnyHashable: ComponentView<Empty>] = [:]
        
        private var itemWithActiveContextGesture: AnyHashable?
        
        private var component: TabBarComponent?
        private weak var state: EmptyComponentState?

        private var isDraggingSelector = false
        private var selectionConfirmTimer: SwiftSignalKit.Timer?

        public override init(frame: CGRect) {
            self.backgroundView = GlassBackgroundView()
            self.collapsedSelectionView = GlassBackgroundView.ContentImageView()
            self.expandedSelectionView = BlurredSelectionView(maxBlurRadius: 12)
            self.expandedSelectionView.alpha = 0

            self.selectedItemsContainerView = UIView()
            self.selectedItemsContainerView.isUserInteractionEnabled = false
            self.expandedSelectionMaskView = UIView()
            self.expandedSelectionMaskView.backgroundColor = .white
            self.expandedSelectionMaskView.isUserInteractionEnabled = false
            self.selectedItemsContainerView.mask = self.expandedSelectionMaskView

            self.contextGestureContainerView = ContextControllerSourceView()
            self.contextGestureContainerView.isGestureEnabled = true

            if #available(iOS 26.0, *) {
                let nativeTabBar = UITabBar()
                self.nativeTabBar = nativeTabBar
                
                let itemFont = Font.semibold(10.0)
                let itemColor: UIColor = .clear
                
                nativeTabBar.traitOverrides.verticalSizeClass = .compact
                nativeTabBar.traitOverrides.horizontalSizeClass = .compact
                nativeTabBar.standardAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                    .foregroundColor: itemColor,
                    .font: itemFont
                ]
                nativeTabBar.standardAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                    .foregroundColor: itemColor,
                    .font: itemFont
                ]
                nativeTabBar.standardAppearance.inlineLayoutAppearance.normal.titleTextAttributes = [
                    .foregroundColor: itemColor,
                    .font: itemFont
                ]
                nativeTabBar.standardAppearance.inlineLayoutAppearance.selected.titleTextAttributes = [
                    .foregroundColor: itemColor,
                    .font: itemFont
                ]
                nativeTabBar.standardAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [
                    .foregroundColor: itemColor,
                    .font: itemFont
                ]
                nativeTabBar.standardAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [
                    .foregroundColor: itemColor,
                    .font: itemFont
                ]
            } else {
                self.nativeTabBar = nil
            }
            
            super.init(frame: frame)
            
            if #available(iOS 17.0, *) {
                self.traitOverrides.verticalSizeClass = .compact
                self.traitOverrides.horizontalSizeClass = .compact
            }
            
            self.addSubview(self.contextGestureContainerView)
            
            if let nativeTabBar = self.nativeTabBar {
                self.contextGestureContainerView.addSubview(nativeTabBar)
                nativeTabBar.delegate = self
                /*let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.onLongPressGesture(_:)))
                longPressGesture.delegate = self
                self.addGestureRecognizer(longPressGesture)*/
            } else {
                self.contextGestureContainerView.addSubview(self.backgroundView)
                self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onTapGesture(_:))))
                self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.onPanGesture(_:))))
            }
            
            self.contextGestureContainerView.shouldBegin = { [weak self] point in
                guard let self, let component = self.component else {
                    return false
                }
                for (id, itemView) in self.itemViews {
                    if let itemView = itemView.view {
                        if self.convert(itemView.bounds, from: itemView).contains(point) {
                            guard let item = component.items.first(where: { $0.id == id }) else {
                                return false
                            }
                            if item.contextAction == nil {
                                return false
                            }
                            
                            self.itemWithActiveContextGesture = id
                            
                            let startPoint = point
                            self.contextGestureContainerView.contextGesture?.externalUpdated = { [weak self] _, point in
                                guard let self else {
                                    return
                                }
                                
                                let dist = sqrt(pow(startPoint.x - point.x, 2.0) + pow(startPoint.y - point.y, 2.0))
                                if dist > 10.0 {
                                    self.contextGestureContainerView.contextGesture?.cancel()
                                }
                            }
                            
                            return true
                        }
                    }
                }
                return false
            }
            self.contextGestureContainerView.customActivationProgress = { [weak self] _, _ in
                let _ = self
                return
                /*guard let self, let itemWithActiveContextGesture = self.itemWithActiveContextGesture else {
                    return
                }
                guard let itemView = self.itemViews[itemWithActiveContextGesture]?.view else {
                    return
                }
                let scaleSide = itemView.bounds.width
                let minScale: CGFloat = max(0.7, (scaleSide - 15.0) / scaleSide)
                let currentScale = 1.0 * (1.0 - progress) + minScale * progress

                switch update {
                case .update:
                    let sublayerTransform = CATransform3DScale(CATransform3DIdentity, currentScale, currentScale, 1.0)
                    itemView.layer.sublayerTransform = sublayerTransform
                case .begin:
                    let sublayerTransform = CATransform3DScale(CATransform3DIdentity, currentScale, currentScale, 1.0)
                    itemView.layer.sublayerTransform = sublayerTransform
                case .ended:
                    let sublayerTransform = CATransform3DScale(CATransform3DIdentity, currentScale, currentScale, 1.0)
                    let previousTransform = itemView.layer.sublayerTransform
                    itemView.layer.sublayerTransform = sublayerTransform

                    itemView.layer.animate(from: NSValue(caTransform3D: previousTransform), to: NSValue(caTransform3D: sublayerTransform), keyPath: "sublayerTransform", timingFunction: CAMediaTimingFunctionName.easeOut.rawValue, duration: 0.2)
                }*/
            }
            self.contextGestureContainerView.activated = { [weak self] gesture, _ in
                guard let self, let component = self.component else {
                    return
                }
                guard let itemWithActiveContextGesture = self.itemWithActiveContextGesture else {
                    return
                }
                
                var itemView: ItemComponent.View?
                if self.nativeTabBar != nil {
                    itemView = self.selectedItemViews[itemWithActiveContextGesture]?.view as? ItemComponent.View
                } else {
                    itemView = self.itemViews[itemWithActiveContextGesture]?.view as? ItemComponent.View
                }
                
                guard let itemView else {
                    return
                }
                
                DispatchQueue.main.async { [weak self] in
                    guard let self else {
                        return
                    }
                    if let nativeTabBar = self.nativeTabBar {
                        func cancelGestures(view: UIView) {
                            for recognizer in view.gestureRecognizers ?? [] {
                                if NSStringFromClass(type(of: recognizer)).contains("sSelectionGestureRecognizer") {
                                    recognizer.state = .cancelled
                                }
                            }
                            for subview in view.subviews {
                                cancelGestures(view: subview)
                            }
                        }
                        
                        cancelGestures(view: nativeTabBar)
                    }
                }
                
                guard let item = component.items.first(where: { $0.id == itemWithActiveContextGesture }) else {
                    return
                }
                item.contextAction?(gesture, itemView.contextContainerView)
            }
        }
        
        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        public func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
            guard let component = self.component else {
                return
            }
            if let index = tabBar.items?.firstIndex(where: { $0 === item }) {
                if index < component.items.count {
                    component.items[index].action(.tap)
                }
            }
        }
        
        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        @objc private func onLongPressGesture(_ recognizer: UILongPressGestureRecognizer) {
            if case .began = recognizer.state {
                if let nativeTabBar = self.nativeTabBar {
                    func cancelGestures(view: UIView) {
                        for recognizer in view.gestureRecognizers ?? [] {
                            if NSStringFromClass(type(of: recognizer)).contains("sSelectionGestureRecognizer") {
                                recognizer.state = .cancelled
                            }
                        }
                        for subview in view.subviews {
                            cancelGestures(view: subview)
                        }
                    }
                    
                    cancelGestures(view: nativeTabBar)
                }
            }
        }
        
        @objc private func onTapGesture(_ recognizer: UITapGestureRecognizer) {
            guard let component = self.component else {
                return
            }
            if case .ended = recognizer.state {
                let point = recognizer.location(in: self)
                var closestItemView: (AnyHashable, CGFloat)?
                for (id, itemView) in self.itemViews {
                    guard let itemView = itemView.view else {
                        continue
                    }
                    let distance = abs(point.x - itemView.center.x)
                    if let previousClosestItemView = closestItemView {
                        if previousClosestItemView.1 > distance {
                            closestItemView = (id, distance)
                        }
                    } else {
                        closestItemView = (id, distance)
                    }
                }
                
                if let (id, _) = closestItemView {
                    guard let item = component.items.first(where: { $0.id == id }) else {
                        return
                    }
                    item.action(.tap)
                    /*if previousSelectedIndex != closestNode.0 {
                     if let selectedIndex = self.selectedIndex, let _ = self.tabBarItems[selectedIndex].item.animationName {
                     container.imageNode.animationNode.play(firstFrame: false, fromIndex: nil)
                     }
                     }*/
                }
            }
        }

        private var smoothedSpeed: CGFloat = 0
        private var lastSmoothedSpeed: CGFloat = 0
        private var deformAmount: CGFloat = 0
        private let maxDeform: CGFloat = 0.3
        private let speedForMaxDeform: CGFloat = 3000
        private let smoothingFactor: CGFloat = 0.85

        private var itemSize: CGSize?
        private let heightDiff: CGFloat = 24
        private let widthDiff: CGFloat = 20

        @objc private func onPanGesture(_ recognizer: UIPanGestureRecognizer) {
            guard let component = self.component, let collapsedSize = itemSize else {
                return
            }

            let expandedSize = CGSize(width: collapsedSize.width + widthDiff, height: collapsedSize.height + heightDiff)
            let innerInset: CGFloat = 3.0
            let point = recognizer.location(in: self)

            let leftLimit = innerInset + collapsedSize.width * 0.5
            let rightLimit = bounds.width - innerInset - collapsedSize.width * 0.5
            let clampedX = max(leftLimit, min(rightLimit, point.x))

            if recognizer.state == .began {
                collapsedSelectionView.layer.removeAllAnimations()
                expandedSelectionMaskView.layer.removeAllAnimations()
                expandedSelectionView.layer.removeAllAnimations()
                expandedSelectionView.removeAnimations()

                expandedSelectionView.layer.setAffineTransform(.identity)
                expandedSelectionMaskView.layer.setAffineTransform(.identity)

                isDraggingSelector = true
                smoothedSpeed = 0
                lastSmoothedSpeed = 0

                var frame = expandedSelectionView.frame
                frame.size.width = expandedSize.width
                frame.size.height = expandedSize.height
                frame.origin.y = frame.origin.y - heightDiff * 0.5
                frame.origin.x = clampedX - expandedSize.width * 0.5

                let expandTransition = ComponentTransition.spring(duration: 0.2)
                expandTransition.setFrame(view: expandedSelectionView, frame: frame)
                expandTransition.setFrame(view: expandedSelectionMaskView, frame: frame)
                expandTransition.setFrame(view: collapsedSelectionView, frame: frame)
                expandTransition.setAlpha(view: expandedSelectionView, alpha: 1)
                expandTransition.setAlpha(view: collapsedSelectionView, alpha: 0)
                expandTransition.setCornerRadius(layer: expandedSelectionView.layer, cornerRadius: expandedSize.height * 0.5)
                expandTransition.setCornerRadius(layer: expandedSelectionMaskView.layer, cornerRadius: expandedSize.height * 0.5)
                expandedSelectionView.updateLayout(size: frame.size, transition: expandTransition)
            }

            var closestItemView: (AnyHashable, CGFloat)?
            for (id, itemView) in self.itemViews {
                guard let itemView = itemView.view else {
                    continue
                }
                let distance = abs(point.x - itemView.center.x)
                if let previousClosestItemView = closestItemView {
                    if previousClosestItemView.1 > distance {
                        closestItemView = (id, distance)
                    }
                } else {
                    closestItemView = (id, distance)
                }
            }

            var hoveredItem: Item?
            var isHoveredUpdated = false
            if let (id, _) = closestItemView {
                guard let item = component.items.first(where: { $0.id == id }) else {
                    return
                }
                if component.hoveredId != id {
                    isHoveredUpdated = true
                }
                component.hoveredId = id
                hoveredItem = item
            }

            if recognizer.state == .began && isHoveredUpdated {
                hoveredItem?.action(.pan)
            }

            if recognizer.state == .changed  && isHoveredUpdated {
                self.selectionConfirmTimer?.invalidate()
                let selectionConfirmTimer = SwiftSignalKit.Timer(timeout: 0.2, repeat: false, completion: { [weak self] in
                    if let strongSelf = self, let hoveredItem, strongSelf.component?.hoveredId == hoveredItem.id {
                        strongSelf.selectionConfirmTimer?.invalidate()
                        strongSelf.selectionConfirmTimer = nil

                        hoveredItem.action(.pan)
                    }
                }, queue: Queue.mainQueue())
                self.selectionConfirmTimer = selectionConfirmTimer
                selectionConfirmTimer.start()
            }

            if recognizer.state == .changed {
                expandedSelectionView.layer.removeAnimation(forKey: "position")
                expandedSelectionMaskView.layer.removeAnimation(forKey: "position")
                collapsedSelectionView.layer.removeAnimation(forKey: "position")

                var center = expandedSelectionView.center
                center.x = clampedX
                expandedSelectionView.center = center
                expandedSelectionMaskView.center = center
                collapsedSelectionView.center = center

                let rawSpeed = abs(recognizer.velocity(in: self).x)
                smoothedSpeed = smoothingFactor * smoothedSpeed + (1 - smoothingFactor) * rawSpeed

                let increasing = lastSmoothedSpeed == 0 || smoothedSpeed > lastSmoothedSpeed + 15

                if increasing {
                    expandedSelectionView.layer.removeAnimation(forKey: "decayTransformAnimation")
                    expandedSelectionMaskView.layer.removeAnimation(forKey: "decayTransformAnimation")

                    let baseSize = CGSize(width: expandedSize.width, height: expandedSize.height)

                    let targetDeform = min(maxDeform, smoothedSpeed / speedForMaxDeform)
                    deformAmount = targetDeform

                    let targetHeight = baseSize.height * (1 + deformAmount)
                    let targetWidth = baseSize.width / (1 + deformAmount)

                    let presentation = expandedSelectionView.layer.presentation() ?? expandedSelectionView.layer

                    let currentScaleY = presentation.value(forKeyPath: "transform.scale.y") as? CGFloat ?? 1
                    let currentScaleX = presentation.value(forKeyPath: "transform.scale.x") as? CGFloat ?? 1

                    let currentHeight = expandedSize.height * currentScaleY
                    let currentWidth = expandedSize.width * currentScaleX

                    let lerp: CGFloat = 0.2
                    let newHeight = max(expandedSize.height, currentHeight + (targetHeight - currentHeight) * lerp)
                    let newWidth = min(expandedSize.width, currentWidth + (targetWidth - currentWidth) * lerp)

                    let scaleY = newHeight / expandedSize.height
                    let scaleX = newWidth / expandedSize.width

                    expandedSelectionView.layer.setAffineTransform(CGAffineTransform(scaleX: scaleX, y: scaleY))
                    expandedSelectionMaskView.layer.setAffineTransform(CGAffineTransform(scaleX: scaleX, y: scaleY))
                } else {
                    if expandedSelectionView.layer.animation(forKey: "decayTransformAnimation") == nil {
                        let presentation = expandedSelectionView.layer.presentation() ?? expandedSelectionView.layer

                        let transformSpring = CASpringAnimation(keyPath: "transform")
                        transformSpring.fromValue = presentation.transform
                        transformSpring.toValue = CATransform3DIdentity
                        transformSpring.damping = 12
                        transformSpring.stiffness = 180
                        transformSpring.mass = 1
                        transformSpring.duration = transformSpring.settlingDuration

                        expandedSelectionView.transform = .identity
                        expandedSelectionView.layer.add(transformSpring, forKey: "decayTransformAnimation")
                        expandedSelectionMaskView.transform = .identity
                        expandedSelectionMaskView.layer.add(transformSpring, forKey: "decayTransformAnimation")
                    }
                }

                lastSmoothedSpeed = smoothedSpeed
            }

            if recognizer.state == .ended || recognizer.state == .cancelled || recognizer.state == .failed {
                guard let hoveredItem, let targetFrame = self.itemViews[hoveredItem.id]?.view?.frame else {
                    self.isDraggingSelector = false
                    return
                }

                expandedSelectionView.layer.setAffineTransform(.identity)
                expandedSelectionMaskView.layer.setAffineTransform(.identity)

                hoveredItem.action(.pan)

                let collapseTransition = ComponentTransition.spring(duration: 0.3)
                collapseTransition.setFrame(view: expandedSelectionView, frame: targetFrame)
                collapseTransition.setFrame(view: expandedSelectionMaskView, frame: targetFrame)
                collapseTransition.setFrame(view: collapsedSelectionView, frame: targetFrame)
                collapseTransition.setAlpha(view: expandedSelectionView, alpha: 0)
                collapseTransition.setAlpha(view: collapsedSelectionView, alpha: 1)
                collapseTransition.setCornerRadius(layer: expandedSelectionView.layer, cornerRadius: targetFrame.height * 0.5)
                collapseTransition.setCornerRadius(layer: expandedSelectionMaskView.layer, cornerRadius: targetFrame.height * 0.5)
                expandedSelectionView.updateLayout(size: targetFrame.size, transition: collapseTransition)

                self.isDraggingSelector = false
                self.selectionConfirmTimer?.invalidate()
                self.selectionConfirmTimer = nil
            }
        }

        override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            return super.hitTest(point, with: event)
        }
        
        public func frameForItem(at index: Int) -> CGRect? {
            guard let component = self.component else {
                return nil
            }
            if index < 0 || index >= component.items.count {
                return nil
            }
            guard let itemView = self.itemViews[component.items[index].id]?.view else {
                return nil
            }
            return self.convert(itemView.bounds, from: itemView)
        }
        
        public override func didMoveToWindow() {
            super.didMoveToWindow()
            
            self.state?.updated()
        }
        
        func update(component: TabBarComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
            let innerInset: CGFloat = 3.0
            
            let availableSize = CGSize(width: min(500.0, availableSize.width), height: availableSize.height)
            
            let previousComponent = self.component
            self.component = component
            self.state = state
            
            self.overrideUserInterfaceStyle = component.theme.overallDarkAppearance ? .dark : .light
            
            if let nativeTabBar = self.nativeTabBar {
                if previousComponent?.items.map(\.item.title) != component.items.map(\.item.title) {
                    let items: [UITabBarItem] = (0 ..< component.items.count).map { i in
                        return UITabBarItem(title: component.items[i].item.title, image: nil, tag: i)
                    }
                    nativeTabBar.items = items
                    for (_, itemView) in self.itemViews {
                        itemView.view?.removeFromSuperview()
                    }
                    for (_, selectedItemView) in self.selectedItemViews {
                        selectedItemView.view?.removeFromSuperview()
                    }
                    if let index = component.items.firstIndex(where: { $0.id == component.selectedId }) {
                        nativeTabBar.selectedItem = nativeTabBar.items?[index]
                    }
                }
                
                nativeTabBar.frame = CGRect(origin: CGPoint(), size: CGSize(width: availableSize.width, height: component.isTablet ? 74.0 : 83.0))
                nativeTabBar.layoutSubviews()
            }
            
            var nativeItemContainers: [Int: UIView] = [:]
            var nativeSelectedItemContainers: [Int: UIView] = [:]
            if let nativeTabBar = self.nativeTabBar {
                for subview in nativeTabBar.subviews {
                    if NSStringFromClass(type(of: subview)).contains("PlatterView") {
                        for subview in subview.subviews {
                            if NSStringFromClass(type(of: subview)).hasSuffix("SelectedContentView") {
                                for subview in subview.subviews {
                                    if NSStringFromClass(type(of: subview)).hasSuffix("TabButton") {
                                        nativeSelectedItemContainers[nativeSelectedItemContainers.count] = subview
                                    }
                                }
                            } else if NSStringFromClass(type(of: subview)).hasSuffix("ContentView") {
                                for subview in subview.subviews {
                                    if NSStringFromClass(type(of: subview)).hasSuffix("TabButton") {
                                        nativeItemContainers[nativeItemContainers.count] = subview
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            var itemSize = CGSize(width: floor((availableSize.width - innerInset * 2.0) / CGFloat(component.items.count)), height: 56.0)
            itemSize.width = min(94.0, itemSize.width)
            self.itemSize = itemSize

            if let itemContainer = nativeItemContainers[0] {
                itemSize = itemContainer.bounds.size
            }
            
            let contentHeight = itemSize.height + innerInset * 2.0
            var contentWidth: CGFloat = innerInset
            
            if self.collapsedSelectionView.image?.size.height != itemSize.height {
                self.collapsedSelectionView.image = generateStretchableFilledCircleImage(radius: itemSize.height * 0.5, color: .white)?.withRenderingMode(.alwaysTemplate)
            }
            self.collapsedSelectionView.tintColor = component.theme.list.itemPrimaryTextColor.withMultipliedAlpha(0.05)

            var validIds: [AnyHashable] = []
            var selectionFrame: CGRect?
            for index in 0 ..< component.items.count {
                let item = component.items[index]
                validIds.append(item.id)
                
                let itemView: ComponentView<Empty>
                var itemTransition = transition
                
                if let current = self.itemViews[item.id] {
                    itemView = current
                } else {
                    itemTransition = itemTransition.withAnimation(.none)
                    itemView = ComponentView()
                    self.itemViews[item.id] = itemView
                }
                
                let selectedItemView: ComponentView<Empty>
                if let current = self.selectedItemViews[item.id] {
                    selectedItemView = current
                } else {
                    selectedItemView = ComponentView()
                    self.selectedItemViews[item.id] = selectedItemView
                }
                
                let isItemSelected = component.selectedId == item.id
                
                let _ = itemView.update(
                    transition: itemTransition,
                    component: AnyComponent(ItemComponent(
                        item: item,
                        theme: component.theme,
                        isSelected: false
                    )),
                    environment: {},
                    containerSize: itemSize
                )
                let _ = selectedItemView.update(
                    transition: itemTransition,
                    component: AnyComponent(ItemComponent(
                        item: item,
                        theme: component.theme,
                        isSelected: true
                    )),
                    environment: {},
                    containerSize: itemSize
                )
                
                let itemFrame = CGRect(origin: CGPoint(x: contentWidth, y: floor((contentHeight - itemSize.height) * 0.5)), size: itemSize)
                if let itemComponentView = itemView.view as? ItemComponent.View, let selectedItemComponentView = selectedItemView.view as? ItemComponent.View {
                    if itemComponentView.superview == nil {
                        itemComponentView.isUserInteractionEnabled = false
                        selectedItemComponentView.isUserInteractionEnabled = false
                        
                        if self.nativeTabBar != nil {
                            if let itemContainer = nativeItemContainers[index] {
                                itemContainer.addSubview(itemComponentView)
                            }
                            if let itemContainer = nativeSelectedItemContainers[index] {
                                itemContainer.addSubview(selectedItemComponentView)
                            }
                        } else {
                            self.contextGestureContainerView.addSubview(itemComponentView)
                            self.selectedItemsContainerView.addSubview(selectedItemComponentView)
                        }
                    }
                    if self.nativeTabBar != nil {
                        if let parentView = itemComponentView.superview {
                            let itemFrame = CGRect(origin: CGPoint(x: floor((parentView.bounds.width - itemSize.width) * 0.5), y: floor((parentView.bounds.height - itemSize.height) * 0.5)), size: itemSize)
                            itemTransition.setFrame(view: itemComponentView, frame: itemFrame)
                            itemTransition.setFrame(view: selectedItemComponentView, frame: itemFrame)
                        }
                    } else {
                        itemTransition.setFrame(view: itemComponentView, frame: itemFrame)
                        itemTransition.setFrame(view: selectedItemComponentView, frame: itemFrame)
                    }
                    
                    if let previousComponent, previousComponent.selectedId != item.id, isItemSelected {
                        itemComponentView.playSelectionAnimation()
                        selectedItemComponentView.playSelectionAnimation()
                    }
                }
                if isItemSelected {
                    selectionFrame = itemFrame
                }
                
                contentWidth += itemFrame.width
            }
            contentWidth += innerInset

            var removeIds: [AnyHashable] = []
            for (id, itemView) in self.itemViews {
                if !validIds.contains(id) {
                    removeIds.append(id)
                    itemView.view?.removeFromSuperview()
                    self.selectedItemViews[id]?.view?.removeFromSuperview()
                }
            }
            for id in removeIds {
                self.itemViews.removeValue(forKey: id)
                self.selectedItemViews.removeValue(forKey: id)
            }

            if self.selectedItemsContainerView.superview == nil {
                self.contextGestureContainerView.addSubview(self.selectedItemsContainerView)
            }

            if !self.isDraggingSelector, let selectionFrame, self.nativeTabBar == nil {
                var selectionViewTransition = transition
                if self.collapsedSelectionView.superview == nil {
                    selectionViewTransition = selectionViewTransition.withAnimation(.none)
                    self.backgroundView.contentView.addSubview(self.collapsedSelectionView)
                    self.contextGestureContainerView.addSubview(self.expandedSelectionView)
                }
                selectionViewTransition.setFrame(view: self.collapsedSelectionView, frame: selectionFrame)
                selectionViewTransition.setFrame(view: self.expandedSelectionView, frame: selectionFrame)
                selectionViewTransition.setFrame(view: self.expandedSelectionMaskView, frame: selectionFrame)
                self.expandedSelectionView.updateLayout(size: selectionFrame.size, transition: selectionViewTransition)
            } else if !self.isDraggingSelector, self.collapsedSelectionView.superview != nil {
                self.collapsedSelectionView.removeFromSuperview()
                self.expandedSelectionView.removeFromSuperview()
                self.expandedSelectionMaskView.removeFromSuperview()
            }

            if let selectionFrame, self.nativeTabBar == nil {
                self.expandedSelectionView.update(size: CGSize(width: selectionFrame.width + widthDiff, height: selectionFrame.height + heightDiff), isDark: component.theme.overallDarkAppearance)
            }

            self.contextGestureContainerView.bringSubviewToFront(self.expandedSelectionView)

            let size = CGSize(width: min(availableSize.width, contentWidth), height: contentHeight)
            
            transition.setFrame(view: self.backgroundView, frame: CGRect(origin: CGPoint(), size: size))
            self.backgroundView.update(size: size, cornerRadius: size.height * 0.5, isDark: component.theme.overallDarkAppearance, tintColor: .init(kind: .panel, color: component.theme.chat.inputPanel.inputBackgroundColor.withMultipliedAlpha(0.7)), transition: transition)
            
            if self.nativeTabBar != nil {
                let finalSize = CGSize(width: availableSize.width, height: 62.0)
                transition.setFrame(view: self.contextGestureContainerView, frame: CGRect(origin: CGPoint(), size: finalSize))
                return finalSize
            } else {
                transition.setFrame(view: self.contextGestureContainerView, frame: CGRect(origin: CGPoint(), size: size))
                return size
            }
        }
    }
    
    public func makeView() -> View {
        return View(frame: CGRect())
    }
    
    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}

private final class ItemComponent: Component {
    let item: TabBarComponent.Item
    let theme: PresentationTheme
    let isSelected: Bool
    
    init(item: TabBarComponent.Item, theme: PresentationTheme, isSelected: Bool) {
        self.item = item
        self.theme = theme
        self.isSelected = isSelected
    }
    
    static func ==(lhs: ItemComponent, rhs: ItemComponent) -> Bool {
        if lhs.item != rhs.item {
            return false
        }
        if lhs.theme !== rhs.theme {
            return false
        }
        if lhs.isSelected != rhs.isSelected {
            return false
        }
        return true
    }
    
    final class View: UIView {
        let contextContainerView: ContextExtractedContentContainingView
        
        private var imageIcon: ComponentView<Empty>?
        private var animationIcon: ComponentView<Empty>?
        private let title = ComponentView<Empty>()
        private var badge: ComponentView<Empty>?
        
        private var component: ItemComponent?
        private weak var state: EmptyComponentState?
        
        private var setImageListener: Int?
        private var setSelectedImageListener: Int?
        private var setBadgeListener: Int?
        
        override init(frame: CGRect) {
            self.contextContainerView = ContextExtractedContentContainingView()
            
            super.init(frame: frame)
            
            self.addSubview(self.contextContainerView)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        deinit {
            if let component = self.component {
                if let setImageListener = self.setImageListener {
                    component.item.item.removeSetImageListener(setImageListener)
                }
                if let setSelectedImageListener = self.setSelectedImageListener {
                    component.item.item.removeSetSelectedImageListener(setSelectedImageListener)
                }
                if let setBadgeListener = self.setBadgeListener {
                    component.item.item.removeSetBadgeListener(setBadgeListener)
                }
            }
        }
        
        func playSelectionAnimation() {
            if let animationIconView = self.animationIcon?.view as? LottieComponent.View {
                animationIconView.playOnce()
            }
        }
        
        func update(component: ItemComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
            let previousComponent = self.component
            
            if previousComponent?.item.item !== component.item.item {
                if let setImageListener = self.setImageListener {
                    self.component?.item.item.removeSetImageListener(setImageListener)
                }
                if let setSelectedImageListener = self.setSelectedImageListener {
                    self.component?.item.item.removeSetSelectedImageListener(setSelectedImageListener)
                }
                if let setBadgeListener = self.setBadgeListener {
                    self.component?.item.item.removeSetBadgeListener(setBadgeListener)
                }
                self.setImageListener = component.item.item.addSetImageListener { [weak self] _ in
                    guard let self else {
                        return
                    }
                    self.state?.updated(transition: .immediate, isLocal: true)
                }
                self.setSelectedImageListener = component.item.item.addSetSelectedImageListener { [weak self] _ in
                    guard let self else {
                        return
                    }
                    self.state?.updated(transition: .immediate, isLocal: true)
                }
                self.setBadgeListener = UITabBarItem_addSetBadgeListener(component.item.item) { [weak self] _ in
                    guard let self else {
                        return
                    }
                    self.state?.updated(transition: .immediate, isLocal: true)
                }
            }
            
            self.component = component
            self.state = state
            
            if let animationName = component.item.item.animationName {
                if let imageIcon = self.imageIcon {
                    self.imageIcon = nil
                    imageIcon.view?.removeFromSuperview()
                }
                
                let animationIcon: ComponentView<Empty>
                var iconTransition = transition
                if let current = self.animationIcon {
                    animationIcon = current
                } else {
                    iconTransition = iconTransition.withAnimation(.none)
                    animationIcon = ComponentView()
                    self.animationIcon = animationIcon
                }
                
                let iconSize = animationIcon.update(
                    transition: iconTransition,
                    component: AnyComponent(LottieComponent(
                        content: LottieComponent.AppBundleContent(
                            name: animationName
                        ),
                        color: component.isSelected ? component.theme.rootController.tabBar.selectedTextColor : component.theme.rootController.tabBar.textColor,
                        placeholderColor: nil,
                        startingPosition: .end,
                        size: CGSize(width: 48.0, height: 48.0),
                        loop: false
                    )),
                    environment: {},
                    containerSize: CGSize(width: 48.0, height: 48.0)
                )
                let iconFrame = CGRect(origin: CGPoint(x: floor((availableSize.width - iconSize.width) * 0.5), y: -4.0), size: iconSize).offsetBy(dx: component.item.item.animationOffset.x, dy: component.item.item.animationOffset.y)
                if let animationIconView = animationIcon.view {
                    if animationIconView.superview == nil {
                        if let badgeView = self.badge?.view {
                            self.contextContainerView.contentView.insertSubview(animationIconView, belowSubview: badgeView)
                        } else {
                            self.contextContainerView.contentView.addSubview(animationIconView)
                        }
                    }
                    iconTransition.setFrame(view: animationIconView, frame: iconFrame)
                }
            } else {
                if let animationIcon = self.animationIcon {
                    self.animationIcon = nil
                    animationIcon.view?.removeFromSuperview()
                }
                
                let imageIcon: ComponentView<Empty>
                var iconTransition = transition
                if let current = self.imageIcon {
                    imageIcon = current
                } else {
                    iconTransition = iconTransition.withAnimation(.none)
                    imageIcon = ComponentView()
                    self.imageIcon = imageIcon
                }
                
                let iconSize = imageIcon.update(
                    transition: iconTransition,
                    component: AnyComponent(Image(
                        image: component.isSelected ? component.item.item.selectedImage : component.item.item.image,
                        tintColor: nil,
                        contentMode: .center
                    )),
                    environment: {},
                    containerSize: CGSize(width: 100.0, height: 100.0)
                )
                let iconFrame = CGRect(origin: CGPoint(x: floor((availableSize.width - iconSize.width) * 0.5), y: 3.0), size: iconSize)
                if let imageIconView = imageIcon.view {
                    if imageIconView.superview == nil {
                        if let badgeView = self.badge?.view {
                            self.contextContainerView.contentView.insertSubview(imageIconView, belowSubview: badgeView)
                        } else {
                            self.contextContainerView.contentView.addSubview(imageIconView)
                        }
                    }
                    iconTransition.setFrame(view: imageIconView, frame: iconFrame)
                }
            }
            
            let titleSize = self.title.update(
                transition: .immediate,
                component: AnyComponent(MultilineTextComponent(
                    text: .plain(NSAttributedString(string: component.item.item.title ?? " ", font: Font.semibold(10.0), textColor: component.isSelected ? component.theme.rootController.tabBar.selectedTextColor : component.theme.rootController.tabBar.textColor))
                )),
                environment: {},
                containerSize: CGSize(width: availableSize.width, height: 100.0)
            )
            let titleFrame = CGRect(origin: CGPoint(x: floor((availableSize.width - titleSize.width) * 0.5), y: availableSize.height - 8.0 - titleSize.height), size: titleSize)
            if let titleView = self.title.view {
                if titleView.superview == nil {
                    self.contextContainerView.contentView.addSubview(titleView)
                }
                titleView.frame = titleFrame
            }
            
            if let badgeText = component.item.item.badgeValue, !badgeText.isEmpty {
                let badge: ComponentView<Empty>
                var badgeTransition = transition
                if let current = self.badge {
                    badge = current
                } else {
                    badgeTransition = badgeTransition.withAnimation(.none)
                    badge = ComponentView()
                    self.badge = badge
                }
                let badgeSize = badge.update(
                    transition: badgeTransition,
                    component: AnyComponent(TextBadgeComponent(
                        text: badgeText,
                        font: Font.regular(13.0),
                        background: component.theme.rootController.tabBar.badgeBackgroundColor,
                        foreground: component.theme.rootController.tabBar.badgeTextColor,
                        insets: UIEdgeInsets(top: 0.0, left: 6.0, bottom: 1.0, right: 6.0)
                    )),
                    environment: {},
                    containerSize: CGSize(width: 100.0, height: 100.0)
                )
                let contentWidth: CGFloat = 25.0
                let badgeFrame = CGRect(origin: CGPoint(x: floor(availableSize.width / 2.0) + contentWidth - badgeSize.width - 1.0, y: 5.0), size: badgeSize)
                if let badgeView = badge.view {
                    if badgeView.superview == nil {
                        self.contextContainerView.contentView.addSubview(badgeView)
                    }
                    badgeTransition.setFrame(view: badgeView, frame: badgeFrame)
                }
            } else if let badge = self.badge {
                self.badge = nil
                badge.view?.removeFromSuperview()
            }
            
            transition.setFrame(view: self.contextContainerView, frame: CGRect(origin: CGPoint(), size: availableSize))
            transition.setFrame(view: self.contextContainerView.contentView, frame: CGRect(origin: CGPoint(), size: availableSize))
            self.contextContainerView.contentRect = CGRect(origin: CGPoint(), size: availableSize)
            
            return availableSize
        }
    }
    
    func makeView() -> View {
        return View(frame: CGRect())
    }
    
    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}
