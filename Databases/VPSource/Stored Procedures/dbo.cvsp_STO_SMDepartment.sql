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
	Title:	SM Departments (vSMDepartment)
	Created: 05/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 11/21/2012 BBA - Modified to use a new UD Cross Ref: SM Dept.
		2. 11/26/2012 BBA - Added disable and enable trigger commands.
		3. 12/07/2012 BBA - Added default parameters for Revenue and Cost accounts.

Notes: IMPORTANT: Set defaults to use for Cost and Revenue accounts below.

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMDepartment]
(@Co bCompany, @DefaultVPRevAccount bGLAcct, @DefaultVPCostAccount bGLAcct, @DeleteDataYN char(1)) 

AS 


/** BACKUP vSMDepartment TABLE **/
IF OBJECT_ID('vSMDepartment_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMDepartment_bak
END;
BEGIN
	SELECT * INTO vSMDepartment_bak FROM vSMDepartment
END;


/**DELETE DATA IN vSMDepartment TABLE**/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMDepartment NOCHECK CONSTRAINT ALL;
	ALTER TABLE vSMDepartment DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMDepartment WHERE SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';	
	ALTER TABLE vSMDepartment CHECK CONSTRAINT ALL;
	ALTER TABLE vSMDepartment ENABLE TRIGGER ALL;
END;


/** DECLARE AND SET PARAMETERS **/
--DECLARE @DefaultVPRevAccount bGLAcct
SET @DefaultVPRevAccount  =' 40000.40           '

--DECLARE @DefaultVPCostAccount bGLAcct
SET @DefaultVPCostAccount =' 50000.42           '

DECLARE @MAXID int 
SET @MAXID=(SELECT ISNULL(MAX(SMDepartmentID),0) FROM dbo.vSMDepartment)


/** POPULATE SM Departments **/
SET IDENTITY_INSERT vSMDepartment ON
ALTER TABLE vSMDepartment NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMDepartment DISABLE TRIGGER ALL;

INSERT vSMDepartment
	(
		SMDepartmentID
	   ,SMCo
       ,Department
       ,Description
       ,GLCo
       ,EquipCostGLAcct
       ,LaborCostGLAcct
       ,MiscCostGLAcct
       ,MaterialCostGLAcct
       ,EquipRevGLAcct
       ,LaborRevGLAcct
       ,MiscRevGLAcct
       ,MaterialRevGLAcct
       ,EquipCostWIPGLAcct
       ,LaborCostWIPGLAcct
       ,MiscCostWIPGLAcct
       ,MaterialCostWIPGLAcct
       ,EquipRevWIPGLAcct
       ,LaborRevWIPGLAcct
       ,MiscRevWIPGLAcct
       ,MaterialRevWIPGLAcct
       ,Notes
		--,UniqueAttchID
		--UD Fields
		--,udConvertedYN 
	   )
--declare @Co bCompany set @Co=	
SELECT
		 SMDepartmentID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, xsd.NewSMDept)
		,SMCo=@Co
		,Department=xsd.NewSMDept
		,Description=MAX(xsd.NewDescription)
		,GLCo=@Co
		,EquipCostGLAcct=@DefaultVPCostAccount
		,LaborCostGLAcct=@DefaultVPCostAccount
		,MiscCostGLAcct=@DefaultVPCostAccount
		,MaterialCostGLAcct=@DefaultVPCostAccount
		,EquipRevGLAcct=@DefaultVPRevAccount
		,LaborRevGLAcct=@DefaultVPRevAccount
		,MiscRevGLAcct=@DefaultVPRevAccount
		,MaterialRevGLAcct=@DefaultVPRevAccount
		,EquipCostWIPGLAcct=@DefaultVPCostAccount
		,LaborCostWIPGLAcct=@DefaultVPCostAccount
		,MiscCostWIPGLAcct=@DefaultVPCostAccount
		,MaterialCostWIPGLAcct=@DefaultVPCostAccount
		,EquipRevWIPGLAcct=@DefaultVPRevAccount
		,LaborRevWIPGLAcct=@DefaultVPRevAccount
		,MiscRevWIPGLAcct=@DefaultVPRevAccount
		,MaterialRevWIPGLAcct=@DefaultVPRevAccount
		,Notes=NULL
		--,UniqueAttchID
		--UD Fields
		--,udConvertedYN='Y'
		
--declare @Co bCompany set @Co=1
--SELECT *
FROM CV_TL_Source_SM.dbo.DEPT d
LEFT JOIN budXRefSMDept xsd
	ON xsd.SMCo=@Co AND xsd.OldSMDept=d.DEPTNBR
LEFT JOIN vSMDepartment vdt
	ON vdt.SMCo=@Co AND vdt.Department=xsd.NewSMDept
WHERE vdt.Department IS NULL 
GROUP BY xsd.SMCo, xsd.NewSMDept
ORDER BY xsd.SMCo, xsd.NewSMDept;

SET IDENTITY_INSERT vSMDepartment OFF
ALTER TABLE vSMDepartment CHECK CONSTRAINT ALL;
ALTER TABLE vSMDepartment ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from vSMDepartment where SMCo=@Co;
select * from vSMDepartment where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMDepartment where SMCo=@Co;
select * from budXRefSMDept where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.DEPT
**/
GO
