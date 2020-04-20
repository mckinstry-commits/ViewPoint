SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 



create proc [dbo].[cvsp_CMS_HQTC_APTH_Update] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
      Title:      HQTC update
      Created on: 9.2.09
      Created By: JIME  
      Revisions:  1. None
**/


set @errmsg=''
set @rowcount=0
 
alter table bHQTC disable trigger all;
 
-- delete existing trans
delete bHQTC where Co=@toco 
 
---- add new trans
BEGIN TRAN
BEGIN TRY
insert bHQTC (TableName, Co, Mth, LastTrans)
 select 'bAPTH',APCo,Mth,Max(APTrans)  from bAPTH where APCo=@toco  group by APCo,Mth;

select @rowcount=@@rowcount;
commit tran
END TRY
 
BEGIN CATCH
select @errmsg=ERROR_PROCEDURE()+' '+convert(varchar(10),ERROR_LINE())+' '+ERROR_MESSAGE()
ROLLBACK
END CATCH;
 
alter table bHQTC enable trigger all;
 
return @@error
 
 

GO
