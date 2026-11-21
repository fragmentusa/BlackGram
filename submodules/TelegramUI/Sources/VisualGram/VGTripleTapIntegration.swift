import UIKit

// MARK: - Triple Tap Recognizer
// Вставить в файл TabBarController форка telegram-ios
// Обычно: TelegramUI/Sources/TabBarController.swift

/*
 КАК ИНТЕГРИРОВАТЬ:
 
 1. Найти в проекте файл где объявлен TabBarController или ChatListController
 2. Добавить extension ниже
 3. В viewDidLoad контроллера чатов добавить:
    setupTripleTap()
*/

extension UIViewController {
    
    /// Вызови в viewDidLoad контроллера списка чатов
    func setupVisualGramTripleTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTripleTap))
        tap.numberOfTapsRequired = 3
        // Добавить на кнопку чатов в tab bar или на сам view
        view.addGestureRecognizer(tap)
    }
    
    @objc func handleTripleTap() {
        openVisualGram()
    }
    
    func openVisualGram() {
        let vc = VGMenuViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        nav.navigationBar.barStyle = .black
        nav.navigationBar.tintColor = .white
        nav.overrideUserInterfaceStyle = .dark
        present(nav, animated: true)
    }
}

// MARK: - Tab Bar Item Triple Tap
// Альтернативный способ — перехватить тройной тап на tab bar item

class VGTabBarController: UITabBarController {
    
    private var tapCounts: [Int: Int] = [:]
    private var tapTimers: [Int: Timer] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
}

extension VGTabBarController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let index = viewControllers?.firstIndex(of: viewController) ?? -1
        
        // Index 0 = Chats tab
        if index == 0 {
            tapCounts[index, default: 0] += 1
            
            tapTimers[index]?.invalidate()
            tapTimers[index] = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                self?.tapCounts[index] = 0
            }
            
            if tapCounts[index] == 3 {
                tapCounts[index] = 0
                tapTimers[index]?.invalidate()
                viewController.openVisualGram()
                return false
            }
        }
        
        return true
    }
}

// MARK: - Stars Balance Page Integration
// Показывает страницу Stars с визуальным балансом

class VGStarsBalanceViewController: UIViewController {
    
    private let manager = VisualGramManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
    }
    
    private func setupUI() {
        // Star field background
        let starField = makeStarField()
        view.addSubview(starField)
        
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 60),
            stack.centerXAnchor.constraint(equalTo: scroll.centerXAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -40)
        ])
        
        // Big star
        let starLabel = UILabel()
        starLabel.text = "⭐"
        starLabel.font = .systemFont(ofSize: 100)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Telegram Stars"
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.textColor = .white
        
        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Buy Stars to unlock content and\nservices in mini apps on Telegram."
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = .systemGray
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        // Balance card
        let balanceCard = makeBalanceCard()
        balanceCard.widthAnchor.constraint(equalToConstant: view.frame.width - 32).isActive = true
        balanceCard.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
        // Earn stars section
        let earnCard = makeEarnCard()
        earnCard.widthAnchor.constraint(equalToConstant: view.frame.width - 32).isActive = true
        
        // Transactions segment
        let segControl = UISegmentedControl(items: ["All Transactions", "Incoming", "Outgoing"])
        segControl.selectedSegmentIndex = 0
        segControl.widthAnchor.constraint(equalToConstant: view.frame.width - 32).isActive = true
        
        // Top up transaction row
        let txRow = makeTxRow()
        txRow.widthAnchor.constraint(equalToConstant: view.frame.width - 32).isActive = true
        
        [starLabel, titleLabel, subtitleLabel, balanceCard, earnCard, segControl, txRow].forEach {
            stack.addArrangedSubview($0)
        }
    }
    
    private func makeBalanceCard() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(white: 0.15, alpha: 1)
        card.layer.cornerRadius = 16
        
        let profile = manager.getCurrentProfile()
        
        let balanceLabel = UILabel()
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        balanceLabel.text = "⭐ \(formatter.string(from: NSNumber(value: profile.starsBalance)) ?? "\(profile.starsBalance)")"
        balanceLabel.font = .boldSystemFont(ofSize: 36)
        balanceLabel.textColor = .white
        
        let yourBalance = UILabel()
        yourBalance.text = "your balance"
        yourBalance.font = .systemFont(ofSize: 14)
        yourBalance.textColor = .systemGray
        
        let buyBtn = UIButton(type: .system)
        buyBtn.setTitle("⊕ Buy More Stars", for: .normal)
        buyBtn.setTitleColor(.white, for: .normal)
        buyBtn.backgroundColor = .systemBlue
        buyBtn.layer.cornerRadius = 12
        buyBtn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        let giftBtn = UIButton(type: .system)
        giftBtn.setTitle("👥 Gift Stars to Friends", for: .normal)
        giftBtn.setTitleColor(.systemBlue, for: .normal)
        
        let stack = UIStackView(arrangedSubviews: [balanceLabel, yourBalance, buyBtn, giftBtn])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            buyBtn.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
        
        return card
    }
    
    private func makeEarnCard() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(white: 0.15, alpha: 1)
        card.layer.cornerRadius = 16
        
        let icon = UILabel()
        icon.text = "🌟"
        icon.font = .systemFont(ofSize: 32)
        
        let titleLabel = UILabel()
        titleLabel.text = "Earn Stars"
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.textColor = .white
        
        let desc = UILabel()
        desc.text = "Distribute links to mini apps and earn\na share of their revenue in Stars."
        desc.font = .systemFont(ofSize: 13)
        desc.textColor = .systemGray
        desc.numberOfLines = 0
        
        let arrow = UILabel()
        arrow.text = "›"
        arrow.textColor = .systemGray
        arrow.font = .systemFont(ofSize: 20)
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, desc])
        textStack.axis = .vertical
        textStack.spacing = 4
        
        let hStack = UIStackView(arrangedSubviews: [icon, textStack, arrow])
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hStack)
        
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        
        return card
    }
    
    private func makeTxRow() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(white: 0.15, alpha: 1)
        card.layer.cornerRadius = 12
        
        let icon = UILabel()
        icon.text = "⭐"
        icon.font = .systemFont(ofSize: 28)
        icon.backgroundColor = .systemBlue
        icon.textAlignment = .center
        icon.layer.cornerRadius = 20
        icon.clipsToBounds = true
        icon.widthAnchor.constraint(equalToConstant: 40).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let title = UILabel()
        title.text = "Stars Top-Up"
        title.textColor = .white
        title.font = .boldSystemFont(ofSize: 15)
        
        let profile = manager.getCurrentProfile()
        let subtitle = UILabel()
        subtitle.text = "via Premium Bot"
        subtitle.textColor = .systemGray
        subtitle.font = .systemFont(ofSize: 13)
        
        let amount = UILabel()
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        amount.text = "+\(formatter.string(from: NSNumber(value: profile.starsBalance)) ?? "\(profile.starsBalance)") ⭐"
        amount.textColor = .systemGreen
        amount.font = .boldSystemFont(ofSize: 15)
        
        let date = UILabel()
        date.text = "Nov 21 18:27"
        date.textColor = .systemGray
        date.font = .systemFont(ofSize: 12)
        
        let leftStack = UIStackView(arrangedSubviews: [title, subtitle])
        leftStack.axis = .vertical
        leftStack.spacing = 2
        
        let rightStack = UIStackView(arrangedSubviews: [amount, date])
        rightStack.axis = .vertical
        rightStack.spacing = 2
        rightStack.alignment = .trailing
        
        let hStack = UIStackView(arrangedSubviews: [icon, leftStack, rightStack])
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(hStack)
        
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            hStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            hStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            hStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        
        return card
    }
    
    private func makeStarField() -> UIView {
        let container = UIView(frame: view.bounds)
        container.backgroundColor = .clear
        
        for _ in 0..<40 {
            let star = UILabel()
            star.text = ["⭐", "✦", "·", "+"].randomElement()
            star.font = .systemFont(ofSize: CGFloat.random(in: 8...20))
            star.textColor = UIColor(red: 1, green: 0.8, blue: 0, alpha: CGFloat.random(in: 0.2...0.6))
            star.frame = CGRect(
                x: CGFloat.random(in: 0...view.frame.width),
                y: CGFloat.random(in: 0...600),
                width: 24, height: 24
            )
            container.addSubview(star)
        }
        
        return container
    }
}
