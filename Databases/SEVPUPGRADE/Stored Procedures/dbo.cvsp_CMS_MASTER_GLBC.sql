SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





create proc [dbo].[cvsp_CMS_MASTER_GLBC] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as

/*
	=========================================================================
	Copyright © 2009 Viewpoint Construction Software (VCS) 
	The TSQL code in this procedure may not be reproduced, copied, modified,
	or executed without written consent from VCS.
	=========================================================================
	Title:		Budget Codes (GLBC) 
	Created:	10.01.08
	Created by:	Shayona Roberts
	Revisions:	1. JRE 08/07/09 - created proc & @toc, @fromco

**/


set @errmsg=''
set @rowcount=0
exec dbo.cvsp_Disable_Foreign_Keys
-- delete existing trans
alter table bGLBC disable trigger all;

BEGIN tran
delete from bGLBC where GLCo=@toco
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY
insert bGLBC(GLCo, BudgetCode,udSource,udConv,udCGCTable)

select distinct @toco, b.BUDGREVNO , udSource='MASTER_GLBC', udConv='Y',udCGCTable='GLTBDE'
from CV_CMS_SOURCE.dbo.GLTBDE b 
where b.COMPANYNUMBER=@fromco

select @rowcount=@@rowcount
COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH
exec dbo.cvsp_Enable_Foreign_Keys
return @@error

GO
