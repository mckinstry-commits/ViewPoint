SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE proc [dbo].[cvsp_CMS_JCCH_ZeroEst] 
	( @fromco1	smallint
	, @fromco2	smallint
	, @fromco3	smallint
	, @toco		smallint
	, @errmsg	varchar(1000) output
	, @rowcount bigint output
	) 
as


/**
=========================================================================
	Copyright © 2009 Viewpoint Construction Software (VCS) 
	The TSQL code in this procedure may not be reproduced, modified,
	transmitted or executed without written consent from VCS

=========================================================================
	Title:		JC Original Job Estimates (JCCH) 
	Created:	11.13.09
	Created by:	JJH
	Purpose:	Inserts a record for phases with cost detail that weren't inserted with original script.
	Revisions:	1. none
**/

set @errmsg=''
set @rowcount=0


--get customer defaults
declare @BillFlag char(1), @ItemUnitFlag char(1), @PhaseUnitFlag char(1), 
	@BuyOutYN char(1), @Plugged char(1), @ActiveYN char(1), @SourceStatus char(1),
	@DefaultUM char(3), @DefaultUMUnits char(3)

select @BillFlag=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='BillFlag' and a.TableName='bJCCH';

select @ItemUnitFlag=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ItemUnitFlag' and a.TableName='bJCCH';

select @PhaseUnitFlag=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PhaseUnitFlag' and a.TableName='bJCCH';

select @BuyOutYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='BuyOutYN' and a.TableName='bJCCH';

select @Plugged=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Plugged' and a.TableName='bJCCH';

select @ActiveYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ActiveYN' and a.TableName='bJCCH';

select @SourceStatus=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='SourceStatus' and a.TableName='bJCCH';

select @DefaultUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DefaultUM' and a.TableName='bJCCH';

select @DefaultUMUnits=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@toco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DefaultUMUnits' and a.TableName='bJCCH';


ALTER Table bJCCH disable trigger all;

-- add new trans
BEGIN TRAN
BEGIN TRY

insert into bJCCH (JCCo, Job, PhaseGroup,Phase, CostType,UM,BillFlag,ItemUnitFlag,PhaseUnitFlag, 
	BuyOutYN,Plugged,ActiveYN,OrigHours,OrigUnits,OrigCost,SourceStatus, udSource,udConv)

select JCCD.JCCo
	, JCCD.Job
	, JCCD.PhaseGroup
	, JCCD.Phase
	, JCCD.CostType
	, min(isnull(JCCD.UM,@DefaultUM))
	, @BillFlag
	, @ItemUnitFlag
	, @PhaseUnitFlag
	, @BuyOutYN
	, @Plugged
	, @ActiveYN
	, OrigHours=0
	, OrigUnits=0
	, OrigCost=0
	, @SourceStatus
	, udSource = 'JCCH_ZeroEst'
	, udConv='Y'
from bJCCD JCCD
	left join bJCCH JCCH on JCCD.JCCo=JCCH.JCCo and JCCD.Job=JCCH.Job
		and JCCD.Phase=JCCH.Phase and JCCD.CostType=JCCH.CostType
where JCCD.JCCo=@toco 
	and JCCH.JCCo is null 
group by JCCD.JCCo, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType;


 
select @rowcount=@@rowcount



COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


ALTER Table bJCCH enable trigger all;

return @@error


GO
