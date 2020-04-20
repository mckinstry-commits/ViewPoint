SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--Drop proc brptSubcontractStatus    
CREATE  proc [dbo].[brptSubcontractStatus]    
(@SLCo bCompany,     
@BeginSubContract VARCHAR(30) =' ',     
@EndSubContract VARCHAR(30) = 'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzz',    
@BegInvoicedDate smalldatetime,     
@ThroughDate smalldatetime,    
@IncludeInvoiceDetails bYN='Y',    
@IncludeCODetails bYN='Y',     
@BeginJob bJob=' ',     
@EndJob bJob='zzzzzzzzzz',     
@BeginVendor bVendor=0,     
@EndVendor bVendor=999999)    
        /* created 12/15/97 TF last changed 7/28/99 changed Paid <=date or null*/    
        /* Mod JRE 11/10/99 added @BeginJob, @EndJob bJob, @BeginVendor bVendor, @EndVendor bVendor */    
        /* Mod E.T. 07/15/02 fixed the JCCI join to be left, cleaned up. */    
        /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0     
                            fixed : Concatination & using tables instead of views. Issue #20721 */    
        /* Mod 03/25/04 Issue 24126 Add APTH Notes and APTL Notes to SL Subcontract Billing Report NF */    
        /* Mod 9/28/04  changed JCJM link to an Inner Join CR */    
		/* Issue 25938 Added with(nolock) to the from and join statements NF 11/11/04 */    
        /* Mod 4/13/05 Issue 27510 CR Inserted nested Case stmt for Pay Category Retainage */ 
        /* Mod 06/25/2010 GF - issue #135813 expanded SL to varchar(30) */ 
        /* Issue 140546 11/11/10 HH - Added ToDateBilledAmtNet = ToDateBilledAmt - ToDateBilledAmtTax 
											CurrBilledAmtNet = CurrBilledAmtNet - CurrBilledAmtTax
        */
          
as    
    
    
    
    
    
    
--DROP TABLE #SubContractStatus    
    
--    
--Declare @SLCo bCompany    
--set @SLCo = 1    
--     
--Declare @BeginSubContract VARCHAR(30)     
--set @BeginSubContract = 'sc99901'    
--    
--Declare @EndSubContract VARCHAR(30)    
--set @EndSubContract = 'sc99901'    
--    
--Declare @BegInvoicedDate smalldatetime    
--set @BegInvoicedDate = '2005-09-01'    
--     
--Declare @ThroughDate smalldatetime    
--set @ThroughDate = '2009-10-06'    
--    
--Declare @IncludeInvoiceDetails bYN    
--set @IncludeInvoiceDetails = 'Y'    
--    
--Declare @IncludeCODetails bYN    
--set @IncludeCODetails = 'Y'    
--     
--Declare @BeginJob bJob    
--set @BeginJob = '99901-'     
--    
--Declare @EndJob bJob    
--set @EndJob = '99901-'    
--     
--Declare @BeginVendor bVendor    
--set @BeginVendor = 788890    
--     
--Declare @EndVendor bVendor    
--set @EndVendor = 788890    
--    
--declare @InclTaxes bYN    
--set @InclTaxes = 'Y'    
    
    
    
----drop table #SubContractStatus    
----    
--    
create table #SubContractStatus    
(InsertType  varchar(40),    
SLCo   tinyint  NULL,    
SL			VARCHAR(30) NULL,    
SubDesc		VARCHAR(60) Null,    
SubStatus  tinyint  Null,    
Vendor   int  Null,    
VendorName  varchar (60) Null,    
VendorAddress varchar (60) Null,    
VendorCitySTZip varchar (60) Null,    
SLItem   smallint NULL,    
Addon   tinyint  Null,--10    
AddonPct  numeric(6,4) Null,    
AddonDesc  Char (60) Null,    
ItemType  tinyint  NULL,    
ItemDesc  varchar (60) NULL,    
ItemUM   varchar (3) NULL,    
JCCo   tinyint  NULL,    
Job    varchar(10) NULL,    
JobDesc   varchar (30) Null,    
JobAddress  varchar (60) Null,    
JobCitySTZip varchar (60) Null,--20    
PhaseGrp  tinyint  NULL,    
Phase   varchar(20) NULL,    
JCCType   tinyint  NULL,    
OrigItemCost decimal(12,2) NULL,    
OrigItemTax  decimal(12,2) NULL,----------------------------    
    
    
ChangeOrderCost decimal (12,2) NULL,    
ChangeOrderTax decimal (12,2) NULL,--------------------------------------    
CurrItemCost decimal(12,2) NULL,    
    
OrigItemUnits decimal(12,3) NULL,    
ChangeOrderUnits decimal (12,3) NULL,    
CurrItemUnits decimal(12,3) NULL,    
OrigItemUC  decimal(16,5) NULL,--30    
ChangeOrderUC decimal (16,5) NULL,    
CurrItemUC  decimal(16,5) NULL,    
ToDateBilledUnits decimal (12,3) NULL,    
CurrBilledUnits decimal (12,3) Null,    
ToDateBilledAmt decimal(12,2) NULL,    
ToDateBilledAmtTax decimal(12,2) NULL,-----------------------------------------    
CurrBilledAmt decimal(12,2) NULL,    
CurrBilledAmtTax decimal(12,2) NULL,-----------------------------------------    
PaidAmt   decimal(12,2) NULL,    
PaidAmtTax  decimal(12,2) NULL,-----------------------------------------    
ToDateRetain decimal(12,2) NULL,    
ToDateRetainTax decimal(12,2) NULL,-----------------------------------------    
CurrRetain  decimal (12,2) Null,    
CurrRetainTax decimal(12,2) NULL,-----------------------------------------    
ToDateDiscounts decimal(12,2) NULL,--40    
CurrDiscounts decimal (12,2) Null,    
APMth   smalldatetime Null,    
APTrans   int  Null,    
APRef   varchar (15) Null,    
APInvDate  smalldatetime Null,    
APLine   smallint Null,    
APSeq   tinyint  Null,    
APPayType  tinyint  Null,    
APUM   varchar (3) Null,    
APUnits   decimal (12,3) Null,--50    
APUnitCost  decimal (16,5) Null,    
APLineType  tinyint  Null,    
APAmount  decimal (12,2) Null,    
APAmountTax  decimal (12,2) Null,--------------------------------------------------------------------    
APDiscount  decimal (12,2) Null,    
APPaidAmt  decimal (12,2) Null,    
APPaidAmtTax decimal (12,2) Null,--------------------------------------------------------------------    
APBank   smallint Null,    
APCheck   varchar (10) Null,--57    
    
TotTaxAmount    decimal (12,2) Null,-----------------------------------------------------------------------    
    
InternalChangeOrder smallint Null,    
AppChangeOrder varchar (10) Null,--60    
CODate   smalldatetime Null,    
COMonth   smalldatetime Null,    
COTrans   int  Null,    
CODesc   varchar (60) Null,    
COUM   varchar (3) Null,    
COUnits   decimal (12,3) Null,    
COUnitCost  decimal (16,5) Null,    
COCost   decimal (16,2) Null,    
COCostTax  decimal (16,2) Null,-------------------------------------------------------------------------    
ReportSeq  varchar (1) Null,    
NoteSeq   varchar (1) Null,--70    
APTHNotes  Text  Null,    
APTLNotes  Text  Null,    
PayCategoryYN   char (1)        Null,    
APTDPayCategory int             Null,    
APCORetPayType smallint        Null,    
APPCRetPayType smallint Null, --76  
TaxType smallint Null )--77    
    
  
    
--select * from #SubContractStatus    
--            
         /* insert Change Order info for SubContract item */    
        /*Original Cost and Units exclude Backcharge Amts*/    
    
insert into #SubContractStatus    
(InsertType,SLCo,SL,SLItem,ItemType,Addon,AddonPct,AddonDesc,ItemDesc,ItemUM,JCCo,Job,PhaseGrp,Phase,JCCType,    
OrigItemCost, OrigItemTax, ChangeOrderCost, ChangeOrderTax, OrigItemUnits, ChangeOrderUnits,OrigItemUC,ChangeOrderUC, TaxType)    
    
    
Select     
'Change Order' as 'InsertType',    
SLIT.SLCo as 'SLCo',    
SLIT.SL as 'SL',    
SLIT.SLItem as 'SLItem',    
SLIT.ItemType as 'ItemType',    
Max(SLIT.Addon) as 'Addon',    
Max(SLIT.AddonPct) as 'AddonPct',    
Max(SLAD.Description) as 'AddonDesc',    
Max(SLIT.Description) as 'ItemDesc',    
SLIT.UM as 'ItemUM',    
SLIT.JCCo as 'JCCo',    
SLIT.Job as 'Job',    
SLIT.PhaseGroup as 'PhaseGrp',    
SLIT.Phase as 'Phase',    
SLIT.JCCType as 'JCCType',     
SLIT.OrigCost as 'OrigItemCost',    
SLIT.OrigTax as 'OrigItemTax',-------------------------------------------------------------------------------------    
sum(case when SLCD.ActDate <=@ThroughDate then (SLCD.ChangeCurCost) else 0 end) as 'ChangeOrderCost',    
sum(case when SLCD.ActDate <=@ThroughDate then (SLCD.ChgToTax) else 0 end) as 'ChangeOrderTax',---------------------------    
    
    
SLIT.OrigUnits as 'OrigItemUnits',    
sum(case when SLCD.ActDate <=@ThroughDate then (SLCD.ChangeCurUnits) else 0 end) as 'ChangeOrderUnits',    
SLIT.OrigUnitCost as 'OrigItemUC',    
sum(case when SLCD.ActDate <=@ThroughDate then (SLCD.ChangeCurUnitCost) else 0 end) as 'ChangeOrderUC',    
SLIT.TaxType  
FROM SLIT with(nolock)    
Left Join SLCD with(nolock)     
 on SLCD.SLCo=SLIT.SLCo     
 and SLCD.SL=SLIT.SL     
 and SLCD.SLItem=SLIT.SLItem    
Left Join SLAD with(nolock)     
 on SLAD.SLCo=SLIT.SLCo     
 and SLAD.Addon=SLIT.Addon    
Join SLHD with(nolock)     
 on SLHD.SLCo=SLIT.SLCo     
 and SLHD.SL=SLIT.SL    
where SLIT.SLCo=@SLCo     
 and SLIT.SL>= @BeginSubContract and SLIT.SL<= @EndSubContract    
 and isnull(SLIT.Job,'') between @BeginJob and @EndJob    
 and isnull(SLHD.Vendor,0) between @BeginVendor and @EndVendor    
group by SLIT.SLCo,SLIT.SL,SLIT.SLItem,SLIT.ItemType, SLIT.Description,SLIT.UM,SLIT.JCCo,    
SLIT.Job,SLIT.PhaseGroup,SLIT.Phase,SLIT.JCCType, SLIT.OrigCost, SLIT.OrigTax, SLIT.OrigUnits,    
SLIT.OrigUnitCost, SLIT.TaxType    
    
    
    
--select 1, * from #SubContractStatus    
--drop table #SubContractStatus    
            
         /* insert AP info for SubContract item */    
insert into #SubContractStatus    
(InsertType,SLCo,SL,SLItem,ItemType,Addon,AddonPct,AddonDesc,ItemDesc,ItemUM,JCCo,Job,PhaseGrp,Phase,JCCType,    
ToDateBilledUnits,CurrBilledUnits,ToDateBilledAmt,ToDateBilledAmtTax, CurrBilledAmt,CurrBilledAmtTax, PaidAmt,PaidAmtTax,    
ToDateRetain,ToDateRetainTax, CurrRetain, CurrRetainTax, ToDateDiscounts,CurrDiscounts, TaxType)    
            
Select     
'AP SubContract Items' as 'InsertType',    
SLIT.SLCo as 'SLCo',    
SLIT.SL,    
SLIT.SLItem,    
SLIT.ItemType,    
Max(SLIT.Addon) as 'Addon',    
Max(SLIT.AddonPct) as 'AddonPct',    
Max(SLAD.Description)as 'AddonDesc',    
SLIT.Description as 'ItemDesc',    
SLIT.UM as 'ItemUM',    
SLIT.JCCo,    
SLIT.Job,    
SLIT.PhaseGroup,    
SLIT.Phase,    
SLIT.JCCType,    
(case when APTH.InvDate<=@ThroughDate then APTL.Units else 0 end) as 'ToDateBilledUnits',    
(case when APTH.InvDate>=@BegInvoicedDate and APTH.InvDate<=@ThroughDate then APTL.Units else 0 end),    
    
sum(case when APTH.InvDate <=@ThroughDate then (APTD.Amount) else 0 end) as 'ToDateBilledAmt',    
    
sum(case when APTH.InvDate <=@ThroughDate then (APTD.TotTaxAmount) else 0 end) as 'ToDateBilledAmtTax',-------------------    
    
sum (case when APTH.InvDate>=@BegInvoicedDate and APTH.InvDate<=@ThroughDate     
    then APTD.Amount else 0 end) as 'CurrBilledAmt',    
    
sum (case when APTH.InvDate>=@BegInvoicedDate and APTH.InvDate<=@ThroughDate     
    then APTD.TotTaxAmount else 0 end) as 'CurrBilledAmtTax',----------------------------------    
    
    
    
sum(case when APTD.Status>2 and APTH.InvDate <=@ThroughDate     
   and (APTD.PaidDate<=@ThroughDate or APTD.PaidDate is null)    
   then (APTD.Amount) else 0 end) as 'PaidAmt',    
    
    
sum(case when APTD.Status>2 and APTH.InvDate <=@ThroughDate     
   and (APTD.PaidDate<=@ThroughDate or APTD.PaidDate is null)    
   then (APTD.TotTaxAmount) else 0 end) as 'PaidAmtTax',---------------------------------------------------    
    
    
sum(case when APTD.PayType=(case when APTD.PayCategory is null then             
       APCO.RetPayType else APPC.RetPayType end)     
  and (APTD.PaidDate Is Null or APTD.PaidDate>@ThroughDate) and (APTH.InvDate <=@ThroughDate)    
  then (APTD.Amount) else 0 end) as 'ToDateRetain',    
    
sum(case when APTD.PayType=(case when APTD.PayCategory is null then             
       APCO.RetPayType else APPC.RetPayType end)     
  and (APTD.PaidDate Is Null or APTD.PaidDate>@ThroughDate) and (APTH.InvDate <=@ThroughDate)    
  then (APTD.TotTaxAmount) else 0 end) as 'ToDateRetainTax',--------------------------------------------------    
    
    
    
sum(case when APTD.PayType=(case when APTD.PayCategory is null then             
       APCO.RetPayType else APPC.RetPayType end)    
   and (APTD.PaidDate Is Null or APTD.PaidDate> @ThroughDate)     
   and(APTH.InvDate>=@BegInvoicedDate and APTH.InvDate<=@ThroughDate)    
  then (APTD.Amount) else 0 end) as 'CurrRetain',    
    
sum(case when APTD.PayType=(case when APTD.PayCategory is null then             
       APCO.RetPayType else APPC.RetPayType end)    
   and (APTD.PaidDate Is Null or APTD.PaidDate> @ThroughDate)     
   and(APTH.InvDate>=@BegInvoicedDate and APTH.InvDate<=@ThroughDate)    
  then (APTD.TotTaxAmount) else 0 end) as 'CurrRetainTax',------------------------------------------    
    
    
    
sum(case when APTH.InvDate <=@ThroughDate then (APTD.DiscTaken) else 0 end) as 'ToDateDiscounts',    
sum(case when APTH.InvDate <=@ThroughDate     
   and (APTH.InvDate>=@BegInvoicedDate and APTH.InvDate<=@ThroughDate)    
   then (APTD.DiscTaken) else 0 end) as 'CurrDiscounts'  ,  
SLIT.TaxType  
FROM SLIT with(nolock)    
Join SLHD with(nolock)     
 on SLHD.SLCo=SLIT.SLCo     
 and SLHD.SL=SLIT.SL    
Left Join APTL with(nolock)     
 on APTL.APCo=SLIT.SLCo     
 and APTL.SL=SLIT.SL     
 and APTL.SLItem=SLIT.SLItem    
Left Join APTD with(nolock)     
 on APTD.APCo=APTL.APCo     
 and APTD.Mth=APTL.Mth     
 and APTD.APTrans=APTL.APTrans    
 and APTD.APLine=APTL.APLine    
Left Join APTH with(nolock)     
 on APTH.APCo=APTL.APCo     
 and APTH.Mth=APTL.Mth     
 and APTH.APTrans=APTL.APTrans    
Left Join SLAD with(nolock)     
 on SLAD.SLCo=SLIT.SLCo     
 and SLAD.Addon=SLIT.Addon    
Left Join APCO with(nolock)     
 on APCO.APCo=APTL.APCo    
Left Join APPC with(nolock)     
 on APTD.APCo=APPC.APCo     
 and APTD.PayCategory=APPC.PayCategory    
    
where SLIT.SLCo=@SLCo and SLIT.SL>= @BeginSubContract and SLIT.SL<= @EndSubContract    
and isnull(SLIT.Job,'') between @BeginJob and @EndJob    
and isnull(SLHD.Vendor,0) between @BeginVendor and @EndVendor    
group by SLIT.SLCo,SLIT.SL,SLIT.SLItem,SLIT.ItemType,SLIT.Description,SLIT.UM,    
SLIT.JCCo,SLIT.Job,SLIT.PhaseGroup,SLIT.Phase,SLIT.JCCType,APTL.APTrans,APTL.Units,    
APTH.InvDate, SLIT.TaxType   
    
--select 2,* from #SubContractStatus    
    
--drop table #SubContractStatus    
    
            
/* insert invoice details info */    
insert into #SubContractStatus    
(InsertType, SLCo,SL, SLItem,ItemType,JCCo,Job,APMth,APTrans,APRef,APInvDate,APLine,APSeq,APPayType,    
APUM,APUnits,APUnitCost,APLineType,    
APAmount, APAmountTax, APDiscount, APPaidAmt, APPaidAmtTax, APBank, APCheck, TotTaxAmount,    
ReportSeq, TaxType)    
    
Select     
'Invoice Details Info' as 'InsertType',    
APTL.APCo as 'SLCo',    
APTL.SL as 'SL',     
APTL.SLItem as 'SLItem',    
Max(SLIT.ItemType) as 'ItemType',    
Max(SLIT.JCCo) as 'JCCo',    
Max(SLIT.Job) as 'Job',    
APTL.Mth as 'APMth',    
APTL.APTrans as 'APTrans',    
Max(APTH.APRef) as 'APRef',    
APTH.InvDate as 'APInvDate',    
APTL.APLine as 'APLine',    
APTD.APSeq as 'APSeq',    
APTD.PayType as 'APPayType',    
APTL.UM as 'APUM',    
(case when APTH.InvDate <=@ThroughDate then (APTL.Units) else 0 end) as 'APUnits',    
(case when APTH.InvDate <=@ThroughDate then (APTL.UnitCost) else 0 end) as 'APUnitCost',    
APTL.LineType as 'APLineType',    
sum(case when APTH.InvDate <=@ThroughDate then (APTD.Amount) else 0 end) as 'APAmount',    
    
sum(case when APTH.InvDate <=@ThroughDate     
   and APTL.TaxType in (1,3)     
 then (APTD.TotTaxAmount) else 0 end) as 'APAmountTax',-------------------------------------------------------------    
    
sum(case when APTH.InvDate <=@ThroughDate then (APTD.DiscTaken) else 0 end) as 'APDiscount',    
sum(case when APTD.Status>2 and APTH.InvDate <=@ThroughDate     
  and (APTD.PaidDate<=@ThroughDate or APTD.PaidDate is null)    
 then (APTD.Amount) else 0 end) as 'APPaidAmt',    
sum(case when APTD.Status>2 and APTH.InvDate <=@ThroughDate     
  and (APTD.PaidDate<=@ThroughDate or APTD.PaidDate is null)    
  and APTL.TaxType in (1,3)     
 then (APTD.Amount) else 0 end) as 'APPaidAmtTax',--------------------------------------    
    
    
(case when APTD.PaidDate<=@ThroughDate then APTD.CMAcct else null end)  as 'APBank',     
(case when APTD.PaidDate<=@ThroughDate then APTD.CMRef else null end)  as 'APCheck',    
case when APTL.TaxType in (1,3) then APTD.TotTaxAmount else 0 end as 'TotTaxAmount',    
--DROP TABLE #SubContractStatus    
'1' ,  
SLIT.TaxType   
FROM APTL with(nolock)    
Join APTD with(nolock)     
 on APTD.APCo=APTL.APCo     
 and APTD.Mth=APTL.Mth     
 and APTD.APTrans=APTL.APTrans     
 and APTD.APLine=APTL.APLine    
Join APTH with(nolock)     
 on APTH.APCo=APTL.APCo     
 and APTH.Mth=APTL.Mth     
 and APTH.APTrans=APTL.APTrans     
 and APTH.InvDate <=@ThroughDate    
Join SLIT with(nolock)     
 on SLIT.SLCo=APTL.APCo     
 and SLIT.SL=APTL.SL     
 and SLIT.SLItem=APTL.SLItem    
Join SLHD with(nolock)     
 on SLHD.SLCo=SLIT.SLCo     
 and SLHD.SL=SLIT.SL    
Left Join APCO with(nolock)     
 on APCO.APCo=APTL.APCo    
Left join APPC with(nolock)     
 on APPC.APCo=APCO.APCo and APPC.RetPayType=APCO.RetPayType    
where APTL.APCo=@SLCo and APTL.SL>= @BeginSubContract and APTL.SL<= @EndSubContract    
and isnull(SLIT.Job,'') between @BeginJob and @EndJob    
and isnull(SLHD.Vendor,0) between @BeginVendor and @EndVendor      
and @IncludeInvoiceDetails='Y'    
GROUP BY    
APTL.APCo,APTL.Mth,APTL.APTrans,APTL.APLine,APTL.SL, APTL.SLItem,    
APTL.Mth,APTL.APTrans, APTH.InvDate,APTL.APLine,APTD.PayType,    
APTL.UM,APTL.Units,    
APTL.UnitCost,APTL.LineType,APTD.APSeq,APTD.CMAcct,APTD.CMRef,APTD.PaidDate,    
APCO.PayCategoryYN, APTD.PayCategory, APCO.RetPayType, APPC.RetPayType, APTL.TaxType, TotTaxAmount, SLIT.TaxType     
    
    
--select 3,* from #SubContractStatus    
    
    
    
--select * from #SubContractStatus    
    
    
    
    
    
/* insert Change Order details info */    
insert into #SubContractStatus    
(InsertType, SLCo,SL,SLItem,ItemType,JCCo,Job,InternalChangeOrder,AppChangeOrder,CODate,    
COMonth,COTrans,CODesc,COUM,COUnits,COUnitCost,COCost,COCostTax, ReportSeq, TaxType)    
    
    
select     
'Change Order Detail' as 'InsertType',    
SLCD.SLCo as 'SLCo',    
SLCD.SL as 'SL',    
SLCD.SLItem as 'SLItem',    
SLIT.ItemType as 'ItemType',    
SLIT.JCCo as 'JCCo',    
SLIT.Job as 'Job',    
SLCD.SLChangeOrder as 'InternalChangeOrder',    
SLCD.AppChangeOrder as 'AppChangeOrder',    
SLCD.ActDate as 'CODate',    
SLCD.Mth as 'COMonth',    
SLTrans as 'COTrans',    
SLCD.Description as 'CODesc',    
SLCD.UM as 'COUM',    
(case when SLCD.ActDate <=@ThroughDate then (SLCD.ChangeCurUnits) else 0 end) as 'COUnits',    
(case when SLCD.ActDate <=@ThroughDate then (SLCD.ChangeCurUnitCost) else 0 end) as 'COUnitCost',    
(case when SLCD.ActDate <=@ThroughDate then (SLCD.ChangeCurCost) else 0 end) as 'COCost',    
    
(case when SLCD.ActDate <=@ThroughDate then (SLCD.ChgToTax) else 0 end) as 'COCostTax',------------------    
    
    
'2'  ,  
SLIT.TaxType  
FROM SLCD with(nolock)    
Join SLIT with(nolock)     
 on SLIT.SLCo=SLCD.SLCo     
 and SLIT.SL=SLCD.SL     
 and SLIT.SLItem=SLCD.SLItem    
Join SLHD with(nolock)     
 on SLHD.SLCo=SLIT.SLCo     
 and SLHD.SL=SLIT.SL      
 and isnull(SLIT.Job,'') between @BeginJob and @EndJob    
 and isnull(SLHD.Vendor,0) between @BeginVendor and @EndVendor    
where SLCD.SLCo=@SLCo and SLCD.SL>= @BeginSubContract and SLCD.SL<= @EndSubContract    
 and isnull(SLIT.Job,'') between @BeginJob and @EndJob    
 and isnull(SLHD.Vendor,0) between @BeginVendor and @EndVendor    
 and @IncludeCODetails='Y'    
    
    
    
    
--select 4, * from #SubContractStatus    
    
/*GROUP BY SLCD.SLCo,SLCD.SL,SLCD.SLItem,SLIT.JCCo,SLIT.Job,SLCD.SLChangeOrder,SLCD.ActDate,    
SLCD.Mth,SLCD.Description,SLCD.UM*/    
    
/* Insert the APTL Notes per Issue 24126*/    
    
insert into #SubContractStatus    
(InsertType,SLCo, SL, SLItem, ItemType, JCCo, Job, APTLNotes, NoteSeq, TaxType)    
    
select     
'APTL Notes' as 'InsertType',    
SLIT.SLCo as 'SLCo',    
SLIT.SL as 'SL',    
SLIT.SLItem as 'SLItem',    
SLIT.ItemType as 'ItemType',    
SLIT.JCCo as 'JCCo',    
SLIT.Job as 'Job',     
APTL.Notes as 'APTLNotes',     
'N' ,  
SLIT.TaxType   
FROM SLIT with(nolock)    
Join APTL with(nolock)     
 on APTL.APCo=SLIT.SLCo and APTL.SL=SLIT.SL and APTL.SLItem=SLIT.SLItem    
Join APTH with(nolock)     
 on APTH.APCo=APTL.APCo and APTH.Mth=APTL.Mth and APTH.APTrans=APTL.APTrans    
Join SLHD with(nolock)     
 on SLHD.SLCo=SLIT.SLCo and SLHD.SL=SLIT.SL    
where SLIT.SLCo=@SLCo and SLIT.SL>= @BeginSubContract and SLIT.SL<= @EndSubContract    
and isnull(SLIT.Job,'') between @BeginJob and @EndJob    
and isnull(SLHD.Vendor,0) between @BeginVendor and @EndVendor     
and APTH.InvDate >=@BegInvoicedDate and APTH.InvDate <= @ThroughDate     
and APTL.Notes is not Null      
    
--select 5, * from #SubContractStatus    
    
/* select the results */    
select    
a.InsertType,      
a.SLCo,    
a.SL,    
SubDesc=SLHD.Description,    
SubStatus=SLHD.Status,    
Vendor=APVM.Vendor,    
VendorName=APVM.Name,    
VendorAddress=APVM.Address,    
VendorCitySTZip=(case when APVM.City is Null then IsNull(APVM.City,'')+' '+IsNull(APVM.State,'')+' '+IsNull(APVM.Zip,'') else IsNull(APVM.City,'')+',  '+IsNull(APVM.State,'')+' '+IsNull(APVM.Zip,'')end),    
a.SLItem,    
a.ItemType,    
a.Addon,    
a.AddonPct,    
a.AddonDesc,    
a.ItemDesc,    
a.ItemUM,    
a.JCCo,    
a.Job,    
ContItem=JCCI.Item,    
ContItemDesc=JCCI.Description,    
SICode=JCCI.SICode,    
JobDesc=JCJM.Description,    
JobAddress=JCJM.MailAddress,    
JobCitySTZip=(case when JCJM.MailCity is NULL then IsNull(JCJM.MailCity,'')+' '+IsNull(JCJM.MailState,'')+' '+IsNull(JCJM.MailZip,'')else IsNull(JCJM.MailCity,'')+', '+IsNull(JCJM.MailState,'')+' '+IsNull(JCJM.MailZip,'')end),    
a.PhaseGrp,    
a.Phase,    
a.JCCType,    
a.OrigItemCost,    
a.OrigItemTax,    
a.ChangeOrderCost,    
a.ChangeOrderTax,    
(case when a.ItemUM<>'LS'      
 then a.OrigItemCost+(isnull(a.ChangeOrderUnits,0)*(a.OrigItemUC+isnull(a.ChangeOrderUC,0)))     
 else a.OrigItemCost+a.ChangeOrderCost end) as 'CurrItemCost',    
    
    
    
isnull(a.OrigItemCost,0) + isnull(a.OrigItemTax,0) + isnull(a.ChangeOrderCost,0) + isnull(ChangeOrderTax,0)    
 as 'CurrItemCostWTax',    
    
    
    
    
a.OrigItemUnits,    
a.ChangeOrderUnits,    
(case when a.ItemUM<>'LS' then a.OrigItemUnits+a.ChangeOrderUnits else 0 end) as 'CurrItemUnits',    
a.OrigItemUC,    
a.ChangeOrderUC,    
(a.OrigItemUC+a.ChangeOrderUC) as 'CurrItemUC',    
(case when a.ItemType=3 then a.OrigItemCost else 0 end) as 'BackChargeAmt',    
(case when a.ItemType=3 then a.OrigItemUnits else 0 end) as 'BackChargeUnits',    
a.ToDateBilledUnits,    
a.CurrBilledUnits,    
a.ToDateBilledAmt,    
a.ToDateBilledAmtTax,-------------    
a.CurrBilledAmt,    
a.CurrBilledAmtTax,---------------    
a.PaidAmt,    
a.PaidAmtTax,---------------------    
a.ToDateRetain,    
a.ToDateRetainTax,----------------    
a.CurrRetain,    
a.CurrRetainTax,------------------    
a.ToDateDiscounts,    
a.CurrDiscounts,    
a.APTrans,a.APRef,a.APInvDate,a.APLine,a.APSeq,a.APPayType,a.APUM,a.APUnits,a.APUnitCost,    
a.APLineType,    
a.APAmount,    
a.APAmountTax,    
a.APDiscount,     
a.APPaidAmt,    
a.APPaidAmtTax,    
a.APBank,    
a.APCheck,    
a.TotTaxAmount,    
a.InternalChangeOrder,    
a.AppChangeOrder,    
a.CODate,    
a.COMonth,    
a.COTrans,    
a.CODesc,    
a.COUM,    
a.COUnits,    
a.COUnitCost,    
a.COCost,    
a.COCostTax,    
a.ReportSeq,     
a.APTLNotes,   --Add the notes per Issue 24126 03/24/04 NF    
BegSub=@BeginSubContract, EndSub=@EndSubContract,    
BegInvoiceDate=@BegInvoicedDate, ThroughDate=@ThroughDate,    
CoName=HQCO.Name,  
a.TaxType,
a.ToDateBilledAmt - a.ToDateBilledAmtTax as ToDateBilledAmtNet,
a.CurrBilledAmt - a.CurrBilledAmtTax as CurrBilledAmtNet
FROM #SubContractStatus a with(nolock)    
Join HQCO with(nolock)     
 on HQCO.HQCo=a.SLCo    
left Join SLHD with(nolock)     
 on SLHD.SLCo=a.SLCo and SLHD.SL=a.SL    
left Join JCJP  with(nolock)     
 on JCJP.JCCo=a.JCCo     
 and JCJP.Job=a.Job     
 and JCJP.PhaseGroup=a.PhaseGrp     
 and JCJP.Phase=a.Phase    
Left Join JCCI with(nolock)     
 on JCCI.JCCo=JCJP.JCCo     
 and JCCI.Contract=JCJP.Contract and JCCI.Item=JCJP.Item    
Join JCJM with(nolock)     
 on JCJM.JCCo=a.JCCo     
 and JCJM.Job=a.Job    
Left Join APVM with(nolock)     
 on APVM.VendorGroup=SLHD.VendorGroup     
 and APVM.Vendor=SLHD.Vendor    
where a.SLCo=@SLCo and a.SL>=@BeginSubContract and a.SL<=@EndSubContract    
and isnull(JCJM.Job,'')=isnull(JCJM.Job,'')    
--select * from #SubContractStatus    
--DROP TABLE #SubContractStatus    

GO
GRANT EXECUTE ON  [dbo].[brptSubcontractStatus] TO [public]
GO
