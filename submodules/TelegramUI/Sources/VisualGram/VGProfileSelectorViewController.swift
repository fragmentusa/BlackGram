import UIKit

// MARK: - Profile Selector

class VGProfileSelectorViewController: UIViewController {
    
    private let manager = VisualGramManager.shared
    private var tableView: UITableView!
    var onSelect: ((VGProfile) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Выбор профиля"
        view.backgroundColor = .black
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addProfile)
        )
        
        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.backgroundColor = .black
        tableView.delegate = self
        tableView.dataSource = self
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
    }
    
    @objc private func addProfile() {
        let alert = UIAlertController(title: "Новый профиль", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Название профиля" }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Создать", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            let profile = VGProfile(id: UUID().uuidString, name: name)
            self?.manager.saveProfile(profile)
            self?.tableView.reloadData()
        })
        present(alert, animated: true)
    }
}

extension VGProfileSelectorViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manager.getProfiles().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.backgroundColor = UIColor(white: 0.12, alpha: 1)
        let profile = manager.getProfiles()[indexPath.row]
        
        cell.textLabel?.text = profile.name
        cell.textLabel?.textColor = .white
        
        var details: [String] = []
        if profile.hasPremium { details.append("Premium") }
        if profile.verificationType != .none { details.append(profile.verificationType.rawValue) }
        if let num = profile.collectibleNumber { details.append(num) }
        cell.detailTextLabel?.text = details.joined(separator: " · ")
        cell.detailTextLabel?.textColor = .systemGray
        
        if profile.id == manager.getCurrentProfileId() {
            cell.accessoryType = .checkmark
            cell.tintColor = .systemBlue
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let profile = manager.getProfiles()[indexPath.row]
        manager.setCurrentProfileId(profile.id)
        onSelect?(profile)
        tableView.reloadData()
        navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let profile = manager.getProfiles()[indexPath.row]
        guard profile.id != "main" else { return nil }
        
        let delete = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, completion in
            var profiles = self?.manager.getProfiles() ?? []
            profiles.removeAll { $0.id == profile.id }
            if let data = try? JSONEncoder().encode(profiles) {
                UserDefaults.standard.set(data, forKey: "vg_profiles")
            }
            if self?.manager.getCurrentProfileId() == profile.id {
                self?.manager.setCurrentProfileId("main")
            }
            self?.tableView.reloadData()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - Colors & Background

class VGColorsViewController: UIViewController {
    
    private let manager = VisualGramManager.shared
    private var previewView: UIView!
    private var selectedColor: String = "blue"
    private var selectedBg: String = "none"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Цвета и фон профиля"
        view.backgroundColor = .black
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Сохранить",
            style: .done,
            target: self,
            action: #selector(save)
        )
        
        let profile = manager.getCurrentProfile()
        selectedColor = profile.profileColor ?? "blue"
        selectedBg = profile.profileBackground ?? "none"
        
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
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32)
        ])
        
        // Preview
        previewView = makePreview()
        previewView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        stack.addArrangedSubview(previewView)
        
        // Color section
        let colorTitle = makeSectionTitle("Цвет профиля")
        stack.addArrangedSubview(colorTitle)
        
        let colorGrid = makeColorGrid()
        stack.addArrangedSubview(colorGrid)
        
        // Background section
        let bgTitle = makeSectionTitle("Фон профиля")
        stack.addArrangedSubview(bgTitle)
        
        let bgGrid = makeBackgroundGrid()
        stack.addArrangedSubview(bgGrid)
    }
    
    private func makePreview() -> UIView {
        let container = UIView()
        container.layer.cornerRadius = 20
        container.clipsToBounds = true
        
        let gradient = CAGradientLayer()
        gradient.colors = colorForKey(selectedColor).map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        container.layer.addSublayer(gradient)
        
        let profile = manager.getCurrentProfile()
        
        let nameLabel = UILabel()
        nameLabel.text = profile.name
        nameLabel.textColor = .white
        nameLabel.font = .boldSystemFont(ofSize: 20)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(nameLabel)
        
        // Badges
        var badgeText = ""
        if profile.hasPremium { badgeText += "⭐ " }
        if profile.hasTelegramBadge { badgeText += "✓ " }
        if profile.verificationType == .major { badgeText += "☑ " }
        
        let badgeLabel = UILabel()
        badgeLabel.text = badgeText
        badgeLabel.font = .systemFont(ofSize: 16)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(badgeLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            badgeLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            badgeLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        DispatchQueue.main.async {
            gradient.frame = container.bounds
        }
        
        return container
    }
    
    private func makeColorGrid() -> UIView {
        let colors: [(String, [UIColor])] = [
            ("blue", [.systemBlue, UIColor(red: 0.1, green: 0.4, blue: 1, alpha: 1)]),
            ("purple", [.systemPurple, UIColor(red: 0.6, green: 0.1, blue: 0.9, alpha: 1)]),
            ("green", [.systemGreen, UIColor(red: 0.1, green: 0.7, blue: 0.3, alpha: 1)]),
            ("orange", [.systemOrange, UIColor(red: 1, green: 0.5, blue: 0, alpha: 1)]),
            ("red", [.systemRed, UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)]),
            ("gold", [UIColor(red: 1, green: 0.8, blue: 0, alpha: 1), UIColor(red: 0.9, green: 0.6, blue: 0, alpha: 1)]),
            ("teal", [.systemTeal, UIColor(red: 0, green: 0.7, blue: 0.7, alpha: 1)]),
            ("pink", [.systemPink, UIColor(red: 1, green: 0.2, blue: 0.5, alpha: 1)])
        ]
        
        let grid = UIStackView()
        grid.axis = .horizontal
        grid.distribution = .fillEqually
        grid.spacing = 12
        
        for (key, colorPair) in colors {
            let btn = makeColorButton(key: key, colors: colorPair)
            grid.addArrangedSubview(btn)
        }
        
        return grid
    }
    
    private func makeColorButton(key: String, colors: [UIColor]) -> UIButton {
        let btn = UIButton()
        btn.layer.cornerRadius = 20
        btn.clipsToBounds = true
        btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let gradient = CAGradientLayer()
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        btn.layer.addSublayer(gradient)
        
        if key == selectedColor {
            btn.layer.borderWidth = 3
            btn.layer.borderColor = UIColor.white.cgColor
        }
        
        btn.tag = key.hashValue
        btn.accessibilityLabel = key
        btn.addTarget(self, action: #selector(selectColor(_:)), for: .touchUpInside)
        
        DispatchQueue.main.async {
            gradient.frame = btn.bounds
        }
        
        return btn
    }
    
    private func makeBackgroundGrid() -> UIView {
        let backgrounds = [
            ("none", "Нет"),
            ("stars", "Звёзды ✦"),
            ("dots", "Точки ·"),
            ("lines", "Линии —"),
            ("gradient", "Градиент"),
            ("dark", "Тёмный")
        ]
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        
        for (key, name) in backgrounds {
            let btn = UIButton(type: .system)
            btn.setTitle(name, for: .normal)
            btn.setTitleColor(key == selectedBg ? .white : .systemGray, for: .normal)
            btn.backgroundColor = key == selectedBg ? UIColor(white: 0.25, alpha: 1) : UIColor(white: 0.15, alpha: 1)
            btn.layer.cornerRadius = 12
            btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
            btn.accessibilityLabel = key
            btn.addTarget(self, action: #selector(selectBackground(_:)), for: .touchUpInside)
            stack.addArrangedSubview(btn)
        }
        
        return stack
    }
    
    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 13)
        return label
    }
    
    private func colorForKey(_ key: String) -> [UIColor] {
        switch key {
        case "purple": return [.systemPurple, UIColor(red: 0.6, green: 0.1, blue: 0.9, alpha: 1)]
        case "green": return [.systemGreen, UIColor(red: 0.1, green: 0.7, blue: 0.3, alpha: 1)]
        case "orange": return [.systemOrange, UIColor(red: 1, green: 0.5, blue: 0, alpha: 1)]
        case "red": return [.systemRed, UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)]
        case "gold": return [UIColor(red: 1, green: 0.8, blue: 0, alpha: 1), UIColor(red: 0.9, green: 0.6, blue: 0, alpha: 1)]
        case "teal": return [.systemTeal, UIColor(red: 0, green: 0.7, blue: 0.7, alpha: 1)]
        case "pink": return [.systemPink, UIColor(red: 1, green: 0.2, blue: 0.5, alpha: 1)]
        default: return [.systemBlue, UIColor(red: 0.1, green: 0.4, blue: 1, alpha: 1)]
        }
    }
    
    @objc private func selectColor(_ sender: UIButton) {
        selectedColor = sender.accessibilityLabel ?? "blue"
        manager.updateCurrentProfile { $0.profileColor = self.selectedColor }
        setupUI()
    }
    
    @objc private func selectBackground(_ sender: UIButton) {
        selectedBg = sender.accessibilityLabel ?? "none"
        manager.updateCurrentProfile { $0.profileBackground = self.selectedBg }
        setupUI()
    }
    
    @objc private func save() {
        navigationController?.popViewController(animated: true)
    }
}
