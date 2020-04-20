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
	Title:	SM Standard Item (vSMStandardItem)
	Created: 12/04/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 12/07/2012 BBA - Added group by but expect that they would only want to combine
			duplicate items that have the same cost and rate.

Notes: Misc Cost Offset GL Acct
Enter the GL account to use as the offset account when posting miscellaneous work completed lines 
(via SM Batches and SM Batch Process) that reference this standard item. Must be a valid account 
(set up in GL Chart of Accounts) with a subledger code of S-Service or null.
When processing a miscellaneous work completed batch, the system will post one entry to each 
line's transaction account (as defined in SM Departments) and one offsetting entry to this account.

If this field is left blank, the Miscellaneous Cost Offset Account specified in SM Company Parameters
will be used.

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMStandardItem]
(@Co bCompany, @DeleteDataYN char(1))

AS 


/** BACKUP vSMStandardItem TABLE **/
IF OBJECT_ID('vSMStandardItem_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMStandardItem_bak
END;
BEGIN
	SELECT * INTO vSMStandardItem_bak FROM vSMStandardItem
END;


/**DELETE DATA IN vSMStandardItem TABLE**/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMStandardItem NOCHECK CONSTRAINT ALL;
	ALTER TABLE vSMStandardItem DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMStandardItem WHERE SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';	
	ALTER TABLE vSMStandardItem CHECK CONSTRAINT ALL;
	ALTER TABLE vSMStandardItem ENABLE TRIGGER ALL;	
END;


/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXID int 
SET @MAXID=(SELECT ISNULL(MAX(SMStandardItemID),0) FROM dbo.vSMStandardItem)


/** POPULATE SM Standard Items **/
SET IDENTITY_INSERT vSMStandardItem ON
ALTER TABLE vSMStandardItem NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMStandardItem DISABLE TRIGGER ALL;

INSERT INTO dbo.vSMStandardItem
	(
	    SMStandardItemID
	   ,SMCo
       ,StandardItem
       ,Description
       ,CostRate
       ,BillableRate
       ,SMCostType
       ,MiscCostOffsetGLCo
       ,MiscCostOffsetGLAcct
       ,Notes
		--,UniqueAttchID
		--UD Fields
		--,udConvertedYN 
	)

--declare @Co bCompany set @Co=
SELECT
	    SMStandardItemID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, xsi.NewStdItem)
	   ,SMCo=@Co
       ,StandardItem=xsi.NewStdItem
       ,Description=MAX(xsi.NewDescription)
       ,CostRate=MAX(mi.UNITCOST)--MAY NEED CHANGED IF GROUPING, ASSUMPTION IS SAME COST
       ,BillableRate=MAX(mi.UNITSALE)--MAY NEED CHANGED IF GROUPING, ASSUMPTION IS SAME RATE
       ,SMCostType=MAX(xct.NewCostType)
       ,MiscCostOffsetGLCo=@Co
       ,MiscCostOffsetGLAcct=NULL --See notes above.
       ,Notes=NULL
		--,UniqueAttchID
		--UD Fields
		--,udConvertedYN 

--declare @Co bCompany set @Co=1
--SELECT *
FROM CV_TL_Source_SM.dbo.MISCITEMS mi
INNER JOIN budXRefSMStdItems xsi
	ON xsi.SMCo=@Co AND xsi.OldStdItem=mi.MISCITEMNBR
LEFT JOIN budXRefSMCostTypes xct
	ON xct.SMCo=@Co AND xct.OldCostType=mi.PRODUCT
LEFT JOIN vSMStandardItem vsi
	ON vsi.SMCo=@Co AND vsi.StandardItem=xsi.NewStdItem
WHERE vsi.StandardItem IS NULL
GROUP BY xsi.SMCo, xsi.NewStdItem 
ORDER BY xsi.SMCo, xsi.NewStdItem;

SET IDENTITY_INSERT vSMStandardItem OFF
ALTER TABLE vSMStandardItem CHECK CONSTRAINT ALL;
ALTER TABLE vSMStandardItem ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
SELECT COUNT(*) FROM vSMStandardItem WHERE SMCo=@Co;
SELECT * FROM vSMStandardItem WHERE SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMStandardItem where SMCo=@Co;
select * from budXRefSMStdItems where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.MISCITEMS;
**/
GO
