//
//  ATRootViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

final class ATRootViewController: UIViewController {

    enum Module: Int, CaseIterable {
        case home
        case explore
        case chat
        case profile
    }

    private(set) static weak var current: ATRootViewController?

    private let contentView = UIView()
    private let dock: ATDock
    private let composeButton = ATComposeButton()
    private let tabs: [ATNavigationController]

    private var visibleModule: Module = .home
    private var isDockHidden = false

    private let dockOcclusion: CGFloat = 70

    init() {
        let roots: [UIViewController] = [
            ATHomeViewController(),
            ATExploreViewController(),
            ATChatListViewController(),
            ATProfileViewController(),
        ]

        tabs = roots.map { ATNavigationController(rootViewController: $0) }

        dock = ATDock(items: [
            ATDock.Item(symbol: "house", activeSymbol: "house.fill"),
            ATDock.Item(symbol: "safari", activeSymbol: "safari.fill"),
            ATDock.Item(symbol: "bubble.left.and.bubble.right", activeSymbol: "bubble.left.and.bubble.right.fill"),
            ATDock.Item(symbol: "person", activeSymbol: "person.fill"),
        ])

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ATTheme.Palette.paper
        overrideUserInterfaceStyle = .light

        contentView.backgroundColor = ATTheme.Palette.paper
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(dock)
        dock.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().offset(-96)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
        }

        view.addSubview(composeButton)
        composeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-ATTheme.Space.gutter)
            make.bottom.equalTo(dock.snp.top).offset(-ATTheme.Space.sm)
        }

        dock.onSelect = { [weak self] index in
            guard let module = Module(rawValue: index) else { return }
            self?.show(module)
        }

        composeButton.onTap = { [weak self] in self?.openCompose() }

        for tab in tabs {
            tab.delegate = self
        }

        composeButton.setShown(true, animated: false)

        show(.home)
        ATRootViewController.current = self
    }

    // MARK: - Modules

    func show(_ module: Module, resettingStack: Bool = false) {
        let tab = tabs[module.rawValue]

        if visibleModule != module || currentChild !== tab {
            currentChild?.willMove(toParent: nil)
            currentChild?.view.removeFromSuperview()
            currentChild?.removeFromParent()

            addChild(tab)
            contentView.addSubview(tab.view)
            tab.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            tab.didMove(toParent: self)
        }

        if resettingStack {
            tab.popToRootViewController(animated: false)
        }

        visibleModule = module
        if dock.selectedIndex != module.rawValue {
            dock.select(module.rawValue, animated: true)
        }

        setDockHidden(tab.viewControllers.count > 1, animated: true)
        applyDockInset()
    }

    // MARK: - Compose

    private func openCompose() {
        guard visibleModule == .home, !isDockHidden else { return }
        tabs[Module.home.rawValue].pushViewController(ATComposeViewController(), animated: true)
    }

    func finishCompose() {
        let tab = tabs[Module.home.rawValue]
        show(.home)
        tab.popToRootViewController(animated: true)
    }

    private var currentChild: UIViewController? {
        children.first
    }

    // MARK: - Dock

    private func setDockHidden(_ hidden: Bool, animated: Bool) {
        if hidden != isDockHidden {
            isDockHidden = hidden

            let changes = {
                self.dock.alpha = hidden ? 0 : 1
                self.dock.transform = hidden
                    ? CGAffineTransform(translationX: 0, y: ATDock.height + 44)
                    : .identity
            }

            if animated {
                UIView.animate(withDuration: 0.24, delay: 0, options: .curveEaseInOut, animations: changes)
            } else {
                changes()
            }

            applyDockInset()
        }

        refreshComposeButton(animated: animated)
    }

    private func refreshComposeButton(animated: Bool) {
        composeButton.setShown(!isDockHidden && visibleModule == .home, animated: animated)
    }

    private func applyDockInset() {
        let inset: CGFloat = isDockHidden ? 0 : dockOcclusion
        tabs.forEach { $0.additionalSafeAreaInsets.bottom = inset }
    }
}

extension ATRootViewController: UINavigationControllerDelegate {

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        guard navigationController === tabs[visibleModule.rawValue] else { return }
        setDockHidden(navigationController.viewControllers.count > 1, animated: animated)
    }
}
