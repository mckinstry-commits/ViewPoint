SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure [dbo].[cvsp_CMS_COTypes] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		JC Change Order Type Table
	Created:	10.15.09
	Created by:	JJH
	Notes:		This table must be updated for each customer individually
	Revisions:	1. none
**/



set @errmsg=''
set @rowcount=0


drop table CV_CMS_SOURCE.dbo.COTypes;
create table CV_CMS_SOURCE.dbo.COTypes
	(COType			varchar(4)		null,
	ContOnly		char(1)			null,
	SubOnly			char(1)			null,
	CostOnly		char(1)			null,
	SubCostOnly		char(1)			null,
	ContCostOnly	char(1)			null,
	UpdateAll		char(1)			null)
	

-- add new trans
BEGIN TRAN
BEGIN TRY

insert into CV_CMS_SOURCE.dbo.COTypes (COType)
select distinct CHGORDERTYPE from CV_CMS_SOURCE.dbo.JCTCGH
where CHGORDERTYPE<>'  '
order by CHGORDERTYPE;

--default all to No
update CV_CMS_SOURCE.dbo.COTypes 
set ContOnly='N', 
	SubOnly='N',
	CostOnly='N',
	SubCostOnly='N',
	ContCostOnly='N',
	UpdateAll='N'

--Update individual types based on how they are used in CMS by the customer

update CV_CMS_SOURCE.dbo.COTypes set ContCostOnly='Y'              where COType='1';
update CV_CMS_SOURCE.dbo.COTypes set UpdateAll='Y'                 where COType='2';
update CV_CMS_SOURCE.dbo.COTypes set SubOnly='Y', SubCostOnly ='Y' where COType='3';


 select @rowcount=@@rowcount;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


return @@error

GO
