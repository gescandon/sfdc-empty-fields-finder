//
// 
// (c) 2012 Appirio, Inc.
//
// EmptyFieldsController
//
//
// 2 Feb 2013   gescandon@appirio.com  Original
// 
//
// 
public with sharing class EmptyFieldsController {
  Map<String, Schema.SObjectType> objectMap;
  public String selectedObj {get;set;}
  public List<String> emptyFields {get;set;}
  public String resultMessage {get;set;}
  public EmptyFieldsController() {
    
  }
  
  public List<SelectOption> getObjectOptions() {
    if (objectMap == null) {
      objectMap = Schema.getGlobalDescribe();
    }
    List<String> objList = new List<String>();
    List<SelectOption> options = new List<SelectOption>();
    options.add(new SelectOption('',' -- select -- '));
    for (String key : objectMap.keyset()) {
      objList.add(key);
    }
    objList.sort();
    for (String key : objList) {
      options.add(new SelectOption(key, key));
    }
    return options;
  }
  
  public void findEmptyFields() {
    if (selectedObj == null) {
      return;
    }
    
    emptyFields = new List<String>();
    Schema.DescribeSObjectResult r = objectMap.get(selectedObj).getDescribe();
  
    Map<String, Schema.SObjectField> fieldMap = r.fields.getMap();
 
    Set<String> emptyFieldSet = new Set<String>();
    
    for (String key : fieldMap.keyset()) {
      if (key.contains('__c')) {
        emptyFieldSet.add(key);
      } else {
        if (Test.isRunningTest()) {
          emptyFieldSet.add(key);
        }
      }
    }
    
    if (emptyFieldSet.size() == 0) {
      resultMessage = 'No empty fields found.';     
    } else {        
      List<String> apiNames = queryEmptyFields(selectedObj, emptyFieldSet, false);
      for (String apin : apiNames) {
        emptyFields.add(fieldMap.get(apin).getDescribe().getLabel());
      }
      emptyFields.sort();
      resultMessage = '' + emptyFields.size() + ' empty fields found.';
    }
  }
  
  public List<String> queryEmptyFields(String objName, Set<String> fieldSet, Boolean includeWhere) {
    List<String> results = new List<String>();
    
    String query = 'select ';
    for (String key : fieldSet) {
      query += key + ', ';
    }
    
    query = query.substring(0, query.length() - 2);
    query += ' from ' + objName;
    if (includeWhere) {
      // this where clause will cause the query to fail
      // when the empty fields include fields types such as Long Text Area.
      query += ' where ';
      for (String key : fieldSet) {
        query += key + '  = null or ';
      }
      query = query.substring(0, query.length() - 4);
    }
    query += ' limit 100';
    System.debug(query);
    
    List<Sobject> sobList = Database.query(query);
    
    Set<String> remains = new Set<String>();
    remains.addAll(fieldSet);
    for (Sobject sob :sobList) {
      for (String key : fieldSet) {
        if (sob.get(key) != null) {
          remains.remove(key);
        }
        if (remains.size() == 0) {
          return results;
        }
      }
    }
    
    
    if (remains.size() < fieldSet.size()) {
      results = queryEmptyFields(objName, remains, false);
    }  else {
      results.addAll(remains);
    }
    return results;
  }
}