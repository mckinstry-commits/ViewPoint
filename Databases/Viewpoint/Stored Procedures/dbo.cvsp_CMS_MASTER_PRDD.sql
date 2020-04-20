SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_MASTER_PRDD] (@fromco smallint, @toco smallint,
	 @errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Employee Add'l Dir Deposit (PRDD)
	Created:	04.15.09
	Created by:	Craig Rutter
	Revisions:	1. 5.19.09 - ADB - Changed Frequency Code to 'W' and DDENO in where clause to '999'.
				2. 8.10.09 - CR - removed DEENO = 997, replaced with 998.
				3. 8/1/2012 BTC - Rewrote to use PRPDTR to determine Direct Deposit records, convert
						both Amount and Percent records, and convert all but the last sequence (which is 
						what is assigned to the PREH record).
				4. 9/17/2012 BTC - Added ltrim to routing number to remove leading space
**/


set @errmsg=''
set @rowcount=0

--get Customer Defaults
declare @defaultSeq tinyint, @defaultStatus varchar(1), @defaultFrequency varchar(1),
	@defaultMethod varchar(1)

select @defaultSeq=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Seq' and a.TableName='bPRDD';

select @defaultStatus=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Status' and a.TableName='bPRDD';

select @defaultFrequency=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Frequency' and a.TableName='bPRDD';

select @defaultMethod=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='Method' and a.TableName='bPRDD';


--Sequence Direct Deposit data
select
	 ded.DCONO
	,ded.DEENO
	,ded.DSTAT
	,ded.DDENO
	,ded.DAMDE
	,ded.DDPCD
	,ded.DDEFQ
	,ded.DDEPC
	,ltrim(ded.DBKID) as DBKID
	,ded.DBKAN
	,RecordSeq = ROW_NUMBER() over (partition by ded.DCONO, ded.DEENO order by ded.DDEPC, ded.DAMDE)
into #TempDirDeposit
--select *
from CV_CMS_SOURCE.dbo.PRPDED ded
join CV_CMS_SOURCE.dbo.PRPDTR dtr
	on dtr.BCONO=ded.DCONO and dtr.BDINO=ded.DDENO and dtr.BDICD='M' and dtr.BCACH='Y'
where ded.DSTAT='A' and ded.DDEFQ<>'0' and ded.DCONO=@fromco

delete #TempDirDeposit where DDEPC=0 and DAMDE=0

select td.* into #TempAddlDirDeposit
from #TempDirDeposit td
left join (select DCONO, DEENO, MAX(RecordSeq) as MaxSeq from #TempDirDeposit group by DCONO, DEENO) d
	on d.DCONO=td.DCONO and d.DEENO=td.DEENO and d.MaxSeq=td.RecordSeq
where d.MaxSeq is null


alter table bPRDD disable trigger all;

-- delete existing trans
BEGIN tran
delete from bPRDD where PRCo=@toco
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY


insert bPRDD (PRCo, Employee, Seq, RoutingId, BankAcct, Type, Status, Frequency, Method, Pct, Amount,
	udSource, udConv, udCGCTable, udCGCTableID)

select PRCo = @toco
	, Employee=ad.DEENO
	, Seq = ad.RecordSeq
	, RoutingId = right('000000000' + convert(varchar(9), ltrim(ad.DBKID)), 9)
	, BankAcct = ad.DBKAN
	, Type=case when ad.DDPCD=22 then 'C' when ad.DDPCD =32 then 'S' end
	, Status=@defaultStatus
	, Frequency=@defaultFrequency
	, Method=case when ad.DDEPC<>0 then 'P' else 'A' end
	, Pct = ad.DDEPC / 100
	, Amount=ad.DAMDE
	, udSource='MASTER_PRDD'
	, udConv='Y'
	, udCGCTable='PRPDED'
	, udCGCTableID=null
--select *
from #TempAddlDirDeposit ad


select @rowcount=@@rowcount
COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bPRDD enable trigger all;

return @@error

GO
