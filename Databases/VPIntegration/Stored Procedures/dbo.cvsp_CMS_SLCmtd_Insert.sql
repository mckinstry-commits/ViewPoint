SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE proc [dbo].[cvsp_CMS_SLCmtd_Insert] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		SL Committed Insert to JC 
	Created:	07.30.09
	Created by: JJH  

	Notes:		Updates committed cost in JC from SL 

	Revisions:	1. 8.29.10 - added SLCompany restriction in the parameters
				2. 10/26/2012 BTC - Added restriction on JCCD delete for SL records only.
						Needed so that we can delete PO records separately.
				3. 10/26/2012 BTC - Modified to update committed cost with Original Amounts.
						Change Order amounts to be updated in separate procedure so that they
						update JCCD in the correct months.
**/



set @errmsg=''
set @rowcount=0

--delete trans
BEGIN TRAN
delete bJCCD where JCCo=@toco and udSource='SLCmtd_Insert'
COMMIT TRAN;


alter table bJCCD disable trigger btJCCDi;
alter table bJCCP disable trigger btJCCPi;

-- add new trans
BEGIN TRAN
BEGIN TRY

insert into bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
			UM,PostedUM,
			JCTransType, Source, Description, ReversalStatus, TotalCmtdCost, 
			RemainCmtdCost, JBBillStatus, SL, SLItem, APCo, Vendor,udSource,udConv)

select JCCo=s.JCCo
	, Mth=s.AddedMth
	, CostTrans=isnull(t.LastTrans,1) + ROW_NUMBER() OVER (PARTITION by s.SLCo, s.AddedMth ORDER BY s.SLCo, s.AddedMth)
	, Job=s.Job
	, PhaseGroup=s.PhaseGroup
	, Phase=s.Phase
	, CostType=s.JCCType
	, PostedDate=s.AddedMth
	, ActualDate=s.AddedMth
	, UM=s.UM
	, PostedUM=s.UM
	, JCTransType='SL'
	, Source='SL Entry'
	, Description=s.Description
	, ReversalStatus=0
	, TotalCmtdCost=s.OrigCost --s.CurCost
	, RemainCmtdCost=s.OrigCost --s.CurCost
	, JBBillStatus=2
	, SL=s.SL
	, SLItem=s.SLItem 
	, APCo=s.SLCo
	, Venodr=h.Vendor
	, udSource='SLCmtd_Insert'
	,udConv ='Y'
from bSLIT s 
	join bJCJP jp on s.JCCo=jp.JCCo and s.Job=jp.Job and s.Phase=jp.Phase --only updates SL where phases exist
	left join bHQTC t on s.SLCo=t.Co and s.AddedMth=t.Mth and t.TableName='bJCCD' 
	left join bSLHD h on s.SLCo=h.SLCo and s.SL=h.SL
where s.SLCo=@toco 
	and s.AddedMth is not null


select @rowcount=@@rowcount;



COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bJCCD enable trigger btJCCDi;
alter table bJCCP enable trigger btJCCPi;

return @@error






GO
