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
	Title:	SM Class (vSMClass)
	Created: 11/26/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes: 

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMClass]
(@Co bCompany, @ActiveOnlyYN char(1), @DeleteDataYN char(1))

AS 


/** BACKUP vSMClass TABLE **/
IF OBJECT_ID('vSMClass_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMClass_bak
END;
BEGIN
	SELECT * INTO vSMClass_bak FROM vSMClass
END;


/**DELETE DATA IN vSMClass TABLE**/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMClass NOCHECK CONSTRAINT ALL;
	ALTER TABLE vSMClass DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMClass WHERE SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';	
	ALTER TABLE vSMClass CHECK CONSTRAINT ALL;
	ALTER TABLE vSMClass ENABLE TRIGGER ALL;
END;


/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXID int 
SET @MAXID=(SELECT ISNULL(MAX(SMClassID),0) FROM dbo.vSMClass)


/** POPULATE SM Class **/
SET IDENTITY_INSERT vSMClass ON
ALTER TABLE vSMClass NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMClass DISABLE TRIGGER ALL;

INSERT vSMClass
	(
		 SMClassID
		,SMCo
		,Class
		,Description
		,Active
		,Notes
		--,UniqueAttchID
		--UD Fields
		--,udConvertedYN 
	   )
--declare @Co bCompany set @Co=	
SELECT
		 SMClassID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, xsc.NewClass)
		,SMCo=@Co
		,Class=xsc.NewClass
		,Description=MAX(xsc.NewDescription)
		,Active=MAX(CASE WHEN eqc.QINACTIVE='N' THEN 'Y' ELSE 'N' END)
		,Notes=NULL
		--,UniqueAttchID
		--UD Fields
		--,udConvertedYN='Y'
		
--declare @Co bCompany set @Co=
--declare @ActiveOnlyYN char(1) set @ActiveOnlyYN='Y'
--SELECT *
FROM CV_TL_Source_SM.dbo.EQPCLASS eqc
INNER JOIN budXRefSMClass xsc
	ON xsc.SMCo=@Co and xsc.OldClass=eqc.EQPCLASS
LEFT JOIN vSMClass vcl
	ON vcl.SMCo=@Co and vcl.Class=xsc.NewClass
WHERE vcl.Class IS NULL 
GROUP BY xsc.SMCo, xsc.NewClass
ORDER BY xsc.SMCo, xsc.NewClass;

SET IDENTITY_INSERT vSMClass OFF
ALTER TABLE vSMClass CHECK CONSTRAINT ALL;
ALTER TABLE vSMClass ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from vSMClass where SMCo=@Co;
select * from vSMClass where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMClass where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.EQPCLASS;
**/
GO
