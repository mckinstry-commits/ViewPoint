SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_CM_ClearEntries] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**

=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		CM Clear Entries
	Created:	11.06.09
	Created by:	JJH
	Revisions:	1. None
*/

set @errmsg='';
set @rowcount=0;

ALTER Table bCMDT disable trigger all;

--Get Customer Defaults
declare @defaultClearDate smalldatetime 
select @defaultClearDate=isnull(b.DefaultDate,a.DefaultDate) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ClearDate' and a.TableName='bCMDT';




-- add new trans
BEGIN TRAN
BEGIN TRY

update bCMDT set StmtDate=@defaultClearDate, ClearedAmt=Amount, ClearDate=@defaultClearDate
from bCMDT 
where bCMDT.CMCo=@toco 
	and ActDate<=@defaultClearDate;


select @rowcount=@@rowcount;



COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


ALTER Table bCMDT enable trigger all;

return @@error

GO
