SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[cvsp_CMS_MASTER_GLBD] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as

/**

=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		GL Budgets for Calendar Yrs  (GLBD)
	Created:	12.01.2008	
	Created by:	Craig Rutter
	Revisions:	1. 2.19.09 - ADB - Added variables for multiple company conversion.
				2. 2.23.09 - ADB - Added join to bHQCO table for select statement in WHERE clause.
				3. 6.9.09 - ADB - Broke apart task to accommodate CMS fiscal vs. calendar year companies.

**/


set @errmsg=''
set @rowcount=0

-- get vendor group from HQCO
declare @VendorGroup smallint, @TaxGroup smallint,@CustGroup smallint
select @VendorGroup=VendorGroup, @CustGroup=CustGroup,@TaxGroup=TaxGroup from bHQCO where HQCo=@toco

--get Customer defaults
declare @defaultOverrideMinAmtYN varchar(1)

select @defaultOverrideMinAmtYN=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='@OverrideMinAmtYN' and a.TableName='xxxx';

alter table bGLBD disable trigger all;

-- delete existing trans
BEGIN tran
delete from bGLBD where GLCo=@toco
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY

insert bGLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt,udSource,udConv,udCGCTable/*,udCGCTableID*/)

select @toco, newGLAcct, g.BUDGREVNO, 
	convert(smalldatetime,cast(g.BUYEAR as varchar)+'/1/1'),  -- Jan
	sum(g.FISCALPERJAN)
	,udSource ='MASTER_GLBD'
	, udConv='Y'
	,udCGCTable='GLTBUD'
	----,udCGCTableID= GLTBUDID
from CV_CMS_SOURCE.dbo.GLTBUD g with (nolock)
	join Viewpoint.dbo.budxrefGLAcct on Company = @fromco and g.GENLEDGERACCT=oldGLAcct
where g.COMPANYNUMBER =@fromco
group by  g.BUYEAR, newGLAcct, g.BUDGREVNO

union all

select @toco, newGLAcct, g2.BUDGREVNO, 
	convert(smalldatetime,cast(g2.BUYEAR as varchar)+'/2/1'),  -- Feb
	sum(g2.FISCALPERFEB),udSource ='MASTER_GLBD'
	, udConv='Y'
	,udCGCTable='GLTBUD'
	--,udCGCTableID= GLTBUDID
from CV_CMS_SOURCE.dbo.GLTBUD g2 with (nolock)
	join Viewpoint.dbo.budxrefGLAcct on Company = @fromco and g2.GENLEDGERACCT=oldGLAcct
where g2.COMPANYNUMBER =@fromco
group by  g2.BUYEAR, newGLAcct, g2.BUDGREVNO

union all

select @toco, newGLAcct, g3.BUDGREVNO, 
	convert(smalldatetime,cast(g3.BUYEAR as varchar)+'/3/1'),  
	sum(g3.FISCALPERMAR),udSource ='MASTER_GLBD', udConv='Y',udCGCTable='GLTBUD'--,udCGCTableID= GLTBUDID
from CV_CMS_SOURCE.dbo.GLTBUD g3 with (nolock)
	join Viewpoint.dbo.budxrefGLAcct on Company = @fromco and g3.GENLEDGERACCT=oldGLAcct
where g3.COMPANYNUMBER =@fromco
group by  g3.BUYEAR, newGLAcct, g3.BUDGREVNO

union all

select @toco, newGLAcct, g.BUDGREVNO, 
	convert(smalldatetime,cast(g.BUYEAR as varchar)+'/4/1'),  
 sum(g.FISCALPERAPR),udSource ='MASTER_GLBD', udConv='Y', udCGCTable='GLTBUD'--,udCGCTableID= GLTBUDID
from CV_CMS_SOURCE.dbo.GLTBUD g with (nolock)
	join Viewpoint.dbo.budxrefGLAcct on Company = @fromco and g.GENLEDGERACCT=oldGLAcct
where g.COMPANYNUMBER =@fromco
group by  g.BUYEAR, newGLAcct, g.BUDGREVNO

union all

select @toco, newGLAcct, g.BUDGREVNO, 
	convert(smalldatetime,cast(g.BUYEAR as varchar)+'/5/1'),  
	sum(g.FISCALPERMAY),udSource ='MASTER_GLBD', udConv='Y',udCGCTable='GLTBUD'--,udCGCTableID= GLTBUDID
from CV_CMS_SOURCE.dbo.GLTBUD g with (nolock)
	join Viewpoint.dbo.budxrefGLAcct on Company = @fromco and g.GENLEDGERACCT=oldGLAcct
where g.COMPANYNUMBER =@fromco
group by g.BUYEAR, newGLAcct, g.BUDGREVNO

union all

select @toco, newGLAcct, g.BUDGREVNO, 
	convert(smalldatetime,cast(g.BUYEAR as varchar)+'/6/1'),  
	sum(g.FISCALPERJUN),udSource ='MASTER_GLBD', udConv='Y',udCGCTable='GLTBUD'--,udCGCTableID= GLTBUDID
from CV_CMS_SOURCE.dbo.GLTBUD g with (nolock)
	join Viewpoint.dbo.budxrefGLAcct on Company = @fromco and g.GENLEDGERACCT=oldGLAcct
where g.COMPANYNUMBER =@fromco
group by  g.BUYEAR, newGLAcct, g.BUDGREVNO

union all

select @toco, newGLAcct, g.BUDGREVNO, 
	convert(smalldatetime,cast(g.BUYEAR as varchar)+'/7/1'),  
	sum(g.FISCALPERJUL),udSource ='MASTER_GLBD', udConv='Y',udCGCTable='GLTBUD'--,udCGCTableID= GLTBUDID
from CV_CMS_SOURCE.dbo.GLTBUD g with (nolock)
join Viewpoint.dbo.budxrefGLAcct on Company = @fromco and g.GENLEDGERACCT=oldGLAcct
where g.COMPANYNUMBER =@fromco
group by  g.BUYEAR, newGLAcct, g.BUDGREVNO

union all

select @toco, newGLAcct, g.BUDGREVNO, 
	convert(smalldatetime,cast(g.BUYEAR as varchar)+'/8/1'),  
	sum(g.FISCAPPERAUG),udSource ='MASTER_GLBD', udConv='Y',udCGCTable='GLTBUD'--,udCGCTableID= GLTBUDID
from CV_CMS_SOURCE.dbo.GLTBUD g with (nolock)
	join Viewpoint.dbo.budxrefGLAcct on Company = @fromco and g.GENLEDGERACCT=oldGLAcct
where g.COMPANYNUMBER =@fromco
group by  g.BUYEAR, newGLAcct, g.BUDGREVNO

union all

select @toco, newGLAcct, g.BUDGREVNO, 
	convert(smalldatetime,cast(g.BUYEAR as varchar)+'/9/1'),  
	sum(g.FISCALPERSEP),udSource ='MASTER_GLBD', udConv='Y',udCGCTable='GLTBUD'--,udCGCTableID= GLTBUDID
from CV_CMS_SOURCE.dbo.GLTBUD g with (nolock)
	join Viewpoint.dbo.budxrefGLAcct on Company = @fromco and g.GENLEDGERACCT=oldGLAcct
where g.COMPANYNUMBER =@fromco
group by  g.BUYEAR, newGLAcct, g.BUDGREVNO

union all

select @toco, newGLAcct, g.BUDGREVNO, 
	convert(smalldatetime,cast(g.BUYEAR as varchar)+'/10/1'),  
	sum(g.FISCAPPEROCT),udSource ='MASTER_GLBD', udConv='Y',udCGCTable='GLTBUD'--,udCGCTableID= GLTBUDID
from CV_CMS_SOURCE.dbo.GLTBUD g with (nolock)
	join Viewpoint.dbo.budxrefGLAcct on Company = @fromco and g.GENLEDGERACCT=oldGLAcct
where g.COMPANYNUMBER =@fromco
group by  g.BUYEAR, newGLAcct, g.BUDGREVNO

union all

select @toco, newGLAcct, g.BUDGREVNO, 
	convert(smalldatetime,cast(g.BUYEAR as varchar)+'/11/1'),  
	sum(g.FISCALPERNOV),udSource ='MASTER_GLBD', udConv='Y',udCGCTable='GLTBUD'--,udCGCTableID= GLTBUDID
from CV_CMS_SOURCE.dbo.GLTBUD g with (nolock)
	join Viewpoint.dbo.budxrefGLAcct on Company = @fromco and g.GENLEDGERACCT=oldGLAcct
where g.COMPANYNUMBER =@fromco
group by  g.BUYEAR, newGLAcct, g.BUDGREVNO

union all

select @toco, newGLAcct, g.BUDGREVNO, 
	convert(smalldatetime,cast(g.BUYEAR as varchar)+'/12/1'),  
	sum(g.FISCALPERDEC),udSource ='MASTER_GLBD', udConv='Y',udCGCTable='GLTBUD'--,udCGCTableID= GLTBUDID
from CV_CMS_SOURCE.dbo.GLTBUD g with (nolock)
	join Viewpoint.dbo.budxrefGLAcct on Company = @fromco and g.GENLEDGERACCT=oldGLAcct
where g.COMPANYNUMBER =@fromco
group by  g.BUYEAR, newGLAcct, g.BUDGREVNO

select @rowcount=@@rowcount
COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bGLBD enable trigger all;

return @@error

GO
