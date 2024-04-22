import Combine
import UIKit

public protocol BaseCoordinatorType: AnyObject {
    associatedtype CoordinationResult
    
    var presenter: UIViewController? { get }
    
	func start()
    func finish(_ result: CoordinationResult)
}

public protocol PresentableCoordinatorType: BaseCoordinatorType, Presentable {
    var childCoordinators: [String: Any] { get set }
}

open class PresentableCoordinator<CoordinationResult>: UIResponder, PresentableCoordinatorType {
    public var childCoordinators: [String: Any] = [:]
    public var onFinish: ((CoordinationResult) -> Void)?
    private var cleanupFromParentBlock: (() -> Void)?
    public var presenter: UIViewController?
    private let identifier = UUID()
    
    override public init() {
        super.init()
    }
    
    open func start() { start(with: nil) }
	open func start(with link: String?) {}
    
    open func finish(_ result: CoordinationResult) {
        onFinish?(result)
        cleanupFromParentBlock?()
    }
    
    // swiftlint:disable:next unavailable_function
	open func toPresentable() -> UIViewController {
		fatalError("Must override toPresentable()")
	}
}

public protocol CoordinatorBaseType: PresentableCoordinatorType {
    var identifier: String { get }
	var router: Router { get }
}

typealias CoordinatorType = CoordinatorBaseType & NeedsDependency

open class Coordinator<CoordinationResult>: PresentableCoordinator<CoordinationResult>, CoordinatorType {
    public var dependencies: AppDependency {
        didSet {
            updateChildCoordinatorDependencies()
        }
    }
    
    public var identifier: String = UUID().uuidString
    private var cleanupFromParentBlock: (() -> Void)?
    private var cancellables = Set<AnyCancellable>()
	open var router: Router
	
    public init(router: Router, dependencies: AppDependency, presenter: UIViewController? = nil) {
		self.router = router
        self.dependencies = dependencies
        super.init()
        self.presenter = presenter
	}

    override open func finish(_ result: CoordinationResult) {
        onFinish?(result)
        cleanupFromParentBlock?()
    }
	
	public func addChild<T>(_ coordinator: Coordinator<T>) {
        coordinator.cleanupFromParentBlock = { [weak self, weak coordinator] in
            self?.removeChild(coordinator)
        }
        childCoordinators[coordinator.identifier] = coordinator
	}
	
	public func removeChild<T>(_ coordinator: Coordinator<T>?) {
        guard let coordinator = coordinator else { return }
        
        childCoordinators.removeValue(forKey: coordinator.identifier)
	}
    
    override open func toPresentable() -> UIViewController {
        router.toPresentable()
    }
}
