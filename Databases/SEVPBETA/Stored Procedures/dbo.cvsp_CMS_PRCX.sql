SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_PRCX] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		PR Craft Accumulations Detail (PRCX)
	Created:	11.24.09
	Created by:	JJH   
	Revisions:	1. None

**/



set @errmsg=''
set @rowcount=0

--delete existing records
delete bPRCX where PRCo=@toco


-- add new trans
BEGIN TRAN
BEGIN TRY

insert bPRCX (PRCo, PRGroup, PREndDate, Employee, PaySeq, Craft, Class, 
		EDLType, EDLCode, Rate, Basis, Amt, udSource,udConv )
select a.PRCo
	, a.PRGroup
	, a.PREndDate
	, a.Employee
	, a.PaySeq
	, a.Craft
	, a.Class
	, a.EDLType
	, a.EDLCode
	, Rate=isnull(a.udRate,0)
	, Basis=sum(a.Basis)
	, Amt=sum(a.Amt)
	, udSource ='PRCX'
	, udConv='Y'
from bPRCA a
where a.PRCo=@toco
group by a.PRCo, a.PRGroup, a.PREndDate, a.Employee, a.PaySeq,
	a.Craft, a.Class, a.EDLType, a.EDLCode, isnull(a.udRate,0)




COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bPRCX enable trigger all;

return @@error

GO
