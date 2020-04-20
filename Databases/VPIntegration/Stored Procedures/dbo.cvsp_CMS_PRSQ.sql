SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_PRSQ] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as






/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:				PR Employee Sequence Control (PRSQ)
	Created:			10.26.09
	Created by:	JJH        
	Revisions:		1. None
**/


set @errmsg=''
set @rowcount=0


alter table bPRSQ disable trigger all;
alter table bCMDT disable trigger all;

-- delete existing trans
BEGIN tran
delete from bPRSQ where PRCo=@toco
delete from bCMDT where CMCo=@toco and Source like 'PR%'
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY

--Insert the records first into a temp table.  The data is then used to insert into
--PRSQ but the CMRef Sequence can calculate correctly since it can look for any matching
--CM References in PRSQ and in CMDT

create table #seq
	(PRCo		tinyint			null,
	PRGroup		tinyint			null,
	PREndDate	smalldatetime	null,
	Employee	int				null,
	PaySeq		tinyint			null,
	CMCo		tinyint			null,
	CMAcct		int				null,
	CMRef		varchar(10)		null,
	PaidDate	smalldatetime	null,
	PaidMth		smalldatetime	null,
	Hours		decimal(12,2)	null,
	Earnings	decimal(12,2)	null,
	Dedns		decimal(12,2)	null)
create nonclustered index ciSeq on #seq (PRCo, PRGroup, PREndDate, Employee, PaySeq)
create nonclustered index ciCMRef on #seq (PRCo, CMCo, CMAcct, CMRef)

insert into #seq
select  d.PRCo
	, d.PRGroup
	, d.PREndDate
	, d.Employee
	, d.PaySeq
	, CMCo=max(isnull(d.udCMCo, g.CMCo))
	, CMAcct=max(isnull(d.udCMAcct,g.CMAcct))
	, CMRef=max(right('          ' + d.udCMRef,10))
	, PaidDate=convert(smalldatetime, max(d.udPaidDate))
	, PaidMth=max(convert(varchar(2),month(d.udPaidDate))+'/01/'+ convert(varchar(4),year(d.udPaidDate)))
	, Hours=sum(case when d.EDLType='E' then d.Hours else 0 end)
	, Earnings=sum(case when d.EDLType='E' then d.Amount else 0 end)
	, Dedns=sum(case when d.EDLType='D' then d.Amount else 0 end)
from bPRDT d
	left join bPRGR g on d.PRCo=g.PRCo and d.PRGroup=g.PRGroup
where d.PRCo=@toco
group by d.PRCo, d.PRGroup, d.PREndDate, d.Employee, d.PaySeq



--insert into PRSQ
insert bPRSQ (PRCo, PRGroup, PREndDate, Employee, PaySeq, CMCo, 
	CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, ChkType, 
	PaidDate, PaidMth, Hours, Earnings, Dedns, SUIEarnings, PostToAll, Processed, CMInterface, udSource,udConv)
select s.PRCo
	, s.PRGroup
	, s.PREndDate
	, s.Employee
	, s.PaySeq
	, CMCo=s.CMCo
	, CMAcct=s.CMAcct
	, PayMethod='C'
	, CMRef=(right('          ' + s.CMRef,10))
	, CMRefSeq= isnull(NextSeq,0)+ROW_NUMBER() OVER (PARTITION BY t.PRCo, 
					t.CMCo, t.CMAcct, t.CMRef
				order by t.PRCo, t.CMCo, t.CMAcct, t.CMRef)
				-(case when isnull(NextSeq,0)<>0 then 0 else 1 end)
	, EFTSeq=0
	, ChkType='C'
	, PaidDate=s.PaidDate
	, PaidMth=s.PaidMth
	, Hours=s.Hours
	, Earnings=s.Earnings
	, Dedns=s.Dedns
	, SUIEarnings=0
	, PostToAll='Y'
	, Processed='Y'
	, CMInterface='Y'
	, udSource ='PRSQ'
	, udConv='Y'
from #seq s
	--This figures out if the CMRef has been used in any other pay period.  If so, it 
	--needs to change the CMRefSeq to be unique
	join (select PRCo, CMCo, CMAcct, CMRef
			from #seq 
			group by PRCo, CMCo, CMAcct, CMRef)
			as t 
			on s.PRCo=t.PRCo and s.CMCo=t.CMCo and s.CMAcct=t.CMAcct 
				and s.CMRef=t.CMRef
	left join (select CMCo, CMAcct, CMRef, NextSeq=max(CMRefSeq)
					from bCMDT
					where bCMDT.CMCo=@toco
					group by CMCo, CMAcct, CMRef)
					as c
					on s.CMCo=c.CMCo and s.CMAcct=c.CMAcct 
						and s.CMRef=c.CMRef

/*

Insert bPRSQ (PRCo, PRGroup, PREndDate, Employee, PaySeq, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, ChkType, 
PaidDate, PaidMth, Hours, Earnings, Dedns, SUIEarnings, PostToAll, Processed, CMInterface, udSource,udConv)

select d.PRCo
	, d.PRGroup
	, d.PREndDate
	, d.Employee
	, d.PaySeq
	, CMCo=max(isnull(d.udCMCo, g.CMCo))
	, CMAcct=max(isnull(d.udCMAcct,g.CMAcct))
	, PayMethod='C'
	, CMRef=max(right('          ' + d.udCMRef,10))
	, CMRefSeq= max(isnull(c.NextSeq,0))+
				max(isnull(t.NextSeq,0))+
				ROW_NUMBER() OVER (PARTITION BY d.PRCo, 
				max(isnull(d.udCMCo, g.CMCo)), max(isnull(d.udCMAcct,g.CMAcct)), 
				max(d.udCMRef) 
				order by d.PRCo, max(isnull(d.udCMCo, g.CMCo)), max(isnull(d.udCMAcct,g.CMAcct)), 
				max(d.udCMRef) ) -1
	, EFTSeq=0
	, ChkType='C'
	, PaidDate=convert(smalldatetime, max(d.udPaidDate))
	, PaidMth=max(convert(varchar(2),month(d.udPaidDate))+'/01/'+ convert(varchar(4),year(d.udPaidDate)))
	, Hours=sum(case when d.EDLType='E' then d.Hours else 0 end)
	, Earnings=sum(case when d.EDLType='E' then d.Amount else 0 end)
	, Dedns=sum(case when d.EDLType='D' then d.Amount else 0 end)
	, SUIEarnings=0
	, PostToAll='Y'
	, Processed='Y'
	, CMInterface='Y'
	, udSource ='PRSQ'
	, udConv='Y'
from bPRDT d
	left join bPRGR g on d.PRCo=g.PRCo and d.PRGroup=g.PRGroup
	left join (select CMCo, CMAcct, CMRef, NextSeq=max(CMRefSeq)
					from bCMDT
					where bCMDT.CMCo=@toco
					group by CMCo, CMAcct, CMRef)
					as c
					on isnull(d.udCMCo, g.CMCo)=c.CMCo and isnull(d.udCMAcct,g.CMAcct)=c.CMAcct 
						and d.udCMRef=c.CMRef
	left join (select PRCo, CMCo, CMAcct, CMRef, NextSeq=max(CMRefSeq)
					from bPRDT
					where bPRDT.PRCo=@toco
					group by PRCo, CMCo, CMAcct, CMRef)
					as t
					on d.PRCo=t.PRCO
						and isnull(d.udCMCo, g.CMCo)=t.CMCo 
						and isnull(d.udCMAcct,g.CMAcct)=c.CMAcct 
						and d.udCMRef=c.CMRef
where d.PRCo=@toco
group by d.PRCo, d.PRGroup, d.PREndDate, d.Employee, d.PaySeq

*/

select @rowcount=@@rowcount;








COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bPRSQ enable trigger all;
ALTER Table bCMDT enable trigger all;

return @@error



GO
