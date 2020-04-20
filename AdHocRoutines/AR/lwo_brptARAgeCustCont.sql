USE [Viewpoint]
GO

/****** Object:  Stored Procedure dbo.brptARAgeCustCont    Original Script Date: 8/28/99 9:32:28 AM     
                                                               Copied From ARAgePM     Copy Date  3/21/02    
           
        Used in Report   ARAgeCustCont.rpt    
       *******/    
alter proc [dbo].[lwo_brptARAgeCustCont]   
(
	@Company bCompany=null
,	@Month bMonth = null
,	@AgeDate bDate = null
,	@BegCust bCustomer=0
,	@EndCust bCustomer=999999
,	@RecType varchar(20) = ''
,	@IncludeInvoicesThrough bDate = '12/31/2049'
,	@IncludeAdjPayThrough bDate = '12/31/2049'
,	@AgeOnDueorInv char(1)='D'
,	@LevelofDetail char(1)='I'
,	@DeductDisc char(1)='Y'
,	@DaysBetweenCols tinyint=30
,	@AgeOpenCredits char(1)='N'
,	@BegPM int=0
,	@EndPM int=2147483647
,	@BegContract bContract = ''
,	@EndContract bContract = 'zzzzzzzzzz'
	)
-- @Department int,@POC int)    
            
        With Recompile    
           as    
          /* Mod 6/28/99 TF */    
          /* Mod 6/29/99 JE */    
         /* Mod 4/4/00 JE increased RecType to 20 chars */    
         /* Mod 6/13/00 JRE changed Project Manager where clause -- if @BegPM=0 then include all AR even if PM is null */    
         /* Mod 3/21/02 CR Added new field OpenYN - this field will check to see if a customer has an open amount*/    
         /* Mod 11/12/02 CR Added another clause to the OpenYN formula, it was not checking within the Month parameters */    
         /* Mod 1/20/03 CR Added clause to remove ARTL.LineType <> 'F'(Finance Charges)      
        reversed and added back in on 2/6/03 CR   */    
         /* Mod 2/6/03 CR changed Where Clause Contract parameters pointing, originally pointing to ARTH1, now ARTL  */    
         /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 fixed : Contcatination & notes. Issue #20721 */    
         /* Mod 6/12/03 DH Removed Notes Field Issue 20993*/    
         /*Mod 7/21/03  issue not created yet....added NOLOCKS to the From Clause CR    
           Mod 8/8/03  Mod 8/8/03 DH Issue 22103.  Added With Recompile       
    Mod 12/18/03 issue 22659 CR remmed out the OPENYN field and added the Join Select stmt in the Join clause    
           Mod 2/23/05 CR Issue 26960  added Company to the LastCheckDate sub query  */    
          /* mod 7/18/07 CR Issue 125877 created derived table for RecType */    
          /* SP modified for call #1358619 - changed to use temp tables to take it from 10 minutes to 1. - JH*/    
          /*    used mod for above call on issue #127001  CR */    
          /*08/30/2012	ScottAlvey	CL-###### / V1-B-10810	AR Customer and Aging Reports - not showing SM Invoice description	
			added cte to get just Invoiced invoices from SM and the left joined it twice, once to ARTH and another to
			ARTH1.*/
			set nocount on

if @Month is null
	select @Month = dateadd(month,-1,cast(cast(MONTH(getdate()) as varchar(2)) + '/1/' + cast(year(getdate()) as varchar(4)) as smalldatetime))

if @AgeDate is null
	select @AgeDate = dateadd(day, -1, dateadd(month,1,@Month))

if @IncludeInvoicesThrough is null
	select @IncludeInvoicesThrough = '12/31/2049'

if @IncludeAdjPayThrough is null
	select @IncludeAdjPayThrough = '12/31/2049'

if @BegCust is null 
	select @BegCust=0

if @EndCust is null
	select @EndCust=999999

if @AgeOnDueorInv is null --char(1)='D'
	select @AgeOnDueorInv='D'

if @LevelofDetail is null --char(1)='I'
	select @LevelofDetail='I'

if @DeductDisc is null --char(1)='Y'
	select @DeductDisc='Y'

if @DaysBetweenCols is null --tinyint=30
	select @DaysBetweenCols=30

if @AgeOpenCredits is null --char(1)='N'
	select @AgeOpenCredits='N'

if @BegPM is null --int=0
	select @BegPM=0

if @EndPM is null --int=2147483647
	select @EndPM=2147483647

if @BegContract is null --bContract = ''
	select @BegContract=''

if @EndContract is null --bContract = 'zzzzzzzzzz'
	select @EndContract='zzzzzzzzzz'

if @RecType in (null,'')    
begin    
    select @RecType = null    
end    
else    
begin    
    select @RecType = ',' + @RecType + ','    
end    
    
create table #Open    
 (ARCo   tinyint  null,    
 ApplyMth smalldatetime null,    
 ApplyTrans int  null)    
    
create table #RT    
 (ARCo  tinyint  null,    
 RecType int  null)    
    
insert into #Open (ARCo, ApplyMth, ApplyTrans)    
Select ARTL.ARCo, ApplyMth, ApplyTrans From ARTL     
                            Join ARTH on ARTH.ARCo=ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans    
                            Where ARTL.Mth<=@Month and ARTH.TransDate <= case when ARTH.ARTransType='I' then @IncludeInvoicesThrough  else @IncludeAdjPayThrough end    
                            Group By ARTL.ARCo, ApplyMth, ApplyTrans having sum(ARTL.Retainage)<>0 or sum(ARTL.Amount)<>0    
    
    
    
insert into #RT (ARCo, RecType)    
select ARRT.ARCo, ARRT.RecType /*into RT*/     
from ARRT with (nolock)    
where (ARRT.ARCo = @Company or @Company is null) and ARRT.ARCo < 100 AND (@RecType is null or CHARINDEX(','+convert(varchar(3),ARRT.RecType)+',',@RecType)>0)    ;

-- start V1-B-10810

create table  #retTable 
(
	[Mth] smalldatetime NOT NULL,
	[ARTLARTrans] int NOT NULL,
	[ARTLRecType] tinyint NULL,
	[AgeDate] smalldatetime NOT NULL,
	[DaysFromAge] int NULL,
	[AgeBucket] [varchar](10) NOT NULL,
	[OpenPaymentFlag] [int] NOT NULL,
	[AgeAmount] [numeric](15, 2) NULL,
	[Amount] [numeric](13, 2) NULL,
	[Retainage] [numeric](13, 2) NULL,
	[DiscOffered] [numeric](13, 2) NULL,
	[ApplyMth] smalldatetime NOT NULL,
	[ApplyTrans] int NOT NULL,
	[ARCo] tinyint NOT NULL,
	[ARTHARTrans] int NOT NULL,
	[ARTransType] [char](1) NOT NULL,
	[Customer] int NULL,
	[ARTHRecType] [tinyint] NULL,
	[TransDate] smalldatetime NOT NULL,
	--[Description] [varchar](max) NULL,
	[AppliedTrans] int NULL,
	[InvoiceARTransType] [char](1) NOT NULL,
	[InvoiceJCCo] tinyint NULL,
	[InvoiceContract] varchar(10) NULL,
	[ContractDesc] [varchar](8000) NULL,
	[POC] [int] NULL,
	[POCName] [varchar](30) NULL,
	[JCDepartment] varchar(10) null,
	[GLDepartmentNumber]	varchar(10) null,
	[GLDepartmentName]	varchar(30) null,
	InvoiceSMCo tinyint null,
	InvoiceSMWorkOrderID int null,
	InvoiceSMWorkOrder varchar(10) null,
	InvoiceSMWorkCompletedId bigint null,
	GLCo tinyint null,
	GLAcct char(20) null,
	[Invoice] [varchar](10) NULL,
	[InvoiceTransDate] smalldatetime NOT NULL,
	[InvoiceDueDate] smalldatetime NULL,
	[InvoiceDiscDate] smalldatetime NULL,
	[InvoiceDesc] [varchar](max) NULL,
	[Name] [varchar](60) NULL,
	[SortName] varchar(15) NOT NULL,
	[Phone] varchar(20) NULL,
	[Contact] [varchar](30) NULL,
	[StmntPrint] char(1) NOT NULL,
	[DateDesc] [varchar](8) NOT NULL,
	[LineDateDesc] [varchar](9) NOT NULL,
	[Over1Desc] [varchar](7) NULL,
	[Over2Desc] [varchar](7) NULL,
	[Over3Desc] [varchar](8) NULL,
	[LastCheckDate] smalldatetime NULL,
	[PrintCompany] [varchar](64) NULL,
	[ParamMonth] smalldatetime NULL,
	[ParamAgeDate] smalldatetime NULL,
	[ParamBegPM] [int] NULL,
	[ParamEndPM] [int] NULL,
	[ParamBegCust] [varchar](8) NULL,
	[ParamEndCust] [varchar](8) NULL,
	[ParamRecType] [varchar](20) NULL,
	[ParamIncInvoicesThru] smalldatetime NULL,
	[ParamInclAdjPayThru] smalldatetime NULL,
	[ParamAgeOnDueorInv] [char](1) NULL,
	[ParamLevelofDetail] [char](1) NULL,
	[ParamDeductDisc] [char](1) NULL,
	[ParamDaysBetweenCols] [tinyint] NULL,
	[ParamAgeOpenCredits] [char](1) NULL,
	[ParamBegContract] varchar(10) NULL,
	[ParamEndContract] varchar(10) NULL
);


   
with

cte_SMInvoiceList

as

(
	select
		ARCo 
		, ARPostedMth 
		, ARTrans 
		, DescriptionOfWork
		, InvoiceStatus
	from
		SMInvoiceList
	where
		InvoiceStatus = 'Invoiced'
)		  

-- end V1-B-10810

	INSERT INTO #retTable
	(
		[Mth]
	,	[ARTLARTrans]
	,	[ARTLRecType]
	,	[AgeDate]
	,	[DaysFromAge]
	,	[AgeBucket]
	,	[OpenPaymentFlag]
	,	[AgeAmount]
	,	[Amount]
	,	[Retainage]
	,	[DiscOffered]
	,	[ApplyMth]
	,	[ApplyTrans]
	,	[ARCo]
	,	[ARTHARTrans]
	,	[ARTransType]
	,	[Customer]
	,	[ARTHRecType]
	,	[TransDate]
	--,	[Description]
	,	[AppliedTrans]
	,	[InvoiceARTransType]
	,	[InvoiceJCCo]
	,	[InvoiceContract]
	,	[ContractDesc]
	,	[POC]
	,	[POCName]
	,	[JCDepartment]
	,	InvoiceSMCo 
	,	InvoiceSMWorkOrderID 
	,	InvoiceSMWorkOrder 
	,	InvoiceSMWorkCompletedId
	,	GLCo
	,	GLAcct
	,	[Invoice]
	,	[InvoiceTransDate]
	,	[InvoiceDueDate]
	,	[InvoiceDiscDate]
	,	[InvoiceDesc]
	,	[Name]
	,	[SortName]
	,	[Phone]
	,	[Contact]
	,	[StmntPrint]
	,	[DateDesc]
	,	[LineDateDesc]
	,	[Over1Desc]
	,	[Over2Desc]
	,	[Over3Desc]
	,	[LastCheckDate]
	,	[PrintCompany]
	,	[ParamMonth]
	,	[ParamAgeDate]
	,	[ParamBegPM]
	,	[ParamEndPM]
	,	[ParamBegCust]
	,	[ParamEndCust]
	,	[ParamRecType]
	,	[ParamIncInvoicesThru]
	,	[ParamInclAdjPayThru]
	,	[ParamAgeOnDueorInv]
	,	[ParamLevelofDetail]
	,	[ParamDeductDisc]
	,	[ParamDaysBetweenCols]
	,	[ParamAgeOpenCredits]
	,	[ParamBegContract]
	,	[ParamEndContract]
	)    
	SELECT    
		ARTL.Mth
	,	ARTLARTrans=ARTL.ARTrans
	,	ARTLRecType=ARTL.RecType
	,	AgeDate=
			case 
				when @AgeOnDueorInv='I' then ARTH1.TransDate 
				else isnull(ARTH1.DueDate,ARTH1.TransDate) 
			end
	,	DaysFromAge= 
			case 
				when @AgeOnDueorInv='I' then DATEDIFF(day, ARTH1.TransDate, @AgeDate) 
				else DATEDIFF(day,isnull(ARTH1.DueDate,ARTH1.TransDate), @AgeDate) 
			end
	,	AgeBucket= 
			case 
				when @AgeOnDueorInv='I' then 
					case 
						when DATEDIFF(day, ARTH1.TransDate, @AgeDate) < 0 then 'Future'
						when DATEDIFF(day, ARTH1.TransDate, @AgeDate) >= 0 and DATEDIFF(day, ARTH1.TransDate, @AgeDate) < 30 then 'DueCurrent'
						when DATEDIFF(day, ARTH1.TransDate, @AgeDate) >= 30 and DATEDIFF(day, ARTH1.TransDate, @AgeDate) < 60 then 'Due30to60'
						when DATEDIFF(day, ARTH1.TransDate, @AgeDate) >= 60 and DATEDIFF(day, ARTH1.TransDate, @AgeDate) < 90 then 'Due60to90'
						when DATEDIFF(day, ARTH1.TransDate, @AgeDate) >= 90 and DATEDIFF(day, ARTH1.TransDate, @AgeDate) < 120 then 'Due90to120'
						else 'Due120Plus'
					end                 
				else    
					case 
						when DATEDIFF(day,isnull(ARTH1.DueDate,ARTH1.TransDate), @AgeDate) < 0 then 'Future'
						when DATEDIFF(day,isnull(ARTH1.DueDate,ARTH1.TransDate), @AgeDate) >= 0 and DATEDIFF(day,isnull(ARTH1.DueDate,ARTH1.TransDate), @AgeDate) < 30 then 'DueCurrent'
						when DATEDIFF(day,isnull(ARTH1.DueDate,ARTH1.TransDate), @AgeDate) >= 30 and DATEDIFF(day,isnull(ARTH1.DueDate,ARTH1.TransDate), @AgeDate) < 60 then 'Due30to60'
						when DATEDIFF(day,isnull(ARTH1.DueDate,ARTH1.TransDate), @AgeDate) >= 60 and DATEDIFF(day,isnull(ARTH1.DueDate,ARTH1.TransDate), @AgeDate) < 90 then 'Due60to90'
						when DATEDIFF(day,isnull(ARTH1.DueDate,ARTH1.TransDate), @AgeDate) >= 90 and DATEDIFF(day,isnull(ARTH1.DueDate,ARTH1.TransDate), @AgeDate) < 120 then 'Due90to120'
						else 'Due120Plus'
					end        					        
				end
	,	OpenPaymentFlag=
			case 
				when @AgeOpenCredits='Y' and ((ARTH.ARTransType='P' and ARTL.Mth=ARTL.ApplyMth and ARTL.ARTrans=ARTL.ApplyTrans) or ARTH1.ARTransType='P')  then  1 
				else 0 
			end
	,	AgeAmount=
			(
				Case 
					when @DeductDisc='Y' then isnull(ARTL.Amount,0)-isnull(ARTL.DiscOffered,0)-isnull(ARTL.Retainage,0)    
					else isnull(ARTL.Amount,0)-isnull(ARTL.Retainage,0) 
				end
			)-0
	,	Amount=isnull(ARTL.Amount,0)-0, Retainage=isnull(ARTL.Retainage,0)-0
	,	DiscOffered=ARTL.DiscOffered-0
	,	ARTL.ApplyMth
	,	ARTL.ApplyTrans
	,	ARTH.ARCo
	,	ARTHARTrans=ARTH.ARTrans --2015.06.05 - LWO - Duplicate column.  Already present via ARTL.ARTRans
	,	ARTH.ARTransType
	,	ARTH.Customer
	,	ARTHRecType=ARTH.RecType
	,	ARTH.TransDate
	--,		ARTH.Description
	--,	Description = 
	--		case 
	--			when ARTH.Source = 'SM Invoice' then REPLACE(REPLACE(SMARTH.DescriptionOfWork, CHAR(13), ' '), CHAR(10), '')
	--			else REPLACE(REPLACE(ARTH.Description, CHAR(13), ' '), CHAR(10), '')  
	--		end
	,	ARTH.AppliedTrans
	,	InvoiceARTransType=ARTH1.ARTransType
	,	InvoiceJCCo=isnull(ARTH1.JCCo,ARTL.JCCo)
	,	InvoiceContract=isnull(ARTH1.Contract,ARTL.Contract)
	,	ContractDesc=REPLACE(REPLACE(JCCM.Description, CHAR(13), ''),CHAR(10), ' ') 
	,	POC = JCCM.udPOC
	,	POCName= JCMP.Name
	,	JCCM.Department
	,	InvoiceSMCo = ARTL.udSMCo
	,	InvoiceSMWorkOrderID = ARTL.udSMWorkOrderID
	,	InvoiceSMWorkOrder = ARTL.udWorkOrder
	,	InvoiceSMWorkCompletedId = ARTL.SMWorkCompletedID
	,	ARTL.GLCo
	,	ARTL.GLAcct
	,	ARTH1.Invoice
	,	InvoiceTransDate=ARTH1.TransDate
	,	InvoiceDueDate=ARTH1.DueDate
	,	InvoiceDiscDate=ARTH1.DiscDate
	--,	InvoiceDesc=ARTH1.Description
	,	InvoiceDesc = 
			case 
				when ARTH1.Source = 'SM Invoice' then REPLACE(REPLACE(SMARTH1.DescriptionOfWork, CHAR(13), ''), CHAR(10), ' ')
				else REPLACE(REPLACE(ARTH1.Description, CHAR(13), ''), CHAR(10), ' ')  
			end
	,	ARCM.Name
	,	ARCM.SortName
	,	ARCM.Phone
	,	ARCM.Contact
	,	ARCM.StmntPrint
	,	DateDesc=
			case 
				when @AgeOnDueorInv='D' then 'Due Date' 
				else  'Inv Date' 
			end
	,	LineDateDesc=
			case 
				when @AgeOnDueorInv='D' and @LevelofDetail='I' then 'Due Date'    
				when @AgeOnDueorInv='I' and @LevelofDetail='I' then 'Inv Date'    
				else 'Tran Date' 
			end
	,	Over1Desc=convert(varchar(3),@DaysBetweenCols+1)+'-'+convert(varchar(3),@DaysBetweenCols*2)
	,	Over2Desc=convert(varchar(3),(@DaysBetweenCols*2)+1)+'-'+convert(varchar(3),@DaysBetweenCols*3)
	,	Over3Desc='Over '+convert(varchar(3),@DaysBetweenCols*3)
	,	LastCheckDate = 
			(
				select 
					Max(a.TransDate) 
				from 
					ARTH a 
				where 
					a.ARTransType = 'P' 
				and a.Customer = ARTH.Customer 
				and a.Mth<=@Month 
				and a.TransDate <=@IncludeAdjPayThrough 
				and a.ARCo = ARTH.ARCo
			)
	,	PrintCompany= convert(varchar(3),HQCO.HQCo)+' '+Isnull(HQCO.Name,'')
	,	ParamMonth=@Month
	,	ParamAgeDate=@AgeDate    
	,	ParamBegPM=@BegPM  
	,	ParamEndPM=@EndPM    
	,	ParamBegCust=
			Case 
				when @BegCust=0 then 'First' 
				else convert(varchar(8),@BegCust) 
			end    
	,	ParamEndCust=
			Case 
				when @EndCust=99999999 then 'Last' 
				else convert(varchar(8),@EndCust) 
			end    
	,	ParamRecType=
			Case 
				when @RecType is null then 'All' 
				else @RecType 
			end
	,	ParamIncInvoicesThru=@IncludeInvoicesThrough
	,	ParamInclAdjPayThru=@IncludeAdjPayThrough  
	,	ParamAgeOnDueorInv=@AgeOnDueorInv
	,	ParamLevelofDetail=@LevelofDetail    
	,	ParamDeductDisc=@DeductDisc
	,	ParamDaysBetweenCols=@DaysBetweenCols
	,	ParamAgeOpenCredits=@AgeOpenCredits   
	,	ParamBegContract=@BegContract            
	,	ParamEndContract=@EndContract 
	/*
	InvoiceNotes=ARTH1.Notes    			
	JCCM.Department,
	JCCM.udPOC 
	*/
	FROM    
		ARTL with (NOLOCK)    
	JOIN ARTH ARTH1 with (NOLOCK) ON 
		ARTL.ARCo = ARTH1.ARCo 
	AND ARTL.ApplyMth = ARTH1.Mth 
	AND ARTL.ApplyTrans = ARTH1.ARTrans    
	JOIN #Open OpenC ON 
		OpenC.ARCo=ARTL.ARCo 
	and OpenC.ApplyMth=ARTL.ApplyMth 
	and OpenC.ApplyTrans=ARTL.ApplyTrans --changed from select statement 127001          
	JOIN HQCO with (NOLOCK) ON 
		ARTL.ARCo = HQCO.HQCo    
	JOIN ARTH with (NOLOCK) ON 
		ARTL.ARCo = ARTH.ARCo 
	AND ARTL.Mth = ARTH.Mth 
	AND ARTL.ARTrans = ARTH.ARTrans    
	JOIN ARCM with (NOLOCK) ON 
		ARTH.CustGroup = ARCM.CustGroup 
	AND ARTH.Customer = ARCM.Customer    
	-- Invalid,  Get POC from Contract, not PM from Job
	--Left Join JCJM with (NOLOCK) on 
	--	ARTL.JCCo=JCJM.JCCo 
	--and ARTL.Contract=JCJM.Contract 
	--and (
	--		JCJM.Job=(select min(x.Job) from JCJM x where x.JCCo=ARTL.JCCo and x.Contract=ARTL.Contract)
	--	)    
	Left Join JCCM with (NOLOCK) on 
		JCCM.JCCo=ARTL.JCCo 
	and ARTL.Contract=JCCM.Contract    
	Left Join JCMP with (NOLOCK) on 
		JCMP.JCCo=JCCM.JCCo 
	and JCMP.ProjectMgr=JCCM.udPOC   
	join #RT RT on 
		RT.ARCo = ARTL.ARCo 
	and RT.RecType = ARTL.RecType --changed from select statement 127001    
	-- start V1-B-10810
	LEFT JOIN cte_SMInvoiceList SMARTH ON 
		ARTH.ARCo=SMARTH.ARCo 
	AND ARTH.Mth=SMARTH.ARPostedMth 
	AND ARTH.ARTrans=SMARTH.ARTrans  
	LEFT JOIN cte_SMInvoiceList SMARTH1 ON 
		ARTH1.ARCo=SMARTH1.ARCo 
	AND ARTH1.Mth=SMARTH1.ARPostedMth 
	AND ARTH1.ARTrans=SMARTH1.ARTrans 
	-- end V1-B-10810 
	WHERE    
		(ARTL.ARCo=@Company or @Company is null) 
	AND ARTL.ARCo < 100 
	AND ARTL.Mth <= @Month 
	AND (ARTH1.ARCo=@Company or @Company is null) 
	AND ARTH1.ARCo < 100 
	AND ARTH1.Customer >= @BegCust 
	AND ARTH1.Customer <= @EndCust 
	AND isnull(JCCM.udPOC,0) >= @BegPM 
	AND isnull(JCCM.udPOC,2147483647) <= @EndPM               
	AND (ARTH.TransDate <= case when ARTH.ARTransType='I' then @IncludeInvoicesThrough  else @IncludeAdjPayThrough end)    
	and (isnull(ARTL.Contract,' ') >= @BegContract and isnull(ARTL.Contract,' ') <= @EndContract) -- Changed from ARTH1 to ARTL CR    
	ORDER BY    
		ARTH1.ARCo ASC    
	,	ARCM.SortName ASC   
	,	case when @AgeOpenCredits='Y' and ((ARTH.ARTransType='P' and ARTL.Mth=ARTL.ApplyMth and ARTL.ARTrans=ARTL.ApplyTrans) or ARTH1.ARTransType='P')  then  1 else 0 end
	,	ARTH1.Invoice
	,	ARTH1.Mth    
	,	ARTL.ApplyTrans    
	,	ARTH.ARTransType 


/*  Update #retTable with GL Department Numbers */
update 
	#retTable 
set 
	GLDepartmentNumber=glpi.Instance
,	GLDepartmentName=glpi.Description
from
	JCDM jcdm 
join GLPI glpi on
	jcdm.GLCo=glpi.GLCo
and glpi.PartNo=3
and substring(jcdm.OpenRevAcct,10,4)=glpi.Instance
where
	jcdm.JCCo=#retTable.InvoiceJCCo
and jcdm.Department=#retTable.JCDepartment


update 
	#retTable 
set 
	GLDepartmentNumber=glpi.Instance
,	GLDepartmentName=glpi.Description
from 
	SMWorkOrder smwo
join SMServiceCenter smcntr on
	smwo.SMCo=smcntr.SMCo
and smwo.ServiceCenter=smcntr.ServiceCenter 
join SMDepartment smdept on
	smcntr.SMCo=smdept.SMCo
and smcntr.Department=smdept.Department 
join GLPI glpi on
	smdept.GLCo=glpi.GLCo
and glpi.PartNo=3
and substring(smdept.MaterialRevGLAcct,10,4)=glpi.Instance
where
	smwo.SMCo=#retTable.InvoiceSMCo
and smwo.WorkOrder=#retTable.InvoiceSMWorkOrder

set nocount off

select 
		[Mth]
	,	ARTRans = [ARTLARTrans]
	,	RecType = [ARTLRecType]
	,	[AgeDate]
	,	[DaysFromAge]
	,	[AgeBucket]
	,	[OpenPaymentFlag]
	,	[AgeAmount]
	,	[Amount]
	,	[Retainage]
	,	[DiscOffered]
	,	[ApplyMth]
	,	[ApplyTrans]
	,	[ARCo]
	--,	[ARTHARTrans]
	,	[ARTransType]
	,	[Customer]
	--,	[ARTHRecType]
	,	[TransDate]
	--,	InvoiceDescription = [Description]
	,	[AppliedTrans]
	,	[InvoiceARTransType]
	,	[InvoiceJCCo]
	,	[InvoiceContract]
	,	[ContractDesc]
	,	[POC]
	,	[POCName]
	,	[JCDepartment] 
	,	[GLDepartmentNumber]
	,	[GLDepartmentName]
	,	InvoiceSMCo 
	,	InvoiceSMWorkOrderID 
	,	InvoiceSMWorkOrder 
	,	InvoiceSMWorkCompletedId
	,	GLCo
	,	GLAcct
	,	[Invoice]
	,	[InvoiceTransDate]
	,	[InvoiceDueDate]
	,	[InvoiceDiscDate]
	,	[InvoiceDesc]
	,	CustomerName = [Name]
	,	CustomerSortName = [SortName]
	,	CustomerPhone = [Phone]
	,	CustomerContact = [Contact]
	,	[StmntPrint]
	--,	[DateDesc]
	--,	[LineDateDesc]
	--,	[Over1Desc]
	--,	[Over2Desc]
	--,	[Over3Desc]
	,	[LastCheckDate]
	--,	[PrintCompany]
	,	[ParamMonth]
	,	[ParamAgeDate]
	,	[ParamBegPM]
	,	[ParamEndPM]
	,	[ParamBegCust]
	,	[ParamEndCust]
	,	[ParamRecType]
	,	[ParamIncInvoicesThru]
	,	[ParamInclAdjPayThru]
	,	[ParamAgeOnDueorInv]
	,	[ParamLevelofDetail]
	,	[ParamDeductDisc]
	,	[ParamDaysBetweenCols]
	,	[ParamAgeOpenCredits]
	,	[ParamBegContract]
	,	[ParamEndContract]
from 
	#retTable

go

grant exec on lwo_brptARAgeCustCont to public
go


declare @Company bCompany
declare @Month bMonth
declare @AgeDate bDate
declare @BegCust bCustomer
declare @EndCust bCustomer
declare @RecType varchar(20)
declare @IncludeInvoicesThrough bDate
declare @IncludeAdjPayThrough bDate
declare @AgeOnDueorInv char(1)
declare @LevelofDetail char(1)
declare @DeductDisc char(1)
declare @DaysBetweenCols tinyint
declare @AgeOpenCredits char(1)
declare @BegPM int
declare @EndPM int
declare @BegContract bContract
declare @EndContract bContract

set @Company =null
set @Month  =null --'2015-05-01'
set @AgeDate  = null --'2015-05-31'
set @BegCust =null
set @EndCust =null
set @RecType = null
set @IncludeInvoicesThrough  = null --'2049-12-31'
set @IncludeAdjPayThrough  = null --'2049-12-31'
set @AgeOnDueorInv ='D'
set @LevelofDetail ='I'
set @DeductDisc ='Y'
set @DaysBetweenCols =30
set @AgeOpenCredits ='N'
set @BegPM =0
set @EndPM =2147483647
set @BegContract  =' '
set @EndContract  = 'zzzzzzzzzz'

exec lwo_brptARAgeCustCont @Company, @Month, @AgeDate, @BegCust, @EndCust, @RecType, @IncludeInvoicesThrough, @IncludeAdjPayThrough, @AgeOnDueorInv, @LevelofDetail, @DeductDisc, @DaysBetweenCols, @AgeOpenCredits, @BegPM, @EndPM, @BegContract, @EndContract



--select
--	glpi.Instance
--,	glpi.Description
--from 
--	SMWorkOrder smwo
--join SMServiceCenter smcntr on
--	smwo.SMCo=smcntr.SMCo
--and smwo.ServiceCenter=smcntr.ServiceCenter 
--join SMDepartment smdept on
--	smcntr.SMCo=smdept.SMCo
--and smcntr.Department=smdept.Department 
--join GLPI glpi on
--	smdept.GLCo=glpi.GLCo
--and glpi.PartNo=3
--and substring(smdept.MaterialRevGLAcct,10,4)=glpi.Instance
