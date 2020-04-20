SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_SLStatus] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AP Payment Detail (APPD)
	Created:	10.13.09
	Created by: JJH  
	Revisions:	1. 9.23.10 - Added code to change status to closed on subcontracts when job is closed - JH
**/



set @errmsg=''
set @rowcount=0



ALTER Table bSLHD disable trigger btSLHDu;


-- add new trans
BEGIN TRAN
BEGIN TRY


Update bSLHD Set Status=2
from bSLHD 
	join (select SLCo, SL, Rem=sum(CurCost) - sum(InvCost) 
			from bSLIT 
			where SLCo=@toco
			group by SLCo, SL 
			having sum(CurCost) - sum(InvCost)=0) i
		on bSLHD.SLCo=i.SLCo and bSLHD.SL=i.SL
where bSLHD.SLCo=@toco;


select @rowcount=@@rowcount;


update bSLHD Set Status = 0
from bSLHD
 join bJCJM j on bSLHD.JCCo = j.JCCo and bSLHD.Job = j.Job 
where j.JobStatus = 1
	and bSLHD.SLCo=@toco;


select @rowcount=@rowcount+@@rowcount;

update bSLHD Set Status = 2
from bSLHD
 join bJCJM j on bSLHD.JCCo = j.JCCo and bSLHD.Job = j.Job 
where j.JobStatus in (2,3)
	and bSLHD.SLCo=@toco;


select @rowcount=@rowcount+@@rowcount;







COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bSLHD enable trigger all;

return @@error

GO
