SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE procedure  [dbo].[cvsp_CMS_JCCD] 
	( @fromco1	smallint
	, @fromco2	smallint
	, @fromco3	smallint
	, @toco		smallint
	, @errmsg	varchar(1000) output
	, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		JC Cost Detail
	Created:	08.12.09
	Created by:	SR  
	Notes:		CMS Job Cost Posting table contains all the costs AND revenue, 
				and has records that aren't job related at all. Viewpoint we split out cost 
				from revenue into two tables JCCD for cost and JCID for revenue
				JCID will get updated in the AR Container and the Costs for AP comes from the AP Container. 
				The where clause below is filtering out AR and AP cost types and or source - SR

				Because we are turning the insert trigger off, which would update JCCP, 
				we have to update JCCP here. If the record exists then update JCCP, if it doesn't exist then insert - SR

	Revisions:	1. JRE 08/10/09 Actual Hours
				2. BTC 10/03/13 Added JCJobs cross reference


**/


set @errmsg=''
set @rowcount=0

--get defaults from HQCO
declare @PhaseGroup tinyint
select @PhaseGroup=PhaseGroup from bHQCO where HQCo=@toco;

--get Customer defaults
declare @defaultUM varchar(3), @defaultEarnFactor numeric(5,3), @defaultEarnType tinyint
select @defaultUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DefaultUM' and a.TableName='bJCCH';




--declare variables for functions
Declare @Job varchar(30)
Set @Job =  (Select InputMask from vDDDTc where Datatype = 'bJob')




ALTER Table bJCCD disable trigger ALL;
ALTER Table bJCCP disable trigger ALL;

-- delete existing trans
BEGIN tran
delete from bJCCD where JCCo=@toco and ActualCost<>0
	and udConv='Y';
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY

insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,UM,PostedUM,
                 JCTransType, Source, ReversalStatus, ActualCost, ActualHours,JBBillStatus, Description, 
				GLTransAcct,udSource,udConv,udCGCTable,udCGCTableID)

select JCCo=@toco
	, Mth = substring(convert(nvarchar(max),j.ENTEREDDATE),5,2) + '/01/' + substring(convert(nvarchar(max),j.ENTEREDDATE),1,4)
	, CostTrans = isnull(t.LastTrans,1) + row_number() over (partition by @toco order by @toco)
	, Job = xj.VPJob -- dbo.bfMuliPartFormat(RTRIM(j.JOBNUMBER) + RTRIM(j.SUBJOBNUMBER),@Job)
	, PhaseGroup = @PhaseGroup
	, Phase = p.newPhase
	,CostType =c.CostType
	,PostedDate = substring(convert(nvarchar(max),j.ENTEREDDATE),5,2) + '/' 
			+ substring(convert(nvarchar(max),j.ENTEREDDATE),7,2)+ '/' + substring(convert(nvarchar(max),j.ENTEREDDATE),1,4)
	,ActualDate = substring(convert(nvarchar(max),j.ENTEREDDATE),5,2) + '/' 
				+ substring(convert(nvarchar(max),j.ENTEREDDATE),7,2)+ '/' + substring(convert(nvarchar(max),j.ENTEREDDATE),1,4)
	,UM = @defaultUM
	,PostedUM = @defaultUM
	/* Navajo had had a problem the valid Sources in the insert trigger of JCCD are 
	 -- validate Source
    if @source not in ('AP Entry', 'JC OrigEst','JC CostAdj','JC Projctn', 'JC Progres', 'JC MatUse',
     					'JC ChngOrd', 'PO Entry', 'PO Close','PO Change', 'PO Receipt', 'SL Change', 'SL Close', 
    					'SL Entry', 'PM Intface', 'PR Entry', 'AR Receipt', 'EMRev', 'MS Tickets', 'IN MatlOrd',
    					----TK-07440
    					'JC Plugged', 'Roll Up', 'PO Dist')
    	begin
    	select @errmsg = 'Invalid Source.'
    	GoTo error
    	End
       
	
	,JCTransType= 'JC'
	,Source=case 
		WHEN LEFT(JOURNALCTL,2) = 'GJ' THEN 'GL Jrnl' 
		WHEN LEFT(JOURNALCTL,2) = 'SA' THEN 'AR Entry'  
		WHEN LEFT(JOURNALCTL,2) = 'PJ' THEN 'AP Entry'
		WHEN LEFT(JOURNALCTL,2) = 'PR' THEN 'PR Update' 
		WHEN LEFT(JOURNALCTL,2) = 'CD' THEN 'AP Payment' 
		WHEN LEFT(JOURNALCTL,2) = 'CR' THEN 'AR Receipt' 
		WHEN LEFT(JOURNALCTL,2) = 'EQ' THEN 'EMRev' 
		ELSE 'JC CostAdj' 
	END
	*/
	, JCTransType= Case 
		WHEN LEFT(JOURNALCTL,2) = 'GJ' THEN 'JC' 
		WHEN LEFT(JOURNALCTL,2) = 'SA' THEN 'AR'  
		WHEN LEFT(JOURNALCTL,2) = 'PJ' THEN 'AP'
		WHEN LEFT(JOURNALCTL,2) = 'PR' THEN 'PR' 
		WHEN LEFT(JOURNALCTL,2) = 'CD' THEN 'AP' 
		WHEN LEFT(JOURNALCTL,2) = 'CR' THEN 'AR' 
		WHEN LEFT(JOURNALCTL,2) = 'EQ' THEN 'EM' 
		ELSE 'JC' END
	,Source='JC CostAdj' 
	,ReversalStatus = 0
	,ActualCost = GLAMT
	,ActualHours=REGHOURS+OVTHRS+OTHHRS
	,JBBillStatus = 2
	,Description =left(((case when RECORDTYPE<>'' then RECORDTYPE + ' / ' else '' end) + TRANSSOURCE + ' ' + DESC20A),60)
	,GLTransAcct = GENLEDGERACCT
	,udSource='JCCD'
	, udConv='Y'
	,udCGCTable='JCTPST'
	,udCGCTableID= j.JCTPSTID
	
from CV_CMS_SOURCE.dbo.JCTPST j
	
 JOIN [MCK_MAPPING_DATA ].[dbo].[McKCGCActiveJobsForConversion2] jobs 
		ON	jobs.GCONO = j.COMPANYNUMBER
		AND jobs.GJBNO     = j.JOBNUMBER
		and jobs.GSJNO  = j.SUBJOBNUMBER
		and jobs.GDVNO = j.DIVISIONNUMBER
	
join Viewpoint.dbo.budxrefJCJobs xj
	on xj.COMPANYNUMBER = j.COMPANYNUMBER and xj.DIVISIONNUMBER = j.DIVISIONNUMBER and xj.JOBNUMBER = j.JOBNUMBER 
		and xj.SUBJOBNUMBER = j.SUBJOBNUMBER and xj.VPJob is not null
	
left join HQTC t on substring(convert(nvarchar(max),j.ENTEREDDATE),5,2) + '/01/' + 
			substring(convert(nvarchar(max),j.ENTEREDDATE),1,4)=t.Mth and t.Co=@toco and t.TableName='bJCCD'
			
join Viewpoint.dbo.budxrefPhase p 
	on p.Company=@PhaseGroup 
	and p.oldPhase=j.JCDISTRIBTUION
	
join Viewpoint.dbo.budxrefCostType c 
	on c.Company=@PhaseGroup 
	and c.CMSCostType=j.COSTTYPE
	
where j.COMPANYNUMBER in (@fromco1,@fromco2,@fromco3)
	and COSTTYPE not in ('','R') 
	and ENTEREDDATE<>0;


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
