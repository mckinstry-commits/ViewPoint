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
	Title:	Populate SM Equipment Types (budXRefSMEQPTypes) Cross Reference Table
	Created: 10/16/2012
	Created by:	VCS Technical Services
	Revisions:	
		1. 

Notes:

**/

CREATE PROCEDURE [dbo].[cvsp_STO_SM_XRefSMEQPTypes]
(@Co bCompany, @DeleteDataYN char(1))

AS 

/** DECLARE AND SET PARAMETERS **/
declare @MAXSeq int set @MAXSeq=(select ISNULL(MAX(Seq),0) from budXRefSMEQPTypes) 


/** BACKUP budXRefSMEQPTypes TABLE **/
IF OBJECT_ID('budXRefSMEQPTypes_bak','U') IS NOT NULL
BEGIN
	DROP TABLE budXRefSMEQPTypes_bak
END;
BEGIN
	SELECT * INTO budXRefSMEQPTypes_bak FROM dbo.budXRefSMEQPTypes
END;


/**DELETE DATA IN budXRefSMEQPTypes TABLE**/
if @DeleteDataYN IN('Y','y')
begin
	delete budXRefSMEQPTypes where SMCo=@Co
end;


/** CHANGE NewYN='N' FOR REFRESH **/
update budXRefSMEQPTypes
set NewYN='N'
where SMCo=@Co and NewYN='Y'


/** INSERT/UPDATE SM EQUIPMENT TYPES XREFERENCE TABLE **/
IF OBJECT_ID('budXRefSMEQPTypes') IS NOT NULL
BEGIN
	INSERT dbo.budXRefSMEQPTypes
		(
				Seq
			   ,OldSMCo
			   ,OldEQPType
			   ,OldDescription
			   ,OldClass
			   ,SMCo
			   ,NewEQPType
			   ,NewDescription
			   ,NewClass
			   ,ActiveYN
			   ,NewYN
			   --,UniqueAttchID
			   ,Notes
		   )
	--declare @Co bCompany set @Co=	
	SELECT
				Seq=@MAXSeq+ROW_NUMBER () OVER (ORDER BY @Co,eqt.EQPTYPE)
			   ,OldSMCo=@Co
			   ,OldType=eqt.EQPTYPE
			   ,OldDescription=eqt.DESCRIPTION
			   ,OldClass=eqt.EQPCLASS
			   ,SMCo=@Co
			   ,NewType=eqt.EQPTYPE --Default
			   ,NewDescription=eqt.DESCRIPTION
			   ,NewClass=xsc.NewClass
			   ,ActiveYN=case when QINACTIVE='N' then 'Y' else 'N' end
			   ,NewYN='Y'
			   --,UniqueAttchID
			   ,Notes=NULL
		
	--declare @Co bCompany set @Co=
	--SELECT *
	FROM CV_TL_Source_SM.dbo.EQPTYPE eqt
	INNER JOIN budXRefSMClass xsc
		ON xsc.SMCo=@Co and xsc.OldClass=eqt.EQPCLASS	
	LEFT JOIN budXRefSMEQPTypes xt
		ON xt.SMCo=@Co and xt.OldEQPType=eqt.EQPTYPE
	WHERE xt.OldEQPType IS NULL
	ORDER BY xt.SMCo, xt.OldEQPType;
END;


/** RECORD COUNT **/
--declare @Co bCompany set @Co=	
select COUNT(*) from budXRefSMEQPTypes where SMCo=@Co;
select * from budXRefSMEQPTypes where SMCo=@Co;


/** DATA REVIEW 
--declare @Co bCompany set @Co=	
select * from vSMType where SMCo=@Co;
select * from CV_TL_Source_SM.dbo.EQPTYPE
**/


GO
