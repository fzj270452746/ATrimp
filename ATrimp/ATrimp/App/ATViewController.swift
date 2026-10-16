//
//  ATViewController.swift
//  ATrimp
//
//
import SnapKit
import UIKit

class ATViewController: UIViewController {

    private(set) var navBar: ATNavBar?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ATTheme.Palette.paper
        overrideUserInterfaceStyle = .light
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    // MARK: - Header

    @discardableResult
    func installNavBar(title: String?, showsBack: Bool = true) -> ATNavBar {
        let bar = ATNavBar(title: title, showsBack: showsBack)
        view.addSubview(bar)

        bar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }

        if showsBack {
            bar.onBack = { [weak self] in self?.goBack() }
        }
        navBar = bar
        return bar
    }

    // MARK: - Navigation

    func push(_ viewController: UIViewController) {
        navigationController?.pushViewController(viewController, animated: true)
    }

    func goBack() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Presentation shortcuts

    func showToast(_ message: String) {
        ATToast.show(message, in: view)
    }

    @discardableResult
    func requireSignIn(message: String? = nil) -> Bool {
        guard !ATSession.shared.isSignedIn else { return false }
        if let message { showToast(message) }
        present(ATLoginViewController(), animated: true)
        return true
    }

    // MARK: - Sheets

    func presentSheet(_ controller: UIViewController, detents: [UISheetPresentationController.Detent] = [.medium(), .large()]) {
        controller.modalPresentationStyle = .pageSheet
        if let sheet = controller.sheetPresentationController {
            sheet.detents = detents
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = ATTheme.Radius.large
        }
        present(controller, animated: true)
    }
}
