SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



create proc [dbo].[cvsp_CMS_PR_OUTSTANDING_CMDT] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â© 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		CM Detail - PR (CMDT)
	Created:	09.15.11
	Created by:	CR    
	Revisions:	1. None
	Notes:		Inserts Oustanding PR Checks only into CMDT
**/


set @errmsg=''
set @rowcount=0



ALTER Table bCMDT disable trigger all;

--delete trans
BEGIN TRAN
delete bCMDT where CMCo=@toco and Source='PR Update';
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY

insert bCMDT (CMCo, Mth,CMTrans,CMAcct,CMTransType,SourceCo,Source
,ActDate,PostedDate,Amount,ClearedAmt,BatchId,CMRef,CMRefSeq,Payee
,GLCo,CMGLAcct,Void,Purge,Description,udSource,udConv,udCGCTable)

select @toco
, (p.Mth)
, CMTrans=isnull(t.LastTrans,1)+row_number()over
			(partition by @toco, p.Mth order by @toco, p.Mth)
, c.CMAcct
	, CMTransType=1
	, SourceCo=@toco
	, Source='PR Update'
	, ActDate=(substring(convert(nvarchar(max),p.TDTCK),5,2) 
	+'/'+ substring(convert(nvarchar(max),p.TDTCK),7,2) +  '/'+
	substring(convert(nvarchar(max),p.TDTCK),1,4))
	, PostedDate=(substring(convert(nvarchar(max),p.TDTCK),5,2) 
	+'/'+ substring(convert(nvarchar(max),p.TDTCK),7,2) +  '/'+
	substring(convert(nvarchar(max),p.TDTCK),1,4))
	, Amount=p.TAMCK*-1
	, ClearedAmount=0
	, BatchId=0
	, CMRef=space(10-datalength(rtrim(p.TCKNO))) + rtrim(p.TCKNO)
	, CMRefSeq=1
	, Payee=p.TEENO
	, GLCo=@toco
	, CMGLAcct=isnull(c.GLAcct,'')
	, Void='N'
	, Purge='N'
	, Description=preh.LastName + preh.FirstName
	, udSource ='PR_OUTSTANDING_CMDT'
	, udConv='Y'
	,udCGCTable='PRPCHK'
from CV_CMS_SOURCE.dbo.PRPCHK p
left join bHQTC t on p.TCONO=t.Co and p.Mth=t.Mth and t.TableName='bCMDT'
left join bCMAC c on p.TCONO=c.CMCo and p.CMAcct=c.CMAcct
left join bPREH preh on @toco=preh.PRCo and p.TEENO=preh.Employee

where p.TCONO=@toco


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
