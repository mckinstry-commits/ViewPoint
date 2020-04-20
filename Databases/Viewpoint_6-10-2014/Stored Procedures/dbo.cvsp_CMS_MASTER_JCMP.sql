SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE proc [dbo].[cvsp_CMS_MASTER_JCMP] 
	( @fromco1	smallint
	, @fromco2	smallint
	, @fromco3	smallint
	, @toco		smallint
	, @errmsg	varchar(1000) output
	, @rowcount bigint output
	) 
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
				4. 10/05/2013 BTC - Added catch to not duplicate records already loaded that were not converted
				
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

with j as (
select distinct j.PROJMANAGER 
  from CV_CMS_SOURCE.dbo.JCTDSC j
  join MCK_MAPPING_DATA.dbo.McKCGCActiveJobsForConversion2 aj
  on aj.GCONO = j.COMPANYNUMBER
 and aj.GJBNO = j.JOBNUMBER
 and aj.GSJNO = j.SUBJOBNUMBER
 and aj.GDVNO = j.DIVISIONNUMBER)

insert bJCMP (JCCo, ProjectMgr, Name, Phone, FAX, MobilePhone, Pager, Email, udSource,udConv,udCGCTable,udCGCTableID)
select distinct JCCo=@toco
	, ProjectMgr  = convert(varchar(10),nme.EMPLOYEENUMBER) --+ '0'
	, Name        = max(rtrim(nme.NAME25))
	, Phone       = max(case 
						when nme.AREACODE = 0 
								and nme.PHONENO <> 0 
						then '(   ' + ') ' + substring(convert(varchar(7), nme.PHONENO),1,3) + '-'
										   + substring(convert(varchar(7), nme.PHONENO),4,4)
						when nme.AREACODE = 0 and  nme.PHONENO = 0 
						then NULL 
					    else '(' + convert(varchar(3), nme.AREACODE) + ') ' + 
						 substring(convert(varchar(7), nme.PHONENO),1,3) + '-' +
						 substring(convert(varchar(7), nme.PHONENO),4,4) 
					end)
	, FAX          = max(case 
						when nme.FAXPHONENO=0 
						then null 
						else convert(nvarchar(max),nme.FAXAREACODE)+convert(nvarchar(max),nme.FAXPHONENO) 
					 end)
	, MobilePhone  = max(case 
						when nme.CELLPHONENUMBER=0 
						then null 
						else convert(nvarchar(max),nme.CELLAREACODE)+convert(nvarchar(max),nme.CELLPHONENUMBER) 
					 end)
	, Pager        = max(case 
						when nme.OTHERPHONENO=0 
						then null 
						else convert(nvarchar(max),nme.OTHERAREACODE)+convert(nvarchar(max),nme.OTHERPHONENO) 
					 end)
	, Email        = max(nme.EMAILADDR)
	, udSource     = 'MASTER_JCMP'
	, udConv       = 'Y'
	, udCGCTable   = 'JCTNME'
	, udCGCTableID = max(JCTNMEID)
	
from CV_CMS_SOURCE.dbo.JCTNME nme
join j
  on j.PROJMANAGER = nme.EMPLOYEENUMBER
left join bJCMP mp
	on (mp.ProjectMgr = nme.EMPLOYEENUMBER or LOWER(mp.Name) = LOWER(nme.NAME25) ) and mp.JCCo = @toco

where nme.COMPANYNUMBER in (@fromco1,@fromco2,@fromco3)
	--and  JCTNME.NAMETYPE='PM';  /* Removed:  all NAMETYPES in McKinstry's data = 'FF'
	and mp.ProjectMgr is null
	group by EMPLOYEENUMBER

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
