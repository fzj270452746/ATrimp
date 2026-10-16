//
//  ATLoadingOverlay.swift
//  ATrimp
//
//
import SnapKit
import UIKit

enum ATLoadingOverlay {

    private static let tag = 9_143
    private static var workItem: DispatchWorkItem?

    static func run(duration: TimeInterval = 1.2, then completion: (() -> Void)? = nil) {
        guard let host = keyWindow else {
            completion?()
            return
        }

        workItem?.cancel()
        host.viewWithTag(tag)?.removeFromSuperview()

        let overlay = UIView()
        overlay.tag = tag
        overlay.backgroundColor = ATTheme.Palette.paper.withAlphaComponent(0.86)
        overlay.alpha = 0

        let card = UIView()
        card.backgroundColor = ATTheme.Palette.paperRaised
        card.layer.cornerRadius = ATTheme.Radius.medium
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = ATTheme.hairline
        card.layer.borderColor = ATTheme.Palette.rule.cgColor
        ATTheme.Elevation.apply(to: card, level: 2)

        overlay.addSubview(card)
        host.addSubview(overlay)

        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(104)
        }

        overlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        host.layoutIfNeeded()

        let mark = UIView()
        card.addSubview(mark)
        mark.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(48)
        }
        host.layoutIfNeeded()
        perform(Int.random(in: 0..<5), in: mark)

        UIView.animate(withDuration: 0.2) { overlay.alpha = 1 }

        let item = DispatchWorkItem {
            UIView.animate(withDuration: 0.22, animations: {
                overlay.alpha = 0
            }, completion: { _ in
                overlay.removeFromSuperview()
                completion?()
            })
        }
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: item)
    }

    static func hide() {
        workItem?.cancel()
        workItem = nil
        keyWindow?.viewWithTag(tag)?.removeFromSuperview()
    }

    // MARK: - The five marks

    private static func perform(_ index: Int, in container: UIView) {
        switch index {
        case 0: sweepArc(in: container)
        case 1: risingDots(in: container)
        case 2: expandingRings(in: container)
        case 3: equaliser(in: container)
        default: orbitingDot(in: container)
        }
    }

    private static func sweepArc(in container: UIView) {
        let side: CGFloat = 44
        let shape = CAShapeLayer()
        shape.frame = CGRect(x: 0, y: 0, width: side, height: side)
        shape.path = UIBezierPath(
            arcCenter: CGPoint(x: side / 2, y: side / 2),
            radius: side / 2 - 3,
            startAngle: -.pi / 2,
            endAngle: .pi * 1.5,
            clockwise: true
        ).cgPath
        shape.fillColor = nil
        shape.strokeColor = ATTheme.Palette.ink.cgColor
        shape.lineWidth = 2.5
        shape.lineCap = .round
        shape.strokeEnd = 0.24
        container.layer.addSublayer(shape)

        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue = CGFloat.pi * 2
        spin.duration = 0.9
        spin.repeatCount = .infinity
        shape.add(spin, forKey: "spin")

        let breathe = CABasicAnimation(keyPath: "strokeEnd")
        breathe.fromValue = 0.12
        breathe.toValue = 0.72
        breathe.duration = 0.55
        breathe.autoreverses = true
        breathe.repeatCount = .infinity
        shape.add(breathe, forKey: "breathe")
    }

    private static func risingDots(in container: UIView) {
        let dots = (0..<3).map { _ -> UIView in
            let dot = UIView()
            dot.backgroundColor = ATTheme.Palette.ink
            dot.layer.cornerRadius = 3.5
            dot.frame = CGRect(x: 0, y: 0, width: 7, height: 7)
            container.addSubview(dot)
            return dot
        }

        for (index, dot) in dots.enumerated() {
            dot.center = CGPoint(x: 10 + CGFloat(index) * 14, y: 24)
        }

        for (index, dot) in dots.enumerated() {
            let rise = CABasicAnimation(keyPath: "position.y")
            rise.fromValue = 30
            rise.toValue = 18
            rise.duration = 0.42
            rise.beginTime = CACurrentMediaTime() + Double(index) * 0.12
            rise.autoreverses = true
            rise.repeatCount = .infinity
            dot.layer.add(rise, forKey: "rise")

            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1
            fade.toValue = 0.35
            fade.duration = 0.42
            fade.beginTime = CACurrentMediaTime() + Double(index) * 0.12
            fade.autoreverses = true
            fade.repeatCount = .infinity
            dot.layer.add(fade, forKey: "fade")
        }
    }

    private static func expandingRings(in container: UIView) {
        for index in 0..<3 {
            let ring = CAShapeLayer()
            ring.frame = container.bounds
            ring.path = UIBezierPath(ovalIn: CGRect(x: 21, y: 21, width: 2, height: 2)).cgPath
            ring.fillColor = nil
            ring.strokeColor = ATTheme.Palette.ink.cgColor
            ring.lineWidth = 1.6
            container.layer.addSublayer(ring)

            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 1
            scale.toValue = 22
            scale.duration = 1.5
            scale.beginTime = CACurrentMediaTime() + Double(index) * 0.5
            scale.repeatCount = .infinity

            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 0.85
            fade.toValue = 0
            fade.duration = 1.5
            fade.beginTime = CACurrentMediaTime() + Double(index) * 0.5
            fade.repeatCount = .infinity

            ring.add(scale, forKey: "scale")
            ring.add(fade, forKey: "fade")
        }
    }

    private static func equaliser(in container: UIView) {
        let heights: [CGFloat] = [14, 26, 34, 20]
        for (index, height) in heights.enumerated() {
            let bar = UIView()
            bar.backgroundColor = ATTheme.Palette.ink
            bar.layer.cornerRadius = 1.5
            bar.frame = CGRect(x: CGFloat(index) * 11, y: (40 - height) / 2, width: 5, height: height)
            container.addSubview(bar)

            let stretch = CABasicAnimation(keyPath: "transform.scale.y")
            stretch.fromValue = 0.4
            stretch.toValue = 1
            stretch.duration = 0.38
            stretch.beginTime = CACurrentMediaTime() + Double(index) * 0.09
            stretch.autoreverses = true
            stretch.repeatCount = .infinity
            bar.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            bar.layer.add(stretch, forKey: "stretch")
        }
    }

    private static func orbitingDot(in container: UIView) {
        let ring = CAShapeLayer()
        ring.frame = container.bounds
        ring.path = UIBezierPath(ovalIn: CGRect(x: 4, y: 4, width: 40, height: 40)).cgPath
        ring.fillColor = nil
        ring.strokeColor = ATTheme.Palette.ruleStrong.cgColor
        ring.lineWidth = 1.2
        container.layer.addSublayer(ring)

        let dot = CALayer()
        dot.frame = CGRect(x: 21, y: 1, width: 7, height: 7)
        dot.backgroundColor = ATTheme.Palette.accent.cgColor
        dot.cornerRadius = 3.5
        container.layer.addSublayer(dot)

        let orbit = CABasicAnimation(keyPath: "transform.rotation.z")
        orbit.fromValue = 0
        orbit.toValue = CGFloat.pi * 2
        orbit.duration = 0.95
        orbit.repeatCount = .infinity
        container.layer.add(orbit, forKey: "orbit")
    }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}
