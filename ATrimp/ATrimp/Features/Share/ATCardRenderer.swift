//
//  ATCardRenderer.swift
//  ATrimp
//
//
import UIKit

enum ATCardRenderer {

    private static let size = CGSize(width: 1080, height: 1350)
    private static let margin: CGFloat = 76

    // MARK: - A filing

    static func card(
        for post: ATPost,
        author: ATUser?,
        media: [ATPostMedia]
    ) -> UIImage {
        render { context in
            drawGround(in: context)
            var y = margin + 8

            y = drawWordmark(at: y, trailing: post.isRedeemed ? "WENT BACK" : nil, tint: post.theme.tint, in: context)

            y += 34
            y = draw(sectionLabel: post.theme.title, at: y, colour: post.theme.tint)

            y += 14
            y = draw(
                place: post.locationName,
                country: post.country,
                at: y
            )

            y += 22
            let photo = media.first.flatMap { cover(for: $0) }
            y = draw(image: photo, at: y, height: 620, in: context, seed: post.id, symbol: nil)

            y += 40
            y = draw(
                body: post.body,
                at: y,
                limit: size.height - margin - 110 - y,
                pointSize: 30,
                lines: 5
            )

            let byline = [author?.displayName, author?.homeCity]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
            draw(
                footer: byline.isEmpty ? "ATrimp" : "\(byline) — filed with ATrimp",
                at: size.height - margin - 30
            )
        }
    }

    // MARK: - A place

    static func card(for dossier: ATPlaceDossier) -> UIImage {
        render { context in
            drawGround(in: context)
            var y = margin + 8

            y = drawWordmark(at: y, trailing: nil, tint: ATTheme.Palette.mist, in: context)

            y += 34
            y = draw(sectionLabel: "The dossier", at: y, colour: ATTheme.Palette.mist)

            y += 14
            y = draw(place: dossier.place.name, country: dossier.place.country, at: y)

            y += 26
            y = drawPlaceTally(dossier, at: y)

            y += 30
            y = drawLensBar(dossier, at: y, in: context)

            y += 36
            if let quote = dossier.posts.first {
                y = draw(
                    body: quote.body,
                    at: y,
                    limit: size.height - margin - 110 - y,
                    pointSize: 28,
                    lines: 4
                )
            }

            draw(
                footer: "\(dossier.postCount) filings from \(dossier.authorCount) travellers — ATrimp",
                at: size.height - margin - 30
            )
        }
    }

    // MARK: - The digest

    static func card(for wrapped: ATWrapped) -> UIImage {
        render { context in
            drawGround(in: context)
            var y = margin + 8

            y = drawWordmark(at: y, trailing: nil, tint: ATTheme.Palette.accent, in: context)

            y += 34
            y = draw(sectionLabel: "The year in second thoughts", at: y, colour: ATTheme.Palette.accent)

            y += 16
            y = drawHeadline(wrapped.periodPhrase, at: y)

            y += 26
            y = draw(figures: [
                ("\(wrapped.filings)", "filings"),
                ("\(wrapped.places)", "places"),
                ("\(wrapped.countries)", "countries"),
            ], at: y)

            y += 44
            y = draw(rule: y)

            y += 34
            if let dominant = wrapped.dominantLens {
                y = draw(
                    body: "The library reads most often as \(dominant.title.lowercased()) — \(wrapped.lenses.first?.count ?? 0) of \(wrapped.filings) filings.",
                    at: y,
                    limit: 130,
                    pointSize: 28,
                    lines: 3
                )
                y += 20
            }

            if let busiest = wrapped.busiest {
                y = draw(
                    body: "Most filed: \(busiest.dossier.place.name), \(busiest.dossier.place.country) — \(busiest.score) filings.",
                    at: y,
                    limit: 110,
                    pointSize: 28,
                    lines: 2
                )
                y += 20
            }

            y = draw(
                body: "\(wrapped.answered) filings have been answered — somebody went back and wrote what changed.",
                at: y,
                limit: 110,
                pointSize: 28,
                lines: 2
            )

            if wrapped.hasReaderPart {
                draw(
                    footer: "Yours: \(wrapped.readerFiled) filed · \(wrapped.readerLiked) liked · \(wrapped.readerRecognised) same here — ATrimp",
                    at: size.height - margin - 30
                )
            } else {
                draw(footer: "Counted from the filings themselves — ATrimp", at: size.height - margin - 30)
            }
        }
    }

    private static func drawHeadline(_ text: String, at y: CGFloat) -> CGFloat {
        let title = NSAttributedString(
            string: text,
            attributes: [
                .font: ATTheme.Typeface.serif(64, .semibold),
                .foregroundColor: ATTheme.Palette.ink,
            ]
        )
        title.draw(at: CGPoint(x: margin, y: y))
        return y + title.size().height
    }

    private static func draw(figures: [(String, String)], at y: CGFloat) -> CGFloat {
        let width = size.width - margin * 2
        let column = width / CGFloat(max(1, figures.count))
        var tallest: CGFloat = 0

        for (index, figure) in figures.enumerated() {
            let value = NSAttributedString(
                string: figure.0,
                attributes: [
                    .font: ATTheme.Typeface.serif(72, .semibold),
                    .foregroundColor: ATTheme.Palette.ink,
                ]
            )
            let caption = NSAttributedString(
                string: figure.1.uppercased(),
                attributes: [
                    .font: ATTheme.Typeface.sans(22, .semibold),
                    .foregroundColor: ATTheme.Palette.inkFaint,
                    .kern: 2.4,
                ]
            )

            let x = margin + column * CGFloat(index)
            value.draw(at: CGPoint(x: x, y: y))
            caption.draw(at: CGPoint(x: x, y: y + value.size().height + 6))
            tallest = max(tallest, value.size().height + 6 + caption.size().height)
        }

        return y + tallest
    }

    private static func draw(rule y: CGFloat) -> CGFloat {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: size.width - margin, y: y))
        path.lineWidth = 2
        ATTheme.Palette.rule.setStroke()
        path.stroke()
        return y
    }

    // MARK: - Rendering

    private static func render(_ body: (UIGraphicsImageRendererContext) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image(actions: body)
    }

    private static func drawGround(in context: UIGraphicsImageRendererContext) {
        ATTheme.Palette.paper.setFill()
        context.fill(CGRect(origin: .zero, size: size))

        let frame = CGRect(origin: .zero, size: size).insetBy(dx: 34, dy: 34)
        let path = UIBezierPath(rect: frame)
        path.lineWidth = 2
        ATTheme.Palette.rule.setStroke()
        path.stroke()
    }

    @discardableResult
    private static func drawWordmark(
        at y: CGFloat,
        trailing: String?,
        tint: UIColor,
        in context: UIGraphicsImageRendererContext
    ) -> CGFloat {
        let mark = NSAttributedString(
            string: "ATRIMP",
            attributes: [
                .font: ATTheme.Typeface.serif(30, .semibold),
                .foregroundColor: ATTheme.Palette.ink,
                .kern: 4.0,
            ]
        )
        mark.draw(at: CGPoint(x: margin, y: y))

        if let trailing {
            let stamp = NSAttributedString(
                string: trailing,
                attributes: [
                    .font: ATTheme.Typeface.sans(22, .heavy),
                    .foregroundColor: tint,
                    .kern: 2.0,
                ]
            )
            let width = stamp.size().width
            stamp.draw(at: CGPoint(x: size.width - margin - width, y: y + 8))
        }

        return y + mark.size().height
    }

    private static func draw(sectionLabel text: String, at y: CGFloat, colour: UIColor) -> CGFloat {
        let label = NSAttributedString(
            string: text.uppercased(),
            attributes: [
                .font: ATTheme.Typeface.sans(22, .semibold),
                .foregroundColor: colour,
                .kern: 3.2,
            ]
        )
        label.draw(at: CGPoint(x: margin, y: y))
        return y + label.size().height
    }

    private static func draw(place name: String, country: String, at y: CGFloat) -> CGFloat {
        let title = NSAttributedString(
            string: name,
            attributes: [
                .font: ATTheme.Typeface.serif(64, .semibold),
                .foregroundColor: ATTheme.Palette.ink,
            ]
        )
        title.draw(at: CGPoint(x: margin, y: y))

        if !country.isEmpty {
            let region = NSAttributedString(
                string: country,
                attributes: [
                    .font: ATTheme.Typeface.sans(26, .medium),
                    .foregroundColor: ATTheme.Palette.inkFaint,
                ]
            )
            region.draw(at: CGPoint(x: margin, y: y + title.size().height + 4))
            return y + title.size().height + 4 + region.size().height
        }
        return y + title.size().height
    }

    private static func cover(for media: ATPostMedia) -> UIImage? {
        ATMediaLibrary.image(
            for: media,
            size: CGSize(width: 1200, height: 880),
            symbol: media.kind == .video ? "play.fill" : nil
        )
    }

    private static func draw(
        image: UIImage?,
        at y: CGFloat,
        height: CGFloat,
        in context: UIGraphicsImageRendererContext,
        seed: String,
        symbol: String?
    ) -> CGFloat {
        let width = size.width - margin * 2
        let rect = CGRect(x: margin, y: y, width: width, height: height)
        let picture = image ?? ATArt.photo(seed: seed, size: rect.size, symbol: symbol)

        context.cgContext.saveGState()
        UIBezierPath(rect: rect).addClip()
        picture.draw(in: rect)
        context.cgContext.restoreGState()

        return y + height
    }

    @discardableResult
    private static func draw(
        body: String,
        at y: CGFloat,
        limit: CGFloat,
        pointSize: CGFloat,
        lines: Int
    ) -> CGFloat {
        guard limit > 0 else { return y }

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = pointSize * 0.32
        paragraph.lineBreakMode = .byWordWrapping

        let font = ATTheme.Typeface.sans(pointSize)
        let lineHeight = font.lineHeight + paragraph.lineSpacing
        let height = min(limit, CGFloat(lines) * lineHeight)

        let text = NSAttributedString(
            string: body,
            attributes: [
                .font: font,
                .foregroundColor: ATTheme.Palette.ink,
                .paragraphStyle: paragraph,
            ]
        )

        text.draw(
            with: CGRect(x: margin, y: y, width: size.width - margin * 2, height: height),
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
            context: nil
        )
        return y + height
    }

    private static func draw(footer text: String, at y: CGFloat) {
        let rule = UIBezierPath()
        rule.move(to: CGPoint(x: margin, y: y - 22))
        rule.addLine(to: CGPoint(x: size.width - margin, y: y - 22))
        rule.lineWidth = 2
        ATTheme.Palette.rule.setStroke()
        rule.stroke()

        let footer = NSAttributedString(
            string: text,
            attributes: [
                .font: ATTheme.Typeface.sans(22, .medium),
                .foregroundColor: ATTheme.Palette.inkSoft,
            ]
        )
        footer.draw(at: CGPoint(x: margin, y: y))
    }

    private static func drawPlaceTally(_ dossier: ATPlaceDossier, at y: CGFloat) -> CGFloat {
        let tally = NSAttributedString(
            string: "\(dossier.postCount) filings · \(dossier.authorCount) travellers",
            attributes: [
                .font: ATTheme.Typeface.sans(26, .medium),
                .foregroundColor: ATTheme.Palette.inkSoft,
            ]
        )
        tally.draw(at: CGPoint(x: margin, y: y))
        return y + tally.size().height
    }

    private static func drawLensBar(
        _ dossier: ATPlaceDossier,
        at y: CGFloat,
        in context: UIGraphicsImageRendererContext
    ) -> CGFloat {
        let entries = dossier.themesByWeight
        let total = entries.reduce(0) { $0 + $1.count }
        guard total > 0 else { return y }

        let width = size.width - margin * 2
        let height: CGFloat = 26
        var x = margin

        context.cgContext.saveGState()
        UIBezierPath(
            roundedRect: CGRect(x: margin, y: y, width: width, height: height),
            cornerRadius: height / 2
        ).addClip()

        for (index, entry) in entries.enumerated() {
            let segment = index == entries.count - 1
                ? width - (x - margin)
                : width * CGFloat(entry.count) / CGFloat(total)
            entry.theme.tint.setFill()
            UIBezierPath(rect: CGRect(x: x, y: y, width: segment, height: height)).fill()
            x += segment
        }
        context.cgContext.restoreGState()

        var labelY = y + height + 14
        for entry in entries {
            let line = NSAttributedString(
                string: "\(entry.theme.title.uppercased())  \(entry.count)",
                attributes: [
                    .font: ATTheme.Typeface.sans(22, .semibold),
                    .foregroundColor: entry.theme.tint,
                    .kern: 1.6,
                ]
            )
            line.draw(at: CGPoint(x: margin, y: labelY))
            labelY += line.size().height + 6
        }

        return labelY
    }
}
