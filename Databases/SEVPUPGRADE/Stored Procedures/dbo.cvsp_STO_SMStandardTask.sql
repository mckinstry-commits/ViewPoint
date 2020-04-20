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
	Title:	SM Standard Task (vSMStandardTask)
	Created: 11/21/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes: 

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SMStandardTask]
(@Co bCompany, @DeleteDataYN char(1))

AS 


/** BACKUP vSMStandardTask TABLE **/
IF OBJECT_ID('vSMStandardTask_bak','U') IS NOT NULL
BEGIN
	DROP TABLE vSMStandardTask_bak
END;
BEGIN
	SELECT * INTO vSMStandardTask_bak FROM vSMStandardTask
END;


/**DELETE DATA IN vSMStandardTask TABLE**/
IF @DeleteDataYN IN('Y','y')
BEGIN
	ALTER TABLE vSMStandardTask NOCHECK CONSTRAINT ALL;
	ALTER TABLE vSMStandardTask DISABLE TRIGGER ALL;
	BEGIN TRAN
		DELETE vSMStandardTask WHERE SMCo=@Co
	COMMIT TRAN
	CHECKPOINT;
	WAITFOR DELAY '00:00:02.000';	
	ALTER TABLE vSMStandardTask CHECK CONSTRAINT ALL;
	ALTER TABLE vSMStandardTask ENABLE TRIGGER ALL;	
END;


/** DECLARE AND SET PARAMETERS **/
DECLARE @MAXID int 
SET @MAXID=(SELECT ISNULL(MAX(SMStandardTaskID),0) FROM dbo.vSMStandardTask)


/** POPULATE SM Standard Tasks **/
SET IDENTITY_INSERT vSMStandardTask ON
ALTER TABLE vSMStandardTask NOCHECK CONSTRAINT ALL;
ALTER TABLE vSMStandardTask DISABLE TRIGGER ALL;

INSERT INTO dbo.vSMStandardTask
	(
	    SMStandardTaskID
	   ,SMCo
       ,SMStandardTask
       ,Name
       ,Description
       ,Notes
		--,UniqueAttchID
		--UD Fields
		--,udConvertedYN 
	)

--declare @Co bCompany set @Co=
SELECT
	    SMStandardTaskID=@MAXID+ROW_NUMBER() OVER (ORDER BY @Co, xst.NewStdTask)
	   ,SMCo=@Co
       ,SMStandardTask=xst.NewStdTask
       ,Name=MAX(xst.NewName)
       ,Description=MAX(xst.NewDescription)
       ,Notes=NULL
		--,UniqueAttchID
		--UD Fields
		--,udConvertedYN 

--declare @Co bCompany set @Co=1
--SELECT *
FROM CV_TL_Source_SM.dbo.STANDARDTASK st
LEFT JOIN budXRefSMStdTasks xst
	ON xst.SMCo=@Co AND xst.OldStdTask=st.STANDARDTASK
LEFT JOIN vSMStandardTask vst
	ON vst.SMCo=@Co AND vst.SMStandardTask=xst.NewStdTask
WHERE vst.SMStandardTask IS NULL 
GROUP BY xst.SMCo, xst.NewStdTask
ORDER BY xst.SMCo, xst.NewStdTask;

SET IDENTITY_INSERT vSMStandardTask OFF
ALTER TABLE vSMStandardTask CHECK CONSTRAINT ALL;
ALTER TABLE vSMStandardTask ENABLE TRIGGER ALL;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
SELECT COUNT(*) FROM vSMStandardTask WHERE SMCo=@Co;
SELECT * FROM vSMStandardTask WHERE SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMStandardTask where SMCo=@Co;
select * from budXRefSMStdTasks where SMCo=@Co;

select * from CV_TL_Source_SM.dbo.STANDARDTASK st
**/
GO
