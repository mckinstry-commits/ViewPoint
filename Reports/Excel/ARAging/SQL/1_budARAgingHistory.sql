use Viewpoint
go

print 'Date:     ' + convert(varchar(20), getdate(), 101)
print 'Server:   ' + @@SERVERNAME
print 'Database: ' + db_name()
print ''
go

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME='budARAgingHistory' and TABLE_SCHEMA='dbo' and TABLE_TYPE='BASE TABLE' )
begin
	print 'DROP TABLE [dbo].[budARAgingHistory]'
	DROP TABLE [dbo].[budARAgingHistory]
end
go

print 'TABLE [dbo].[budARAgingHistory] already exists'
go
/*
create table  [dbo].[budARAgingHistory]
(
	[FinancialPeriod] smalldatetime not null,	
	[Mth] smalldatetime NOT NULL,
	[ARTLARTrans] int NOT NULL,
	[ARTLRecType] tinyint NULL,
	[AgeDate] smalldatetime NOT NULL,
	[DaysFromAge] int NULL,
	[AgeBucket] [varchar](20) NOT NULL,
	[OpenPaymentFlag] [int] NOT NULL,
	[AgeAmount] [numeric](15, 2) NULL,
	[Amount] [numeric](13, 2) NULL,
	[Retainage] [numeric](13, 2) NULL,
	[Paid] [numeric](13, 2) NULL,
	[CheckDate] smalldatetime null,
	[CheckNo] varchar(10) null,
	[TaxCode] varchar(10) null,
	[TaxAmount] numeric(12,2) null,
	[DiscOffered] [numeric](13, 2) NULL,
	[ApplyMth] smalldatetime NOT NULL,
	[ApplyTrans] int NOT NULL,
	[ARCo] tinyint NOT NULL,
	[ARTHARTrans] int NOT NULL,
	[ARTransType] [char](1) NOT NULL,
	[CustGroup] int null,
	[Customer] int NULL,
	[ARTHRecType] [tinyint] NULL,
	[TransDate] smalldatetime NOT NULL,
	--[Description] [varchar](max) NULL,
	[AppliedTrans] int NULL,
	[InvoiceARTransType] [char](1) NOT NULL,
	[InvoiceJCCo] tinyint NULL,
	[InvoiceContract] varchar(10) NULL,
	[InvoiceContractItem] varchar(16) NULL,
	[ContractDesc] [varchar](8000) NULL,
	[ContractItemDesc] [varchar](8000) NULL,
	[ContractTermsCode] [varchar](30) null,
	[ContractTerms] [varchar](30) null,
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
	[InvoiceTermsCode] [varchar](30) null,
	[InvoiceTerms] [varchar](30) null,
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
	[ParamEndContract] varchar(10) NULL,
	[CollectionNotes] varchar(max) null,
	[TransactionHistory] varchar(max) null,
	[ProjectManagers] varchar(max) null,
	[Source] varchar(100) not null default (@@servername +'.' + db_name()),
	[DateCreated]	datetime	not null default getdate(),
	[CreatedBy]	sysname	not null default suser_sname(),
	[DateModified]	datetime	not null default getdate(),
	[ModifiedBy]	sysname	not null default suser_sname(),

)
go
*/
print 'GRANT ALL RIGHTS ON [dbo].[budARAgingHistory] TO [public, Viewpoint]'
print ''
go

grant select, insert, update, delete on [dbo].[budARAgingHistory] to public
go

--Permission for 6.10+ Environment
--grant select, insert, update, delete on [dbo].[budARAgingHistory] to Viewpoint
go
