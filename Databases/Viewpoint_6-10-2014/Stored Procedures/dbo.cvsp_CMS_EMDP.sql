SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE proc [dbo].[cvsp_CMS_EMDP] (@fromco smallint, @toco smallint,	
@errmsg varchar(1000) output, @rowcount bigint output) 
as
/**

=============================================
Equipment Master Asset Master
Copyright © 2009 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=============================================
-- Date:		April 27, 2010
-- By:		Craig Rutter
-- Revisions:	1. None

**/
set nocount on
set @errmsg=''
set @rowcount=0

/* declare Equip format */
declare @Equip varchar(10)
set @Equip = (select InputMask from vDDDTc where Datatype = 'bEquip');

alter table bEMDP disable trigger all;

-- delete existing trans
begin tran
delete from bEMDP where EMCo=@toco 
	and udConv = 'Y';
commit tran;

-- add new trans
BEGIN TRY
begin tran

insert into bEMDP (EMCo, Equipment, Asset, Description, DeprMethod, DBFactor, FirstMonth, NoMonthsToDepr, 
TtlToDepr, MonthDisposed, PurchasePrice, ResidualValue, SalePrice, AccumDeprAcct, DeprExpAcct, DeprAssetAcct,
 GLCo, Notes, UseResidualVal, udSource, udConv, udCGCTable, udCGCTableID
 /*, udPurchase, udMonths, udResidValue, udCGCDeprTaken*/
 )
 
 select @toco
 , Equipment = dbo.bfMuliPartFormat(ltrim(rtrim(T.EQUIPMENTNUMBER)) ,@Equip)
 , Asset     = dbo.bfMuliPartFormat(ltrim(rtrim(T.EQUIPMENTNUMBER)) ,@Equip)
 , Description = left(T.DESC25A,30) 
 , DeprMethod  =  case when M.DERPMETHOD IN (0,2,5,6) then 'S' else 'D' end
 , DBFactor    = case when M.DERPMETHOD = 7 then 1.5 else null end
 , FirstMonth  = convert(smalldatetime,(substring(convert(nvarchar(max),M.DEPRECIATIONDATE),1,4)+'/'
				+substring(convert(nvarchar(max),M.DEPRECIATIONDATE),5,2) +'/'+'1'))
 , NoMonthsToDepr = (M.LIFEOFASSET*12)/*-DNMODN*/
 , TtlToDepr = M.DEPRECIATIONAMT-M.LIFEOFASSET/*-DNTLAC*/
 , MonthDisposed = CASE WHEN T.DISPOSALDATE = 0 THEN NULL ELSE
	convert(smalldatetime,substring(convert(nvarchar(max),T.DISPOSALDATE),1,4) + '/' + 
	substring(convert(nvarchar(max),T.DISPOSALDATE),5,2) + '/' + '01')
	END
 , PurchasePrice = M.DEPRECIATIONAMT-M.LIFEOFASSET/*-DNTLAC*/ /*MACCS*/
 , ResidualValue = M.LIFEOFASSET
 , SalePrice = left(T.DISPOSALAMT,9)
 , AccumDeprAcct = Accum.newGLAcct
 , DeprExpAcct = Expense.newGLAcct
 , DeprAssetAcct = Asset.newGLAcct
 , GLCO = @toco
 , Notes = null
 , UseResidualVal = 'N'
 , udSource ='EMDP'
 , udConv='Y'
 , udCGCTable ='EQPDNM'
 , udCGCTableID=null
 --, udPurchase = MACCS
 --, udMonths = DNASLF*12
 --, udResidValue = DNSVVL
 --, udCGCDeprTaken = DNTLAC 
 
 
 from CV_CMS_SOURCE.dbo.EQTDNM M
 
  join CV_CMS_SOURCE.dbo.EQTMST T 
	on  M.COMPANYNUMBER=T.COMPANYNUMBER 
	and M.EQUIPMENTNUMBER=T.EQUIPMENTNUMBER
	
 join Viewpoint.dbo.budxrefGLAcct Accum 
	on Accum.Company = @fromco 
	and Accum.oldGLAcct=M.RESVGLACCTNO
	
 join Viewpoint.dbo.budxrefGLAcct Asset 
	on Asset.Company = @fromco 
	and Asset.oldGLAcct=M.ASSETGLACCT
	
 join Viewpoint.dbo.budxrefGLAcct Expense 
	on Expense.Company = @fromco 
	and Expense.oldGLAcct=M.GLEXPENSEACCTNO
 
 where  M.COMPANYNUMBER = @fromco --and DNDNCD = 'B'
 
 select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bEMDP enable trigger all;

return @@error

 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 

GO
