SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure  [dbo].[cvsp_CMS_JC_JCCD_OrigEst] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Insert Original Estimates to JCCD
	Created:	10.26.09
	Created by:	JJH 
	Revisions:	1. none


**/


set @errmsg=''
set @rowcount=0


ALTER Table bJCCD disable trigger ALL;
ALTER Table bJCCP disable trigger ALL;

-- delete existing trans
BEGIN tran
delete from bJCCD where JCCo=@toco and (EstCost<>0 or EstHours<>0 or EstUnits<>0)
	and JCTransType='OE';
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY


insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,UM,PostedUM,
                 JCTransType, Source, ReversalStatus, EstCost, EstHours, EstUnits, Description, udSource,udConv)
select bJCCH.JCCo
	, bJCCM.StartMonth
	, CostTrans=isnull(t.LastTrans,1) + row_number() over (partition by bJCCH.JCCo order by bJCCH.JCCo)
	, bJCCH.Job
	, bJCCH.PhaseGroup
	, bJCCH.Phase
	, bJCCH.CostType
	, bJCCM.StartMonth
	, bJCCM.StartMonth
	, bJCCH.UM
	, bJCCH.UM
	, JCTransType='OE'
	, Source='JC OrigEst'
	, ReversalStatus=0
	, EstCost=bJCCH.OrigCost
	, EstHours=bJCCH.OrigHours
	, EstUnits=bJCCH.OrigUnits
	, Description='Original Estimate'
	, udSource ='JC_JCCD_OrigEst'
	, udConv='Y'
from bJCCH
	join bJCJM on bJCCH.JCCo=bJCJM.JCCo and bJCCH.Job=bJCJM.Job
	join bJCCM on bJCJM.JCCo=bJCCM.JCCo and bJCJM.Contract=bJCCM.Contract
	left join bHQTC t on bJCCH.JCCo=t.Co and bJCCM.StartMonth=t.Mth and t.TableName='bJCCD'
where bJCCH.JCCo=@toco
	
select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bJCCD enable trigger ALL;
ALTER Table bJCCP enable trigger ALL

return @@error

GO
