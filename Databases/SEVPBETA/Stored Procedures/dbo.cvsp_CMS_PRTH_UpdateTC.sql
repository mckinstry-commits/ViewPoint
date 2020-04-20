SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_PRTH_UpdateTC] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:			Updates Timecards to set phase =null when phase exists but job does not
	Created:		01.07.10	
	Created by:		JJH  
	Comments:		There are timecards that convert with a phase and no job. 
					VP wouldn't ever have timecards like that so the phase needs to be cleared.
**/



set @errmsg=''
set @rowcount=0



alter table bPRTH disable trigger all;


update bPRTH set Phase=null where Job is null and Phase is not null

 
-- add new trans
BEGIN TRAN
BEGIN TRY



select @rowcount=@@rowcount;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bPRTH enable trigger all;


return @@error


GO
