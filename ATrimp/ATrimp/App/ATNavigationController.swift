//
//  ATNavigationController.swift
//  ATrimp
//
//
import UIKit

private final class ATInteractivePopGesture: NSObject, UIGestureRecognizerDelegate {
    weak var navigationController: UINavigationController?

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }
}

final class ATNavigationController: UINavigationController {

    private let popGesture = ATInteractivePopGesture()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.isHidden = true
        overrideUserInterfaceStyle = .light
        view.backgroundColor = ATTheme.Palette.paper

        popGesture.navigationController = self
        interactivePopGestureRecognizer?.delegate = popGesture
        interactivePopGestureRecognizer?.isEnabled = true
    }

    override var childForStatusBarStyle: UIViewController? {
        topViewController
    }
}
