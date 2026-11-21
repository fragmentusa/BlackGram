import UIKit

// MARK: - Main Menu (Triple Tap Entry Point)

class VGMenuViewController: UIViewController {
    
    private let manager = VisualGramManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "VisualGram"
        view.backgroundColor = .black
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAccessAndShowPaywall()
    }
    
    private func checkAccessAndShowPaywall() {
        if !manager.isActivated && !manager.isTrialActive {
            showPaywallAlert()
        }
    }
    
    private func setupUI() {
        let tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.backgroundColor = .black
        tableView.delegate = self
        tableView.dataSource = self
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(dismiss(_:))
        )
    }
    
    @objc private func dismiss(_ sender: Any) {
        dismiss(animated: true)
    }
    
    // MARK: - Paywall
    
    private func showPaywallAlert() {
        let alert = UIAlertController(
            title: "Доступ к VisualGram",
            message: "Пробный день закончился. Введите код активации.\n\nПробный период — 24 часа. Один код активирует пожизненный доступ на одном устройстве. Для проверки нужен интернет. Настройки сохраняются при блокировке.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Проверить доступ", style: .default) { [weak self] _ in
            self?.checkAccess()
        })
        alert.addAction(UIAlertAction(title: "Ввести код", style: .default) { [weak self] _ in
            self?.showActivationInput()
        })
        alert.addAction(UIAlertAction(title: "Закрыть", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func checkAccess() {
        if manager.checkAccess() {
            // Refresh
        } else {
            showPaywallAlert()
        }
    }
    
    func showActivationInput() {
        let alert = UIAlertController(
            title: "Код активации",
            message: "Код будет привязан к этому устройству.",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.placeholder = "XXXX-XXXX-XXXX-XXXX-XXXX"
            tf.autocapitalizationType = .allCharacters
            tf.keyboardType = .asciiCapable
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Активировать", style: .default) { [weak self] _ in
            guard let key = alert.textFields?.first?.text else { return }
            if self?.manager.activateWithKey(key) == true {
                self?.showSuccess()
            } else {
                self?.showError()
            }
        })
        present(alert, animated: true)
    }
    
    private func showSuccess() {
        let alert = UIAlertController(title: "✅ Активировано", message: "Доступ открыт навсегда.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showError() {
        let alert = UIAlertController(title: "❌ Ошибка", message: "Неверный ключ активации.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - TableView

extension VGMenuViewController: UITableViewDelegate, UITableViewDataSource {
    
    struct Section {
        var rows: [Row]
    }
    
    enum Row {
        case access
        case profileSelect
        case profile
        case gifts
        case balances
        case activation
    }
    
    var sections: [Section] {
        if manager.isActivated || manager.isTrialActive {
            return [
                Section(rows: [.access]),
                Section(rows: [.profileSelect]),
                Section(rows: [.profile, .gifts, .balances])
            ]
        } else {
            return [
                Section(rows: [.activation])
            ]
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.backgroundColor = UIColor(white: 0.12, alpha: 1)
        cell.accessoryType = .disclosureIndicator
        
        let row = sections[indexPath.section].rows[indexPath.row]
        
        switch row {
        case .access:
            cell.textLabel?.text = "Доступ"
            cell.detailTextLabel?.text = manager.isActivated ? "Активен" : "Пробный"
            cell.detailTextLabel?.textColor = .systemGray
        case .profileSelect:
            cell.textLabel?.text = "Выбор профиля"
            cell.detailTextLabel?.text = manager.getCurrentProfile().name
            cell.detailTextLabel?.textColor = .systemGray
        case .profile:
            cell.textLabel?.text = "Профиль"
        case .gifts:
            cell.textLabel?.text = "Подарки"
        case .balances:
            cell.textLabel?.text = "Балансы"
        case .activation:
            cell.textLabel?.text = "Активация VisualGram"
            cell.detailTextLabel?.text = "Введите код"
            cell.detailTextLabel?.textColor = .systemGray
        }
        
        cell.textLabel?.textColor = .white
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        
        switch row {
        case .activation:
            showActivationInput()
        case .access:
            showAccessInfo()
        case .profileSelect:
            showProfilePicker()
        case .profile:
            let vc = VGProfileViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .gifts:
            let vc = VGGiftsViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .balances:
            let vc = VGBalancesViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func showAccessInfo() {
        let msg = manager.isActivated
            ? "Доступ активирован навсегда."
            : "Пробный период: осталось \(Int(manager.trialTimeLeft / 3600))ч \(Int((manager.trialTimeLeft.truncatingRemainder(dividingBy: 3600)) / 60))мин"
        let alert = UIAlertController(title: "Доступ", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showProfilePicker() {
        let profiles = manager.getProfiles()
        let sheet = UIAlertController(title: "Выбор профиля", message: nil, preferredStyle: .actionSheet)
        for p in profiles {
            sheet.addAction(UIAlertAction(title: p.name, style: .default) { [weak self] _ in
                self?.manager.setCurrentProfileId(p.id)
            })
        }
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(sheet, animated: true)
    }
}
