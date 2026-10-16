//
//  ATRefreshControl.swift
//  ATrimp
//
//
import UIKit

final class ATRefreshControl: UIView {

    var onRefresh: (() -> Void)?

    private(set) var isRefreshing = false

    private weak var scrollView: UIScrollView?
    private var observations: [NSKeyValueObservation] = []
    private var originalInsetTop: CGFloat = 0

    private let threshold: CGFloat = 76
    private let arcLayer = CAShapeLayer()
    private let label = UILabel()

    // MARK: - Attaching

    func attach(to scrollView: UIScrollView) {
        self.scrollView = scrollView

        frame = CGRect(x: 0, y: -threshold, width: scrollView.bounds.width, height: threshold)
        autoresizingMask = [.flexibleWidth]
        scrollView.insertSubview(self, at: 0)

        arcLayer.fillColor = nil
        arcLayer.strokeColor = ATTheme.Palette.accent.cgColor
        arcLayer.lineWidth = 2
        arcLayer.lineCap = .round
        arcLayer.strokeEnd = 0
        layer.addSublayer(arcLayer)

        label.text = "REFRESHING"
        label.font = ATTheme.Typeface.sans(10, .semibold)
        label.textColor = ATTheme.Palette.inkFaint
        label.textAlignment = .center
        label.alpha = 0
        addSubview(label)

        observations = [
            scrollView.observe(\.contentOffset, options: [.new]) { [weak self] view, _ in
                self?.offsetChanged(in: view)
            },
            scrollView.observe(\.isDragging, options: [.new]) { [weak self] view, _ in
                guard !view.isDragging else { return }
                self?.dragEnded(in: view)
            },
        ]
    }

    deinit {
        observations.forEach { $0.invalidate() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let side: CGFloat = 22
        arcLayer.frame = bounds
        arcLayer.path = UIBezierPath(
            arcCenter: CGPoint(x: bounds.midX, y: bounds.midY - 6),
            radius: side / 2,
            startAngle: -.pi / 2,
            endAngle: .pi * 1.5,
            clockwise: true
        ).cgPath

        label.frame = CGRect(x: 0, y: bounds.midY + 14, width: bounds.width, height: 14)
    }

    // MARK: - Gestures

    private func offsetChanged(in scrollView: UIScrollView) {
        if frame.width != scrollView.bounds.width {
            frame.size.width = scrollView.bounds.width
        }

        guard !isRefreshing else { return }
        let pull = -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
        let progress = max(0, min(1, pull / threshold))
        arcLayer.strokeEnd = progress
        arcLayer.transform = CATransform3DMakeRotation(progress * .pi, 0, 0, 1)
    }

    private func dragEnded(in scrollView: UIScrollView) {
        guard !isRefreshing else { return }
        let pull = -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
        if pull >= threshold {
            beginRefreshing()
        } else {
            arcLayer.strokeEnd = 0
            arcLayer.transform = CATransform3DIdentity
        }
    }

    // MARK: - State

    private func beginRefreshing() {
        guard let scrollView, !isRefreshing else { return }
        isRefreshing = true
        originalInsetTop = scrollView.contentInset.top

        scrollView.contentInset.top = originalInsetTop + threshold
        scrollView.setContentOffset(CGPoint(x: 0, y: -(originalInsetTop + threshold)), animated: true)

        label.alpha = 0
        UIView.animate(withDuration: 0.2) { self.label.alpha = 1 }

        startTurning()
        onRefresh?()
    }

    func endRefreshing() {
        guard let scrollView, isRefreshing else { return }
        isRefreshing = false

        stopTurning()
        UIView.animate(withDuration: 0.2) { self.label.alpha = 0 }

        UIView.animate(withDuration: 0.28) {
            scrollView.contentInset.top = self.originalInsetTop
        }
    }

    private func startTurning() {
        arcLayer.strokeEnd = 0.22
        arcLayer.removeAllAnimations()

        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue = CGFloat.pi * 2
        spin.duration = 0.85
        spin.repeatCount = .infinity
        arcLayer.add(spin, forKey: "spin")
    }

    private func stopTurning() {
        arcLayer.removeAllAnimations()
        arcLayer.strokeEnd = 0
        arcLayer.transform = CATransform3DIdentity
    }
}
