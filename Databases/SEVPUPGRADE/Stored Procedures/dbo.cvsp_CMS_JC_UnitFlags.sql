SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure  [dbo].[cvsp_CMS_JC_UnitFlags] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		JC Item and Phase Unit Flags
	Created:	04.12.09
	Created by:	JRE  
	Revisions:	1. none


**/



set @errmsg=''
set @rowcount=0

--get HQCO defaults
declare @PhaseGroup tinyint
select @PhaseGroup=PhaseGroup from bHQCO where HQCo=@toco


BEGIN TRAN
BEGIN TRY

-- set all flags to 'N'
alter table bJCCH disable trigger btJCCHu;
update bJCCH set ItemUnitFlag='N', PhaseUnitFlag='N' 
where ItemUnitFlag<>'N' 
	and PhaseUnitFlag<>'N'
	and JCCo=@toco;


select @rowcount=@@rowcount;


update bJCCH set ItemUnitFlag='Y'
from bJCCH
	join bJCJP on bJCCH.JCCo=bJCJP.JCCo and bJCCH.Job=bJCCH.Job and
				 bJCJP.PhaseGroup = bJCCH.PhaseGroup AND bJCJP.Phase = bJCCH.Phase
	Join (select  bJCJP.JCCo, bJCJP.Contract, bJCJP.Item, ItemPhase=MIN(bJCCH.Phase),
				FirstCT=min(bJCCH.CostType)
		  from bJCJP 
				join bJCCH on bJCJP.JCCo = bJCCH.JCCo 
					and bJCJP.Job = bJCCH.Job 
					and bJCJP.PhaseGroup = bJCCH.PhaseGroup 
					and bJCJP.Phase = bJCCH.Phase
		where bJCJP.JCCo=@toco
		group by bJCJP.JCCo, bJCJP.Contract, bJCJP.Item) 
		as PUCT
		on PUCT.JCCo=bJCJP.JCCo
			and PUCT.Contract=bJCJP.Contract  and PUCT.Item=bJCJP.Item
			and PUCT.ItemPhase=bJCJP.Phase and PUCT.FirstCT=bJCCH.CostType
where bJCCH.JCCo=@toco;   
    

select @rowcount=@rowcount+@@rowcount;
        
update bJCCH set PhaseUnitFlag='Y'
from bJCCH
Join (select bJCCH.JCCo, bJCCH.Job, bJCCH.PhaseGroup, bJCCH.Phase,
            FirstCT=min(bJCCH.CostType)
		from bJCCH 
		where bJCCH.JCCo=@toco
		group by bJCCH.JCCo, bJCCH.Job, bJCCH.PhaseGroup, bJCCH.Phase) 
		as CUCT
		on CUCT.JCCo=bJCCH.JCCo and CUCT.Job=bJCCH.Job 
			and CUCT.PhaseGroup= bJCCH.PhaseGroup and CUCT.Phase = bJCCH.Phase
			and CUCT.FirstCT=bJCCH.CostType
where bJCCH.JCCo=@toco;      


select @rowcount=@rowcount+@@rowcount;

-- turn trigger back on
alter table bJCCH enable trigger all;


--- JCPC ----
-- set all flags to 'N'
alter table bJCPC disable trigger btJCPCu;
update bJCPC set ItemUnitFlag='N', PhaseUnitFlag='N' 
where (ItemUnitFlag<>'N' or PhaseUnitFlag<>'N')
	and bJCPC.PhaseGroup=@PhaseGroup;  
      

select @rowcount=@rowcount+@@rowcount;

update bJCPC set PhaseUnitFlag='Y'
from bJCPC
Join (select bJCPC.PhaseGroup, bJCPC.Phase,
            FirstCT=min(bJCPC.CostType)
		from bJCPC 
		group by bJCPC.PhaseGroup, bJCPC.Phase) 
		as CUCT
		on CUCT.PhaseGroup= bJCPC.PhaseGroup and CUCT.Phase = bJCPC.Phase
			and CUCT.FirstCT=bJCPC.CostType
where bJCPC.PhaseGroup=@PhaseGroup;  


select @rowcount=@rowcount+@@rowcount;

alter table bJCPC enable trigger all;




COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bJCCH enable trigger all;
alter table bJCPC enable trigger all;

return @@error



GO
