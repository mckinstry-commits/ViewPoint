SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE proc [dbo].[cvsp_CMS_MASTER_JCPM] (@fromco smallint, @toco smallint,@Delete varchar(1),
	 @errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
	Copyright © 2009 Viewpoint Construction Software (VCS) 
	The TSQL code in this procedure may not be reproduced, modified,
	transmitted or executed without written consent from VCS

=========================================================================
	Title:		JC Phase Master(JCPM)
	Created:	03.30.09
	Created by:	Andrew Bynum
	Purpose:	Populates JC Phase Master table using JCPCCS CMS table.
	Revisions:	1. None
				2. JRE 08/07/09 - created proc & @toc, @fromco
				3. BTC 6/28/2012 - Changed enable trigger statement to disable
					prior to delete statement.
**/

set @errmsg=''
set @rowcount=0

-- get vendor group from HQCO
declare @PhaseGroup smallint
select @PhaseGroup=PhaseGroup from bHQCO where HQCo=@toco

declare @JobFormat varchar(30), @PhaseFormat varchar(30)
Set @JobFormat =  (Select InputMask from vDDDTc where Datatype = 'bJob');

-- get customer defaults
declare @defaultProjMinPct numeric(8,2)
select @defaultProjMinPct=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ProjMinPct' and a.TableName='bJCPM'; -- shared JCPM & JCCI

ALTER Table bJCPM disable trigger all;	

-- delete existing trans
if @Delete = 'Y' 
BEGIN tran
delete from bJCPM where PhaseGroup=@PhaseGroup
COMMIT TRAN;

-- add new trans
BEGIN TRY
BEGIN TRAN

insert into bJCPM (PhaseGroup,Phase,Description,ProjMinPct,udSource, udConv,udCGCTable)

select distinct 
	PhaseGroup=@PhaseGroup
	,Phase=p.newPhase
	,Description=CSD20A
	,ProjMinPct=@defaultProjMinPct
	, udSource ='MASTER_JCPM'
	, udConv='Y'
	,udCGCTable='JCPCCS'
from CV_CMS_SOURCE.dbo.JCPCCS with (nolock)
	join Viewpoint.dbo.budxrefPhase p on p.Company=@toco and p.oldPhase=CSSGVL
where CSCONO=@fromco and CSSGPS=2

select @rowcount=@@rowcount

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bJCPM enable trigger all;

return @@error



GO
