SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_JCCP] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		JC Cost by Period (JCCP)
	Created:	06.21.09
	Created by:	JJH    
	Revisions:	1. None
	Notes:		Rebuilds JCCP from JCCD.
**/



set @errmsg=''
set @rowcount=0

--get Customer default
declare @defaultProjPlug varchar(1)
select @defaultProjPlug=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ProjPlug' and a.TableName='bJCCI'; 
	


ALTER TABLE bJCCP DISABLE TRIGGER ALL;  

-- delete existing trans
BEGIN tran
delete from bJCCP where JCCo=@toco
	--and udConv = 'Y';
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY
	

INSERT bJCCP
	(JCCo
	, Job
	, PhaseGroup
	, Phase
	, CostType
	, Mth
	, ActualHours
	, ActualUnits
	, ActualCost
	, OrigEstHours
	, OrigEstUnits
	, OrigEstCost
	, CurrEstHours
	, CurrEstUnits
	, CurrEstCost
	, ProjHours
	, ProjUnits
	, ProjCost
	, ForecastHours
	, ForecastUnits
	, ForecastCost
	, TotalCmtdUnits
	, TotalCmtdCost
	, RemainCmtdUnits
	, RemainCmtdCost
	, RecvdNotInvcdUnits
	, RecvdNotInvcdCost	
	, ProjPlug
	, udSource
	, udConv
	 )
	 

select JCCD.JCCo
	, JCCD.Job
	, JCCD.PhaseGroup
	, JCCD.Phase
	, JCCD.CostType
	, JCCD.Mth
	, sum(JCCD.ActualHours)
	, sum(JCCD.ActualUnits)
	, sum(JCCD.ActualCost)
	, sum(case when JCCD.JCTransType='OE' then JCCD.EstHours else 0 end)
	, sum(case when JCCD.JCTransType='OE' then JCCD.EstUnits else 0 end)
	, sum(case when JCCD.JCTransType='OE' then JCCD.EstCost else 0 end)
	, sum(JCCD.EstHours)
	, sum(JCCD.EstUnits)
	, sum(JCCD.EstCost)
	, sum(JCCD.ProjHours)
	, sum(JCCD.ProjUnits)
	, sum(JCCD.ProjCost)
	, ForecastHours=0
	, ForecastUnits=0
	, ForecastCost=0
	, sum(TotalCmtdUnits)
	, sum(TotalCmtdCost)
	, sum(RemainCmtdUnits)
	, sum(RemainCmtdCost)
	, RecvdNotInvcdUnits=0
	, RecvdNotInvcdCost=0
	, ProjPlug=@defaultProjPlug
	, udSource ='JCCP'
	, udConv='Y'
from JCCD with(nolock)
where JCCD.JCCo=@toco
group by JCCD.JCCo, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType, JCCD.Mth
   

select @rowcount=@@rowcount;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER TABLE bJCCP ENABLE TRIGGER ALL;

return @@error

GO
