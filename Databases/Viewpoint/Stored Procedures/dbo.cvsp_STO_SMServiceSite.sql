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
	Title:	Convert STO SM Service Sites to VP SM Service Site (vSMServiceSite)	
	Created: 12/05/2012
	Created by:	VCS - Technical Services - Brenda Ackerson
	Revisions:	
		1. 04/16/2013 BBA - Added the budXRefSMRateTemplate and modified the RateTemplate logic
			to get the New RateTemplate from this table and if NULL default to STD. 

IMPORTANT: Originally not designed with a cross reference table if there is a reason we need
one, i.e. to combine Service Sites then we can add one.
		
**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMServiceSite] 
(@Co bCompany, @DeleteDataYN char(1))
 
AS 


/** DECLARE AND SET PARAMETERS **/
DECLARE @CustGroup TINYINT	SET @CustGroup=(SELECT CustGroup FROM bHQCO WHERE HQCo=@Co)

DECLARE @MAXID INT 
SET @MAXID=(SELECT ISNULL(MAX(SMServiceSiteID),0) FROM dbo.vSMServiceSite)


/** BACKUP DATA IN vSMServiceSite TABLE **/
IF OBJECT_ID('vSMServiceSite_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMServiceSite_bak
END;
BEGIN
	SELECT * INTO vSMServiceSite_bak FROM vSMServiceSite
END;


/** DELETE DATA IN vSMServiceSite TABLE **/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMServiceSite DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMServiceSite
		WHERE vSMServiceSite.SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';
	ALTER TABLE vSMServiceSite ENABLE TRIGGER ALL;
END;


/** POPULATE SM SERVICE SITES **/
SET IDENTITY_INSERT vSMServiceSite ON
ALTER TABLE vSMServiceSite NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMServiceSite DISABLE TRIGGER ALL;

INSERT INTO dbo.vSMServiceSite
		(
			SMServiceSiteID
           ,SMCo
           ,ServiceSite
           ,CustGroup
           ,Customer
           ,Description
           ,Address1
           ,Address2
           ,City
           ,State
           ,Zip
           ,Country
           ,Phone
           ,DefaultServiceCenter
           ,ContactGroup
           ,ContactSeq
           ,RateTemplate    
           ,Active
           --,UniqueAttchID
           ,Notes
           ,BillToARCustomer
           ,ReportID
           ,SMRateOverrideID
           ,SMStandardItemDefaultID
           ,CustomerPOSetting
           ,PrimaryTechnician
           ,InvoiceGrouping
           ,Type
           ,Job
           ,JCCo
           ,CostingMethod
           
           --UD Fields
           --,udConvertedYN
		)

SELECT		
			SMServiceSiteID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, ss.SERVSITENBR)
           ,SMCo=@Co
           ,ServiceSite=CAST(ss.SERVSITENBR AS VARCHAR(20))
           ,CustGroup=@CustGroup
           ,Customer=--NOT NULL
				ISNULL(ar.Customer,(SELECT TOP 1 Customer 
									FROM bARCM
									WHERE CustGroup=@CustGroup AND TempYN='Y')
					  )
           ,Description=ss.NAME --45 char
           ,Address1=ss.ADDRESS
           ,Address2=ss.ADDRESS2
           ,City=ss.CITY
           ,State=UPPER(LEFT(ss.STATE,2))
           ,Zip=
				CASE
					WHEN ss.ZIP IS NULL OR ss.ZIP='' THEN NULL
					WHEN ss.COUNTRY=0 AND LEN(RTRIM(ss.ZIP))=5 THEN LEFT(RTRIM(ss.ZIP),5) 
					WHEN ss.COUNTRY=0 AND LEN(RTRIM(ss.ZIP))>5 THEN LEFT(ss.ZIP,5)+'-'+RIGHT(RTRIM(ss.ZIP),4) 					
					ELSE LEFT(RTRIM(ss.ZIP),12)
				END
           ,Country=CASE WHEN ss.COUNTRY=0 THEN 'US' ELSE NULL END
           ,Phone=dbo.cvfn_StandardPhone(ss.MAINPHONE)
           ,DefaultServiceCenter=--NOT NULL
				ISNULL(ctr.ABBREVIATION,(	SELECT TOP 1 ServiceCenter
											FROM vSMServiceCenter
											WHERE SMCo=@Co)
					  )           
           ,ContactGroup=co.ContactGroup
           ,ContactSeq=NULL
           ,RateTemplate=ISNULL(xrt.NewRateTemplate,'STD') --4/16/2013 BBA
           ,Active=CASE WHEN ss.QINACTIVE='N' THEN 'Y' ELSE 'N' END
           --,UniqueAttchID
           ,Notes=MEMO
           ,BillToARCustomer=ar.Customer
           ,ReportID=NULL
           ,SMRateOverrideID=NULL
           ,SMStandardItemDefaultID=NULL
           ,CustomerPOSetting='N' --N=Non Required, R=Required
           ,PrimaryTechnician=xe.VPEmployee
           ,InvoiceGrouping='C' --C=One Per Customer,S=One per Service Site,W=One per Work Order
           ,Type=--'C'=Customer, 'J'=Job
				CASE 
					WHEN ss.JCJOB IS NULL OR ss.JCJOB='' THEN 'Customer' 
					ELSE 'Job' 
				END
           ,Job=xj.NewJob
           ,JCCo=xj.JCCo
           ,CostingMethod=/*	NULL if Type='C' ELSE if Type='J'
				Cost=Actual Cost (Default) - Send actual costs to Job Cost. 
				Revenue=Markup - Send revenue (cost plus markup) as cost to Job Cost.*/
           		CASE 
					WHEN ss.JCJOB IS NULL OR ss.JCJOB='' THEN NULL
					ELSE 'Cost' 
				END
      
--DECLARE @Co bCompany SET @Co=1
--SELECT *
FROM CV_TL_Source_SM.dbo.SERVICESITE ss
INNER JOIN bHQCO co
	ON co.HQCo=@Co
LEFT JOIN budXRefSMRateTemplate xrt --4/16/13 BBA 
	ON xrt.SMCo=co.HQCo AND xrt.OldRateTemplate=ss.RATESHEETNBR		
LEFT JOIN budXRefCustomer xc
	ON xc.CustGroup=co.CustGroup AND xc.OldCustomerID=ss.ARCUST
LEFT JOIN bARCM ar	
	ON ar.CustGroup=xc.CustGroup AND ar.Customer=xc.NewCustomerID
LEFT JOIN CV_TL_Source_SM.dbo.EMPLOYEE se
	ON se.EMPLOYEENBR=ss.TECHNBR	
LEFT JOIN budXRefPREmployee xe
	ON xe.PRCo=@Co and xe.TLEmployee=LTRIM(RTRIM(se.PREMPLOYEE))
LEFT JOIN budXRefJCAllJobs xj
	ON xj.JCCo=co.HQCo AND xj.OldJob=ss.JCJOB AND (xj.TLExtra IS NULL or xj.TLExtra='')		
LEFT JOIN CV_TL_Source_SM.dbo.CENTER ctr
	ON ctr.CENTERNBR=ss.CENTERNBR
LEFT JOIN vSMServiceSite vss
	ON vss.SMCo=co.HQCo AND CAST(vss.ServiceSite AS INT)=ss.SERVSITENBR
WHERE CAST(vss.ServiceSite AS INT) IS NULL 
ORDER BY vss.SMCo, ss.SERVSITENBR; 

SET IDENTITY_INSERT vSMServiceSite OFF
ALTER TABLE vSMServiceSite CHECK CONSTRAINT ALL;
ALTER TABLE vSMServiceSite ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @CustGroup bGroup set @CustGroup=1
SELECT COUNT(*) AS vSMServiceSite_Count FROM vSMServiceSite WHERE CustGroup=@CustGroup;
SELECT * FROM vSMServiceSite WHERE CustGroup=@CustGroup;

SELECT COUNT(*) AS STO_ServiceSite_Count FROM CV_TL_Source_SM.dbo.SERVICESITE ss


/** DATA REVIEW **/
/*
--DECLARE @Co bCompany SET @Co=1
SELECT * FROM dbo.vSMServiceSite WHERE SMCo=@Co;
SELECT * FROM dbo.vSMRateTemplate WHERE SMCo=@Co;
SELECT * FROM dbo.vSMRateOverride WHERE SMCo=@Co;
SELECT * FROM dbo.vSMStandardItemDefault WHERE SMCo=@Co;

SELECT * FROM CV_TL_Source_SM.dbo.SERVICESITE;
SELECT * FROM CV_TL_Source_SM.dbo.CENTER; 
*/

GO
