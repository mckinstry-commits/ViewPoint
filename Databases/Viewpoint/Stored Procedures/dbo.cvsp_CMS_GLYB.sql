
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_GLYB] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		GL Balance Forward (GLYB)
	Created:	12.01.2008
	Created by:	Craig Rutter
	Revisions:	1.  2.19.09 - ADB - Edited for CMS and variables added for multiple company conversion.
				2. 2.23.09 - ADB - Added join to HQCO table for select in WHERE clause.
				3. 4.9.09 - ADB - Added where statement to look only at 'F' records (Fiscal Years).
**/


set @errmsg=''
set @rowcount=0

declare @defaultYearEndMth tinyint
select @defaultYearEndMth=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
	full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='YearEndMth' and a.TableName='bGLFY';

alter table bGLYB disable trigger all;
--alter table bGLYB NOCHECK CONSTRAINT FK_bGLYB_bGLAC_GLCoGLAcct;
alter table bGLYB NOCHECK CONSTRAINT FK_bGLYB_bGLFY_GLCoFYEMO;

-- delete existing trans
BEGIN tran
delete from bGLYB where GLCo=@toco and udConv = 'Y';
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY

-- For Co's with Calendar Year
insert bGLYB (GLCo, FYEMO, GLAcct, BeginBal,udSource,udConv,udCGCTable,udCGCTableID)


select GLCo=@toco
	, FYEMO=convert(smalldatetime,cast(ACYEAR as varchar(4))+'/'+convert(varchar(2),@defaultYearEndMth)+'/1')
	, GLAcct=max(newGLAcct)
	, BeginBal=sum(g.BALFORWARDFIS)
	, udSource='GLYB'
	, udConv='Y'
	, udCGCTable='GLTACT'
	, udCGCTableID=min(g.GLTACTID)
	
from CV_CMS_SOURCE.dbo.GLTACT g 

	join Viewpoint.dbo.budxrefGLAcct 
	on g.COMPANYNUMBER = Company 
	and (g.GENLEDGERACCT=oldGLAcct)
	
where g.FISCALTAXRECCDE = 'F'
	and COMPANYNUMBER = @fromco 
	and (newGLAcct is not null or newGLAcct <> '    -   -    -    ')
	
group by COMPANYNUMBER, ACYEAR, newGLAcct;


select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

--alter table bGLYB CHECK CONSTRAINT FK_bGLYB_bGLAC_GLCoGLAcct;
alter table bGLYB CHECK CONSTRAINT FK_bGLYB_bGLFY_GLCoFYEMO;

ALTER Table bGLYB enable trigger all;

return @@error

GO
