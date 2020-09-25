//
//  ViewController.swift
//  ConcurrencyTest
//
//  Created by Brian on 8/31/18.
//  Copyright © 2018 Razeware. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var primeNumberButton: UIButton!
  
  @IBAction func calculatePrimeNumbers(_ sender: Any) {
    enablePrimeButton(false)
    DispatchQueue.global(qos: .userInitiated).async {
      for number in 0...1_000_000 {
        let isPrimeNumber = self.isPrime(number: number)
        print("\(number) is prime: \(isPrimeNumber)")
      }
      DispatchQueue.main.async {
        self.enablePrimeButton(true)
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }

  func isPrime(number: Int) -> Bool {
    if number <= 1 {
      return false
    }
    if number <= 3 {
      return true
    }
    var i = 2
    while i * i <= number {
      if number % i == 0 {
        return false
      }
      i = i + 2
    }
    return true
  }
  
  func enablePrimeButton(_ isEnabled: Bool) {
    primeNumberButton.isEnabled = isEnabled
    if isEnabled {
      primeNumberButton.setTitle("Calculate Prime Numbers", for: .normal)
    } else {
      primeNumberButton.setTitle("Calculating...", for: .normal)
    }
  }
  

}

