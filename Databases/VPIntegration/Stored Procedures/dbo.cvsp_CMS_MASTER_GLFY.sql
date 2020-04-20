SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






create proc [dbo].[cvsp_CMS_MASTER_GLFY] (@fromco smallint, @toco smallint, 
		@errmsg varchar(1000) output, @rowcount bigint output) 

as
/*
	=========================================================================
	Copyright © 2009 Viewpoint Construction Software (VCS) 
	The TSQL code in this procedure may not be reproduced, copied, modified,
	or executed without written consent from VCS.
	=========================================================================

	Title:		GL Fiscal Years (GLFY)
	Created:	11.01.08
	Created by:	Shayona Roberts
	Revisions:	1. 2.19.09 - A. Bynum - Edited for CMS &amp; variables added for multiple company conversion.
				2. JRE 08/07/09 - created proc & @toc, @fromco
				3. JRE 08/07/09 - added fiscal year
**/



set @errmsg=''
set @rowcount=0


--Get Customer defaults
declare @defaultYearEndMth tinyint
select @defaultYearEndMth=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='YearEndMth' and a.TableName='bGLFY';


declare @fiscalendmth as varchar(5), @fiscalbeginmth as varchar(5)
select @fiscalendmth=convert(varchar(5),@defaultYearEndMth),
	@fiscalbeginmth=convert(varchar(5),
		case @defaultYearEndMth	
			when 12 then 1
			else @defaultYearEndMth+1
			end )

alter table bGLFP disable trigger all;
alter table bGLFY disable trigger all;

-- delete existing trans
BEGIN tran
delete from bGLFP where GLCo=@toco
delete from bGLFY where GLCo=@toco
COMMIT TRAN;

alter table bGLFP enable trigger all;
alter table bGLFY enable trigger all;

-- add new trans
BEGIN TRAN
BEGIN TRY


insert bGLFY (GLCo, FiscalYear, FYEMO, BeginMth, udSource,udConv,udCGCTable)


select distinct @toco, 
	Fiscalyear=(GLTACC.ACYEAR), 
	FYEMO=convert(smalldatetime,@fiscalendmth+'/1/'+convert(varchar(8),ACYEAR)),
	BeginMth=convert(smalldatetime,@fiscalbeginmth+'/1/'
		+convert(varchar(8),case when @fiscalendmth=12 then ACYEAR else ACYEAR-1 end))
	,udSource ='MASTER_GLFY'
	, udConv='Y'
	,udCGCTable='GLTACC'
from CV_CMS_SOURCE.dbo.GLTACC 
where GLTACC.COMPANYNUMBER =@fromco


-- Next year ??
--insert bGLFY (GLCo, FiscalYear, FYEMO, BeginMth, udConv)
--select @toco, '2013', '9/1/2013', '10/1/2012','Y';





select @rowcount=@@rowcount
COMMIT TRAN

END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bGLFP enable trigger all;
alter table bGLFY enable trigger all;

return @@error

GO
