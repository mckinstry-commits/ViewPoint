SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE proc [dbo].[cvsp_CMS_PRPC] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=============================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=============================================
	Title:		Pay Period Control (PRPC)
	Created:	9.2.09
	Created By:         
	Revisions:	1. None
**/


set @errmsg=''
set @rowcount=0


--Get Customer defaults
declare @defaultFreqCode varchar(5)
select @defaultFreqCode=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='FreqCode' and a.TableName='bPRAF';

alter Table bPRPC disable trigger all;
alter table bPRPS disable trigger all;

-- delete existing trans
begin tran
delete from bPRPC where PRCo=@toco and udConv = 'Y';
delete from bPRPS where PRCo=@toco and udConv = 'Y';
commit tran;

ALTER Table bPRAF disable trigger all;
begin tran
delete from bPRAF where PRCo=@toco and udConv = 'Y'
commit tran;
ALTER Table bPRAF enable trigger all;

-- add new trans
begin try
begin tran

insert bPRPC (PRCo,PRGroup,PREndDate,BeginDate,MultiMth,BeginMth,
LimitMth,Hrs,Days,Wks,Status,JCInterface,EMInterface,GLInterface,
APInterface,LeaveProcess,Conv,MaxRegHrsInWeek1, MaxRegHrsInWeek2, udSource,udConv)

select PRCo = @toco
	,PRGroup=h.PRGroup
	,PREndDate=h.PREndDate
	,BeginDate=dateadd(dd,-6,h.PREndDate)
	,MultiMth = 'N'
	,BeginMth = convert(varchar(2),datepart(mm,h.PREndDate)) + '/01/' + 
			convert(varchar(4),datepart(yy,h.PREndDate))
	,LimitMth = convert(varchar(2),datepart(mm,h.PREndDate)) + '/01/' + 
			convert(varchar(4),datepart(yy,h.PREndDate))
	,Hrs=0
	,Days=0
	,Wks=0
	,Status=1
	,JCInterface='Y'
	,EMInterface='Y'
	,GLInterface='Y'
	,APInterface='Y'
	,LeaveProcess='Y'
	,Conv='N'
	,MaxRegHrsInWeek1 = 40
	,MaxRegHrsInWeek2 = 40
	,udSource ='PRPC'
	, udConv='Y'
from bPRTH h
where h.PRCo=@toco
group by h.PRCo, h.PRGroup, h.PREndDate;

select @rowcount=@@rowcount

insert into bPRPS (PRCo, PRGroup, PREndDate, PaySeq, Description, Bonus, OverrideDirDep,udSource,udConv)

select h.PRCo
	, h.PRGroup
	, h.PREndDate
	, h.PaySeq
	, Description='Conversion'
	, Bonus='N'
	, OverrideDirDep='N'
	, udSource ='PRPC'
	, udConv='Y'
from bPRTH h
where h.PRCo=@toco
group by  h.PRCo, h.PRGroup, h.PREndDate, h.PaySeq;

select @rowcount=@@rowcount


Insert bPRAF (PRCo, PRGroup, PREndDate, Frequency,udSource,udConv)
select distinct PRCo, PRGroup, PREndDate, @defaultFreqCode ,'PRPC', udConv='Y'
from bPRPC 
where PRCo=@toco

select @rowcount=@@rowcount

commit tran
END TRY

BEGIN CATCH
select @errmsg=ERROR_PROCEDURE()+' '+convert(varchar(10),ERROR_LINE())+' '+ERROR_MESSAGE()
if @@trancount>0 rollback tran
END CATCH;


alter Table bPRPC enable trigger all;
alter table bPRPS enable trigger all;

return @@error


GO
