SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[cvsp_CMS_MASTER_ARCM] (@fromco smallint, @toco smallint, 
                @errmsg varchar(1000) output, @rowcount bigint output) 
as


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
                Title:                      Customer Master (ARCM) 
                Created:              10.1.08
                Craeted by:        Shayona Roberts
                Revisions:            1. 08/07/09 - created proc & @toco, @fromco - JRE
									  2. 06/05/2012 BTC - Removed '100 +' from Company link in Address update piece.
									  
				McKinstry Revisions:  1. 06/10/2013 CR remove field for PrintStatement and hard code to 'Y' via Sarah's 6/10/13 email
									  2. 09/10/2013 CR make Billing Address info same as Address info.

**/

set @errmsg=''
set @rowcount=0

-- get Customer group from HQCO
declare @TaxGroup smallint,@CustGroup smallint
select @CustGroup=CustGroup,@TaxGroup=TaxGroup 
from bHQCO where HQCo=@toco



--Get Customer defaults
declare @defaultTaxCode varchar(10)
select @defaultTaxCode=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='TaxCode' and a.TableName='bARCM';

declare @defaultSelPurge varchar(1)
select @defaultSelPurge=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='SelPurge' and a.TableName='bARCM';

declare @defaultStmtType varchar(1)
select @defaultStmtType=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='StmtType' and a.TableName='bARCM';

declare @defaultStmtPrint varchar(1)
select @defaultStmtPrint=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='StmtPrint' and a.TableName='bARCM';

declare @defaultFCType varchar(1)
select @defaultFCType=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='FCType' and a.TableName='bARCM';

declare @defaultFCPct numeric(8,2)
select @defaultFCPct=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='FCPct' and a.TableName='bARCM';

declare @defaultMarkupDiscPct numeric(8,2)
select @defaultMarkupDiscPct=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='MarkupDiscPct' and a.TableName='bARCM';

declare @defaultHaulTaxOpt tinyint
select @defaultHaulTaxOpt=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='HaulTaxOpt' and a.TableName='bARCM';

declare @defaultInvLvl tinyint
select @defaultInvLvl=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='InvLvl' and a.TableName='bARCM';

declare @defaultPrintLvl tinyint --should be 1 or 2
select @defaultPrintLvl=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PrintLvl' and a.TableName='bARCM';

declare @defaultSubtotalLvl tinyint -- should be 1 through 6
select @defaultSubtotalLvl=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='SubtotalLvl' and a.TableName='bARCM';

declare @defaultMiscOnInv varchar(1)
select @defaultMiscOnInv=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='MiscOnInv' and a.TableName='bARCM';

declare @defaultMiscOnPay varchar(1)
select @defaultMiscOnPay=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='MiscOnPay' and a.TableName='bARCM';

declare @defaultSepHaul varchar(1)
select @defaultSepHaul=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='SepHaul' and a.TableName='bARCM';

declare @defaultExclContFromFC varchar(1)
select @defaultExclContFromFC=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='ExclContFromFC' and a.TableName='bARCM';

declare @defaultRecType tinyint
select @defaultRecType=isnull(b.DefaultNumeric,a.DefaultNumeric) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='RecType' and a.TableName='bARTH';

declare @defaultPayTerms varchar(10)
select @defaultPayTerms=isnull(b.DefaultString,a.DefaultString) 
from Viewpoint.dbo.budCustomerDefaults a
full outer join Viewpoint.dbo.budCustomerDefaults b on b.Company=@fromco and a.TableName=b.TableName and a.ColName=b.ColName
where a.Company=0 and a.ColName='PayTerms' and a.TableName='bARTH';

-- delete existing trans
alter table bARCM disable trigger all;

BEGIN tran
alter table vSMCustomer NOCHECK Constraint FK_vSMCustomer_bARCM;
alter table vSMCustomer NOCHECK COnstraint FK_vSMCustomer_bARCM_BillTo;
delete from bARCM where CustGroup=@CustGroup 
alter table vSMCustomer CHECK COnstraint FK_vSMCustomer_bARCM_BillTo;
alter table vSMCustomer CHECK Constraint FK_vSMCustomer_bARCM;
COMMIT TRAN

-- add new trans
BEGIN TRAN
BEGIN TRY

insert bARCM (CustGroup, Customer, Name,SortName,TempYN,Phone,EMail,URL,Address,City,State,Zip,Address2,
Status,RecType, PayTerms, TaxGroup,TaxCode,CreditLimit,SelPurge,StmntPrint,StmtType,FCType,FCPct,MarkupDiscPct,
HaulTaxOpt,InvLvl,MiscOnInv,MiscOnPay,PrintLvl,SubtotalLvl,SepHaul,ExclContFromFC,BillAddress,
BillCity,BillState,BillZip,BillAddress2,DateOpened
,udSource,udConv,udCGCTable,udCGCTableID, udCGCCustomer
)


select @CustGroup
                , Customer   = cust.NewCustomerID  --.CUSTOMERNUMBER
                , Name       = c.NAME25
                , SortName   = cast(upper(substring(replace(c.NAME25,' ',''),1,9)) as varchar(9)) 
                                                + cast(cust.NewCustomerID as varchar(6))
                , TempYN     = 'N'
                , Phone      = case
								when AREACODE=0 and PHONENO=0 then null
								when AREACODE=0 and PHONENO<>0 then convert(varchar(20),PHONENO)
								else 
								convert(varchar(max),AREACODE) + '-' + convert(varchar(max),PHONENO) 
								end
                    /* OR  case when PHONENO<>0 then convert(varchar(3),AREACODE)+'-'+
					convert(varchar(3),(left(PHONENO,3)))+'-'+ convert(varchar(4),(right(PHONENO,4)))
					else null end */
				
                , Email     = case when URLADDRESS='' then null else URLADDRESS end
                , URL       = case when URLADDRESS='' then null else URLADDRESS end
                , Address   = case when ADDRESS25A='' then null else ADDRESS25A end
                , City      = case when CITY18='' then null else CITY18 end
                , State     = case when STATECODE=''  then null else STATECODE end
                , Zip       = case when ZIPCODE=''  then null else ZIPCODE end
                , Address2  = case when c.ADDRESS25B='' then null else ADDRESS25B end
                , Status    =  'A'
                , RecType   = @defaultRecType
				, PayTerms  = @defaultPayTerms
                , TaxGroup  = @TaxGroup
                , TaxCode   = @defaultTaxCode
                , CreditLimit = case when isnull(CREDITLIMIT,0)=0 then 9999999 else CREDITLIMIT end
                , SelPurge       = @defaultSelPurge
                , StmtPrint      = 'Y' /*PRTSTMTCMT  -- removed via Sarah's email dated 6/10/2013 CR */
                , StmtType       = @defaultStmtType
				, FCType         = @defaultFCType
				, FCPct          = @defaultFCPct
				, MarkupDiscPct  = @defaultMarkupDiscPct
				, HaulTaxOpt     = @defaultHaulTaxOpt
				, InvLvl         = @defaultInvLvl
				, MiscOnInv      = @defaultMiscOnInv
				, MiscOnPay      = @defaultMiscOnPay
				, PrintLvl       = @defaultPrintLvl
				, SubtotalLvl    = @defaultSubtotalLvl
				, SepHaul        = @defaultSepHaul
				, ExclContFromFC = @defaultExclContFromFC
	            , BillAddress    = case when ADDRESS25A  ='' then null else ADDRESS25A end
                , BillCity       = case when CITY18      ='' then null else CITY18     end
                , BillState      = case when STATECODE   ='' then null else STATECODE  end
                , BillZip        = case when ZIPCODE     ='' then null else ZIPCODE    end
                , BillAddress2   = case when c.ADDRESS25B='' then null else ADDRESS25B end
                , DateOpened     = case when STARTDATE = 0 then null else
                       convert(smalldatetime,(substring(convert(nvarchar(max),STARTDATE),1,4)
                       +'/'+substring(convert(nvarchar(max),STARTDATE),5,2) 
                       +'/'+substring(convert(nvarchar(max),STARTDATE),7,2)))
                               end
				, udSource       = 'MASTER_ARCM'
				, udConv         = 'Y'
				, udCGCTable     = 'CSTMST'
				, udCGCTableID   = CSTMSTID
				, udCGCCustomer  = c.CUSTOMERNUMBER
				
from CV_CMS_SOURCE.dbo.CSTMST c 

join Viewpoint.dbo.budxrefARCustomer cust 
	on  cust.Company = @fromco 
	and cust.OldCustomerID = c.CUSTOMERNUMBER
	
where COMPANYNUMBER=@fromco

select @rowcount=@@rowcount

--update bARCM
--set 
--Contact = left(rtrim(b.CCNMFS)+ ' '+ (case when b.CCNMLS<>'' then rtrim(ltrim(b.CCNMLS)) else '' end),30)
--                ,Phone = case when a.Phone is null or a.Phone = '' then 
--                                                case when b.CCAREA = 0 and b.CCPHNO <> 0 then '(   ' + ') ' + 
--                                                                substring(convert(varchar(7),b.CCPHNO),1,3) + '-'
--                                                                + substring(convert(varchar(7),b.CCPHNO),4,4)
--                                                when b.CCAREA = 0 and b.CCPHNO = 0 then null else 
--                                                                '(' + convert(varchar(3),b.CCAREA) + ') ' + 
--                                                                substring(convert(varchar(7),b.CCPHNO),1,3) + '-'
--                                                                + substring(convert(varchar(7),b.CCPHNO),4,4) 
--                                                end
--                                end
--                ,Fax=case when a.Fax is null or a.Fax = '' then 
--                                                case when b.CCFXAC = 0 and b.CCFXPH <> 0 then '(   ' + ') ' + 
--                                                                substring(convert(varchar(7),b.CCFXPH),1,3) + '-'
--                                                                + substring(convert(varchar(7),b.CCFXPH),4,4)
--                                                when b.CCFXAC = 0 and b.CCFXPH = 0 then null else 
--                                                                '(' + convert(varchar(3),b.CCFXAC) + ') ' + 
--                                                                substring(convert(varchar(7),b.CCFXPH),1,3) + '-'
--                                                                + substring(convert(varchar(7),b.CCFXPH),4,4) 
--                                                end
--                                end
--                ,ContactExt=case when b.CCPHXT<>0 then b.CCPHXT else null end
--from bARCM a 
--                join bHQCO hq on a.CustGroup = hq.CustGroup
--                join CV_CMS_SOURCE.dbo.CSTCON b on a.Customer = b.CCCUST and b.CCCONO = hq.HQCo
--where a.CustGroup=@CustGroup

--select @rowcount=@rowcount+@@rowcount



COMMIT TRAN

END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bARCM enable trigger all; 

return @@error

GO
