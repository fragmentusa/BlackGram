import UIKit

// MARK: - Gifts Menu

class VGGiftsViewController: UIViewController {
    
    private let manager = VisualGramManager.shared
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Подарки"
        view.backgroundColor = .black
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.backgroundColor = .black
        tableView.delegate = self
        tableView.dataSource = self
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
    }
    
    enum Row {
        case profileSelect, back
        case addNFT, addGift
        case sendNFT, sendGift
        case myGifts, history
    }
    
    let sections: [[Row]] = [
        [.profileSelect, .back],
        [.addNFT, .addGift],
        [.sendNFT, .sendGift],
        [.myGifts, .history]
    ]
}

extension VGGiftsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.backgroundColor = UIColor(white: 0.12, alpha: 1)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.textColor = .white
        
        switch sections[indexPath.section][indexPath.row] {
        case .profileSelect:
            cell.textLabel?.text = "Выбор профиля"
            cell.detailTextLabel?.text = manager.getCurrentProfile().name
            cell.detailTextLabel?.textColor = .systemGray
        case .back: cell.textLabel?.text = "Назад"
        case .addNFT: cell.textLabel?.text = "Добавить NFT"
        case .addGift: cell.textLabel?.text = "Добавить обычный подарок"
        case .sendNFT: cell.textLabel?.text = "Отправить NFT"
        case .sendGift: cell.textLabel?.text = "Отправить обычный подарок"
        case .myGifts: cell.textLabel?.text = "Мои подарки"
        case .history: cell.textLabel?.text = "История операций"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch sections[indexPath.section][indexPath.row] {
        case .back:
            navigationController?.popViewController(animated: true)
        case .addNFT:
            showNFTInput()
        case .addGift:
            let vc = VGGiftShopViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .myGifts:
            let vc = VGMyGiftsViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .history:
            let vc = VGHistoryViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .sendGift:
            let vc = VGGiftShopViewController()
            vc.isSendMode = true
            navigationController?.pushViewController(vc, animated: true)
        default: break
        }
    }
    
    private func showNFTInput() {
        let alert = UIAlertController(title: "Добавить NFT-подарки", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Ссылки или slug через пробел..." }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            let slugs = text.components(separatedBy: " ").filter { !$0.isEmpty }
            for slug in slugs {
                let gift = VGGift(
                    id: UUID().uuidString,
                    name: slug,
                    emoji: "🖼",
                    value: 0,
                    date: Date(),
                    isUpgraded: true,
                    uniqueNumber: Int.random(in: 1...999999),
                    model: nil, backdrop: nil, symbol: nil,
                    availability: 1,
                    totalAvailability: 1,
                    isNFT: true,
                    slugOrLink: slug
                )
                self?.manager.addGift(gift)
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - Gift Shop

class VGGiftShopViewController: UIViewController {
    
    var isSendMode = false
    private let manager = VisualGramManager.shared
    private var collectionView: UICollectionView!
    private var segmentControl: UISegmentedControl!
    private var balanceLabel: UILabel!
    private var catalog: [VGGiftCatalogItem] = []
    private var showCollectibles = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = isSendMode ? "Send a Gift" : "Buy a Gift"
        view.backgroundColor = .black
        catalog = manager.getGiftCatalog()
        setupUI()
    }
    
    private func setupUI() {
        // Header
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 100))
        
        let titleLabel = UILabel()
        titleLabel.text = isSendMode ? "Send a Gift" : "Buy a Gift"
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 24)
        
        balanceLabel = UILabel()
        balanceLabel.textColor = .white
        balanceLabel.font = .systemFont(ofSize: 14)
        updateBalanceLabel()
        
        segmentControl = UISegmentedControl(items: ["All Gifts", "Collectibles"])
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        // Close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(closeShop)
        )
        
        // Right balance
        let balanceBtn = UIBarButtonItem(customView: balanceLabel)
        navigationItem.rightBarButtonItem = balanceBtn
        
        // Collection view
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (view.frame.width - 48) / 3, height: 140)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 60, left: 16, bottom: 16, right: 16)
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .black
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(VGGiftCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
        
        // Segment on top
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentControl)
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    private func updateBalanceLabel() {
        let balance = manager.getCurrentProfile().starsBalance
        balanceLabel?.text = "Balance\n⭐ \(balance)"
        balanceLabel?.numberOfLines = 2
        balanceLabel?.textAlignment = .right
    }
    
    @objc private func segmentChanged() {
        showCollectibles = segmentControl.selectedSegmentIndex == 1
        collectionView.reloadData()
    }
    
    @objc private func closeShop() {
        navigationController?.popViewController(animated: true)
    }
    
    var filteredCatalog: [VGGiftCatalogItem] {
        if showCollectibles {
            return catalog.filter { $0.isResale }
        }
        return catalog
    }
}

extension VGGiftShopViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredCatalog.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! VGGiftCell
        cell.configure(with: filteredCatalog[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = filteredCatalog[indexPath.item]
        showGiftOptions(item: item)
    }
    
    private func showGiftOptions(item: VGGiftCatalogItem) {
        if item.availableLeft == 0 {
            showSoldOut(item: item)
            return
        }
        
        let sheet = UIAlertController(title: "Получить подарок", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Получить сейчас", style: .default) { [weak self] _ in
            self?.receiveGift(item: item)
        })
        sheet.addAction(UIAlertAction(title: "Отложить получение", style: .default) { _ in })
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(sheet, animated: true)
    }
    
    private func receiveGift(item: VGGiftCatalogItem) {
        // Deduct stars
        let profile = manager.getCurrentProfile()
        guard profile.starsBalance >= item.value else {
            let alert = UIAlertController(title: "Недостаточно звёзд", message: "Пополните баланс.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        manager.updateCurrentProfile { $0.starsBalance -= item.value }
        updateBalanceLabel()
        
        let gift = VGGift(
            id: UUID().uuidString,
            name: item.name,
            emoji: item.emoji,
            value: item.value,
            date: Date(),
            isUpgraded: false,
            uniqueNumber: nil,
            model: nil, backdrop: nil, symbol: nil,
            availability: item.availableLeft,
            totalAvailability: item.totalAvailability,
            isNFT: false,
            slugOrLink: nil
        )
        manager.addGift(gift)
        
        // Confetti + success
        showConfetti()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showGiftReceived(gift: gift, item: item)
        }
    }
    
    private func showSoldOut(item: VGGiftCatalogItem) {
        let vc = VGGiftDetailViewController(item: item, isSoldOut: true)
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }
    
    private func showGiftReceived(gift: VGGift, item: VGGiftCatalogItem) {
        let vc = VGGiftReceivedViewController(gift: gift, item: item)
        vc.modalPresentationStyle = .pageSheet
        present(vc, animated: true)
    }
    
    private func showConfetti() {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.bounds.width, height: 1)
        
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemYellow, .systemPurple, .systemOrange]
        emitter.emitterCells = colors.map { color in
            let cell = CAEmitterCell()
            cell.birthRate = 8
            cell.lifetime = 3
            cell.velocity = 200
            cell.velocityRange = 100
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 2
            cell.spinRange = 3
            cell.scaleRange = 0.5
            cell.scaleSpeed = -0.05
            cell.color = color.cgColor
            cell.contents = UIImage(systemName: "star.fill")?.cgImage
            cell.contentsScale = 2
            return cell
        }
        
        view.layer.addSublayer(emitter)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            emitter.removeFromSuperlayer()
        }
    }
}

// MARK: - Gift Cell

class VGGiftCell: UICollectionViewCell {
    
    private let emojiLabel = UILabel()
    private let priceLabel = UILabel()
    private let resaleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = UIColor(white: 0.12, alpha: 1)
        contentView.layer.cornerRadius = 12
        
        emojiLabel.font = .systemFont(ofSize: 48)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        
        priceLabel.font = .boldSystemFont(ofSize: 13)
        priceLabel.textColor = .white
        priceLabel.textAlignment = .center
        priceLabel.backgroundColor = UIColor(white: 0.2, alpha: 1)
        priceLabel.layer.cornerRadius = 10
        priceLabel.clipsToBounds = true
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        resaleLabel.text = "resale"
        resaleLabel.font = .boldSystemFont(ofSize: 10)
        resaleLabel.textColor = .white
        resaleLabel.backgroundColor = .systemGreen
        resaleLabel.textAlignment = .center
        resaleLabel.layer.cornerRadius = 4
        resaleLabel.clipsToBounds = true
        resaleLabel.translatesAutoresizingMaskIntoConstraints = false
        resaleLabel.isHidden = true
        
        contentView.addSubview(emojiLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(resaleLabel)
        
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -15),
            
            priceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            priceLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            priceLabel.heightAnchor.constraint(equalToConstant: 24),
            priceLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            resaleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            resaleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            resaleLabel.widthAnchor.constraint(equalToConstant: 44),
            resaleLabel.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with item: VGGiftCatalogItem) {
        emojiLabel.text = item.emoji
        priceLabel.text = "⭐ \(item.value)\(item.isResale ? "+" : "")"
        resaleLabel.isHidden = !item.isResale
    }
}

// MARK: - Gift Detail (Sold Out)

class VGGiftDetailViewController: UIViewController {
    
    let item: VGGiftCatalogItem
    let isSoldOut: Bool
    
    init(item: VGGiftCatalogItem, isSoldOut: Bool) {
        self.item = item
        self.isSoldOut = isSoldOut
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
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        let emoji = UILabel()
        emoji.text = item.emoji
        emoji.font = .systemFont(ofSize: 80)
        
        let title = UILabel()
        title.text = isSoldOut ? "Unavailable" : item.name
        title.font = .boldSystemFont(ofSize: 24)
        title.textColor = .white
        
        let subtitle = UILabel()
        subtitle.text = isSoldOut ? "This gift has sold out" : ""
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = .systemRed
        
        // Info table
        let infoStack = makeInfoTable()
        infoStack.widthAnchor.constraint(equalToConstant: 300).isActive = true
        
        let getBtn = UIButton(type: .system)
        getBtn.setTitle("Получить", for: .normal)
        getBtn.setTitleColor(.white, for: .normal)
        getBtn.backgroundColor = .systemBlue
        getBtn.layer.cornerRadius = 14
        getBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        getBtn.widthAnchor.constraint(equalToConstant: 300).isActive = true
        
        [emoji, title, subtitle, infoStack, getBtn].forEach { stack.addArrangedSubview($0) }
        
        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func makeInfoTable() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(white: 0.15, alpha: 1)
        container.layer.cornerRadius = 12
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy 'at' HH:mm"
        
        let rows: [(String, String)] = [
            ("First Sale", formatter.string(from: item.firstSale ?? Date())),
            ("Last Sale", formatter.string(from: item.lastSale ?? Date())),
            ("Value", "\(item.value) ⭐"),
            ("Availability", "0 of \(item.totalAvailability) left")
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
            l.padding = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 0)
            
            let v = UILabel()
            v.text = value
            v.textColor = .systemGray
            v.font = .systemFont(ofSize: 14)
            v.textAlignment = .right
            v.padding = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 12)
            
            row.addArrangedSubview(l)
            row.addArrangedSubview(v)
            stack.addArrangedSubview(row)
        }
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    @objc private func close() { dismiss(animated: true) }
}

// MARK: - Gift Received VC

class VGGiftReceivedViewController: UIViewController {
    
    let gift: VGGift
    let item: VGGiftCatalogItem
    
    init(gift: VGGift, item: VGGiftCatalogItem) {
        self.gift = gift
        self.item = item
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
        emoji.text = item.emoji
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
        hideBtn.font = .systemFont(ofSize: 14)
        
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
            
            let v = UILabel()
            v.text = value
            v.textColor = .systemGray
            v.font = .systemFont(ofSize: 14)
            v.textAlignment = .right
            
            [l, v].forEach { label in
                label.translatesAutoresizingMaskIntoConstraints = false
                label.heightAnchor.constraint(equalToConstant: 36).isActive = true
            }
            
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

// MARK: - My Gifts VC

class VGMyGiftsViewController: UIViewController {
    
    private let manager = VisualGramManager.shared
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Мои подарки"
        view.backgroundColor = .black
        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.backgroundColor = .black
        tableView.delegate = self
        tableView.dataSource = self
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
    }
    
    var gifts: [VGGift] { manager.getCurrentProfile().gifts }
}

extension VGMyGiftsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { gifts.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.backgroundColor = UIColor(white: 0.12, alpha: 1)
        let gift = gifts[indexPath.row]
        
        let imageView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        imageView.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.3)
        imageView.layer.cornerRadius = 10
        let emojiLabel = UILabel(frame: imageView.bounds)
        emojiLabel.text = gift.emoji
        emojiLabel.textAlignment = .center
        emojiLabel.font = .systemFont(ofSize: 28)
        imageView.addSubview(emojiLabel)
        
        cell.imageView?.image = imageView.asImage()
        cell.textLabel?.text = gift.displayName
        cell.textLabel?.textColor = .white
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        cell.detailTextLabel?.text = formatter.string(from: gift.date)
        cell.detailTextLabel?.textColor = .systemGray
        
        let menuBtn = UIButton(type: .system)
        menuBtn.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        menuBtn.tintColor = .systemGray
        menuBtn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        cell.accessoryView = menuBtn
        
        return cell
    }
}

// MARK: - History VC

class VGHistoryViewController: UIViewController {
    
    private let manager = VisualGramManager.shared
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "История операций"
        view.backgroundColor = .black
        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.backgroundColor = .black
        tableView.delegate = self
        tableView.dataSource = self
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
    }
    
    var transactions: [VGTransaction] { manager.getTransactions() }
}

extension VGHistoryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { transactions.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.backgroundColor = UIColor(white: 0.12, alpha: 1)
        let tx = transactions[indexPath.row]
        
        let typeStr: String
        switch tx.type {
        case .received: typeStr = "Получение"
        case .sent: typeStr = "Отправка"
        case .upgraded: typeStr = "Улучшение"
        case .purchased: typeStr = "Покупка"
        }
        
        cell.textLabel?.text = "\(typeStr) · \(tx.giftName)"
        cell.textLabel?.textColor = .white
        cell.imageView?.image = UILabel.emojiImage(tx.giftEmoji, size: CGSize(width: 40, height: 40))
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        
        var detail = formatter.string(from: tx.date)
        if tx.type == .received {
            detail = "Не указан → ...\n" + detail
        }
        cell.detailTextLabel?.text = detail
        cell.detailTextLabel?.textColor = .systemGray
        cell.detailTextLabel?.numberOfLines = 2
        
        return cell
    }
}

// MARK: - Helpers

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { ctx in layer.render(in: ctx.cgContext) }
    }
}

extension UILabel {
    static func emojiImage(_ emoji: String, size: CGSize) -> UIImage {
        let view = UIView(frame: CGRect(origin: .zero, size: size))
        view.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.3)
        view.layer.cornerRadius = 8
        let label = UILabel(frame: view.bounds)
        label.text = emoji
        label.textAlignment = .center
        label.font = .systemFont(ofSize: size.width * 0.6)
        view.addSubview(label)
        return view.asImage()
    }
    
    var padding: UIEdgeInsets {
        get { return .zero }
        set { }
    }
}
