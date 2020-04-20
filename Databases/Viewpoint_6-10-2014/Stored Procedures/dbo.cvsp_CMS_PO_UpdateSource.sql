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
	Title:		Update CMS source tables - PO
	Created:	06/14/2012
	Created by:	Viewpoint Technical Services - Bryan Clark
	Revisions:	
			1. 
*/


CREATE proc [dbo].[cvsp_CMS_PO_UpdateSource] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as

set @errmsg='';
set @rowcount=0;

-- add new trans
BEGIN TRAN
BEGIN TRY

--Correct bad dates





--update udMth fields
update CV_CMS_SOURCE.dbo.POTMCT set udMth = substring(convert(nvarchar(max),PODATE),5,2) 
	+ '/01/' + substring(convert(nvarchar(max),PODATE),1,4)

update CV_CMS_SOURCE.dbo.POTMDT set udMth = substring(convert(nvarchar(max),PODATE),5,2) 
	+ '/01/' + substring(convert(nvarchar(max),PODATE),1,4)

update CV_CMS_SOURCE.dbo.POTCDT set udMth = substring(convert(nvarchar(max),CHANGEORDDATE),5,2) 
	+ '/01/' + substring(convert(nvarchar(max),CHANGEORDDATE),1,4)
	
	
----Establish Units type indicator
--if not exists
--	(select * from CV_CMS_SOURCE.dbo.syscolumns c
--		join CV_CMS_SOURCE.dbo.sysobjects o
--			on o.id=c.id
--		where o.name='POTMDT' and c.name='udPOConversionType')
--begin
--	alter table CV_CMS_SOURCE.dbo.POTMDT add udPOConversionType varchar(20)
--end;


--update CV_CMS_SOURCE.dbo.POTMDT set udPOConversionType=null

----PO items with UM of LS or blank and with no units:
--update CV_CMS_SOURCE.dbo.POTMDT set udPOConversionType='LS'
--	where lower(AUM) in ('','ls') and ORIGQTYORDERED=0 and QTYORDERED=0

----PO items with Unit type UM but zero units:
--update CV_CMS_SOURCE.dbo.POTMDT set udPOConversionType='ZeroUnit'
--	where lower(AUM) not in ('','ls') and ORIGQTYORDERED=0 and QTYORDERED=0

----PO items with UM of LS and with units...use EA for UM.
--update CV_CMS_SOURCE.dbo.POTMDT set udPOConversionType='LSQ'
--	where LOWER(AUM) = 'ls' and (ORIGQTYORDERED<>0 or QTYORDERED<>0)

----PO items with UM other than LS and with units...use EA for blanks
--update CV_CMS_SOURCE.dbo.POTMDT set udPOConversionType='Unit'
--	where LOWER(AUM) <> 'ls' and (ORIGQTYORDERED<>0 or QTYORDERED<>0)


--Update ID fields
alter table CV_CMS_SOURCE.dbo.POTMCT drop column udPOTMCTID
alter table CV_CMS_SOURCE.dbo.POTMCT add udPOTMCTID int identity(1,1)

alter table CV_CMS_SOURCE.dbo.POTMDT drop column udPOTMDTID
alter table CV_CMS_SOURCE.dbo.POTMDT add udPOTMDTID int identity(1,1)

alter table CV_CMS_SOURCE.dbo.POTCDT drop column udPOTCDTID
alter table CV_CMS_SOURCE.dbo.POTCDT add udPOTCDTID int identity(1,1)


COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;


return @@error


GO
