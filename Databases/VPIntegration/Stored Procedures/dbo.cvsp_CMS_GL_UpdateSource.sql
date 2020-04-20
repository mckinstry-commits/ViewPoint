SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
=========================================================================
Copyright © 2012 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Update CMS source tables - AP
	Created:	10.15.09
	Created by:	Viewpoint Technical Services - JJH
	Revisions:	
			1. 03/19/2012 BBA - 
*/


create proc [dbo].[cvsp_CMS_GL_UpdateSource] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as

set @errmsg='';
set @rowcount=0;

-- add new trans
BEGIN TRAN
BEGIN TRY

--fix bad dates
update CV_CMS_SOURCE.dbo.GLTPST
set   TRANSACTIONDATE = '20100714' 
where TRANSACTIONDATE = '2010714'

update CV_CMS_SOURCE.dbo.GLTPST
set   TRANSACTIONDATE = '20101230' 
where TRANSACTIONDATE = '2011230'


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


return @@error

GO
