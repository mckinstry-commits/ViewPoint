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
	Title:	SM Service Center (vSMServiceCenter)
	Created: 12/05/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

IMPORTANT: Originally not designed with a cross reference table if there is a reason we need
one, i.e. to combine Service Centers then we can add one.

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMServiceCenter]
(@Co bCompany, @DeleteDataYN char(1))

AS 


/** BACKUP vSMServiceCenter TABLE **/
IF OBJECT_ID('vSMServiceCenter_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMServiceCenter_bak
END;
BEGIN
	SELECT * INTO vSMServiceCenter_bak FROM vSMServiceCenter
END;


/**DELETE DATA IN vSMServiceCenter TABLE**/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMServiceCenter NOCHECK CONSTRAINT ALL;
	ALTER TABLE vSMServiceCenter DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMServiceCenter WHERE SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';	
	ALTER TABLE vSMServiceCenter CHECK CONSTRAINT ALL;
	ALTER TABLE vSMServiceCenter ENABLE TRIGGER ALL;	
END;


/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXID int 
SET @MAXID=(SELECT ISNULL(MAX(ServiceCenterID),0) FROM dbo.vSMServiceCenter)


/** POPULATE SM SERVICE CENTER **/
SET IDENTITY_INSERT vSMServiceCenter ON
ALTER TABLE vSMServiceCenter NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMServiceCenter DISABLE TRIGGER ALL;

INSERT vSMServiceCenter
	(
		 ServiceCenterID
		,SMCo
		,ServiceCenter
		,Description
		,Address
		,Address2
		,City
		,State
		,Zip
		,Country
		,Phone
		,Fax
		,EMail
		,Active
		,Notes
		--,UniqueAttchID
		,TaxGroup
		,TaxCode
		,Department
		,ARCo
				
		--UD Fields
		--,udConvertedYN 
	   )
--declare @Co bCompany set @Co=	
SELECT
		 ServiceCenterID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, ctr.CENTERNBR)
		,SMCo=@Co
		,ServiceCenter=ctr.ABBREVIATION --Both are varchar(10)
		,Description=ctr.NAME
		,Address=ctr.ADDRESS
		,Address2=ctr.ADDRESS2
		,City=ctr.CITY
		,State=ctr.STATE
		,Zip=ctr.ZIP
		,Country=CASE WHEN ctr.COUNTRY=0 THEN 'US' ELSE NULL END
		,Phone=dbo.cvfn_StandardPhone(ctr.PHONE)
		,Fax=dbo.cvfn_StandardPhone(ctr.FAX)
		,EMail=NULL
		,Active=CASE WHEN ctr.QINACTIVE='N' THEN 'Y' ELSE 'N' END
		,Notes=NULL
		--,UniqueAttchID
		,TaxGroup=co.TaxGroup
		,TaxCode=xt.NewTaxCode --Defaults to a non-multilevel tax code.
		,Department=(SELECT TOP 1 Department FROM vSMDepartment WHERE SMCo=@Co)
		,ARCo=@Co

		--UD Fields
		--,udConvertedYN='Y'
		
--declare @Co bCompany set @Co=
--SELECT *
FROM CV_TL_Source_SM.dbo.CENTER ctr
INNER JOIN bHQCO co
	ON co.HQCo=@Co
LEFT JOIN budXRefHQTaxes xt
	ON xt.NewTaxGroup=co.TaxGroup AND xt.OldTaxCode=ctr.TAXGROUP
LEFT JOIN vSMServiceCenter vsc
	ON vsc.SMCo=co.HQCo AND vsc.ServiceCenter=ctr.ABBREVIATION 
WHERE vsc.ServiceCenter IS NULL 
ORDER BY vsc.SMCo, ctr.CENTERNBR;

SET IDENTITY_INSERT vSMServiceCenter OFF
ALTER TABLE vSMServiceCenter CHECK CONSTRAINT ALL;
ALTER TABLE vSMServiceCenter ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
SELECT COUNT(*) FROM vSMServiceCenter WHERE SMCo=@Co;
SELECT * FROM vSMServiceCenter WHERE SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMServiceCenter where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.CENTER;
select * from CV_TL_Source_SM.dbo.DEPT;

--Taxes
select * from bHQTX where HQCo=@Co;
select * from budXRefHQTaxes where HQCo=@Co;
**/


GO
