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
	Title:	SM Work Scope (vSMWorkScope)
	Created: 11/26/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 01/18/2013 BBA Modified PriorityName to use High, Med and Low instead of
			integers.

Notes: 

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMWorkScope]
(@Co bCompany, @DeleteDataYN char(1))

AS 


/** BACKUP vSMWorkScope TABLE **/
IF OBJECT_ID('vSMWorkScope_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMWorkScope_bak
END;
BEGIN
	SELECT * INTO vSMWorkScope_bak FROM vSMWorkScope
END;


/** DELETE DATA IN vSMWorkScope TABLE **/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMWorkScope NOCHECK CONSTRAINT ALL;
	ALTER TABLE vSMWorkScope DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMWorkScope WHERE SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';	
	ALTER TABLE vSMWorkScope CHECK CONSTRAINT ALL;
	ALTER TABLE vSMWorkScope ENABLE TRIGGER ALL;	
END;


/** DECLARE AND SET PARAMETERS **/
declare @MAXID int 
set @MAXID=(select ISNULL(MAX(WorkScopeID),0) from dbo.vSMWorkScope)


/** POPULATE SM Work Scope **/
SET IDENTITY_INSERT vSMWorkScope ON
ALTER TABLE vSMWorkScope NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMWorkScope DISABLE TRIGGER ALL;

INSERT INTO dbo.vSMWorkScope
	(
	    WorkScopeID
	   ,SMCo
       ,WorkScope
       ,Description
       ,WorkScopeSummary
       ,Notes
		--,UniqueAttchID
	   ,PriorityName
	   ,PhaseGroup
	   ,Phase	 
		--UD Fields
		--,udConvertedYN 
	)

--declare @Co bCompany set @Co=
SELECT
	    WorkScopeID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, xws.NewWorkScope)
	   ,SMCo=@Co
       ,WorkScope=xws.NewWorkScope
       ,Description=MAX(xws.NewDescription)
       ,WorkScopeSummary=MAX(xws.NewDescription)
       ,Notes=NULL
	   ,PriorityName= --May Need Modified, STO has no PRIORITY table.
		MIN(CASE 
				WHEN PRIORITY=10 THEN 'High' 
				WHEN PRIORITY=20 THEN 'Med'
				WHEN PRIORITY=30 THEN 'Low'
				ELSE 3
			END)
	   ,PhaseGroup=MAX(co.PhaseGroup)
	   ,Phase=NULL       
		--,UniqueAttchID
		--UD Fields
		--,udConvertedYN 

--declare @Co bCompany set @Co=1
--SELECT *
FROM CV_TL_Source_SM.dbo.PROBLEMS p
INNER JOIN bHQCO co
	ON co.HQCo=@Co
INNER JOIN budXRefSMWorkScopes xws	
	ON xws.SMCo=@Co AND	xws.OldProblemCode=p.PROBLEMCODE
LEFT JOIN vSMWorkScope vws
	ON vws.SMCo=@Co AND vws.WorkScope=xws.NewWorkScope
WHERE vws.Notes IS NULL 
GROUP BY xws.SMCo, xws.NewWorkScope
ORDER BY xws.SMCo, xws.NewWorkScope;

SET IDENTITY_INSERT vSMWorkScope OFF
ALTER TABLE vSMWorkScope CHECK CONSTRAINT ALL;
ALTER TABLE vSMWorkScope ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
SELECT COUNT(*) FROM vSMWorkScope WHERE SMCo=@Co;
SELECT * FROM vSMWorkScope WHERE SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMWorkScope where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.PROBLEMS;
**/
GO
