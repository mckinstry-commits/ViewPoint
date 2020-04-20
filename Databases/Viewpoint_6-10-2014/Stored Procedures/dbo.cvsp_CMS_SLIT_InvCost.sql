SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE proc [dbo].[cvsp_CMS_SLIT_InvCost] 
	( @fromco1 smallint
	, @fromco2 smallint
	, @fromco3 smallint
	, @toco smallint
	, @errmsg varchar(1000) output
	, @rowcount bigint output
	) 
as


/**

=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Updates Invoices amounts on the SL Items
	Created:	10.13.09
	Created by:	JJH
	Revisions:	1. None
	

*/


set @errmsg='';
set @rowcount=0;

ALTER Table bSLIT disable trigger all;

-- add new trans
BEGIN TRAN
BEGIN TRY



update bSLIT Set InvCost=sumGross
from bSLIT s 
	join (select APCo, SL, SLItem, sumGross =sum(GrossAmt)
			from bAPTL 
			where APCo=@toco
			group by APCo, SL, SLItem) 
			as a 
			on s.SLCo=a.APCo and s.SL=a.SL and s.SLItem=a.SLItem
where s.SLCo=@toco;



select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bSLIT enable trigger all;

return @@error



GO
