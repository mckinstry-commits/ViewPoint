SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_MASTER_GLAC] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**

=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
===========================================================================
	Title:		GL Accounts (GLAC)
	Created:	09.02.09
	Created by:	Jim Emery     
	Revisions:	1. None
**/


set @errmsg=''
set @rowcount=0

-- delete existing trans

exec cvsp_Disable_Foreign_Keys;


alter table bGLAC disable trigger all;
alter table bGLPI disable trigger all;
BEGIN tran
delete from bGLAC where GLCo=@toco
COMMIT TRAN;
alter table bGLAC enable trigger all;
alter table bGLAC NOCHECK Constraint CK_bGLAC_SubType;

-- add new trans
BEGIN TRAN
BEGIN TRY

insert bGLAC (GLCo, GLAcct, Description, AcctType, SubType, NormBal, InterfaceDetail, Active, 
	SummaryAcct, CashAccrual,udSource,udConv,udCGCTable)

select distinct @toco
	,GLAcct=newGLAcct
	,Description=left(g.MSD25A,30)
	,AcctType=t.newAcctType
	,SubType=isnull(r.newSubLedgerCode,null)
	,NormBal=g.MSDRCR
	,InterfaceDetail='Y'
	,Active='Y'
	,SummaryAcct=newGLAcct
	,CashAccrual='A'
	,udSource ='MASTER_GLAC'
	, udConv='Y'
	,udCGCTable='GLPMST'
from CV_CMS_SOURCE.dbo.GLPMST g
	join Viewpoint.dbo.budxrefGLAcct glx on glx.Company=@fromco and g.MSGLAN=glx.oldGLAcct
	join Viewpoint.dbo.budxrefGLAcctTypes t on t.Company=@fromco and g.MSTYAC=t.oldAcctType
	left join Viewpoint.dbo.budxrefGLSubLedger r on r.Company=@fromco and g.MSAPCD=r.oldAppCode
where g.MSCONO=@fromco 
	

select @rowcount=@@rowcount
COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


exec cvsp_Enable_Foreign_Keys;

alter table bGLAC enable trigger all;
alter table bGLPI enable trigger all;
alter table bGLAC CHECK Constraint CK_bGLAC_SubType;
return @@error

GO
