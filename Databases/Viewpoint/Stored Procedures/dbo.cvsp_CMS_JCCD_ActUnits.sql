
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure  [dbo].[cvsp_CMS_JCCD_ActUnits] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		JC Cost Detail - ActualUnits
	Created:	08.12.09
	Created by:	SR  
	Notes:		
	Revisions:	1. JRE 08/10/09 Actual Hours
				2. 7/16/10 - JH - Standardized units process to pull from JCTQYD


**/


set @errmsg=''
set @rowcount=0

--get defaults from HQCO
declare @PhaseGroup tinyint
select @PhaseGroup=PhaseGroup from bHQCO where HQCo=@toco;

--get Customer defaults
declare @defaultUM varchar(3), @defaultEarnFactor numeric(5,3), @defaultEarnType tinyint,
	@DefaultUM char(3), @DefaultUMUnits char(3)
select @defaultUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DefaultUM' and a.TableName='bJCCH';

--get Customer defaults
select @defaultEarnFactor=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='EarnFactor' and a.TableName='bJCCD';

select @defaultEarnType=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='EarnType' and a.TableName='bJCCD';

--get Customer defaults
select @DefaultUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DefaultUM' and a.TableName='bJCCH';

select @DefaultUMUnits=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DefaultUMUnits' and a.TableName='bJCCH';

--declare variables for functions
Declare @Job varchar(30)
Set @Job =  (Select InputMask from vDDDTc where Datatype = 'bJob')


ALTER Table bJCCD disable trigger ALL;
ALTER Table bJCCP disable trigger ALL;

-- delete existing trans
BEGIN tran
delete from bJCCD where JCCo=@toco and ActualUnits<>0
	and udConv='Y';
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY

insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,UM,PostedUM,
                 JCTransType, Source, ReversalStatus, ActualUnits,
				JBBillStatus, Description, PostedUnits,udSource,udConv,udCGCTable,udCGCTableID )


select JCCo = @toco
	,Mth =  substring(convert(nvarchar(max),j.SUPPLDATE01),5,2) + '/01/' + substring(convert(nvarchar(max),j.SUPPLDATE01),1,4)
	,CostTrans = isnull(t.LastTrans,1) + ROW_NUMBER() OVER (PARTITION by t.Co,substring(convert(nvarchar(max),j.SUPPLDATE01),5,2) 
		+ '/01/' + substring(convert(nvarchar(max),j.SUPPLDATE01),1,4)
		 ORDER BY t.Co, substring(convert(nvarchar(max),j.SUPPLDATE01),5,2) + '/01/' 
		+ substring(convert(nvarchar(max),j.SUPPLDATE01),1,4))
	,Job = dbo.bfMuliPartFormat(RTRIM(j.JOBNUMBER) + '.' + RTRIM(j.SUBJOBNUMBER),@Job)
	,PhaseGroup = @PhaseGroup
	,Phase = xrefPhase.newPhase
	,CostType = xrefCostType.CostType
	,PostedDate = substring(convert(nvarchar(max),j.SUPPLDATE01),5,2) + '/' + 
		substring(convert(nvarchar(max),j.SUPPLDATE01),7,2)+ '/' + substring(convert(nvarchar(max),j.SUPPLDATE01),1,4)
	,ActualDate = substring(convert(nvarchar(max),j.SUPPLDATE01),5,2) + '/' + 
		substring(convert(nvarchar(max),j.SUPPLDATE01),7,2)+ '/' + substring(convert(nvarchar(max),j.SUPPLDATE01),1,4)
	,UM = isnull(h.UM,'EA')
	,PostedUM = isnull(h.UM,'EA')
	,JCTransType= 'JC'
	,Source='JC CostAdj' -- unsure but we are limited too only so many choices
	,ReversalStatus = 0
	,ActualUnits = j.COSTQTY90
	,JBBillStatus = 2
	,Description ='Convted Act Units'
	,PostedUnits= j.COSTQTY90
	,udSource ='JCCD_ActUnits'
	, udConv='Y'
	,udCGCTable='JCTQYD'
	,udCGCTableID=null
from CV_CMS_SOURCE.dbo.JCTQYD j
	join Viewpoint.dbo.budxrefPhase xrefPhase on xrefPhase.Company=@fromco and xrefPhase.oldPhase=j.JCDISTRIBTUION
	join Viewpoint.dbo.budxrefCostType xrefCostType on xrefCostType.Company=@fromco 
				and xrefCostType.CMSCostType=j.COSTTYPE
	left join bJCCH h on h.JCCo=@toco and h.Job=dbo.bfMuliPartFormat(RTRIM(j.JOBNUMBER) + '.' + RTRIM(j.SUBJOBNUMBER),@Job)
		and h.Phase=xrefPhase.newPhase and h.CostType=xrefCostType.CostType
	left join bHQTC t on substring(convert(nvarchar(max),j.SUPPLDATE01),5,2) + '/01/' + 
		substring(convert(nvarchar(max),j.SUPPLDATE01),1,4)=t.Mth and t.Co=@toco
		and t.TableName='bJCCD'
where j.COSTQTY90<>0 
	and j.COMPANYNUMBER=@fromco


select @rowcount=@@rowcount;





COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bJCCD enable trigger ALL;
ALTER Table bJCCP enable trigger ALL;

return @@error


GO
