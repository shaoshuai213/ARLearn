//
//  ViewController.swift
//  ARLearn
//
//  Created by shaoshuai on 2019/5/27.
//  Copyright © 2019 shaoshuai. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}

	func test() {
		var lock = pthread_rwlock_t()
		pthread_rwlock_init(&lock, nil)

		pthread_rwlock_rdlock(&lock)
		pthread_rwlock_unlock(&lock)

		pthread_rwlock_wrlock(&lock)
		pthread_rwlock_unlock(&lock)

		pthread_rwlock_destroy(&lock)
	}
}

