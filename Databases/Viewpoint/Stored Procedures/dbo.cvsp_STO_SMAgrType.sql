SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================================
Copyright Â© 2013 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================================
	Title:	SM Agreement Type (vSMAgreementType)
	Created: 12/03/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes: 

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMAgrType]
(@Co bCompany, @DeleteDataYN char(1))

AS 


/** BACKUP vSMAgreementType TABLE **/
IF OBJECT_ID('vSMAgreementType_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMAgreementType_bak
END;
BEGIN
	SELECT * INTO vSMAgreementType_bak FROM vSMAgreementType
END;


/**DELETE DATA IN vSMAgreementType TABLE**/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMAgreementType NOCHECK CONSTRAINT ALL;
	ALTER TABLE vSMAgreementType DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMAgreementType WHERE SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';	
	ALTER TABLE vSMAgreementType CHECK CONSTRAINT ALL;
	ALTER TABLE vSMAgreementType ENABLE TRIGGER ALL;	
END;


/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXID int 
SET @MAXID=(SELECT ISNULL(MAX(AgreementTypeID),0) FROM dbo.vSMAgreementType)


/** POPULATE SM Agreement Type **/
SET IDENTITY_INSERT vSMAgreementType ON
ALTER TABLE vSMAgreementType NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMAgreementType DISABLE TRIGGER ALL;

INSERT vSMAgreementType
	(
		 AgreementTypeID
		,SMCo
		,AgreementType
		,Description
		,Active		
		,Department
		,Notes
		--,UniqueAttchID
		--UD Fields
		--,udConvertedYN 
	   )
--declare @Co bCompany set @Co=	
SELECT
		 AgreementTypeID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, xat.NewAgrType)
		,SMCo=@Co
		,AgreementType=xat.NewAgrType
		,Description=MAX(xat.NewDescription)
		,Active=MAX(case when agt.QINACTIVE='N' then 'Y' else 'N' end)
		,Department=MAX(xdt.NewSMDept)
		,Notes=NULL
		--,UniqueAttchID
		--UD Fields
		--,udConvertedYN='Y'
		
--declare @Co bCompany set @Co=
--SELECT *
FROM CV_TL_Source_SM.dbo.AGRTYPE agt
INNER JOIN budXRefSMDept xdt
	ON xdt.OldSMDept=agt.DEPTNBR
INNER JOIN budXRefSMAgrTypes xat
	ON xat.SMCo=@Co and xat.OldAgrType=agt.AGRTYPENBR
LEFT JOIN vSMAgreementType vat
	ON vat.SMCo=@Co and vat.AgreementType=xat.NewAgrType
WHERE  vat.AgreementType IS NULL 
GROUP BY xat.SMCo, xat.NewAgrType
ORDER BY xat.SMCo, xat.NewAgrType;


SET IDENTITY_INSERT vSMAgreementType OFF
ALTER TABLE vSMAgreementType CHECK CONSTRAINT ALL;
ALTER TABLE vSMAgreementType ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from vSMAgreementType where SMCo=@Co;
select * from vSMAgreementType where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMAgreementType where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.AGRTYPE;
**/
GO
