global class ScanFileBatch implements Database.Batchable<sObject>,   Database.AllowsCallouts {
 
    Map<Id,ContentVersion> contentVersionIdMap = new Map<Id,ContentVersion>();
    global ScanFileBatch(Map<Id,ContentVersion> contentVersionIdTriggerMap){
      contentVersionIdMap = contentVersionIdTriggerMap;
    }
  
    //global String query = 'SELECT Id, VersionData, PathOnClient FROM ContentVersion'; // WHERE Id IN: fileIds
      
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, VersionData, PathOnClient FROM ContentVersion WHERE Id IN: contentVersionIdMap.keySet()]);
     }
 
     global void execute(Database.BatchableContext BC, List<ContentVersion> scope) {   
      Map<String,String> fileIdWithresponse = new Map<String,String>();
      for(ContentVersion contv : scope){
         try {                 
            String fileName = contv.PathOnClient;
            String targetURL = 'https://fileurlscanner.onrender.com/getfile';
            String boundary = '----------------------------741e90d31eff';
            String header = '--'+boundary+'\nContent-Disposition: form-data; name="file"; filename="'+fileName+'";\nContent-Type: application/octet-stream';
            // String footer = '\r\n--'+boundary+'--'; 
            String footer = '--'+boundary+'--';             
            String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
            while(headerEncoded.endsWith('='))
            {
            header+=' ';
            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
            }
            String bodyEncoded = EncodingUtil.base64Encode(contv.VersionData);
            Blob bodyBlob = null;
            String last4Bytes = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());
            // GW: replacement section to get rid of padding without corrupting data
            if(last4Bytes.endsWith('==')) {
                // Note: if using \n\n instead of \r\n replace == with 'oK'
                last4Bytes = last4Bytes.substring(0,2) + '0K';
                bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
                // We have appended the \r\n to the Blob, so leave footer as it is.
                String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
                bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);
            } else if(last4Bytes.endsWith('=')) {
            
                last4Bytes = last4Bytes.substring(0,3) + 'N';
                bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
                // We have appended the CR e.g. \r, still need to prepend the line feed to the footer
                footer = '\n' + footer;
                String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
                bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);              
            } else {
                // Prepend the CR LF to the footer
                footer = '\r\n' + footer;
                String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
                bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);  
            }
        
            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type','multipart/form-data; boundary='+boundary);
            req.setMethod('POST');
            req.setEndpoint(targetURL);
            req.setBodyAsBlob(bodyBlob);
            req.setTimeout(120000);
        
            Http http = new Http();
            HTTPResponse res = http.send(req);
            System.debug( res.getBody()+'===='+res.getStatus() );
            if(res.getStatusCode() == 200){  
                  System.debug( res.getBody());
                  fileIdWithresponse.put(contv.Id, res.getBody());
                    
            } 
          }
          catch (Exception e) {         
            System.debug('Error:' + e.getMessage() + 'Line no:' + e.getLineNumber() );           
          }
       }
       System.debug('fileIdWithresponse' +fileIdWithresponse );   
       List<Banned_URL__mdt> urlMdt =  [SELECT MasterLabel, URL__c FROM Banned_URL__mdt]; 
       Set<String> fileIdsSettoDelete = new Set<String>();
       Set<String> uRLnames = new Set<String>();
        if(!urlMdt.isEmpty() && !fileIdWithresponse.isEmpty()){

          for(Banned_URL__mdt url : urlMdt){
              for(String mapKey :fileIdWithresponse.keySet()){
                   System.debug('id of file' +mapKey );
                   System.debug('id of file' +url.URL__c );
                   System.debug('url' +fileIdWithresponse.get(mapKey) );
                   System.debug('url contains ' +fileIdWithresponse.get(mapKey).contains(url.URL__c) );
                  if(fileIdWithresponse.get(mapKey).contains(url.URL__c)){
                    System.debug('id of file' +mapKey );
                    fileIdsSettoDelete.add(mapKey);
                  }
              }
             
          }

        }
        System.debug('fileIdsSettoDelete' +fileIdsSettoDelete );  
        //List<String> username = new List<String>();
        if(!fileIdsSettoDelete.isEmpty()){
          List<ContentDocument> contentDocments = [SELECT Id,Owner.Name, LatestPublishedVersionId FROM ContentDocument WHERE LatestPublishedVersionId IN: fileIdsSettoDelete];       
          if(!contentDocments.isEmpty()){
            delete contentDocments;
            
          }
          // send email to owner of the file 
          // Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
          // String[] toAddresses = new String[] {};
          // mail.setToAddresses(toAddresses);
          // mail.setSubject('Attached File with banned URL ');
          // mail.setPlainTextBody
          // ('We have scanned your attached file and find banned URL, the record is delete from the system');
          // Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
        }  
                                         
    }   
 
    global void finish(Database.BatchableContext BC){
      // send email
    }
}