//
//  ATPlaceMapViewController.swift
//  ATrimp
//
//
import MapKit
import SnapKit
import UIKit

final class ATPlaceMapViewController: ATViewController {

    private let map = MKMapView()
    private let legend = UIStackView()
    private let countLabel = UILabel()

    private var dossiers: [ATPlaceDossier] = []
    private var needsCameraFit = true

    override func viewDidLoad() {
        super.viewDidLoad()

        installNavBar(title: "The map")
        buildMap()
        buildFooter()
        reload()
    }

    // MARK: - Layout

    private func buildMap() {
        map.mapType = .mutedStandard
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.showsCompass = false
        map.pointOfInterestFilter = .excludingAll
        map.delegate = self
        view.addSubview(map)

        map.snp.makeConstraints { make in
            make.top.equalTo(navBar!.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    private func buildFooter() {
        let panel = UIView()
        panel.backgroundColor = ATTheme.Palette.paperRaised
        panel.layer.cornerCurve = .continuous
        view.addSubview(panel)

        countLabel.font = ATTheme.Typeface.caption
        countLabel.textColor = ATTheme.Palette.inkSoft
        countLabel.numberOfLines = 0
        panel.addSubview(countLabel)

        legend.axis = .vertical
        legend.spacing = ATTheme.Space.xxs
        legend.alignment = .leading
        panel.addSubview(legend)

        countLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ATTheme.Space.sm)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.gutter)
        }

        legend.snp.makeConstraints { make in
            make.top.equalTo(countLabel.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.equalToSuperview().offset(ATTheme.Space.gutter)
            make.trailing.lessThanOrEqualToSuperview().offset(-ATTheme.Space.gutter)
            make.bottom.equalToSuperview().offset(-ATTheme.Space.sm)
        }

        panel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - Data

    private func reload() {
        dossiers = ATStore.pinnedPlaceSummaries()

        map.removeAnnotations(map.annotations)
        for dossier in dossiers {
            map.addAnnotation(ATPlaceAnnotation(dossier: dossier))
        }

        let filings = dossiers.reduce(0) { $0 + $1.postCount }
        countLabel.text = "\(filings) filings across \(dossiers.count) places. Tap a pin to open its dossier."

        let dominant = ATPostTheme.allCases.filter { theme in
            dossiers.contains { $0.dominantTheme == theme }
        }
        buildLegend(with: dominant)

        needsCameraFit = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard needsCameraFit, map.bounds.width > 0 else { return }
        needsCameraFit = false

        if dossiers.count > 1 {
            map.showAnnotations(map.annotations, animated: false)
        } else if let only = dossiers.first {
            map.setRegion(
                MKCoordinateRegion(
                    center: only.place.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30)
                ),
                animated: false
            )
        }
    }

    private func buildLegend(with themes: [ATPostTheme]) {
        legend.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let available = (view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width)
            - ATTheme.Space.gutter * 2

        var row = UIStackView()
        row.axis = .horizontal
        row.spacing = ATTheme.Space.md
        row.alignment = .center
        var used: CGFloat = 0

        for theme in themes {
            let view = key(for: theme)
            let width = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width

            if used > 0, used + ATTheme.Space.md + width > available {
                legend.addArrangedSubview(row)
                row = UIStackView()
                row.axis = .horizontal
                row.spacing = ATTheme.Space.md
                row.alignment = .center
                used = 0
            }

            row.addArrangedSubview(view)
            used += (used > 0 ? ATTheme.Space.md : 0) + width
        }

        if !row.arrangedSubviews.isEmpty {
            legend.addArrangedSubview(row)
        }
    }

    private func key(for theme: ATPostTheme) -> UIView {
        let container = UIView()

        let dot = UIView()
        dot.backgroundColor = theme.tint
        dot.layer.cornerRadius = 4
        container.addSubview(dot)

        let label = UILabel()
        label.attributedText = ATTheme.sectionLabel(theme.title, color: ATTheme.Palette.inkSoft)
        container.addSubview(label)

        dot.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(8)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(dot.snp.trailing).offset(5)
            make.trailing.top.bottom.equalToSuperview()
        }

        return container
    }

    private func open(_ dossier: ATPlaceDossier) {
        push(ATPlaceViewController(place: dossier.place))
    }
}

// MARK: - Map

extension ATPlaceMapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let pin = annotation as? ATPlaceAnnotation else { return nil }

        let identifier = "ATPlacePin"
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        view.annotation = annotation
        view.canShowCallout = true
        if view.rightCalloutAccessoryView == nil {
            let chevron = UIButton(type: .detailDisclosure)
            chevron.tintColor = ATTheme.Palette.accent
            view.rightCalloutAccessoryView = chevron
        }

        view.subviews.forEach { $0.removeFromSuperview() }
        let marker = ATPlaceMark(dossier: pin.dossier)
        view.addSubview(marker)
        marker.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        view.frame = CGRect(origin: .zero, size: marker.intrinsicContentSize)

        return view
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let pin = view.annotation as? ATPlaceAnnotation else { return }
        open(pin.dossier)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let pin = view.annotation as? ATPlaceAnnotation else { return }
        mapView.setCenter(pin.coordinate, animated: true)
    }
}

// MARK: - Annotation

private final class ATPlaceAnnotation: NSObject, MKAnnotation {

    let dossier: ATPlaceDossier

    init(dossier: ATPlaceDossier) {
        self.dossier = dossier
    }

    var coordinate: CLLocationCoordinate2D { dossier.place.coordinate }

    var title: String? { dossier.place.name }

    var subtitle: String? {
        let theme = dossier.dominantTheme
        let filings = "\(dossier.postCount) \(dossier.postCount == 1 ? "filing" : "filings")"
        return theme.map { "\(filings) · mostly \($0.title.lowercased())" } ?? filings
    }
}

// MARK: - Pin mark

private final class ATPlaceMark: UIView {

    private let label = UILabel()
    private let side: CGFloat

    init(dossier: ATPlaceDossier) {
        let count = dossier.postCount
        let step: CGFloat = count >= 4 ? 1 : (count >= 2 ? 0.85 : 0.7)
        self.side = 34 * step
        super.init(frame: .zero)

        let tint = dossier.dominantTheme?.tint ?? ATTheme.Palette.mist
        backgroundColor = tint
        layer.cornerRadius = side / 2
        layer.borderWidth = 2
        layer.borderColor = ATTheme.Palette.paper.cgColor

        label.text = "\(count)"
        label.font = ATTheme.Typeface.mono(12, .bold)
        label.textColor = ATTheme.Palette.paper
        label.textAlignment = .center
        addSubview(label)

        snp.makeConstraints { make in
            make.width.height.equalTo(side)
        }

        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override var intrinsicContentSize: CGSize { CGSize(width: side, height: side) }
}

// MARK: - Place coordinates

extension ATPlace {

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude ?? 0, longitude: longitude ?? 0)
    }
}
