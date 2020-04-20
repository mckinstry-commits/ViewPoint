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
	Title:	Populate SM Std Tasks (XRefSMStdTasks) Cross Reference Table
	Created: 10/16/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes:

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_XRefSMStdTasks]
(@Co bCompany, @DeleteDataYN char(1))

AS 

/** DECLARE AND SET PARAMETERS **/
declare @MAXSeq int set @MAXSeq=(select ISNULL(MAX(Seq),0) from budXRefSMStdTasks) 


/** BACKUP budXRefSMStdTasks TABLE **/
IF OBJECT_ID('budXRefSMStdTasks_bak','U') IS NOT NULL
BEGIN
	DROP TABLE budXRefSMStdTasks_bak
END;
BEGIN
	SELECT * INTO budXRefSMStdTasks_bak FROM dbo.budXRefSMStdTasks
END;


/**DELETE DATA IN budXRefSMStdTasks TABLE**/
if @DeleteDataYN IN('Y','y')
begin
	delete budXRefSMStdTasks where SMCo=@Co
end;


--/** CHANGE NewYN='N' FOR REFRESH **/
update budXRefSMStdTasks
set NewYN='N'
where SMCo=@Co and NewYN='Y'


/** INSERT/UPDATE SM STANDARD TASKS XREFERENCE TABLE **/
IF OBJECT_ID('budXRefSMStdTasks') IS NOT NULL
BEGIN
	INSERT dbo.budXRefSMStdTasks
		(
				Seq
			   ,OldSMCo
			   ,OldStdTask
			   ,OldDescription
			   ,SMCo
			   ,NewStdTask
			   ,NewName
			   ,NewDescription
			   ,ActiveYN
			   ,NewYN
			   --,UniqueAttchID
			   ,Notes
		   )
	--declare @Co bCompany set @Co=	
	SELECT
				Seq=@MAXSeq+ROW_NUMBER () OVER (ORDER BY @Co,st.STANDARDTASK)
			   ,OldSMCo=@Co
			   ,OldStdTask=STANDARDTASK
			   ,OldDescription=[DESCRIPTION]
			   ,SMCo=@Co
			   ,NewStdTask=STANDARDTASK --Default
			   ,NewName=[DESCRIPTION]			   
			   ,NewDescription=[DESCRIPTION]
			   ,ActiveYN=case when QINACTIVE='N' then 'Y' else 'N' end
			   ,NewYN='Y'
			   --,UniqueAttchID
			   ,Notes=NULL
		
	--declare @Co bCompany set @Co=
	--SELECT *
	FROM CV_TL_Source_SM.dbo.STANDARDTASK st
	LEFT JOIN budXRefSMStdTasks xst
		ON xst.SMCo=@Co and xst.OldStdTask=st.STANDARDTASK
	WHERE xst.OldStdTask IS NULL
	ORDER BY xst.SMCo, st.STANDARDTASK;
END;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from budXRefSMStdTasks where SMCo=@Co;
select * from budXRefSMStdTasks where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMPayType where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.STANDARDTASK;
**/


GO
