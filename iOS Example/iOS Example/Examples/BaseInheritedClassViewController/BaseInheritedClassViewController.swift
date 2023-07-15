//
//  BaseInheritedClassViewController.swift
//  iOS Example
//
//  Created by Amr Mohamed on 11/02/2023.
//

import UIKit
import SlideUpSheet

class BaseInheritedClassViewController: SlideUpSheetBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // prevents the swipe down to dismiss
        slideUpSheet.allowsDismissing = false
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
