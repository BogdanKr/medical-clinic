/**
 * Created by Bogdan_Krasun on 20.12.2022.
 */

public with sharing class MetadataService {
    public static void updateCustomMetadata(String accessToken) {

        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = 'GoogleAuthSetting.JamesBlack';
        customMetadata.label = 'James Black';
        customMetadata.protected_x = true;

//        Metadata.CustomMetadataValue docEmailMeta = new Metadata.CustomMetadataValue();
//        docEmailMeta.field = 'Doctor_email__c';
//        docEmailMeta.value = 'James.Black.doc@gmail.com';
//        customMetadata.values.add(docEmailMeta);
//        Metadata.CustomMetadataValue refreshTokenMeta = new Metadata.CustomMetadataValue();
//        refreshTokenMeta.field = 'RefreshToken__c';
//        refreshTokenMeta.value = '1//062uF8Zg_d6LhCgYIARAAGAYSNwF-L9IrYx6qMAXHfrV5JjtC0nSoKidSQg3HpD9T0kIpXKvJI8fm_LfzFtb7a_iFcwysWyPvVPY';
//        customMetadata.values.add(refreshTokenMeta);
        Metadata.CustomMetadataValue accessTokenMetaData = new Metadata.CustomMetadataValue();
        accessTokenMetaData.field = 'AccessToken__c';
        accessTokenMetaData.value = accessToken;
        customMetadata.values.add(accessTokenMetaData);
        Metadata.CustomMetadataValue expTimeMeta = new Metadata.CustomMetadataValue();
        expTimeMeta.field = 'Expiration_Time__c';
        expTimeMeta.value = System.now().addSeconds(3599);
        customMetadata.values.add(expTimeMeta);

        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);
        CustomMetadataCallback callback = new CustomMetadataCallback();
        Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
    }

    public static void createCustomMetadata(String email, String name, String accessToken, String refreshToken) {

        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = 'GoogleAuthSetting.' + name.replace(' ', '');
        customMetadata.label = name;
        customMetadata.protected_x = true;

        Metadata.CustomMetadataValue docEmailMeta = new Metadata.CustomMetadataValue();
        docEmailMeta.field = 'Doctor_email__c';
        docEmailMeta.value = email;
        customMetadata.values.add(docEmailMeta);
        Metadata.CustomMetadataValue refreshTokenMeta = new Metadata.CustomMetadataValue();
        refreshTokenMeta.field = 'RefreshToken__c';
        refreshTokenMeta.value = refreshToken;
        customMetadata.values.add(refreshTokenMeta);
        Metadata.CustomMetadataValue accessTokenMetaData = new Metadata.CustomMetadataValue();
        accessTokenMetaData.field = 'AccessToken__c';
        accessTokenMetaData.value = accessToken;
        customMetadata.values.add(accessTokenMetaData);
        Metadata.CustomMetadataValue expTimeMeta = new Metadata.CustomMetadataValue();
        expTimeMeta.field = 'Expiration_Time__c';
        expTimeMeta.value = System.now().addSeconds(3599);
        customMetadata.values.add(expTimeMeta);

        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);
        CustomMetadataCallback callback = new CustomMetadataCallback();
        Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
    }


    public class CustomMetadataCallback implements Metadata.DeployCallback {

        public void handleResult(Metadata.DeployResult result,
                Metadata.DeployCallbackContext context) {
            if (result.status == Metadata.DeployStatus.Succeeded) {
                System.debug(' success : ' + result);
            } else {
                System.debug(' fail : ' + result);
            }
        }
    }
}