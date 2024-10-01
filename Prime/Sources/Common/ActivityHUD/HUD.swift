import UIKit

class HUD: UIView {
    static let tag = 239_932

    @discardableResult
    static func show(
        on view: UIView? = nil,
        mode: Mode,
        animated: Bool = true,
		needsPad: Bool = false,
		offset: CGPoint = .zero,
        isUserInteractionEnabled: Bool = false,
		dismissesOnTap: Bool = false,
        timeout: TimeInterval? = nil,
        onRemove: (() -> Void)? = nil
    ) -> HUD? {
        guard let view = view ?? UIWindow.keyWindow else {
            return nil
        }

        let hudView = mode.view

        let action = {
            let blockingSplashContainerView = UIView()
            blockingSplashContainerView.tag = Self.tag
            blockingSplashContainerView.backgroundColorThemed = Palette.shared.clear
			// Make splash container eat touches by making its !! User Interaction Enabled = TRUE !!
            blockingSplashContainerView.isUserInteractionEnabled = !isUserInteractionEnabled

            blockingSplashContainerView.addSubview(hudView)
            view.addSubview(blockingSplashContainerView)

			hudView.make(.center, .equalToSuperview, [offset.x, offset.y])
			hudView.make(.size, .equal, [88], priorities: [.defaultHigh])

			blockingSplashContainerView.make(.edges, .equalToSuperview)

			if case .spinner(_) = mode {
				if dismissesOnTap {
					// Hide on tap
					blockingSplashContainerView.addTapHandler(feedback: .none) { hudView.remove(animated: false) }
				}
			} else {
				// Hide on tap
				blockingSplashContainerView.addTapHandler(feedback: .none) { hudView.remove(animated: false) }
			}

            hudView.alpha = 0.0

            UIView.animate(
                withDuration: animated ? 0.25 : 0.0,
                animations: {
                    hudView.alpha = 1.0
                },
                completion: { [weak hudView] _ in
                    if let timeout = timeout {
                        delay(timeout) {
                            hudView?.remove(animated: animated, onRemove: onRemove)
                        }
                    }
                }
            )
        }

        if let existingHUD = Self.find(on: view) {
            existingHUD.remove { action() }
        } else {
            action()
        }

        return hudView
    }

    func remove(animated: Bool = true, onRemove: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: animated ? 0.25 : 0.0,
            animations: { [weak self] in
                self?.alpha = 0.0
            },
            completion: { [weak self] _ in
				let blockingSplashContainerView = self?.superview
				blockingSplashContainerView?.removeFromSuperview()

                onRemove?()
            }
        )
    }

    static func find(on view: UIView) -> HUD? {
		view.firstSubviewOf(type: HUD.self)
    }

	enum Mode {
		case spinner(needsPad: Bool)
		case success(needsPad: Bool)
		case failure(needsPad: Bool)

		var view: HUD {
			switch self {
				case .spinner(let needsPad):
					let pad = self.makePad(visible: needsPad)

					pad.make(.size, .equal, [75, 75])

					let loader = SpinningGlobeView()
					pad.addSubview(loader)

					loader.make(.size, .equal, [44, 44])
					loader.make(.center, .equalToSuperview)

					loader.startAnimating()

					return pad

				case .success(let needsPad):
					let pad = self.makePad(visible: needsPad)
					pad.make(.size, .equal, [75, 75])

					let imageView = UIImageView(image: UIImage(named: "activityhud_success"))
					imageView.tintColorThemed = Palette.shared.accentLoader

					pad.addSubview(imageView)
					imageView.make(.center, .equalToSuperview)

					imageView.transform = CGAffineTransformMakeScale(0.33, 0.33)
					UIView.animate(withDuration: 2, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0) {
						imageView.transform = CGAffineTransformIdentity
					}

					return pad

				case .failure(let needsPad):
					let pad = self.makePad(visible: needsPad)

					let imageContainer = UIView { view in
						let image = UIImageView { (imageView: UIImageView) in
							imageView.image = UIImage(named: "activityhud_failure")
							imageView.tintColorThemed = Palette.shared.accentLoader
						}

						view.addSubview(image)
						image.make(.size, .equal, [32, 32])
						image.make([.height, .centerX, .centerY], .equalToSuperview)
					}

					let vStack = UIStackView.vertical(
						imageContainer,
						.vSpacer(10),
						UILabel { (label: UILabel) in
							label.text = "form.server.error.short".localized
							label.textColorThemed = Palette.shared.accentLoader
							label.fontThemed = Palette.shared.primeFont.with(size: 15)
							label.make(resist: 1000, axis: .horizontal)
						}
					)

					pad.addSubview(vStack)
					vStack.make(.edges, .equalToSuperview, [21, 10, -15, -10])

					return pad
			}
		}

		private func makePad(visible: Bool) -> HUD {
			let pad = HUD()
			pad.backgroundColorThemed = Palette.shared.gray5

			pad.layer.cornerRadius = 10
			pad.layer.borderWidth = 1
			pad.layer.borderColorThemed = Palette.shared.gray4

			pad.dropShadow(offset: CGSize(width: 0, height: 5), radius: 5, color: Palette.shared.gray0, opacity: 0.08)

			if !visible {
				pad.hidePad()
			}

			return pad
		}
	}
}

extension HUD {
	private func hidePad() {
		self.backgroundColorThemed = Palette.shared.clear

		self.layer.cornerRadius = 0
		self.layer.borderWidth = 0
		self.layer.borderColorThemed = Palette.shared.clear

		self.dropShadow(color: Palette.shared.clear)
	}
}
