SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure  [dbo].[cvsp_CMS_MASTER_JCPC] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		JC Phase Cost Types (JCPC)
	Created:	10.21.09
	Created by:	JJH
	Revisions:	1. Modified to join JCPM so that records are only created for 
		existing Phase Master records.


**/


set @errmsg=''
set @rowcount=0



--get defaults from HQCO
declare @PhaseGroup tinyint
select @PhaseGroup=PhaseGroup from bHQCO where HQCo=@toco

--get Customer defaults
declare @defaultBillFlag char(1), @defaultUM char(3), @defaultItemUnitFlag char(1), 
	@defaultPhaseUnitFlag char(1)

--Bill Flag
select @defaultBillFlag=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='BillFlag' and a.TableName='bJCCH';

--Default UM
select @defaultUM=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='DefaultUM' and a.TableName='bJCCH';

--Item Unit Flag
select @defaultItemUnitFlag=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ItemUnitFlag' and a.TableName='bJCCH';

--Phase Unit Flag
select @defaultPhaseUnitFlag=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PhaseUnitFlag' and a.TableName='bJCCH';

--delete trans
BEGIN tran
delete from bJCPC where PhaseGroup=@PhaseGroup
	--and udConv = 'Y';
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY

insert into bJCPC (PhaseGroup, Phase, CostType, BillFlag, UM, ItemUnitFlag, PhaseUnitFlag,udSource,udConv)
select @PhaseGroup, ch.Phase, ch.CostType, @defaultBillFlag, 
	@defaultUM, @defaultItemUnitFlag, @defaultPhaseUnitFlag, udSource='MASTER_JCPC', udConv='Y'
from bJCCH ch
join bJCPM pm
	on pm.PhaseGroup=ch.PhaseGroup and pm.Phase=ch.Phase
where ch.JCCo=@toco
group by ch.Phase, ch.CostType



select @rowcount=@rowcount+@@rowcount;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


return @@error


GO
