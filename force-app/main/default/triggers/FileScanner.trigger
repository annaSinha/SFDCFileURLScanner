trigger FileScanner on ContentVersion (After insert) {
    Map<Id,ContentVersion> contentVersionIdTriggerMap = new Map<Id,ContentVersion>();
    for(ContentVersion cv : Trigger.new){
        contentVersionIdTriggerMap.put(cv.Id,cv);
    }
    if(contentVersionIdTriggerMap.size()>0){
        database.executeBatch(new ScanFileBatch(contentVersionIdTriggerMap));// calling batch class
    }
}