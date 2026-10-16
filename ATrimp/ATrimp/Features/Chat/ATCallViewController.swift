//
//  ATCallViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

enum ATCallOutcome {
    case declined
    case endedEarly
}

final class ATCallViewController: UIViewController {

    var onFinished: ((ATCallOutcome) -> Void)?

    private let peer: ATUser

    private let avatar = ATAvatarView(size: 132)
    private let ringOne = UIView()
    private let ringTwo = UIView()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private let glyph = UIImageView()
    private let endButton = UIButton(type: .custom)

    private var hasFinished = false
    private var ringingWork: DispatchWorkItem?
    private var dismissWork: DispatchWorkItem?

    private let connectingDuration: TimeInterval = 5
    private let declineDisplayDuration: TimeInterval = 1.4

    init(peer: ATUser) {
        self.peer = peer
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ATTheme.Palette.ink

        for ring in [ringOne, ringTwo] {
            ring.backgroundColor = .clear
            ring.layer.borderWidth = 1
            ring.layer.borderColor = ATTheme.Palette.paper.withAlphaComponent(0.22).cgColor
            ring.layer.cornerRadius = 66
            view.addSubview(ring)
        }

        avatar.set(user: peer)
        view.addSubview(avatar)

        nameLabel.text = peer.displayName
        nameLabel.font = ATTheme.Typeface.serif(28, .semibold)
        nameLabel.textColor = ATTheme.Palette.paper
        nameLabel.textAlignment = .center
        view.addSubview(nameLabel)

        let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .light)
        glyph.image = UIImage(systemName: "video", withConfiguration: configuration)?
            .withTintColor(ATTheme.Palette.paper.withAlphaComponent(0.55), renderingMode: .alwaysOriginal)
        glyph.contentMode = .center
        view.addSubview(glyph)

        statusLabel.text = "Calling…"
        statusLabel.font = ATTheme.Typeface.sans(15)
        statusLabel.textColor = ATTheme.Palette.paper.withAlphaComponent(0.7)
        statusLabel.textAlignment = .center
        view.addSubview(statusLabel)

        endButton.backgroundColor = ATTheme.Palette.danger
        endButton.layer.cornerRadius = 33
        let endConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        endButton.setImage(
            UIImage(systemName: "phone.down.fill", withConfiguration: endConfiguration)?
                .withTintColor(ATTheme.Palette.paper, renderingMode: .alwaysOriginal),
            for: .normal
        )
        endButton.addTarget(self, action: #selector(handleEnd), for: .touchUpInside)
        view.addSubview(endButton)

        let hint = UILabel()
        hint.text = "Only people you have added one another with can call."
        hint.font = ATTheme.Typeface.sans(11.5)
        hint.textColor = ATTheme.Palette.paper.withAlphaComponent(0.35)
        hint.textAlignment = .center
        hint.numberOfLines = 0
        view.addSubview(hint)

        avatar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-90)
        }

        for ring in [ringOne, ringTwo] {
            ring.snp.makeConstraints { make in
                make.center.equalTo(avatar)
                make.width.height.equalTo(132)
            }
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatar.snp.bottom).offset(ATTheme.Space.xl)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.xl)
        }

        glyph.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(ATTheme.Space.md)
            make.centerX.equalToSuperview()
        }

        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(glyph.snp.bottom).offset(ATTheme.Space.xs)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.xl)
        }

        endButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-ATTheme.Space.xl)
            make.width.height.equalTo(66)
        }

        hint.snp.makeConstraints { make in
            make.bottom.equalTo(endButton.snp.top).offset(-ATTheme.Space.md)
            make.leading.trailing.equalToSuperview().inset(ATTheme.Space.xl)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startRings()

        let work = DispatchWorkItem { [weak self] in
            self?.decline()
        }
        ringingWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + connectingDuration, execute: work)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ringingWork?.cancel()
        dismissWork?.cancel()
    }

    // MARK: - States

    private func startRings() {
        for (index, ring) in [ringOne, ringTwo].enumerated() {
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 1
            scale.toValue = 1.6
            scale.duration = 2.4
            scale.beginTime = CACurrentMediaTime() + Double(index) * 0.8
            scale.repeatCount = .infinity

            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 0.9
            fade.toValue = 0
            fade.duration = 2.4
            fade.beginTime = CACurrentMediaTime() + Double(index) * 0.8
            fade.repeatCount = .infinity

            ring.layer.add(scale, forKey: "scale")
            ring.layer.add(fade, forKey: "fade")
        }
    }

    private func decline() {
        statusLabel.text = "Call declined"

        UIView.animate(withDuration: 0.24) {
            self.avatar.alpha = 0.5
            self.ringOne.alpha = 0
            self.ringTwo.alpha = 0
        }

        ringOne.layer.removeAllAnimations()
        ringTwo.layer.removeAllAnimations()

        let work = DispatchWorkItem { [weak self] in
            self?.finish(.declined)
        }
        dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + declineDisplayDuration, execute: work)
    }

    @objc private func handleEnd() {
        finish(.endedEarly)
    }

    private func finish(_ outcome: ATCallOutcome) {
        guard !hasFinished else { return }
        hasFinished = true
        ringingWork?.cancel()
        dismissWork?.cancel()

        dismiss(animated: true) { [weak self] in
            self?.onFinished?(outcome)
        }
    }
}
