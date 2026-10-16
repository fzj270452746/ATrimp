//
//  ATMediaViewerViewController.swift
//  ATrimp
//
//
import AVFoundation
import AVKit
import SnapKit
import UIKit

final class ATMediaViewerViewController: UIViewController {

    private let media: [ATPostMedia]
    private var startingIndex: Int

    private let collectionView: UICollectionView
    private let closeButton = UIButton(type: .system)
    private let counterLabel = UILabel()
    private let chrome = UIView()
    private var isChromeVisible = true
    private var currentIndex = 0
    private weak var chromeTap: UITapGestureRecognizer?

    init(media: [ATPostMedia], startAt index: Int = 0) {
        self.media = media
        self.startingIndex = min(max(0, index), max(0, media.count - 1))

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override var prefersStatusBarHidden: Bool { !isChromeVisible }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ATTheme.Palette.ink

        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(ATMediaPageCell.self, forCellWithReuseIdentifier: ATMediaPageCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        buildChrome()

        if media.count == 1 {
            counterLabel.isHidden = true
        } else {
            counterLabel.text = "\(startingIndex + 1) / \(media.count)"
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout,
           layout.itemSize != view.bounds.size {
            layout.itemSize = view.bounds.size
            layout.invalidateLayout()

            collectionView.setContentOffset(
                CGPoint(x: CGFloat(startingIndex) * view.bounds.width, y: 0),
                animated: false
            )
        }
    }

    private func buildChrome() {
        chrome.backgroundColor = .clear
        chrome.isUserInteractionEnabled = false
        view.addSubview(chrome)
        chrome.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let scrim = UIView()
        scrim.backgroundColor = ATTheme.Palette.ink.withAlphaComponent(0.55)
        scrim.isUserInteractionEnabled = false
        chrome.addSubview(scrim)

        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: configuration), for: .normal)
        closeButton.tintColor = ATTheme.Palette.paper
        closeButton.backgroundColor = ATTheme.Palette.ink.withAlphaComponent(0.4)
        closeButton.layer.cornerRadius = 18
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        view.addSubview(closeButton)

        counterLabel.font = ATTheme.Typeface.mono(13, .semibold)
        counterLabel.textColor = ATTheme.Palette.paper
        counterLabel.textAlignment = .right
        view.addSubview(counterLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleChrome))
        view.addGestureRecognizer(tap)
        tap.delegate = self
        chromeTap = tap

        scrim.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(140)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(ATTheme.Space.xs)
            make.leading.equalToSuperview().offset(ATTheme.Space.md)
            make.width.height.equalTo(36)
        }

        counterLabel.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.trailing.equalToSuperview().offset(-ATTheme.Space.md)
        }
    }

    @objc private func handleClose() {
        dismiss(animated: true)
    }

    @objc private func toggleChrome() {
        isChromeVisible.toggle()
        let alpha: CGFloat = isChromeVisible ? 1 : 0
        UIView.animate(withDuration: 0.2) {
            self.chrome.alpha = alpha
        }
        setNeedsStatusBarAppearanceUpdate()
    }
}

extension ATMediaViewerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === chromeTap else { return true }
        let y = touch.location(in: view).y
        return y < 160 || y > view.bounds.height - 160
    }
}

extension ATMediaViewerViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        media.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ATMediaPageCell.reuseIdentifier,
            for: indexPath
        ) as! ATMediaPageCell
        cell.configure(with: media[indexPath.item], allowZoom: media.count >= 1)
        return cell
    }
}

extension ATMediaViewerViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? ATMediaPageCell)?.stopPlayback()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let page = Int((scrollView.contentOffset.x / scrollView.bounds.width).rounded())
        guard page != currentIndex, media.indices.contains(page) else { return }
        currentIndex = page
        counterLabel.text = "\(page + 1) / \(media.count)"
    }
}

// MARK: - Page

private final class ATMediaPageCell: UICollectionViewCell {

    static let reuseIdentifier = "ATMediaPageCell"

    private let zoomView = ATZoomScrollView()
    private let imageView = UIImageView()
    private let playerContainer = UIView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let playGlyph = UIImageView()

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var currentMedia: ATPostMedia?
    private var isPrepared = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = ATTheme.Palette.ink

        zoomView.minimumZoomScale = 1
        zoomView.maximumZoomScale = 4
        zoomView.showsHorizontalScrollIndicator = false
        zoomView.showsVerticalScrollIndicator = false
        zoomView.delegate = self
        zoomView.contentInsetAdjustmentBehavior = .never
        contentView.addSubview(zoomView)

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        zoomView.addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        zoomView.addGestureRecognizer(doubleTap)

        playerContainer.backgroundColor = .black
        playerContainer.isHidden = true
        contentView.addSubview(playerContainer)

        spinner.color = ATTheme.Palette.paper
        spinner.hidesWhenStopped = true
        contentView.addSubview(spinner)

        let configuration = UIImage.SymbolConfiguration(pointSize: 44, weight: .regular)
        playGlyph.image = UIImage(systemName: "play.circle", withConfiguration: configuration)?
            .withTintColor(ATTheme.Palette.paper.withAlphaComponent(0.85), renderingMode: .alwaysOriginal)
        playGlyph.isHidden = true
        contentView.addSubview(playGlyph)

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTap.require(toFail: doubleTap)
        playerContainer.addGestureRecognizer(singleTap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()

        zoomView.frame = contentView.bounds
        playerContainer.frame = contentView.bounds
        playerLayer?.frame = playerContainer.bounds
        spinner.center = contentView.center
        playGlyph.center = contentView.center

        if zoomView.zoomScale == 1 {
            imageView.frame = zoomView.bounds
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopPlayback()
        currentMedia = nil
        isPrepared = false
        zoomView.zoomScale = 1
        imageView.image = nil
        playerContainer.isHidden = true
        playGlyph.isHidden = true
    }

    // MARK: - Configuring

    func configure(with media: ATPostMedia, allowZoom: Bool) {
        currentMedia = media
        zoomView.isScrollEnabled = allowZoom

        switch media.kind {
        case .image:
            zoomView.isHidden = false
            playerContainer.isHidden = true
            imageView.image = ATMediaLibrary.image(
                for: media,
                size: contentView.bounds.size == .zero ? CGSize(width: 1170, height: 1500) : contentView.bounds.size
            )
        case .video:
            zoomView.isHidden = true
            playerContainer.isHidden = false
            playGlyph.isHidden = false
            prepareVideo(for: media)
        }
    }

    private func prepareVideo(for media: ATPostMedia) {
        isPrepared = true
        spinner.startAnimating()

        if let fileURL = ATMediaLibrary.fileURL(forReference: media.reference) {
            attachPlayer(url: fileURL)
            return
        }

        ATPlaceholderVideo.url(seed: media.reference, aspect: media.aspect) { [weak self] url in
            guard let self, self.currentMedia?.id == media.id else { return }
            if let url {
                self.attachPlayer(url: url)
            } else {
                self.spinner.stopAnimating()
                self.playGlyph.isHidden = false
            }
        }
    }

    private func attachPlayer(url: URL) {
        spinner.stopAnimating()

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.actionAtItemEnd = .pause

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        layer.frame = playerContainer.bounds
        playerContainer.layer.addSublayer(layer)

        self.player = player
        self.playerLayer = layer

        player.play()
        playGlyph.isHidden = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackEnded),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
    }

    @objc private func playbackEnded() {
        playGlyph.isHidden = false
    }

    @objc private func handleSingleTap() {
        guard let player else { return }
        if player.rate > 0 {
            player.pause()
            playGlyph.isHidden = false
        } else {
            if player.currentItem?.currentTime() == player.currentItem?.duration {
                player.seek(to: .zero)
            }
            player.play()
            playGlyph.isHidden = true
        }
    }

    @objc private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        guard zoomView.isScrollEnabled, !zoomView.isHidden else { return }

        if zoomView.zoomScale > 1 {
            zoomView.setZoomScale(1, animated: true)
            return
        }

        let point = recognizer.location(in: imageView)
        let size = CGSize(width: zoomView.bounds.width / 2.5, height: zoomView.bounds.height / 2.5)
        zoomView.zoom(to: CGRect(
            x: point.x - size.width / 2,
            y: point.y - size.height / 2,
            width: size.width,
            height: size.height
        ), animated: true)
    }

    func stopPlayback() {
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        spinner.stopAnimating()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private final class ATZoomScrollView: UIScrollView {

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === panGestureRecognizer, zoomScale <= 1 {
            return false
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}

extension ATMediaPageCell: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        scrollView === zoomView ? imageView : nil
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let horizontal = max(0, (scrollView.bounds.width - scrollView.contentSize.width) / 2)
        let vertical = max(0, (scrollView.bounds.height - scrollView.contentSize.height) / 2)
        imageView.center = CGPoint(
            x: scrollView.contentSize.width / 2 + horizontal,
            y: scrollView.contentSize.height / 2 + vertical
        )
    }
}
