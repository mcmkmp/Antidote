// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import SnapKit

private struct Constants {
    static let HorizontalLineHeight = 0.5
}

class TabBarController: UITabBarController {
    override var selectedIndex: Int {
        didSet {
            guard let navigation = viewControllers?[selectedIndex] as? UINavigationController else {
                return
            }

            navigation.delegate = self

            if oldValue == selectedIndex {
                navigation.popToRootViewControllerAnimated(true)
            }

            updateSelectedItems()
        }
    }

    private let items: [TabBarAbstractItem]

    private let theme: Theme

    private var customTabBarView: UIView!

    private var customTabBarViewVisibleConstraint: Constraint!
    private var customTabBarViewHiddenConstraint: Constraint!

    init(theme: Theme, controllers: [UINavigationController], tabBarItems: [TabBarAbstractItem]) {
        self.theme = theme
        self.items = tabBarItems

        super.init(nibName: nil, bundle: nil)

        viewControllers = controllers

        delegate = self
    }

    required convenience init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        createCustomTabBarView()
        addItems()
        installConstraints()

        updateSelectedItems()
    }
}

extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        guard let navigation = viewController as? UINavigationController else {
            return
        }

        navigation.delegate = self
    }
}

extension TabBarController: UINavigationControllerDelegate {
    func navigationController(
            navigationController: UINavigationController,
            willShowViewController viewController: UIViewController,
            animated: Bool) {
        tabBar.hidden = true

        if viewController.hidesBottomBarWhenPushed {
            customTabBarViewVisibleConstraint.deactivate()
            customTabBarViewHiddenConstraint.activate()
        }
        else {
            customTabBarViewHiddenConstraint.deactivate()
            customTabBarViewVisibleConstraint.activate()
        }
    }
}

extension TabBarController {
    func createCustomTabBarView() {
        customTabBarView = UIView()
        customTabBarView.backgroundColor = theme.colorForType(.NormalBackground)
        view.addSubview(customTabBarView)

        let horizontalLine = UIView()
        horizontalLine.backgroundColor = theme.colorForType(.SeparatorsAndBorders)
        customTabBarView.addSubview(horizontalLine)

        horizontalLine.snp_makeConstraints {
            $0.top.leading.trailing.equalTo(customTabBarView)
            $0.height.equalTo(Constants.HorizontalLineHeight)
        }
    }

    func addItems() {
        for (index, item) in items.enumerate() {
            item.didTapHandler = { [weak self] in
                self?.selectedIndex = index
            }

            customTabBarView.addSubview(item)
        }
    }

    func installConstraints() {
        customTabBarView.snp_makeConstraints {
            customTabBarViewVisibleConstraint = $0.bottom.equalTo(view.snp_bottom).constraint
            customTabBarViewHiddenConstraint = $0.top.equalTo(view.snp_bottom).constraint
            $0.leading.trailing.equalTo(view)
            $0.height.equalTo(tabBar.frame.size.height)
        }

        customTabBarViewHiddenConstraint.deactivate()

        var previous: TabBarAbstractItem?

        for item in items {
            item.snp_makeConstraints {
                $0.top.bottom.equalTo(customTabBarView)

                if previous != nil {
                    $0.leading.equalTo(previous!.snp_trailing)
                    $0.width.equalTo(previous!)
                }
                else {
                    $0.leading.equalTo(customTabBarView)
                }
            }

            previous = item
        }
        previous!.snp_makeConstraints {
            $0.trailing.equalTo(customTabBarView)
        }
    }

    func updateSelectedItems() {
        for (index, item) in items.enumerate() {
            item.selected = (index == selectedIndex)
        }
    }
}
