//
//  ATLensBar.swift
//  ATrimp
//
//
import SnapKit
import UIKit

private final class ATLensBarTrack: UIView {

    private var entries: [(theme: ATPostTheme, count: Int)] = []
    private var total: Int { entries.reduce(0) { $0 + $1.count } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        layer.cornerRadius = 5
        layer.cornerCurve = .continuous
        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(with entries: [(theme: ATPostTheme, count: Int)]) {
        self.entries = entries.filter { $0.count > 0 }
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard total > 0 else { return }

        var x: CGFloat = 0
        for (index, entry) in entries.enumerated() {
            let width = index == entries.count - 1
                ? bounds.width - x
                : bounds.width * CGFloat(entry.count) / CGFloat(total)

            entry.theme.tint.setFill()
            UIBezierPath(rect: CGRect(x: x, y: 0, width: width, height: bounds.height)).fill()
            x += width
        }
    }
}

// MARK: - Stripe

final class ATLensStripe: UIView {

    private var entries: [(theme: ATPostTheme, count: Int)] = []
    private var total: Int { entries.reduce(0) { $0 + $1.count } }

    private var segments: [CAShapeLayer] = []

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 5)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = ATTheme.Palette.paperDeep
        layer.cornerRadius = 2.5
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(with entries: [(theme: ATPostTheme, count: Int)]) {
        self.entries = entries.filter { $0.count > 0 }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        segments.forEach { $0.removeFromSuperlayer() }
        segments.removeAll()

        guard total > 0, bounds.width > 0 else { return }

        var x: CGFloat = 0
        for (index, entry) in entries.enumerated() {
            let width = index == entries.count - 1
                ? bounds.width - x
                : bounds.width * CGFloat(entry.count) / CGFloat(total)

            let layer = CAShapeLayer()
            layer.path = UIBezierPath(rect: CGRect(x: x, y: 0, width: width, height: bounds.height)).cgPath
            layer.fillColor = entry.theme.tint.cgColor
            self.layer.addSublayer(layer)
            segments.append(layer)

            x += width
        }
    }
}

// MARK: - Bar and legend

final class ATLensBar: UIView {

    private let track = ATLensBarTrack()
    private let legend = UIStackView()
    private let emptyLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        legend.axis = .vertical
        legend.spacing = ATTheme.Space.xs

        emptyLabel.text = "Nothing filed here yet."
        emptyLabel.font = ATTheme.Typeface.caption
        emptyLabel.textColor = ATTheme.Palette.inkFaint

        let column = UIStackView(arrangedSubviews: [track, legend, emptyLabel])
        column.axis = .vertical
        column.spacing = ATTheme.Space.sm
        column.setCustomSpacing(ATTheme.Space.md, after: track)
        addSubview(column)

        track.snp.makeConstraints { make in
            make.height.equalTo(10)
        }

        column.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(
        with entries: [(theme: ATPostTheme, count: Int)],
        averages: [ATPostTheme: Double] = [:]
    ) {
        let present = entries.filter { $0.count > 0 }

        track.configure(with: present)
        legend.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for entry in present {
            legend.addArrangedSubview(
                row(for: entry.theme, count: entry.count, average: averages[entry.theme])
            )
        }

        track.isHidden = present.isEmpty
        legend.isHidden = present.isEmpty
        emptyLabel.isHidden = !present.isEmpty
    }

    private func row(for theme: ATPostTheme, count: Int, average: Double?) -> UIView {
        let container = UIView()

        let configuration = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        let symbol = UIImageView(image: UIImage(systemName: theme.symbol, withConfiguration: configuration))
        symbol.tintColor = theme.tint
        symbol.contentMode = .scaleAspectFit
        container.addSubview(symbol)

        let title = UILabel()
        title.attributedText = ATTheme.sectionLabel(theme.title, color: theme.tint)
        container.addSubview(title)

        let tally = UILabel()
        tally.text = "\(count)"
        tally.font = ATTheme.Typeface.mono(13, .semibold)
        tally.textColor = ATTheme.Palette.inkSoft
        container.addSubview(tally)

        symbol.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(13)
        }

        title.snp.makeConstraints { make in
            make.leading.equalTo(symbol.snp.trailing).offset(ATTheme.Space.xs)
            make.top.bottom.equalToSuperview()
        }

        var leadingAnchor = title.snp.trailing
        if let average {
            let mean = UILabel()
            mean.text = Self.describe(average)
            mean.font = ATTheme.Typeface.mono(12, .medium)
            mean.textColor = ATTheme.Palette.inkFaint
            container.addSubview(mean)

            mean.snp.makeConstraints { make in
                make.leading.greaterThanOrEqualTo(leadingAnchor).offset(ATTheme.Space.xs)
                make.trailing.equalTo(tally.snp.leading).offset(-ATTheme.Space.sm)
                make.centerY.equalToSuperview()
            }
            leadingAnchor = mean.snp.leading
        }

        tally.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(leadingAnchor).offset(ATTheme.Space.xs)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        return container
    }

    private static func describe(_ average: Double) -> String {
        let rounded = average.rounded()
        if abs(average - rounded) < 0.05 {
            return "avg \(Int(rounded))/5"
        }
        return String(format: "avg %.1f/5", average)
    }
}
