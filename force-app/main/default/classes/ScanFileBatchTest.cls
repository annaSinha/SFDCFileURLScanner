@istest 
public class ScanFileBatchTest {
    @isTest static void testbatchClass(){
        ContentVersion cv=new Contentversion();
        cv.title='ABC';
        cv.PathOnClient ='test';
        Blob b=Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body=');
        insert cv;
        Map<Id,ContentVersion> contentVersionIdTriggerMap = new Map<Id,ContentVersion>([SELECT Id, VersionData, PathOnClient FROM ContentVersion]);
        List<Banned_URL__mdt> testMetadata = (List<Banned_URL__mdt>)Json.deserialize('[ {"URL__c": "www.facebook.com","MasterLabel": "facebook"}]', List<Banned_URL__mdt>.class);
        Test.setMock(HttpCalloutMock.class, new ScanFileBatchMock());
        
        ScanFileBatch bs = new ScanFileBatch(contentVersionIdTriggerMap);
        Test.startTest();
            database.executeBatch(bs,200);
        Test.stopTest();
    }
}