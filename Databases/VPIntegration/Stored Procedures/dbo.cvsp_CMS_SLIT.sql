SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_SLIT] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		SL Items (SLIT)
	Created on:	10.12.09
	Created by:     JJH    
	Revisions:	1. 10/25/2012 BTC - Modified to pull from the record with the 
					earliest sequence rather than just pull MIN and MAX values
					per SL Item.
**/


set @errmsg=''
set @rowcount=0





ALTER Table bSLIT disable trigger ALL;


-- delete existing trans
BEGIN tran
delete from bSLIT where SLCo=@toco;
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY

--alter table bSLIT add udSLContractNo varchar(15)

insert bSLIT (SLCo, SL, SLItem, ItemType,AddonPct,JCCo, Job,PhaseGroup, Phase, JCCType,
	Description,UM,GLCo,GLAcct,WCRetPct,SMRetPct,
	VendorGroup,OrigUnits, OrigUnitCost, OrigCost, CurUnits, CurUnitCost, CurCost,
	StoredMatls,InvUnits,InvCost,AddedMth,udSLContractNo,udSource,udConv)
select @toco
	,SL = sl.SL
	,SLItem = sl.SLItem
	,ItemType = 1
	,AddonPct = 0
	,JCCo = sl.PMCo
	,Job = sl.Project
	,PhaseGroup = sl.PhaseGroup
	,Phase = sl.Phase
	,JCCType = sl.CostType
	,Description = sl.SLItemDescription
	,UM=sl.UM
	,GLCo =@toco
	,GLAcct = 0
	,WCRetPct = sl.WCRetgPct
	,SMRetPct = sl.SMRetgPct
	,VendorGroup = sl.VendorGroup
	,OrigUnits = 0
	,OrigUnitCost = 0
	,OrigCost = 0
	,CurUnits = 0
	,CurUnitCost = 0
	,CurCost = 0
	,StoredMatls = 0
	,InvUnits = 0
	,InvCost = 0
	,AddedMth = CONVERT(varchar(max), MONTH(sl.InterfaceDate)) + '/01/' 
		+ CONVERT(varchar(max), year(sl.InterfaceDate))
	,udSLContractNo = sl.udSLContractNo
	,udSource ='SLIT'
	,udConv ='Y'
from bPMSL sl
join (select PMCo, SL, SLItem, MIN(Seq) as MinSeq from bPMSL group by PMCo, SL, SLItem) m
	on m.PMCo=sl.PMCo and m.SL=sl.SL and m.SLItem=sl.SLItem and m.MinSeq=sl.Seq
where sl.PMCo=@toco and sl.SL is not null 


select @rowcount=@@rowcount;


Update bSLIT Set OrigCost=PMSLAmount
from bSLIT 
	join (select SLCo, SL, SLItem, PMSLAmount=sum(Amount) 
			from bPMSL 
			where RecordType='O' 
				and bPMSL.SLCo=@toco
			group by SLCo, SL, SLItem) 
		as p 
		on bSLIT.SLCo=p.SLCo and bSLIT.SL=p.SL and bSLIT.SLItem=p.SLItem
where bSLIT.SLCo=@toco;


select @rowcount=@rowcount+@@rowcount;



Update bSLIT Set CurCost=PMSLAmount
from bSLIT 
	join (select SLCo, SL, SLItem, PMSLAmount=sum(Amount) 
			from bPMSL 
			where SLCo=@toco
			group by SLCo, SL, SLItem) 
		as p 
		on bSLIT.SLCo=p.SLCo and bSLIT.SL=p.SL and bSLIT.SLItem=p.SLItem
where bSLIT.SLCo=@toco;


select @rowcount=@rowcount+@@rowcount;


update bSLIT set GLAcct= OpenWIPAcct 
from bSLIT
	join bJCJP on bJCJP.JCCo=bSLIT.JCCo and bJCJP.Job=bSLIT.Job and bJCJP.PhaseGroup=bSLIT.PhaseGroup 
		and bJCJP.Phase=bSLIT.Phase
	join bJCCI on bJCJP.JCCo=bJCCI.JCCo and bJCJP.Contract=bJCCI.Contract 
		and bJCJP.Item=bJCCI.Item
	join bJCDC on bJCDC.JCCo=bJCCI.JCCo and bJCDC.Department=bJCCI.Department 
		and bJCDC.PhaseGroup=bJCJP.PhaseGroup and bJCDC.CostType=bSLIT.JCCType
where bSLIT.SLCo=@toco and (bSLIT.GLAcct in ('','0') or bSLIT.GLAcct is null); 

select @rowcount=@rowcount+@@rowcount;




--------------------------------------------------------------------------
----Update SLHD description to match the description of the first item on the SL
--update bSLHD set bSLHD.Description=left(i.Description,30)
--from bSLHD 
--	join (select SLIT.SLCo, SLIT.SL, SLIT.Description
--			from SLIT
--				join (select SLCo, SL, Item=min(SLItem)
--						from SLIT
--						where SLCo=@toco
--						group by SLCo, SL)
--						as t
--						on t.SLCo=SLIT.SLCo and t.SL=SLIT.SL and t.Item=SLIT.SLItem
--			where SLIT.SLCo=@toco
--			) as i
--			on i.SLCo=bSLHD.SLCo and i.SL=bSLHD.SL
--				and bSLHD.Description<>i.Description
--where bSLHD.SLCo=@toco;
			



COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bSLIT enable trigger ALL;

return @@error






GO
