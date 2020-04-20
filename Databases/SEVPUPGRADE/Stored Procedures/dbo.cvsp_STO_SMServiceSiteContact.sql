SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================================
Copyright Â© 2012 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================================
	Title:	Convert STO SM Service Site Contact to VP SM Service Site (vSMServiceSiteContactContact)	
	Created: 12/06/2012
	Created by:	VCS - Technical Services - Brenda Ackerson
	Revisions:	
		1. 

	IMPORTANT: 
		
**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMServiceSiteContact] 
(@Co bCompany, @DeleteDataYN char(1))
 
AS 


/** DECLARE AND SET PARAMETERS **/
DECLARE @ContactGroup TINYINT	SET @ContactGroup=(SELECT ContactGroup FROM bHQCO WHERE HQCo=@Co)

DECLARE @MAXID INT 
SET @MAXID=(SELECT ISNULL(MAX(SMServiceSiteContactID),0) FROM dbo.vSMServiceSiteContact)


/** BACKUP DATA IN vSMServiceSiteContact TABLE **/
IF OBJECT_ID('vSMServiceSiteContact_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMServiceSiteContact_bak
END;
BEGIN
	SELECT * INTO vSMServiceSiteContact_bak FROM vSMServiceSiteContact
END;


/** DELETE DATA IN vSMServiceSiteContact TABLE **/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMServiceSiteContact DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMServiceSiteContact
		WHERE vSMServiceSiteContact.SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';
	ALTER TABLE vSMServiceSiteContact ENABLE TRIGGER ALL;
END;


/** POPULATE SM SERVICE SITE CONTACT **/
SET IDENTITY_INSERT vSMServiceSiteContact ON
ALTER TABLE vSMServiceSiteContact NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMServiceSiteContact DISABLE TRIGGER ALL;

INSERT INTO dbo.vSMServiceSiteContact
		(
			SMServiceSiteContactID
           ,SMCo
           ,ServiceSite
           ,ContactGroup
           ,ContactSeq
           
           --UD Fields
           --,udConvertedYN
		)

SELECT		
			SMServiceSiteContactID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, ss.SERVSITENBR, vsc.ContactSeq)
           ,SMCo=@Co
           ,ServiceSite=vss.ServiceSite
           ,ContactGroup=co.ContactGroup
           ,ContactSeq=vhc.ContactSeq

--DECLARE @Co bCompany SET @Co=1
--SELECT *
FROM CV_TL_Source_SM.dbo.SERVICESITE_CONTACTS ss
INNER JOIN bHQCO co
	ON co.HQCo=@Co
INNER JOIN vSMServiceSite vss
	ON vss.SMCo=co.HQCo AND CAST(vss.ServiceSite AS INT)=ss.SERVSITENBR
LEFT JOIN vHQContact vhc
	ON vhc.ContactGroup=co.ContactGroup AND vhc.Notes='SM Service Site Contact'
		AND vhc.udSTOContactID=ss.SMCONTACTID
LEFT JOIN vSMServiceSiteContact vsc
	ON vsc.SMCo=@Co AND CAST(vsc.ServiceSite AS INT)=ss.SERVSITENBR
		AND vsc.ContactGroup=co.ContactGroup AND vsc.ContactSeq=vhc.ContactSeq
WHERE vsc.ContactSeq IS NULL 
ORDER BY vsc.SMCo, ss.SERVSITENBR, vsc.ContactSeq; 

SET IDENTITY_INSERT vSMServiceSiteContact OFF
ALTER TABLE vSMServiceSiteContact CHECK CONSTRAINT ALL;
ALTER TABLE vSMServiceSiteContact ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @ContactGroup bGroup set @ContactGroup=1
SELECT COUNT(*) AS vSMServiceSiteContact_Count FROM vSMServiceSiteContact WHERE ContactGroup=@ContactGroup;
SELECT * FROM vSMServiceSiteContact WHERE ContactGroup=@ContactGroup;

SELECT COUNT(*) AS STO_ServiceSiteContacts_Count 
FROM CV_TL_Source_SM.dbo.SERVICESITE_CONTACTS ss


/** DATA REVIEW **/
/*
--DECLARE @Co bCompany SET @Co=
SELECT * FROM dbo.vSMServiceSite WHERE SMCo=@Co;
SELECT * FROM dbo.vSMServiceSiteContact WHERE SMCo=@Co;
SELECT * FROM dbo.vHQContact WHERE Notes='SM Service Site Contact' AND HQCo=@Co;


SELECT * FROM CV_TL_Source_SM.dbo.SERVICESITE;
SELECT * FROM CV_TL_Source_SM.dbo.CENTER; 
*/

GO
