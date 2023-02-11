//
//  ViewController.swift
//  iOS Example
//
//  Created by Amr Mohamed on 11/02/2023.
//

import UIKit
import SheetPresentationController

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0: presentCustomLayoutExample()
        case 1: presentTableViewExample()
        case 2: presentScrollViewExample()
        case 3: presentBaseInheritedClassExample()
        default: break
        }
    }
    
    private func presentCustomLayoutExample() {
        let dvc = CustomViewController()
        dvc.modalPresentationStyle = .custom
        dvc.transitioningDelegate = SheetSharedTransitioningDelegate.sharedDelegate()
        present(dvc, animated: true)
    }
    
    private func presentTableViewExample() {
        let dvc = TableViewController()
        dvc.modalPresentationStyle = .custom
        dvc.transitioningDelegate = SheetSharedTransitioningDelegate.sharedDelegate()
        present(dvc, animated: true)
    }
    
    private func presentScrollViewExample() {
        let dvc = ScrollViewController()
        dvc.modalPresentationStyle = .custom
        dvc.transitioningDelegate = SheetSharedTransitioningDelegate.sharedDelegate()
        present(dvc, animated: true)
    }
    
    private func presentBaseInheritedClassExample() {
        // notice we don't need to set the modalPresentationStyle
        // or the transitioningDelegate because they are set
        // automatically in the SheetBaseViewController
        let dvc = BaseInheritedClassViewController()
        present(dvc, animated: true)
    }
}
