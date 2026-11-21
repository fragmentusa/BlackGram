import UIKit

// MARK: - Send Gift Flow

class VGSendGiftViewController: UIViewController {
    
    private let manager = VisualGramManager.shared
    private var tableView: UITableView!
    private var selectedGift: VGGift?
    private var recipientUsername: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Отправить подарок"
        view.backgroundColor = .black
        setupUI()
    }
    
    private func setupUI() {
        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.backgroundColor = .black
        tableView.delegate = self
        tableView.dataSource = self
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
    }
    
    var myGifts: [VGGift] { manager.getCurrentProfile().gifts }
}

extension VGSendGiftViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int { 2 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : myGifts.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Получатель" : "Выбери подарок"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.backgroundColor = UIColor(white: 0.12, alpha: 1)
        cell.textLabel?.textColor = .white
        
        if indexPath.section == 0 {
            cell.textLabel?.text = recipientUsername ?? "Выбрать пользователя"
            cell.textLabel?.textColor = recipientUsername == nil ? .systemGray : .white
            cell.accessoryType = .disclosureIndicator
        } else {
            let gift = myGifts[indexPath.row]
            cell.textLabel?.text = gift.emoji + " " + gift.displayName
            cell.detailTextLabel?.text = gift.isUpgraded ? "NFT" : "\(gift.value) ⭐"
            cell.detailTextLabel?.textColor = .systemGray
            if selectedGift?.id == gift.id {
                cell.accessoryType = .checkmark
                cell.tintColor = .systemBlue
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            showUserPicker()
        } else {
            selectedGift = myGifts[indexPath.row]
            tableView.reloadData()
            if recipientUsername != nil {
                confirmSend()
            }
        }
    }
    
    private func showUserPicker() {
        let alert = UIAlertController(title: "Получатель", message: "Введите @username", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "@username"
            tf.autocapitalizationType = .none
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Выбрать", style: .default) { [weak self] _ in
            self?.recipientUsername = alert.textFields?.first?.text
            self?.tableView.reloadData()
            if self?.selectedGift != nil {
                self?.confirmSend()
            }
        })
        present(alert, animated: true)
    }
    
    private func confirmSend() {
        guard let gift = selectedGift, let recipient = recipientUsername else { return }
        
        let alert = UIAlertController(
            title: "Отправить подарок?",
            message: "\(gift.emoji) \(gift.displayName)\nПолучатель: \(recipient)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Отправить", style: .default) { [weak self] _ in
            self?.sendGift(gift: gift, to: recipient)
        })
        present(alert, animated: true)
    }
    
    private func sendGift(gift: VGGift, to recipient: String) {
        // Remove from my gifts
        manager.updateCurrentProfile { profile in
            profile.gifts.removeAll { $0.id == gift.id }
        }
        
        // Add transaction
        manager.addTransaction(VGTransaction(
            id: UUID().uuidString,
            type: .sent,
            giftName: gift.displayName,
            giftEmoji: gift.emoji,
            date: Date(),
            fromProfile: manager.getCurrentProfileId(),
            toProfile: recipient,
            amount: gift.value,
            currency: "stars"
        ))
        
        // Show sent animation
        showSentAnimation(gift: gift, recipient: recipient)
    }
    
    private func showSentAnimation(gift: VGGift, recipient: String) {
        let vc = VGGiftSentViewController(gift: gift, recipient: recipient)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                vc.dismiss(animated: true) {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}

// MARK: - Gift Sent Animation

class VGGiftSentViewController: UIViewController {
    
    let gift: VGGift
    let recipient: String
    
    init(gift: VGGift, recipient: String) {
        self.gift = gift
        self.recipient = recipient
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.05, alpha: 0.95)
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        let emojiLabel = UILabel()
        emojiLabel.text = gift.emoji
        emojiLabel.font = .systemFont(ofSize: 100)
        
        let titleLabel = UILabel()
        titleLabel.text = "Подарок отправлен!"
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 24)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "\(gift.displayName) → \(recipient)"
        subtitleLabel.textColor = .systemGray
        subtitleLabel.font = .systemFont(ofSize: 16)
        
        [emojiLabel, titleLabel, subtitleLabel].forEach { stack.addArrangedSubview($0) }
        
        // Confetti
        startConfetti()
        
        // Animate emoji
        emojiLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
            emojiLabel.transform = .identity
        }
    }
    
    private func startConfetti() {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.bounds.width, height: 1)
        
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemYellow, .systemPurple]
        emitter.emitterCells = colors.map { color in
            let cell = CAEmitterCell()
            cell.birthRate = 10
            cell.lifetime = 4
            cell.velocity = 250
            cell.velocityRange = 100
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 2
            cell.scaleRange = 0.5
            cell.scaleSpeed = -0.05
            cell.color = color.cgColor
            cell.scale = 0.5
            return cell
        }
        view.layer.addSublayer(emitter)
    }
}

// MARK: - Profile Gifts Tab (показывается в профиле TG)

class VGProfileGiftsTabViewController: UIViewController {
    
    private let manager = VisualGramManager.shared
    private var collectionView: UICollectionView!
    private var sendBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    private func setupUI() {
        // Tabs: Posts | Archived Posts | Gifts
        let tabStack = UIStackView()
        tabStack.axis = .horizontal
        tabStack.distribution = .fillEqually
        tabStack.spacing = 0
        tabStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabStack)
        
        let tabNames = ["Posts", "Archived Posts", "Gifts 🎁"]
        for (i, name) in tabNames.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(name, for: .normal)
            btn.setTitleColor(i == 2 ? .white : .systemGray, for: .normal)
            btn.backgroundColor = i == 2 ? UIColor(white: 0.2, alpha: 1) : .clear
            btn.layer.cornerRadius = 16
            btn.titleLabel?.font = .systemFont(ofSize: 14, weight: i == 2 ? .semibold : .regular)
            tabStack.addArrangedSubview(btn)
        }
        
        // Collection
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width - 32, height: 200)
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 80, right: 16)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .black
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(VGProfileGiftCell.self, forCellWithReuseIdentifier: "giftCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        // Send button
        sendBtn = UIButton(type: .system)
        sendBtn.setTitle("Send Gifts to Friends", for: .normal)
        sendBtn.setTitleColor(.white, for: .normal)
        sendBtn.backgroundColor = .systemBlue
        sendBtn.layer.cornerRadius = 16
        sendBtn.titleLabel?.font = .boldSystemFont(ofSize: 16)
        sendBtn.addTarget(self, action: #selector(sendGifts), for: .touchUpInside)
        sendBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendBtn)
        
        NSLayoutConstraint.activate([
            tabStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            tabStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tabStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tabStack.heightAnchor.constraint(equalToConstant: 36),
            
            collectionView.topAnchor.constraint(equalTo: tabStack.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            sendBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            sendBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sendBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sendBtn.heightAnchor.constraint(equalToConstant: 52)
        ])
    }
    
    @objc private func sendGifts() {
        let vc = VGSendGiftViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    var gifts: [VGGift] { manager.getCurrentProfile().gifts }
}

extension VGProfileGiftsTabViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "giftCell", for: indexPath) as! VGProfileGiftCell
        cell.configure(with: gifts[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let gift = gifts[indexPath.item]
        showGiftDetail(gift: gift)
    }
    
    private func showGiftDetail(gift: VGGift) {
        if gift.isUpgraded {
            let vc = VGNFTGiftDetailViewController(gift: gift)
            vc.modalPresentationStyle = .pageSheet
            present(vc, animated: true)
        } else {
            let vc = VGSavedGiftDetailViewController(gift: gift)
            vc.modalPresentationStyle = .pageSheet
            present(vc, animated: true)
        }
    }
}

// MARK: - Profile Gift Cell (в профиле)

class VGProfileGiftCell: UICollectionViewCell {
    
    private let emojiLabel = UILabel()
    private let badgeLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = UIColor(white: 0.12, alpha: 1)
        contentView.layer.cornerRadius = 16
        
        emojiLabel.font = .systemFont(ofSize: 80)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        
        badgeLabel.font = .boldSystemFont(ofSize: 12)
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = UIColor(white: 0.3, alpha: 0.9)
        badgeLabel.layer.cornerRadius = 8
        badgeLabel.clipsToBounds = true
        badgeLabel.textAlignment = .center
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(emojiLabel)
        contentView.addSubview(badgeLabel)
        
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            badgeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            badgeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            badgeLabel.widthAnchor.constraint(equalToConstant: 70),
            badgeLabel.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with gift: VGGift) {
        emojiLabel.text = gift.emoji
        if let num = gift.uniqueNumber {
            badgeLabel.text = "1 of \(gift.totalAvailability / 1000)K"
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
    }
}

// MARK: - Saved Gift Detail (не улучшенный)

class VGSavedGiftDetailViewController: UIViewController {
    
    let gift: VGGift
    
    init(gift: VGGift) {
        self.gift = gift
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.1, alpha: 1)
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeBtn.tintColor = .systemGray
        closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeBtn)
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        let emoji = UILabel()
        emoji.text = gift.emoji
        emoji.font = .systemFont(ofSize: 80)
        
        let title = UILabel()
        title.text = "Saved Gift"
        title.font = .boldSystemFont(ofSize: 24)
        title.textColor = .white
        
        let subtitle = UILabel()
        subtitle.text = "Upgrade this gift to turn it into a unique collectible."
        subtitle.font = .systemFont(ofSize: 15)
        subtitle.textColor = .systemGray
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy 'at' HH:mm"
        
        let infoView = makeInfoTable(rows: [
            ("Date", formatter.string(from: gift.date)),
            ("Value", "\(gift.value) ⭐"),
            ("Availability", "0 of \(gift.totalAvailability) left"),
            ("Status", "Non-Unique")
        ])
        infoView.widthAnchor.constraint(equalToConstant: 300).isActive = true
        
        let hideBtn = UIButton(type: .system)
        hideBtn.setTitle("This gift is visible.  Hide from Profile >", for: .normal)
        hideBtn.setTitleColor(.systemBlue, for: .normal)
        
        let upgradeBtn = UIButton(type: .system)
        upgradeBtn.setTitle("Upgrade ⬆", for: .normal)
        upgradeBtn.setTitleColor(.white, for: .normal)
        upgradeBtn.backgroundColor = .systemBlue
        upgradeBtn.layer.cornerRadius = 14
        upgradeBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        upgradeBtn.widthAnchor.constraint(equalToConstant: 300).isActive = true
        upgradeBtn.addTarget(self, action: #selector(upgrade), for: .touchUpInside)
        
        [emoji, title, subtitle, infoView, hideBtn, upgradeBtn].forEach { stack.addArrangedSubview($0) }
        
        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func makeInfoTable(rows: [(String, String)]) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(white: 0.15, alpha: 1)
        container.layer.cornerRadius = 12
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        for (label, value) in rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fillEqually
            
            let l = UILabel()
            l.text = label
            l.textColor = .white
            l.font = .systemFont(ofSize: 14)
            l.heightAnchor.constraint(equalToConstant: 36).isActive = true
            
            let v = UILabel()
            v.text = value
            v.textColor = .systemGray
            v.font = .systemFont(ofSize: 14)
            v.textAlignment = .right
            
            row.addArrangedSubview(l)
            row.addArrangedSubview(v)
            stack.addArrangedSubview(row)
        }
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        return container
    }
    
    @objc private func upgrade() {
        VisualGramManager.shared.upgradeGift(id: gift.id)
        dismiss(animated: true)
    }
    
    @objc private func close() { dismiss(animated: true) }
}

// MARK: - NFT Gift Detail (улучшенный)

class VGNFTGiftDetailViewController: UIViewController {
    
    let gift: VGGift
    
    init(gift: VGGift) {
        self.gift = gift
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        // Gradient background
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.2, green: 0.6, blue: 0.5, alpha: 1).cgColor,
            UIColor(red: 0.5, green: 0.2, blue: 0.7, alpha: 1).cgColor
        ]
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
        
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeBtn.tintColor = UIColor.white.withAlphaComponent(0.7)
        closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeBtn)
        
        let moreBtn = UIButton(type: .system)
        moreBtn.setImage(UIImage(systemName: "ellipsis.circle.fill"), for: .normal)
        moreBtn.tintColor = UIColor.white.withAlphaComponent(0.7)
        moreBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(moreBtn)
        
        // Emoji big
        let emojiLabel = UILabel()
        emojiLabel.text = gift.emoji
        emojiLabel.font = .systemFont(ofSize: 120)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emojiLabel)
        
        // Title
        let titleLabel = UILabel()
        let numStr = gift.uniqueNumber != nil ? " #\(gift.uniqueNumber!)" : ""
        titleLabel.text = gift.name + numStr
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Model subtitle
        let modelLabel = UILabel()
        modelLabel.text = gift.model ?? "Unique"
        modelLabel.font = .systemFont(ofSize: 16)
        modelLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        modelLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(modelLabel)
        
        // Action buttons
        let actionsStack = UIStackView()
        actionsStack.axis = .horizontal
        actionsStack.distribution = .fillEqually
        actionsStack.spacing = 12
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actionsStack)
        
        for (icon, name) in [("arrow.right.circle.fill", "transfer"), ("crown.fill", "wear"), ("tag.fill", "sell")] {
            let btn = makeActionButton(icon: icon, label: name)
            actionsStack.addArrangedSubview(btn)
        }
        
        // Info table
        let infoView = makeInfoTable()
        infoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoView)
        
        // Hide / Skip
        let hideBtn = UIButton(type: .system)
        hideBtn.setTitle("This gift is visible.  Hide from Profile >", for: .normal)
        hideBtn.setTitleColor(.systemBlue, for: .normal)
        hideBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hideBtn)
        
        let skipBtn = UIButton(type: .system)
        skipBtn.setTitle("Skip", for: .normal)
        skipBtn.setTitleColor(.white, for: .normal)
        skipBtn.backgroundColor = .systemBlue
        skipBtn.layer.cornerRadius = 14
        skipBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        skipBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skipBtn)
        
        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            moreBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            moreBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            emojiLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            emojiLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            modelLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            modelLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            actionsStack.topAnchor.constraint(equalTo: modelLabel.bottomAnchor, constant: 20),
            actionsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionsStack.heightAnchor.constraint(equalToConstant: 70),
            
            infoView.topAnchor.constraint(equalTo: actionsStack.bottomAnchor, constant: 16),
            infoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            hideBtn.topAnchor.constraint(equalTo: infoView.bottomAnchor, constant: 12),
            hideBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            skipBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            skipBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            skipBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            skipBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func makeActionButton(icon: String, label: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        container.layer.cornerRadius = 12
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        
        let labelView = UILabel()
        labelView.text = label
        labelView.textColor = .white
        labelView.font = .systemFont(ofSize: 12)
        labelView.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [iconView, labelView])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        return container
    }
    
    private func makeInfoTable() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(white: 0.1, alpha: 0.5)
        container.layer.cornerRadius = 12
        
        let profile = VisualGramManager.shared.getCurrentProfile()
        
        let rows: [(String, String)] = [
            ("Owner", profile.name),
            ("Model", gift.model ?? "Unique"),
            ("Symbol", gift.symbol ?? "—"),
            ("Backdrop", gift.backdrop ?? "—"),
            ("Availability", "1/\(gift.totalAvailability) issued")
        ]
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        for (label, value) in rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fillEqually
            
            let l = UILabel()
            l.text = label
            l.textColor = .white
            l.font = .systemFont(ofSize: 14)
            l.heightAnchor.constraint(equalToConstant: 36).isActive = true
            
            let v = UILabel()
            v.text = value
            v.textColor = UIColor.white.withAlphaComponent(0.7)
            v.font = .systemFont(ofSize: 14)
            v.textAlignment = .right
            
            row.addArrangedSubview(l)
            row.addArrangedSubview(v)
            stack.addArrangedSubview(row)
        }
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        
        return container
    }
    
    @objc private func close() { dismiss(animated: true) }
}
