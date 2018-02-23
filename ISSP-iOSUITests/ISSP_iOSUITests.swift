//
//  ISSP_iOSUITests.swift
//  ISSP-iOSUITests
//
//  Created by Gautham Velappan/New York/IBM on 2/22/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import XCTest

class ISSP_iOSUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testExample() {
        
        let app = XCUIApplication()
        
        //Get all the textviews in the controller
        let textFields = app.textFields
        let latTextField: XCUIElement = textFields.element(matching: .textField, identifier: "latTextView")
        let lonTextField: XCUIElement = textFields.element(matching: .textField, identifier: "lonTextView")
        let altTextField: XCUIElement = textFields.element(matching: .textField, identifier: "altTextView")

        let buttons = app.buttons
        let submitButton: XCUIElement = buttons.element(matching: .button, identifier: "submitButton")
        
        latTextField.typeText("40.12")
        lonTextField.typeText("-70.34")
        altTextField.typeText("63.0")

        submitButton.tap()
    }
    
}
