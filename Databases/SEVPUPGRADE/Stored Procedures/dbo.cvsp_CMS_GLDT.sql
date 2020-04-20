SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_GLDT] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as






/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		GL Detail (GLDT)
	Created:	02.01.09
	Created by: CR        
	Revisions:	1. 2.19.09 - ADB - Edited for CMS and variables added for multiple company conversion.
				2. 2.23.09 - ADB - Added join for select statement in WHERE clause.
				3. 3.23.09 - JE - moved to stored procedure
**/


set @errmsg=''
set @rowcount=0


ALTER Table bGLDT disable trigger all;

-- delete existing trans
BEGIN tran
delete from bGLDT where GLCo=@toco
	--and udConv = 'Y'  
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY


INSERT bGLDT (GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate,
 DatePosted, Description, BatchId, Amount, RevStatus, Adjust, Purge,udSource,udConv,udCGCTable,udCGCTableID)

select GLCo   = @toco
	, Mth     = convert(smalldatetime,(convert(varchar(4),ENTRYYEAR)+'/'+convert(varchar(2),ENTRYMONTH)+'/'+'01'))  
	, GLTrans = ROW_NUMBER() OVER (PARTITION BY COMPANYNUMBER,convert(smalldatetime,(convert(varchar(4),ENTRYYEAR)+'/'+
				convert(varchar(2),ENTRYMONTH)+'/'+'01'))
				ORDER BY COMPANYNUMBER,convert(smalldatetime,(convert(varchar(4),ENTRYYEAR)+'/'+convert(varchar(2),ENTRYMONTH)+'/'+'01')), newGLAcct)
	, GLAcct   = x.newGLAcct
	, Jrnl     = isnull(j.GLJrnl, 'GJ')
	, GLRef    = convert(varchar(5),right(JOURNALCTL,5)) + '-' + 
		         case 
					when JOURNALNO < 10 
						THEN '000' + convert(varchar(1),rtrim(JOURNALNO))
					when JOURNALNO between 9 and 99 
						THEN '00' + convert(varchar(2),rtrim(JOURNALNO))
					when JOURNALNO between 100 and 1000 
						THEN '0' + convert(varchar(3),rtrim(JOURNALNO)) 
				 else 
					convert(varchar(4),rtrim(JOURNALNO)) 
					END  --XJRCT
	,SourceCo   = @toco
	,Source     = isnull(j.Source, 'GL Jrnl' )
	,ActDate    = convert(smalldatetime,(convert(varchar(4),ENTRYYEAR)+'/'+convert(varchar(2),ENTRYMONTH)+'/'+convert(VARCHAR(2),ENTRYDAY) ))
	,DatePosted = case 
					when TRANSACTIONDATE=0 
					then convert(smalldatetime,(convert(varchar(4),ENTRYYEAR)+'/'+
					     convert(varchar(2),ENTRYMONTH)+'/'+
					     convert(VARCHAR(2),ENTRYDAY) )) 
				  else	
					case 
						when substring(convert(nvarchar(max),TRANSACTIONDATE),5,2)<= 12 
						then convert(smalldatetime,(substring(convert(nvarchar(max),TRANSACTIONDATE),1,4)+'/'+
						     substring(convert(nvarchar(max),TRANSACTIONDATE),5,2)+'/'+
						     substring(convert(nvarchar(max),TRANSACTIONDATE),7,2)))
					 else
							convert(smalldatetime,(substring(convert(nvarchar(max),TRANSACTIONDATE),1,4)+'/'+
							convert(varchar(2),ENTRYMONTH) +'/'+
							substring(convert(nvarchar(max),TRANSACTIONDATE),7,2))) 
					 end 
				  end
	, Description  = DESC20A
	, BatchId      = 1
	, Amount       = AMOUNT
	, RevStatus    = 0
	, Adjust       = 'N'
	, Purge        = 'N'
	, udSource     = 'GLDT'
	, udConv       = 'Y'
	, udCGCTable   = 'GLTPST'
	, udCGCTableID = GLTPSTID
	
from CV_CMS_SOURCE.dbo.GLTPST
	left join Viewpoint.dbo.budxrefGLAcct x 
		on x.Company=@fromco 
		and GENLEDGERACCT=x.oldGLAcct
	left join Viewpoint.dbo.budxrefGLJournals j 
		on left(JOURNALCTL,2)=CMSCode

where COMPANYNUMBER=@fromco
	and ENTRYMONTH <> 0 
	and ENTRYDAY <> 0 
	and x.newGLAcct is not null
	and JOURNALCTL is not null;


select @rowcount=@@rowcount

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bGLDT enable trigger all;

return @@error

GO
