import UIKit
import SnapKit

infix operator ~/ : MultiplicationPrecedence
public func ~/ (lhs: Int, rhs: Int) -> CGFloat {
	CGFloat(lhs) / CGFloat(rhs)
}

final class SandboxViewController: UITableViewController {
	private lazy var rows: [(title: String, viewController: UIViewController)] = [
		bannerEntry,
        taskEntry,

		("Множественный календарь", FSCalendarRangeSelectionViewController(monthCount: 24) { _ in}),
		("Единичный календарь", FSCalendarRangeSelectionViewController(monthCount: 24, isMultipleSelectionAllowed: false, selectedDates: Date().asClosedRange) { _ in})
	]

    private var bannerEntry: (title: String, viewController: UIViewController) {
        ("Баннеры", UIViewController(title: "Баннеры", view: UIView { (view: UIView) in
            view.backgroundColor = .gray
            let triplet = UIView { (view: UIView) in
                view.clipsToBounds = true

                let first = UIView { view in
                    view.backgroundColor = .red
                    view.layer.cornerRadius = 10
                }

                let second = UIView { view in
                    view.backgroundColor = .green
                    view.layer.cornerRadius = 10
                }

                let third = UIView { view in
                    view.backgroundColor = .blue
                    view.layer.cornerRadius = 10
                }

                let secondTopSpacer = UIView()
                let secondTrailingSpacer = UIView()
                let thirdTopSpacer = UIView()

                view.addSubviews(secondTopSpacer, secondTrailingSpacer, thirdTopSpacer)
                view.addSubviews(first, second, third)

                first.make([.top, .leading], .equalToSuperview)
                first.make(.height, .equal, to: 125 ~/ 138, of: view)
                first.make(ratio: 213 ~/ 125)

                second.make(.height, .equal, to: 77 ~/ 138, of: view)
                second.make(ratio: 141 ~/ 77)
                second.make(.bottom, .equalToSuperview)
                second.place(under: secondTopSpacer)
                secondTopSpacer.make(.edges(except: .bottom), .equalToSuperview)
                secondTopSpacer.make(.height, .equal, to: 61 ~/ 138, of: view)
                secondTrailingSpacer.place(behind: second)
                secondTrailingSpacer.make(.edges(except: .leading), .equalToSuperview)
                secondTrailingSpacer.make(.width, .equal, to: 55 ~/ 345, of: view)

                third.make(.trailing, .equalToSuperview)
                third.make(.height, .equal, to: 77 ~/ 138, of: view)
                third.make(ratio: 1)

                third.place(under: thirdTopSpacer)
                thirdTopSpacer.make(.edges(except: .bottom), .equalToSuperview)
                thirdTopSpacer.make(.height, .equal, to: 23 ~/ 138, of: view)
            }

            triplet.backgroundColor = .white
            view.addSubview(triplet)
            triplet.make(.center, .equalToSuperview)
            triplet.make(.width, .equalToSuperview)
            triplet.make(ratio: 345 ~/ 138)

            triplet.addTapHandler {
                AeroticketsEndpoint.shared.getAerotickets().promise.done {
                    print($0)
                }.catch { error in
                    print(error)
                }
            }
        }))
    }

    private var taskEntry: (title: String, viewController: UIViewController) {
        ("Таски", UIViewController(title: "Таски", view: {
            let view = UIView()
            view.backgroundColor = .gray

            let stack = ScrollableStack(.vertical)

            view.addSubview(stack)
            stack.snp.makeConstraints { make in
                make.edges.equalTo(view.safeAreaLayoutGuide)
            }

            func task(
                id: Int = Int.random(in: 1...1_000),
                completionDate: Date? = nil,
                customizationHandler: (Task) -> Task = { $0 }
            ) -> Task {
                let task = Task(
                    completed: completionDate != nil, completedAt: 0, completedAtDate: completionDate,
                    customerID: 0, id: 0, orders: [], reserved: false, taskID: id,
                    deleted: false, updatedAt: Date.distantPast, unreadCount: 0,
                    taskDate: nil, subtitle: "TEST Subtitle", startServiceDateFormatted: nil,
                    startServiceDateDay: nil, attachedFiles: []
                )
                return customizationHandler(task)
            }

            for completed in [true, false] {
                for showsFeedback in [true, false] {
                    for showsLatestMessage in [true, false] {
                        for lastMessageExists in [true, false] {
                            for draftExists in [true, false] {
                                var task = task()
                                task.completed = completed
                                task.lastChatMessage = nil
                                task.latestDraft = nil
                                if lastMessageExists {
                                    task.lastChatMessage = .init(guid: UUID().uuidString, clientId: "123", channelId: UUID().uuidString, source: "TELEGRAM", timestamp: Date.distantPast, status: .seen, type: .text, content: "Message Message Message Message Message Message")
                                }
                                if draftExists {
                                    task.latestDraft = .init(guid: UUID().uuidString, clientId: "123", channelId: UUID().uuidString, source: "TELEGRAM", timestamp: Date.distantPast, status: .draft, type: .text, content: "Draft Draft Draft Draft Draft Draft Draft Draft Draft Draft Draft")
                                }

                                let model = RequestListItemViewModel(task: task, showsLatestMessage: showsLatestMessage, showsPromoCategories: false, showsFeedback: showsFeedback, taskTypeImageLeading: 10, taskTypeImageSize: CGSize(width: 44, height: 44), routesToTaskDetails: false, promoCategories: [:], roundsCorners: true)

                                let item = RequestListItemView()

                                let label = UILabel()
                                label.alpha = 0.5
                                label.backgroundColor = .white
                                label.textColor = .red
                                label.adjustsFontSizeToFitWidth = true
                                label.addTapHandler {
                                    label.isHidden = true
                                }

                                label.text = "Comp: \(completed), feed: \(showsFeedback), mess: \(showsLatestMessage), messEx: \(lastMessageExists), drft: \(draftExists)"

                                item.addSubviews(label)
                                label.snp.makeConstraints { make in
                                    make.center.horizontalEdges.equalToSuperview()
                                }

                                item.setup(with: model, onOrderViewTap: nil, onPromoCategoryTap: nil)

                                stack.addArrangedSubview(item)
                                stack.addArrangedSubview(.vSpacer(20))
                            }
                        }
                    }
                }
            }

            stack.addArrangedSubview(.vSpacer(growable: 0))

            return view
        }()))
    }

	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.backgroundColorThemed = Palette.shared.gray5

		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
	}

	override func numberOfSections(in tableView: UITableView) -> Int { 1 }

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		self.rows.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		cell.textLabel?.text = rows[indexPath.row].title
		cell.accessoryType = .disclosureIndicator
		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let viewController = rows[indexPath.row].viewController

		self.navigationController?.pushViewController(viewController, animated: true)
	}
}
