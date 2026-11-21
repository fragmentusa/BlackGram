import UIKit

class VGProfileViewController: UIViewController {
    
    private let manager = VisualGramManager.shared
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Профиль"
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
    
    // MARK: - Sections
    
    enum Row {
        case profileSelect, back
        case premium, badge, verification
        case nftUsername, profileNumber, level, usernames
        case colors, workHours, address
    }
    
    let sections: [[Row]] = [
        [.profileSelect, .back],
        [.premium, .badge, .verification],
        [.nftUsername, .profileNumber, .level, .usernames],
        [.colors, .workHours, .address]
    ]
}

// MARK: - TableView

extension VGProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let profile = manager.getCurrentProfile()
        let row = sections[indexPath.section][indexPath.row]
        
        switch row {
        case .premium, .badge:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.backgroundColor = UIColor(white: 0.12, alpha: 1)
            let sw = UISwitch()
            cell.accessoryView = sw
            if row == .premium {
                cell.textLabel?.text = "Telegram Premium"
                sw.isOn = profile.hasPremium
                sw.tag = 1
            } else {
                cell.textLabel?.text = "Галочка Telegram"
                sw.isOn = profile.hasTelegramBadge
                sw.tag = 2
            }
            sw.addTarget(self, action: #selector(toggleSwitch(_:)), for: .valueChanged)
            cell.textLabel?.textColor = .white
            return cell
            
        default:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.backgroundColor = UIColor(white: 0.12, alpha: 1)
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = .white
            cell.detailTextLabel?.textColor = .systemGray
            
            switch row {
            case .profileSelect:
                cell.textLabel?.text = "Выбор профиля"
                cell.detailTextLabel?.text = profile.name
            case .back:
                cell.textLabel?.text = "Назад"
            case .verification:
                cell.textLabel?.text = "Верификация"
                cell.detailTextLabel?.text = profile.verificationType == .none ? "Выключена" : profile.verificationType.rawValue.capitalized
            case .nftUsername:
                cell.textLabel?.text = "Добавить NFT-юзернейм"
                cell.detailTextLabel?.text = profile.nftUsername
            case .profileNumber:
                cell.textLabel?.text = "Номер профиля"
                cell.detailTextLabel?.text = profile.collectibleNumber
            case .level:
                cell.textLabel?.text = "Уровень"
                cell.detailTextLabel?.text = profile.level == nil ? "Настоящий" : "\(profile.level!)"
            case .usernames:
                cell.textLabel?.text = "Юзернеймы"
                cell.detailTextLabel?.text = "\(profile.usernames.count)"
            case .colors:
                cell.textLabel?.text = "Цвета и фон профиля"
            case .workHours:
                cell.textLabel?.text = "Часы работы"
                cell.detailTextLabel?.text = profile.workHours
            case .address:
                cell.textLabel?.text = "Адрес"
                cell.detailTextLabel?.text = profile.address
            default:
                break
            }
            return cell
        }
    }
    
    @objc func toggleSwitch(_ sw: UISwitch) {
        manager.updateCurrentProfile { profile in
            if sw.tag == 1 { profile.hasPremium = sw.isOn }
            if sw.tag == 2 { profile.hasTelegramBadge = sw.isOn }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section][indexPath.row]
        
        switch row {
        case .back:
            navigationController?.popViewController(animated: true)
        case .verification:
            showVerificationPicker()
        case .nftUsername:
            showTextInput(title: "NFT-юзернейм", placeholder: "@username.ton") { [weak self] val in
                self?.manager.updateCurrentProfile { $0.nftUsername = val }
                self?.tableView.reloadData()
            }
        case .profileNumber:
            let vc = VGCollectibleNumberViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .level:
            showLevelPicker()
        case .usernames:
            showTextInput(title: "Добавить юзернейм", placeholder: "@username") { [weak self] val in
                self?.manager.updateCurrentProfile { $0.usernames.append(val) }
                self?.tableView.reloadData()
            }
        case .workHours:
            showTextInput(title: "Часы работы", placeholder: "Пн-Пт 9:00-18:00") { [weak self] val in
                self?.manager.updateCurrentProfile { $0.workHours = val }
                self?.tableView.reloadData()
            }
        case .address:
            showTextInput(title: "Адрес", placeholder: "Город, улица") { [weak self] val in
                self?.manager.updateCurrentProfile { $0.address = val }
                self?.tableView.reloadData()
            }
        default:
            break
        }
    }
    
    // MARK: - Helpers
    
    private func showVerificationPicker() {
        let sheet = UIAlertController(title: "Верификация", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Major", style: .default) { [weak self] _ in
            self?.manager.updateCurrentProfile { $0.verificationType = .major }
            self?.tableView.reloadData()
        })
        sheet.addAction(UIAlertAction(title: "Hold", style: .default) { [weak self] _ in
            self?.manager.updateCurrentProfile { $0.verificationType = .hold }
            self?.tableView.reloadData()
        })
        sheet.addAction(UIAlertAction(title: "Выключить", style: .destructive) { [weak self] _ in
            self?.manager.updateCurrentProfile { $0.verificationType = .none }
            self?.tableView.reloadData()
        })
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(sheet, animated: true)
    }
    
    private func showLevelPicker() {
        let alert = UIAlertController(title: "Уровень Telegram", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Уровень (пусто — настоящий р..."
            tf.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { [weak self] _ in
            let text = alert.textFields?.first?.text ?? ""
            let level = Int(text)
            self?.manager.updateCurrentProfile { $0.level = level }
            self?.tableView.reloadData()
        })
        present(alert, animated: true)
    }
    
    private func showTextInput(title: String, placeholder: String, completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = placeholder }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Сохранить", style: .default) { _ in
            completion(alert.textFields?.first?.text ?? "")
        })
        present(alert, animated: true)
    }
}

// MARK: - Collectible Number VC

class VGCollectibleNumberViewController: UIViewController {
    
    private let manager = VisualGramManager.shared
    private var numberField: UITextField!
    private var priceField: UITextField!
    private var priceLabel: UILabel!
    private var datePicker: UIDatePicker!
    private var tonRate: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Номер про..."
        view.backgroundColor = .black
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Сохранить", style: .done, target: self, action: #selector(save))
        
        setupUI()
        fetchRate()
        
        if let num = manager.getCurrentProfile().collectibleNumber {
            numberField.text = num
        }
    }
    
    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        numberField = makeField(placeholder: "Номер: +7... или +888...")
        priceField = makeField(placeholder: "Цена TON")
        priceField.keyboardType = .decimalPad
        priceField.addTarget(self, action: #selector(priceChanged), for: .editingChanged)
        
        priceLabel = UILabel()
        priceLabel.textColor = .systemGray
        priceLabel.font = .systemFont(ofSize: 14)
        priceLabel.text = "Стоимость появится после загрузки курса TON."
        
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.tintColor = .white
        datePicker.overrideUserInterfaceStyle = .dark
        
        stack.addArrangedSubview(numberField)
        stack.addArrangedSubview(priceField)
        stack.addArrangedSubview(priceLabel)
        stack.addArrangedSubview(datePicker)
    }
    
    private func makeField(placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.textColor = .white
        tf.backgroundColor = UIColor(white: 0.15, alpha: 1)
        tf.layer.cornerRadius = 10
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.leftViewMode = .always
        tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return tf
    }
    
    @objc private func priceChanged() {
        guard let rate = tonRate,
              let text = priceField.text,
              let ton = Double(text) else {
            priceLabel.text = "Стоимость появится после загрузки курса TON."
            return
        }
        let usd = ton * rate
        priceLabel.text = "≈ \(String(format: "%.2f", usd)) USDT"
    }
    
    private func fetchRate() {
        manager.fetchTONRate { [weak self] rate in
            DispatchQueue.main.async {
                self?.tonRate = rate
                self?.priceLabel.text = rate != nil ? "Введите цену в TON" : "Не удалось загрузить курс TON."
            }
        }
    }
    
    @objc private func save() {
        let number = numberField.text ?? ""
        let price = Double(priceField.text ?? "") ?? 0
        let date = datePicker.date
        
        manager.updateCurrentProfile { profile in
            profile.collectibleNumber = number.isEmpty ? nil : number
            profile.collectibleNumberPrice = price > 0 ? price : nil
            profile.collectibleNumberDate = date
        }
        
        navigationController?.popViewController(animated: true)
        
        if !number.isEmpty {
            showCollectiblePopup(number: number, price: price, date: date)
        }
    }
    
    private func showCollectiblePopup(number: String, price: Double, date: Date) {
        // Show Fragment-style popup
        let vc = VGCollectibleNumberPopupViewController(number: number, price: price, date: date, tonRate: tonRate)
        vc.modalPresentationStyle = .pageSheet
        navigationController?.present(vc, animated: true)
    }
}

// MARK: - Fragment-style Popup

class VGCollectibleNumberPopupViewController: UIViewController {
    
    let number: String
    let price: Double
    let date: Date
    let tonRate: Double?
    
    init(number: String, price: Double, date: Date, tonRate: Double?) {
        self.number = number
        self.price = price
        self.date = date
        self.tonRate = tonRate
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.1, alpha: 1)
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40)
        ])
        
        // Fragment icon
        let iconView = UIView(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        iconView.backgroundColor = .systemBlue
        iconView.layer.cornerRadius = 35
        iconView.widthAnchor.constraint(equalToConstant: 70).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        
        let iconLabel = UILabel()
        iconLabel.text = "◈"
        iconLabel.font = .systemFont(ofSize: 32)
        iconLabel.textColor = .white
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconView.addSubview(iconLabel)
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor)
        ])
        
        let titleLabel = UILabel()
        titleLabel.textColor = .white
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let usd = tonRate != nil ? String(format: "$%.2f", price * tonRate!) : ""
        titleLabel.text = "\(number) is a collectible phone number that belongs to"
        
        let descLabel = UILabel()
        descLabel.textColor = .systemGray
        descLabel.font = .systemFont(ofSize: 14)
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        descLabel.text = "The phone number \(number) was acquired on Fragment on \(formatter.string(from: date)) for ♦\(Int(price)) (\(usd))."
        
        let learnBtn = UIButton(type: .system)
        learnBtn.setTitle("Learn More", for: .normal)
        learnBtn.backgroundColor = .systemBlue
        learnBtn.setTitleColor(.white, for: .normal)
        learnBtn.layer.cornerRadius = 12
        learnBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        learnBtn.widthAnchor.constraint(equalToConstant: 280).isActive = true
        
        let copyBtn = UIButton(type: .system)
        copyBtn.setTitle("Copy Phone Number", for: .normal)
        copyBtn.addTarget(self, action: #selector(copyNumber), for: .touchUpInside)
        
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(descLabel)
        stack.addArrangedSubview(learnBtn)
        stack.addArrangedSubview(copyBtn)
    }
    
    @objc private func copyNumber() {
        UIPasteboard.general.string = number
        dismiss(animated: true)
    }
}
