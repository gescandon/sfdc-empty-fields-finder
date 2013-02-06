//
// 
// (c) 2012 Appirio, Inc.
//
// EmptyFieldsController_Test
//
//
// 2 Feb 2013   gescandon@appirio.com  Original
// 
//
// 
@isTest
private class EmptyFieldsController_Test {


  static testMethod void testForEmptyFields() {
    EmptyFieldsController ctlr = new EmptyFieldsController();
    System.assert(ctlr.getObjectOptions() != null);
    ctlr.selectedObj = 'Account';
    ctlr.findEmptyFields();    
  }
}