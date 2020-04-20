SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------





create proc [dbo].[cvsp_CMS_GL_AddColsIndexes] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as




/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Add Columns and Indexes to GL tables 
	Created:	06.22.10	
	Created by: JJH
	Revisions:	1. none
**/


set @errmsg=''
set @rowcount=0


-- add new trans
BEGIN try


if not exists (select name from Viewpoint.dbo.sysindexes 
   where  id=OBJECT_ID('Viewpoint.dbo.budxrefGLSubLedger') and name ='ixrefGLSubLedger')  
create unique clustered index ixrefGLSubLedger on 
	Viewpoint.dbo.budxrefGLSubLedger(Company, oldAppCode, newSubLedgerCode);
	
if not exists (select name from Viewpoint.dbo.sysindexes 
   where  id=OBJECT_ID('Viewpoint.dbo.budxrefGLAcctTypes') and name ='ixrefGLAcctType')	
create unique clustered index ixrefGLAcctType on 
	Viewpoint.dbo.budxrefGLAcctTypes(Company, oldAcctType, newAcctType);
	
if not exists (select name from Viewpoint.dbo.sysindexes 
   where  id=OBJECT_ID('Viewpoint.dbo.budxrefGLAcct') and name ='ixrefGLAcct')	
create unique clustered index ixrefGLAcct on 
	Viewpoint.dbo.budxrefGLAcct(Company, oldGLAcct, newGLAcct);



END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')

END CATCH;


return @@error



GO
