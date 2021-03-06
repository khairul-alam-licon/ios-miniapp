import MiniApp

extension ViewController {
    func fetchAppList(inBackground: Bool) {
        showProgressIndicator(silently: inBackground) {
            MiniApp.shared(with: Config.getCurrent(), navigationSettings: Config.getNavConfig()).list { (result) in
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                }
                switch result {
                case .success(let responseData):
                    DispatchQueue.main.async {
                        self.decodeResponse = responseData
                        self.tableView.reloadData()
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    if !inBackground {
                        self.displayAlert(title: NSLocalizedString("error_title", comment: ""), message: NSLocalizedString("error_list_message", comment: ""), dismissController: true)
                    }
                }
                if !inBackground {
                    self.dismissProgressIndicator()
                }
            }
        }
    }

    func fetchAppInfo(for miniAppID: String) {
        self.showProgressIndicator {
            MiniApp.shared(with: Config.getCurrent(), navigationSettings: Config.getNavConfig()).info(miniAppId: miniAppID) { (result) in
                switch result {
                case .success(let responseData):
                    self.currentMiniAppInfo = responseData
                    self.fetchMiniApp(for: responseData)
                case .failure(let error):
                    print(error.localizedDescription)
                    self.dismissProgressIndicator {
                        self.fetchMiniAppUsingId(title: NSLocalizedString("error_title", comment: ""), message: NSLocalizedString("error_single_message", comment: ""))
                    }
                }
            }
        }
    }

    func fetchMiniApp(for appInfo: MiniAppInfo) {
        MiniApp.shared(with: Config.getCurrent(), navigationSettings: Config.getNavConfig()).create(appInfo: appInfo, completionHandler: { (result) in
            switch result {
            case .success(let miniAppDisplay):
                self.dismissProgressIndicator {
                    self.currentMiniAppView = miniAppDisplay
                    self.performSegue(withIdentifier: "DisplayMiniApp", sender: nil)
                }
            case .failure(let error):
                self.displayAlert(title: NSLocalizedString("error_title", comment: ""), message: NSLocalizedString("error_miniapp_download_message", comment: ""), dismissController: true) { _ in
                    self.fetchAppList(inBackground: true)
                }
                print("Errored: ", error.localizedDescription)
            }
        }, messageInterface: self)
    }

    func fetchMiniAppUsingId(title: String? = nil, message: String? = nil) {
        self.displayTextFieldAlert(title: title, message: message) { (_, textField) in
            if let textField = textField, let miniAppID = textField.text, miniAppID.count > 0 {
                self.fetchAppInfo(for: miniAppID)
            } else {
                self.fetchMiniAppUsingId(title: NSLocalizedString("error_invalid_miniapp_id", comment: ""), message: NSLocalizedString("input_valid_miniapp_title", comment: ""))
            }
        }
    }
}
