import UIKit

class VGBalancesViewController: UIViewController {
    
    private let manager = VisualGramManager.shared
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Балансы"
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
        case starsBalance, addOperation
        case gramBalance, gramCard
    }
    
    let sections: [[Row]] = [
        [.profileSelect, .back],
        [.starsBalance, .addOperation],
        [.gramBalance, .gramCard]
    ]
}

extension VGBalancesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let profile = manager.getCurrentProfile()
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.backgroundColor = UIColor(white: 0.12, alpha: 1)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .systemGray
        
        switch sections[indexPath.section][indexPath.row] {
        case .profileSelect:
            cell.textLabel?.text = "Выбор профиля"
            cell.detailTextLabel?.text = profile.name
        case .back:
            cell.textLabel?.text = "Назад"
        case .starsBalance:
            cell.textLabel?.text = "Баланс звёзд"
            cell.detailTextLabel?.text = profile.starsBalance == 0 ? "Настоящий баланс" : "⭐ \(profile.starsBalance)"
        case .addOperation:
            cell.textLabel?.text = "Добавить операцию"
        case .gramBalance:
            cell.textLabel?.text = "Баланс GRAM"
            cell.detailTextLabel?.text = profile.gramBalance == 0 ? "Не задан" : "💎 \(profile.gramBalance)"
        case .gramCard:
            cell.textLabel?.text = "Оформить карточку GRAM"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch sections[indexPath.section][indexPath.row] {
        case .back:
            navigationController?.popViewController(animated: true)
        case .starsBalance:
            showStarsInput()
        case .addOperation:
            showAddOperation()
        case .gramBalance:
            showGramInput()
        case .gramCard:
            let vc = VGGramCardViewController()
            navigationController?.pushViewController(vc, animated: true)
        default: break
        }
    }
    
    private func showStarsInput() {
        let alert = UIAlertController(title: "Баланс звёзд", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Баланс"
            tf.keyboardType = .numberPad
            tf.text = self.manager.getCurrentProfile().starsBalance == 0 ? "" : "\(self.manager.getCurrentProfile().starsBalance)"
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { [weak self] _ in
            let val = Int(alert.textFields?.first?.text ?? "") ?? 0
            self?.manager.updateCurrentProfile { $0.starsBalance = val }
            self?.tableView.reloadData()
        })
        present(alert, animated: true)
    }
    
    private func showGramInput() {
        let alert = UIAlertController(title: "Баланс GRAM", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "GRAM"
            tf.keyboardType = .decimalPad
            tf.text = self.manager.getCurrentProfile().gramBalance == 0 ? "" : "\(self.manager.getCurrentProfile().gramBalance)"
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { [weak self] _ in
            let val = Double(alert.textFields?.first?.text ?? "") ?? 0
            self?.manager.updateCurrentProfile { $0.gramBalance = val }
            self?.tableView.reloadData()
        })
        present(alert, animated: true)
    }
    
    private func showAddOperation() {
        let sheet = UIAlertController(title: "Добавить операцию", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "⭐ Добавить Stars", style: .default) { [weak self] _ in
            self?.showStarsInput()
        })
        sheet.addAction(UIAlertAction(title: "💎 Добавить GRAM", style: .default) { [weak self] _ in
            self?.showGramInput()
        })
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(sheet, animated: true)
    }
}

// MARK: - GRAM Card VC

class VGGramCardViewController: UIViewController {
    
    private let manager = VisualGramManager.shared
    private var cardView: UIView!
    private var balanceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Карточка G..."
        view.backgroundColor = .black
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Отмена", style: .plain, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Сохранить", style: .done, target: self, action: #selector(save))
        
        setupUI()
    }
    
    private func setupUI() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32)
        ])
        
        // Card Preview
        cardView = makeCardView()
        cardView.heightAnchor.constraint(equalToConstant: 180).isActive = true
        stack.addArrangedSubview(cardView)
        
        // Description
        let desc = UILabel()
        desc.text = "Фон и наклейки выбираются отдельно. Перемещай наклейку одним пальцем, меняй размер и поворачивай двумя. Изменения сохраняются автоматически."
        desc.textColor = .systemGray
        desc.font = .systemFont(ofSize: 14)
        desc.numberOfLines = 0
        stack.addArrangedSubview(desc)
        
        // Buttons
        let bgBtn = makeButton(title: "Фон", color: .white, textColor: .white, style: .plain)
        bgBtn.addTarget(self, action: #selector(selectBackground), for: .touchUpInside)
        
        let addStickerBtn = makeButton(title: "Добавить наклейку", color: .clear, textColor: .systemBlue, style: .tinted)
        addStickerBtn.addTarget(self, action: #selector(addSticker), for: .touchUpInside)
        
        let removeStickerBtn = makeButton(title: "Убрать наклейку", color: .clear, textColor: .systemBlue, style: .tinted)
        removeStickerBtn.addTarget(self, action: #selector(removeSticker), for: .touchUpInside)
        
        let resetBtn = makeButton(title: "Сбросить карточку", color: .clear, textColor: .systemBlue, style: .tinted)
        resetBtn.addTarget(self, action: #selector(resetCard), for: .touchUpInside)
        
        [bgBtn, addStickerBtn, removeStickerBtn, resetBtn].forEach { stack.addArrangedSubview($0) }
    }
    
    private func makeCardView() -> UIView {
        let card = UIView()
        card.layer.cornerRadius = 20
        card.clipsToBounds = true
        
        // Gradient background
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.systemBlue.cgColor, UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1).cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        card.layer.addSublayer(gradient)
        card.layoutIfNeeded()
        
        // Stars decoration
        for _ in 0..<15 {
            let star = UILabel()
            star.text = ["✦", "+", "·"].randomElement()
            star.textColor = UIColor.white.withAlphaComponent(0.3)
            star.font = .systemFont(ofSize: CGFloat.random(in: 8...16))
            star.frame = CGRect(
                x: CGFloat.random(in: 0...340),
                y: CGFloat.random(in: 0...180),
                width: 20,
                height: 20
            )
            card.addSubview(star)
        }
        
        // Balance label
        let profile = manager.getCurrentProfile()
        balanceLabel = UILabel()
        balanceLabel.text = "💎  \(Int(profile.gramBalance)) GRAM"
        balanceLabel.textColor = .white
        balanceLabel.font = .boldSystemFont(ofSize: 24)
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(balanceLabel)
        
        // QR button
        let qrBtn = UIButton(type: .system)
        qrBtn.setImage(UIImage(systemName: "qrcode"), for: .normal)
        qrBtn.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        qrBtn.tintColor = .black
        qrBtn.layer.cornerRadius = 10
        qrBtn.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(qrBtn)
        
        NSLayoutConstraint.activate([
            balanceLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            balanceLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            qrBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            qrBtn.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            qrBtn.widthAnchor.constraint(equalToConstant: 50),
            qrBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Resize gradient on layout
        DispatchQueue.main.async {
            gradient.frame = card.bounds
        }
        
        return card
    }
    
    private func makeButton(title: String, color: UIColor, textColor: UIColor, style: UIButton.Configuration.Style? = nil) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(textColor == .white ? .white : textColor, for: .normal)
        btn.backgroundColor = UIColor(white: 0.15, alpha: 1)
        btn.layer.cornerRadius = 12
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return btn
    }
    
    @objc private func selectBackground() {
        let sheet = UIAlertController(title: "Фон карточки", message: nil, preferredStyle: .actionSheet)
        let backgrounds = ["Синий", "Фиолетовый", "Зелёный", "Золотой", "Чёрный"]
        for bg in backgrounds {
            sheet.addAction(UIAlertAction(title: bg, style: .default) { [weak self] _ in
                self?.manager.updateCurrentProfile { $0.gramCardBackground = bg.lowercased() }
            })
        }
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(sheet, animated: true)
    }
    
    @objc private func addSticker() {
        let sheet = UIAlertController(title: "Наклейка", message: nil, preferredStyle: .actionSheet)
        let stickers = ["🌟", "🔥", "💫", "✨", "🎯", "🚀"]
        for s in stickers {
            sheet.addAction(UIAlertAction(title: s, style: .default) { [weak self] _ in
                self?.manager.updateCurrentProfile { $0.gramCardSticker = s }
            })
        }
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(sheet, animated: true)
    }
    
    @objc private func removeSticker() {
        manager.updateCurrentProfile { $0.gramCardSticker = nil }
    }
    
    @objc private func resetCard() {
        manager.updateCurrentProfile {
            $0.gramCardBackground = "blue"
            $0.gramCardSticker = nil
        }
    }
    
    @objc private func cancel() { navigationController?.popViewController(animated: true) }
    @objc private func save() { navigationController?.popViewController(animated: true) }
}
