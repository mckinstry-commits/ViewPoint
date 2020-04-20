SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_HQTC_SLCD_Update] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as



/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		HQTC Invoice update
	Created on:	9.2.09
	Created by:         
	Revisions:	1. None
**/
set @errmsg=''
set @rowcount=0

alter table bHQTC disable trigger all;

-- delete existing trans
BEGIN tran
delete bHQTC where Co=@toco and TableName='bSLCD'
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY
insert bHQTC (TableName, Co, Mth, LastTrans)
 select 'bSLCD',SLCo,Mth,Max(SLTrans)
 from bSLCD with (nolock)
 where SLCo=@toco
 group by SLCo,Mth;


select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bHQTC enable trigger all;

return @@error

GO
