// 
// (c) 2012 Appirio, Inc.
//
// EmptyFieldsController
//
//
// 2 Feb 2013   gescandon@appirio.com  Original
// 
//
 
public with sharing class EmptyFieldsController {
  Map<String, Schema.SObjectType> objectMap;
  public String selectedObj {get;set;}
  public List<String> emptyFields {get;set;}
  public String resultMessage {get;set;}
  public String finalSoql {get;set;}
  public Double stime;
  public Double etime;
   
  Integer DEFAULT_DEPTH = 100;
  public Integer depth {get;set;}
  public Boolean searchAllObjects {get;set;}
  Map<String, Schema.SObjectField> objectFieldMap  =
    new Map<String, Schema.SObjectField>();
  Map<String, String> fieldLabelMap = 
    new Map<String, String>();
  Map<String, String> fieldTypeMap = 
    new Map<String, String>();
    
  public EmptyFieldsController() {
    depth = DEFAULT_DEPTH; 
    searchAllObjects = false; 
    if (objectMap == null) {
      objectMap = Schema.getGlobalDescribe();
    }
  }
  
  public List<SelectOption> getObjectOptions() {
    List<String> objList = new List<String>();
    List<SelectOption> options = new List<SelectOption>();
    options.add(new SelectOption('',' -- select -- '));
    for (String key : objectMap.keyset()) {
      objList.add(key);
    }
    objList.sort();
    for (String key : objList) {
      if (searchAllObjects) {
        options.add(new SelectOption(key, key));
      } else {
        if (key.indexOf('__c') > 0) {
          options.add(new SelectOption(key, key));              
        }
      }
    }
    return options;
  }
  
  public void findEmptyFields() {
    if (selectedObj == null) {
      return;
    }
    stime = Datetime.now().getTime();
    emptyFields = new List<String>();

    Schema.DescribeSObjectResult r = objectMap.get(selectedObj).getDescribe();
  
    objectFieldMap = r.fields.getMap();
 
    Set<String> emptyFieldSet = new Set<String>();
    
    for (String key : objectFieldMap.keyset()) {
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
        //emptyFields.add(fieldMap.get(apin).getDescribe().getLabel());
        emptyFields.add(apin);
      }
      emptyFields.sort();
      etime = Datetime.now().getTime();
      String elapse = String.valueOf((etime - stime)/1000);
      resultMessage = '' + emptyFields.size() + ' empty fields found. (' + elapse + 's)';
      finalSoql = '(' + finalSoql + ')';
    }
  }
  
  public List<String> queryEmptyFields(String objName, Set<String> fieldSet, Boolean includeWhere) {
    List<String> results = new List<String>();
    depth = 2 * depth; // each query looks a little deeper
    
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
        if (!fieldTypeMap.keyset().contains(key)) {
          Schema.DescribeFieldResult fd = objectFieldMap.get(key).getDescribe();
          fieldTypeMap.put(key, fd.getType().name());
          fieldLabelMap.put(key, fd.getLabel());
        }
        if (fieldTypeMap.get(key) != 'TextArea') {
          query += ' (' + key + '  != null) or ';
        }
      }
      query = query.substring(0, query.length() - 4);
    } else {
    
    query += ' limit ' + String.valueOf(depth);
    }
    Set<String> remains = new Set<String>();
    finalSoql = query;
    
    try {
      List<Sobject> sobList = Database.query(query);
      depth = sobList.size();
      // exit if the object has no records
      if (sobList.size() == 0) {
        results.addAll(fieldSet);
        return results;
      }
      
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
    } catch (Exception e) {
      String emsg = e.getMessage();
      ApexPages.addMessages(e);
      return results;
    }
    
    
    
    if (remains.size() < fieldSet.size()) {
      results = queryEmptyFields(objName, remains, true);
    }  else {
      results.addAll(remains);
    }
    return results;
  }
  
  
  public void updateObjects() {
    // intentionally left blank
    // used to update search options
  }
}