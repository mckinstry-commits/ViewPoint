SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_MASTER_JCMP] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, modified,
transmitted or executed without written consent from VCS.
=========================================================================
	Title: 		JC Project Managers (JCMP)
	Created:	12.01.08
	Created by:	Shayona Roberts
	Revisions:	1. 02.20.09 - A. Bynum - Removed Email import; there is no such field in CMS, client may use custom field.
				2. JRE 08/07/09 - created proc & @toco, @fromco
				3. 6/5/2012 BTC - Added Email using EMAILADDR field of JCTNME.
				
**/


set @errmsg=''
set @rowcount=0
	

ALTER Table bJCMP disable trigger all;

-- delete existing trans
BEGIN tran
delete from bJCMP where JCCo=@toco
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY

insert bJCMP (JCCo, ProjectMgr, Name, Phone, FAX, MobilePhone, Pager, Email, udSource,udConv,udCGCTable,udCGCTableID)
select JCCo=@toco
	, ProjectMgr=convert(varchar(10),JCTNME.EMPLOYEENUMBER) --+ '0'
	, Name=rtrim(JCTNME.NAME25)
	, Phone=case when JCTNME.AREACODE = 0 and JCTNME.PHONENO <> 0 
					then '(   ' + ') ' + substring(convert(varchar(7),JCTNME.PHONENO),1,3) + '-'
							+ substring(convert(varchar(7), JCTNME.PHONENO),4,4)
					when JCTNME.AREACODE = 0 and  JCTNME.PHONENO = 0 then NULL 
					else '(' + convert(varchar(3),JCTNME.AREACODE) + ') ' + 
						substring(convert(varchar(7), JCTNME.PHONENO),1,3) + '-'
						+ substring(convert(varchar(7), JCTNME.PHONENO),4,4) 
				end
	, FAX=case when JCTNME.FAXPHONENO=0 then null 
			else convert(nvarchar(max),JCTNME.FAXAREACODE)+convert(nvarchar(max),JCTNME.FAXPHONENO) end
	, MobilePhone=case when JCTNME.CELLPHONENUMBER=0 then null 
					else convert(nvarchar(max),JCTNME.CELLAREACODE)+convert(nvarchar(max),JCTNME.CELLPHONENUMBER) end
	, Pager=case when JCTNME.OTHERPHONENO=0 then null 
					else convert(nvarchar(max),JCTNME.OTHERAREACODE)+convert(nvarchar(max),JCTNME.OTHERPHONENO) end
	, Email = JCTNME.EMAILADDR
	, udSource ='MASTER_JCMP'
	, udConv='Y'
	,udCGCTable='JCTNME'
	,udCGCTableID=JCTNMEID
from CV_CMS_SOURCE.dbo.JCTNME with(nolock)
where JCTNME.COMPANYNUMBER=@fromco 
	and  JCTNME.NAMETYPE='PM';

select @rowcount=@@rowcount

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bJCMP enable trigger all;

return @@error

GO
