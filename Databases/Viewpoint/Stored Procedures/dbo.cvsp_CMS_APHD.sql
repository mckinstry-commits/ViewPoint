
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_APHD](@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		AP Hold Detail (APHD)
	Created:	10.13.09
	Created by: JJH
	Notes:		Can NOT put ud fields on this table!!  unless Dev changes the way the table works.      
	Revisions:	1. None
	
	
	
	
**/


set @errmsg=''
set @rowcount=0

--get defaults from APCO
declare @holdcode varchar(10);
select @holdcode=RetHoldCode from bAPCO where APCo=@toco;


-- delete existing trans
BEGIN tran
delete from bAPHD where APCo=@toco
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY


insert bAPHD (APCo, Mth, APTrans, APLine, APSeq, HoldCode)

select APCo
	, Mth
	, APTrans
	, APLine
	, APSeq
	, HoldCode=@holdcode

from bAPTD
where Status = 2 
	and bAPTD.APCo=@toco

select @rowcount=@@rowcount;


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


return @@error

GO
