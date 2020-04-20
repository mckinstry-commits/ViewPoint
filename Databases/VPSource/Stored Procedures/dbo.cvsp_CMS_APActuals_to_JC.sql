SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_APActuals_to_JC]  (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AP Committed Reductions to JC (JCCD)
	Created:	07.30.09
	Created by:	JJH    
	Revisions:	1. None
	Notes:		Inserts AP activity to JC - updates actual cost and committed
**/



set @errmsg=''
set @rowcount=0

--get default UM
declare @defaultUM varchar(3)
select @defaultUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='UM' and a.TableName='bAPTL';


ALTER table bJCCP disable trigger btJCCPi;
ALTER table bJCCD disable trigger btJCCDi;

--no deletes necessary - already made in cvsp_CGC_SLCmtd_Insert


-- add new trans
BEGIN TRAN
BEGIN TRY

insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate, UM, PostedUM,
				JCTransType, Source, ReversalStatus, ActualCost, JBBillStatus, 
				VendorGroup, Vendor, APCo, APTrans, APLine, APRef, TaxGroup, TaxCode,
				TaxAmt, RemainCmtdCost, SL, SLItem, PO, POItem, Description,udSource,udConv)

select JCCo=a.APCo
	, Mth=a.Mth
	, CostTrans=isnull(t.LastTrans,1) + ROW_NUMBER() OVER (PARTITION by a.APCo, a.Mth ORDER BY a.APCo, a.Mth)
	, Job=a.Job
	, PhaseGroup=a.PhaseGroup
	, Phase=a.Phase
	, CostType=a.JCCType
	, PostedDate=a.Mth
	, ActualDate=a.Mth
	, UM=isnull(j.UM, @defaultUM)
	, PostedUM=isnull(a.UM, @defaultUM)
	, JCTransType='AP'
	, Source='AP Entry'
	, ReversalStatus=0
	, ActualCost=0
	, JBBillStatus=2
	, VendorGroup=h.VendorGroup
	, Vendor=h.Vendor
	, APCo=a.APCo
	, APTrans=a.APTrans
	, APLine=a.APLine
	, APRef=h.APRef
	, TaxGroup=a.TaxGroup
	, TaxCode=a.TaxCode
	, TaxAmt=a.TaxAmt
	, RemainCmtdCost=case when a.LineType in (7,6) then a.GrossAmt * -1 else 0 end
	, SL=case when a.LineType=7 then a.SL else null end
	, SLItem=case when a.LineType=7 then a.SLItem else null end
	, PO=case when a.LineType=6 then a.PO else null end
	, POItem=case when a.LineType=6 then a.POItem else null end
	, Description=a.Description
	, udSource ='APActuals_to_JC'
	, udConv='Y'
	
from bAPTL a 

	join bAPTH h 
		on a.APCo=h.APCo 
		and a.Mth=h.Mth 
		and a.APTrans=h.APTrans
		
	left join HQTC t 
		on a.APCo=t.Co 
		and a.Mth=t.Mth 
		and t.TableName='bJCCD'
		
	left join JCCH j 
		on a.APCo=j.JCCo 
		and a.Job=j.Job 
		and a.Phase=j.Phase 
		and a.JCCType=j.CostType
		
	left join SLIT s 
		on a.APCo=s.SLCo 
		and a.SL=s.SL 
		and a.SLItem=s.SLItem
	
	
where a.APCo=@toco
	and a.Job is not null 
	and j.Job is not null
	and isnull(a.udSubHistYN,'N')='N';--restricts purged history from updating to JC, done separately


select @rowcount=@@rowcount;



COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


ALTER table bJCCD enable trigger all;
ALTER table bJCCP enable trigger all;

return @@error


GO
