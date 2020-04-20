SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_PREA] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as






/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:				PR Employee Accumulations
	Created:			10.26.09
	Created by:	JJH        
	Revisions:		1. None
**/


set @errmsg=''
set @rowcount=0


alter table bPREA disable trigger all;

-- delete existing trans
BEGIN tran
delete from bPREA where PRCo=@toco
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY


insert bPREA (PRCo, Employee, Mth, EDLType, EDLCode, Hours, Amount, SubjectAmt, EligibleAmt, AuditYN,udSource,udConv)

select d.PRCo
	, d.Employee
	, Mth=convert(varchar(2),datepart(mm,d.udPaidDate)) + '/01/' + 
			convert(varchar(4),datepart(yy,d.udPaidDate))
	, d.EDLType
	, d.EDLCode
	, Hours=sum(case when d.EDLType='E' then d.Hours else 0 end)
	, Amount=sum(d.Amount)
	, SubjectAmt=sum(d.SubjectAmt)
	, EligibleAmt=sum(d.EligibleAmt)
	, AuditYN='N'
	, udSource ='PREA'
	, udConv='Y'
from bPRDT d
where d.PRCo=@toco and d.udPaidDate is not null
group by d.PRCo, d.PRGroup, convert(varchar(2),datepart(mm,d.udPaidDate)) + '/01/' + 
			convert(varchar(4),datepart(yy,d.udPaidDate)), d.Employee, d.EDLType, d.EDLCode



select @rowcount=@@rowcount




COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bPREA enable trigger all;

return @@error



GO
