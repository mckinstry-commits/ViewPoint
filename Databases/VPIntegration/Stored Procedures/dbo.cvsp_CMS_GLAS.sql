SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE proc [dbo].[cvsp_CMS_GLAS] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
===========================================================================
	Created on:	9.2.09
	Created by:         
	Revisions:	1. 6/5/2012 BTC - Need to activate all accounts before updating
		since we are leaving the triggers on.
**/


set @errmsg=''
set @rowcount=0


--Temporarily activate all accounts
select GLCo, GLAcct, Active into #TempInactive
from bGLAC where GLCo=@fromco and Active='N';

alter table bGLAC disable trigger all;
begin tran
update bGLAC set Active='Y' where GLCo=@fromco and Active='N'
commit tran;
alter table bGLAC enable trigger all;


-- delete existing trans
alter table bGLAS disable trigger btGLASd;
BEGIN tran
delete from bGLAS where GLCo=@toco
COMMIT TRAN;
alter table bGLAS enable trigger btGLASd;

alter table bGLBL disable trigger btGLBLd;
BEGIN tran
delete from bGLBL where GLCo=@toco
COMMIT TRAN;
alter table bGLBL enable trigger btGLBLd;

--alter table bGLAS disable trigger all;
--Leave triggers on to update GLBL

-- add new trans
BEGIN TRAN
BEGIN TRY

insert bGLAS (GLCo, GLAcct, Mth, Jrnl, GLRef, SourceCo, Source, NetAmt, Adjust, Purge,udSource,udConv)

select @toco
	,GLAcct
	,Mth
	,Jrnl
	,GLRef
	,SourceCo
	,Source
	,NetAmt=sum(Amount)
	,Adjust='N'
	,Purge='N'
	,udSouce ='GLAS'
	, udConv='Y'
from bGLDT
where GLCo=@toco 
	
group by GLCo, GLAcct, Mth, Jrnl, GLRef, SourceCo, Source

/* Set GL Journal Descriptions to GLDT Descriptions */
alter table bGLRF disable trigger all;
update bGLRF
set Description = ltrim(left(dt.Description,30))
from bGLRF rf
join bGLDT dt on rf.GLCo = dt.GLCo and rf.Jrnl = dt.Jrnl and rf.GLRef = dt.GLRef and rf.Mth = dt.Mth
WHERE rf.GLCo=@toco
alter table bGLRF enable trigger all;

select @rowcount=@@rowcount

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

--alter table bGLAS enable trigger all;


--Return accounts to inactive status
alter table bGLAC disable trigger all;
begin tran
update bGLAC set Active=t.Active
--select *
from bGLAC ac
join #TempInactive t
	on t.GLCo=ac.GLCo and t.GLAcct=ac.GLAcct
commit tran;
alter table bGLAC enable trigger all;


return @@error

GO
