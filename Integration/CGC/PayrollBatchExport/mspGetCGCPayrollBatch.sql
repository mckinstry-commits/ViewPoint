USE [MCK_INTEGRATION]
GO

/****** Object:  StoredProcedure [dbo].[mspGetCgcPayrollBatch]    Script Date: 06/09/2014 13:21:47 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[mspGetCgcPayrollBatch]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[mspGetCgcPayrollBatch]
GO


create PROCEDURE [dbo].[mspGetCgcPayrollBatch]
(
	@CompanyNumber	decimal(2,0)
,	@BatchNumber	decimal(5,0)
,	@WeekEnding		NUMERIC(8,0)
,	@DoRefresh		INT=0
)
AS

SET NOCOUNT ON

--ALTER TABLE dbo.cgcPRPBCH ADD DTWE [numeric](8,0) null 
--ALTER TABLE dbo.cgcPRPBCI ADD DTWE [numeric](8,0) null 

--UPDATE cgcPRPBCH SET DTWE=20140511



--Create Local Tables if they do not exist
BEGIN 
	IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='cgcPRPBCH')
	BEGIN
		PRINT 'Create dbo.cgcPRPBCH'
		SELECT *,@WeekEnding AS DTWE INTO dbo.cgcPRPBCH FROM CMS.S1017192.CMSFIL.PRPBCH 
	END

	IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='cgcPRPBCI')
	BEGIN
		PRINT 'Create dbo.cgcPRPBCI'
		SELECT *,@WeekEnding AS DTWE INTO dbo.cgcPRPBCI FROM CMS.S1017192.CMSFIL.PRPBCI 
	END

	IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='cgcPRPIND')
	BEGIN
		PRINT 'Create dbo.cgcPRPIND'
		SELECT * INTO dbo.cgcPRPIND FROM CMS.S1017192.CMSFIL.PRPIND 
	END
	PRINT ''
	
	IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='cgcPRPWKD')
	BEGIN
		PRINT 'Create dbo.cgcPRPWKD'
		SELECT * INTO dbo.cgcPRPWKD FROM CMS.S1017192.CMSFIL.PRPWKD
	END
	
	IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='cgcPayrollBatchForVPImport')
	BEGIN
		PRINT 'Create dbo.cgcPayrollBatchForVPImport'
		
		CREATE TABLE [dbo].[cgcPayrollBatchForVPImport](
			[Co] [tinyint] NULL,
			[Mth] [smalldatetime] NULL,
			[BatchId] [int] NULL,
			[BatchSequence] [int] NULL,
			[BatchTransType] [char](1) NULL,
			[Employee] [int] NULL,
			[PRGroup] [tinyint] NULL,
			[PREndDate] [smalldatetime] NULL,
			[PaySeq] [tinyint] NULL,
			[PostSeq] [smallint] NULL,
			[Type] [char](1) NULL,
			[DayNum] [smallint] NULL,
			[PostDate] [smalldatetime] NULL,
			[JCCo] [tinyint] NULL,
			[Job] [varchar](10) NULL,
			[PhaseGroup] [tinyint] NULL,
			[Phase] [varchar](20) NULL,
			[GLCo] [tinyint] NULL,
			[EMCo] [tinyint] NULL,
			[WO] [varchar](10) NULL,
			[WOItem] [smallint] NULL,
			[Equipment] [varchar](10) NULL,
			[EMGroup] [tinyint] NULL,
			[EquipPhase] [varchar](20) NULL,
			[CostCode] [varchar](10) NULL,
			[CompType] [varchar](10) NULL,
			[Component] [varchar](10) NULL,
			[SMCo] [tinyint] NULL,
			[SMWorkOrder] [int] NULL,
			[SMScope] [int] NULL,
			[SMPayType] [varchar](10) NULL,
			[RevCode] [varchar](10) NULL,
			[SMCostType] [smallint] NULL,
			[SMJCCostType] [tinyint] NULL,
			[EquipCType] [tinyint] NULL,
			[UsageUnits] [numeric](10, 2) NULL,
			[TaxState] [varchar](4) NULL,
			[LocalCode] [varchar](10) NULL,
			[UnempState] [varchar](4) NULL,
			[InsState] [varchar](4) NULL,
			[InsCode] [varchar](10) NULL,
			[PRDept] [varchar](10) NULL,
			[Crew] [varchar](10) NULL,
			[Cert] [char](1) NULL,
			[Craft] [varchar](10) NULL,
			[Class] [varchar](10) NULL,
			[EarnCode] [smallint] NULL,
			[Shift] [tinyint] NULL,
			[Hours] [numeric](10, 2) NULL,
			[Rate] [numeric](16, 5) NULL,
			[Amt] [numeric](12, 2) NULL,
			[Memo] [varchar](500) NULL,
			[udArea] [varchar](5) NULL
			) 
	END
	PRINT ''
END


--SELECT * FROM cgcPRPWKD
IF @DoRefresh=1
BEGIN
	
	--Delete All Existing Records for specified company and batch number
	BEGIN
		DELETE dbo.cgcPRPBCH WHERE BCCONO=@CompanyNumber AND BCBT05=@BatchNumber AND DTWE=@WeekEnding
		PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' dbo.cgcPRPBCH records.'
		DELETE dbo.cgcPRPBCI WHERE BICONO=@CompanyNumber AND BIBT05=@BatchNumber AND DTWE=@WeekEnding
		PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' dbo.cgcPRPBCI records.'
		DELETE dbo.cgcPRPIND WHERE INCONO=@CompanyNumber AND INBT05=@BatchNumber AND INDTWE=@WeekEnding
		PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' dbo.cgcPRPIND records.'
		DELETE dbo.cgcPRPWKD WHERE GPCONO=@CompanyNumber AND GPBT05=@BatchNumber AND GPDTWE=@WeekEnding
		PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' dbo.cgcPRPWKD records.'
		PRINT ''
	END

	--Fetch all records for specified company and batch number
	BEGIN
		INSERT dbo.cgcPRPBCH SELECT *,@WeekEnding FROM CMS.S1017192.CMSFIL.PRPBCH WHERE BCCONO=@CompanyNumber AND BCBT05=@BatchNumber 
		PRINT 'Inserted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' dbo.cgcPRPBCH records.'
		INSERT dbo.cgcPRPBCI SELECT *,@WeekEnding FROM CMS.S1017192.CMSFIL.PRPBCI WHERE BICONO=@CompanyNumber AND BIBT05=@BatchNumber	
		PRINT 'Inserted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' dbo.cgcPRPBCI records.'
		INSERT dbo.cgcPRPIND SELECT * FROM CMS.S1017192.CMSFIL.PRPIND WHERE INCONO=@CompanyNumber AND INBT05=@BatchNumber AND INDTWE=@WeekEnding
		PRINT 'Inserted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' dbo.cgcPRPIND records.'
		INSERT dbo.cgcPRPWKD SELECT * FROM CMS.S1017192.CMSFIL.PRPWKD WHERE GPCONO=@CompanyNumber AND GPBT05=@BatchNumber AND GPDTWE=@WeekEnding	
		PRINT 'Inserted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' dbo.cgcPRPIND records.'
		PRINT ''
	END

END

DELETE dbo.cgcPayrollBatchForVPImport WHERE Memo LIKE '%@@' + CAST(@CompanyNumber AS VARCHAR(5)) + '.' + CAST(@BatchNumber AS VARCHAR(10)) + '.' + CAST(@WeekEnding AS VARCHAR(10)) + '@@%'
PRINT 'Deleted ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' dbo.cgcPayrollBatchForVPImport records.'	

--Create Temp Table to Match VP Import Table Format
--DECLARE @vp_IM_Payroll TABLE
--(
--	Co				TINYINT				null
--,	Mth				SMALLDATETIME		null
--,	BatchId			INT					null
--,	BatchSequence	int					null
--,	BatchTransType	CHAR(1)				null
--,	Employee		int					null
--,	PRGroup			tinyint				null
--,	PREndDate		smalldatetime		null
--,	PaySeq			tinyint				null
--,	PostSeq			smallint			null
--,	[Type]			CHAR(1)				null
--,	DayNum			smallint			null
--,	PostDate		smalldatetime		null
--,	JCCo			tinyint				null
--,	Job				varchar(10)			null
--,	PhaseGroup		tinyint				null
--,	Phase			varchar(20)			null
--,	GLCo			tinyint				null
--,	EMCo			tinyint				null
--,	WO				varchar(10)			null
--,	WOItem			smallint			null
--,	Equipment		varchar(10)			null
--,	EMGroup			tinyint				null
--,	EquipPhase		varchar(20)			null
--,	CostCode		varchar(10)			null
--,	CompType		varchar(10)			null
--,	Component		varchar(10)			null
--,	SMCo			tinyint				null
--,	SMWorkOrder		int					null
--,	SMScope			int					null
--,	SMPayType		varchar(10)			null
--,	RevCode			varchar(10)			null
--,	SMCostType		smallint			null
--,	SMJCCostType	tinyint				null
--,	EquipCType		tinyint				null
--,	UsageUnits		numeric(10,2)		null
--,	TaxState		varchar(4)			null
--,	LocalCode		varchar(10)			null
--,	UnempState		varchar(4)			null
--,	InsState		varchar(4)			null
--,	InsCode			varchar(10)			null
--,	PRDept			varchar(10)			null
--,	Crew			varchar(10)			null
--,	[Cert]			CHAR(1)				null
--,	Craft			varchar(10)			null
--,	Class			varchar(10)			null
--,	EarnCode		smallint			null
--,	Shift			tinyint				null
--,	[Hours]			numeric(10,2)		null
--,	Rate			numeric(16,5)		null
--,	Amt				numeric(12,2)		null
--,	Memo			varchar(500)		NULL
----,	udArea		varchar(5)			null
--)

--Create Cursor to process all records for a Company/Batch combination
DECLARE cgc_source CURSOR FOR
SELECT
     GPSTAT  --[char](1) --NOT NULL,
,    GPCONO  --[numeric](2, 0) --NOT NULL,
,    GPDVNO  --[numeric](3, 0) --NOT NULL,
,    GPLEEN  --[numeric](5, 0) --NOT NULL,
,    GPGP05  --[numeric](5, 0) --NOT NULL,
,    GPSQ05  --[numeric](5, 0) --NOT NULL,
,    GPCKTY  --[char](2) --NOT NULL,
,    GPERCD  --[char](1) --NOT NULL,
,    GPEENO  --[numeric](5, 0) --NOT NULL,
,    GPWKNO  --[numeric](1, 0) --NOT NULL,
,    GPJBNO  --[char](6) --NOT NULL,
,    GPSJNO  --[char](3) --NOT NULL,
,    GPJCDI  --[char](15) --NOT NULL,
,    GPCSTY  --[char](1) --NOT NULL,
,    GPGLAN  --[numeric](15, 0) --NOT NULL,
,    GPEQNO  --[char](10) --NOT NULL,
,    GPEECL  --[numeric](3, 0) --NOT NULL,
,    GPSTCD  --[numeric](3, 0) --NOT NULL,
,    GPLCCD  --[numeric](3, 0) --NOT NULL,
,    GPUNNO  --[char](5) --NOT NULL,
,    GPDYWK  --[numeric](1, 0) --NOT NULL,
,    GPEETY  --[char](2) --NOT NULL,
,    GPWCCD  --[numeric](4, 0) --NOT NULL,
,    GPWCRF  --[numeric](2, 0) --NOT NULL,
,    GPRGHR  --[numeric](5, 2) --NOT NULL,
,    GPOVHR  --[numeric](5, 2) --NOT NULL,
,    GPOTHR  --[numeric](5, 2) --NOT NULL,
,    GPOTTY  --[char](2) --NOT NULL,
,    GPRGRT  --[numeric](6, 3) --NOT NULL,
,    GPOVRT  --[numeric](6, 3) --NOT NULL,
,    GPOTRT  --[numeric](6, 3) --NOT NULL,
,    GPAJ01  --[char](2) --NOT NULL,
,    GPAJ02  --[char](2) --NOT NULL,
,    GPAJ03  --[char](2) --NOT NULL,
,    GPAJ04  --[char](2) --NOT NULL,
,    GPAJ05  --[char](2) --NOT NULL,
,    GPAA01  --[numeric](7, 2) --NOT NULL,
,    GPAA02  --[numeric](7, 2) --NOT NULL,
,    GPAA03  --[numeric](7, 2) --NOT NULL,
,    GPAA04  --[numeric](7, 2) --NOT NULL,
,    GPAA05  --[numeric](7, 2) --NOT NULL,
,    GPDN01  --[numeric](3, 0) --NOT NULL,
,    GPDN02  --[numeric](3, 0) --NOT NULL,
,    GPDN03  --[numeric](3, 0) --NOT NULL,
,    GPDN04  --[numeric](3, 0) --NOT NULL,
,    GPDN05  --[numeric](3, 0) --NOT NULL,
,    GPUC01  --[numeric](3, 0) --NOT NULL,
,    GPUC02  --[numeric](3, 0) --NOT NULL,
,    GPUC03  --[numeric](3, 0) --NOT NULL,
,    GPUC04  --[numeric](3, 0) --NOT NULL,
,    GPUC05  --[numeric](3, 0) --NOT NULL,
,    GPSHNO  --[numeric](1, 0) --NOT NULL,
,    GPDPNO  --[numeric](3, 0) --NOT NULL,
,    GPPYTY  --[char](1) --NOT NULL,
,    GPSDDP  --[numeric](3, 0) --NOT NULL,
,    GPGLBK  --[numeric](15, 0) --NOT NULL,
,    GPDICO  --[numeric](2, 0) --NOT NULL,
,    GPDIDV  --[numeric](3, 0) --NOT NULL,
,    GPSLRY  --[numeric](9, 2) --NOT NULL,
,    GPWONO  --[numeric](6, 0) --NOT NULL,
,    GPCPNO  --[char](3) --NOT NULL,
,    GPEQCT  --[numeric](1, 0) --NOT NULL,
,    GPEQCD  --[char](1) --NOT NULL,
,    GPTKNO  --[numeric](5, 0) --NOT NULL,
,    GPTMPC  --[char](1) --NOT NULL,
,    GPCUST  --[numeric](5, 0) --NOT NULL,
,    GPWCST  --[numeric](3, 0) --NOT NULL,
,    GPLN02  --[numeric](2, 0) --NOT NULL,
,    GPDTWE  --[numeric](8, 0) --NOT NULL,
,    GPEXCD  --[char](1) --NOT NULL,
,    GPCRNO  --[numeric](2, 0) --NOT NULL,
,    GPATCD  --[char](1) --NOT NULL,
,    GPECCD  --[char](1) --NOT NULL,
,    GPSDRG  --[numeric](6, 3) --NOT NULL,
,    GPSDOV  --[numeric](6, 3) --NOT NULL,
,    GPSDOT  --[numeric](6, 3) --NOT NULL,
,    GPGLJC  --[numeric](15, 0) --NOT NULL,
,    GPSCCD  --[char](1) --NOT NULL,
,    GPLCD2  --[numeric](3, 0) --NOT NULL,
,    GPCNWO  --[char](20) --NOT NULL,
,    GPEQLN  --[numeric](3, 0) --NOT NULL,
,    GPGA01  --[numeric](15, 0) --NOT NULL,
,    GPGA02  --[numeric](15, 0) --NOT NULL,
,    GPGA03  --[numeric](15, 0) --NOT NULL,
,    GPGA04  --[numeric](15, 0) --NOT NULL,
,    GPGA05  --[numeric](15, 0) --NOT NULL,
,    GPRPCD  --[char](1) --NOT NULL,
,    GPSDCD  --[numeric](1, 0) --NOT NULL,
,    GPHWRG  --[numeric](6, 3) --NOT NULL,
,    GPHWOV  --[numeric](6, 3) --NOT NULL,
,    GPHWOT  --[numeric](6, 3) --NOT NULL,
,    GPBT05  --[numeric](5, 0) --NOT NULL,
,    GPCRGP  --[char](2) --NOT NULL,
,    GPCKCD  --[char](1) --NOT NULL,
,    GPSTD2  --[numeric](3, 0) --NOT NULL,
,    GPHMUN  --[char](5) --NOT NULL,
,    GPHMST  --[numeric](3, 0) --NOT NULL,
,    GPSDST  --[numeric](3, 0) --NOT NULL,
,    GPEQRH  --[numeric](5, 2) --NOT NULL,
,    GPEQVH  --[numeric](5, 2) --NOT NULL,
,    GPEQOH  --[numeric](5, 2) --NOT NULL,
,    GPQTY   --[numeric](9, 0) --NOT NULL,
,    GPRTQT  --[numeric](6, 3) --NOT NULL,
,    GPPWCD  --[char](1) --NOT NULL,
,    GPEQCL  --[char](3) --NOT NULL,
,    GPPSLB  --[char](1) --NOT NULL,
,    GPTYHR  --[char](2) --NOT NULL,
,    GPEQUP  --[char](1) --NOT NULL,
,    GPEXST  --[char](1) --NOT NULL,
,    GPUN01  --[char](5) --NOT NULL,
,    GPUN02  --[char](5) --NOT NULL,
,    GPUN03  --[char](5) --NOT NULL,
,    GPUN04  --[char](5) --NOT NULL,
,    GPUN05  --[char](5) --NOT NULL,
,    GPFABU  --[numeric](7, 2) --NOT NULL,
,    GPFAB2  --[numeric](7, 2) --NOT NULL,
,    GPFUBU  --[numeric](7, 2) --NOT NULL,
,    GPSUBU  --[numeric](7, 2) --NOT NULL,
,    GPWCBU  --[numeric](7, 2) --NOT NULL,
,    GPBIBU  --[numeric](7, 2) --NOT NULL,
,    GPPDBU  --[numeric](7, 2) --NOT NULL,
,    GPSDBU  --[numeric](7, 2) --NOT NULL,
,    GPAURV  --[char](1) --NOT NULL,
,    GPFAEN  --[numeric](7, 2) --NOT NULL,
,    GPFAE2  --[numeric](7, 2) --NOT NULL,
,    GPFUEN  --[numeric](7, 2) --NOT NULL,
,    GPSUEN  --[numeric](7, 2) --NOT NULL,
,    GPWCEN  --[numeric](7, 2) --NOT NULL,
,    GPBIEN  --[numeric](7, 2) --NOT NULL,
,    GPPDEN  --[numeric](7, 2) --NOT NULL,
,    GPSDEN  --[numeric](7, 2) --NOT NULL,
,    GPDEWT  --[numeric](9, 2) --NOT NULL,
,    GPFAWT  --[numeric](7, 2) --NOT NULL,
,    GPSWWT  --[numeric](7, 2) --NOT NULL,
,    GPSUWT  --[numeric](7, 2) --NOT NULL,
,    GPSDWT  --[numeric](7, 2) --NOT NULL,
,    GPLCWT  --[numeric](7, 2) --NOT NULL,
,    GPWCWT  --[numeric](7, 2) --NOT NULL,
,    GPSWW2  --[numeric](7, 2) --NOT NULL,
,    GPLCW2  --[numeric](7, 2) --NOT NULL,
,    GPTPRP  --[numeric](7, 2) --NOT NULL,
,    GPTPGN  --[numeric](7, 2) --NOT NULL,
,    GPTPXC  --[numeric](7, 2) --NOT NULL,
,    GPTPDM  --[numeric](7, 2) --NOT NULL,
,    GPMMWG  --[numeric](7, 2) --NOT NULL,
,    GPTPEE  --[char](1) --NOT NULL,
,    GPCSCO  --[numeric](2, 0) --NOT NULL,
,    GPCSDV  --[numeric](3, 0) --NOT NULL,
,    GPLCBU  --[numeric](7, 2) --NOT NULL,
,    GPLCEN  --[numeric](7, 2) --NOT NULL,
,    GPDCID  --[numeric](20, 0) --NOT NULL,
,    GPEECO  --[numeric](2, 0) --NOT NULL,
,    GPEEDV  --[numeric](3, 0) --NOT NULL,
,    GPAYPR  --[numeric](2, 0) --NOT NULL,
,    GPCPPE  --[char](1) --NOT NULL
FROM 
	cgcPRPWKD
WHERE
	GPCONO=@CompanyNumber
AND GPBT05=@BatchNumber
AND GPDTWE = @WeekEnding
AND GPDTWE >= 20140101
ORDER BY
	GPBT05, GPCONO, GPEENO, GPGP05, GPSQ05, GPDYWK
FOR READ ONLY

--Declare CGC Variable for Cursor Use
BEGIN
DECLARE @GPSTAT  [char](1) --NOT NULL,
DECLARE @GPCONO  [numeric](2, 0) --NOT NULL,
DECLARE @GPDVNO  [numeric](3, 0) --NOT NULL,
DECLARE @GPLEEN  [numeric](5, 0) --NOT NULL,
DECLARE @GPGP05  [numeric](5, 0) --NOT NULL,
DECLARE @GPSQ05  [numeric](5, 0) --NOT NULL,
DECLARE @GPCKTY  [char](2) --NOT NULL,
DECLARE @GPERCD  [char](1) --NOT NULL,
DECLARE @GPEENO  [numeric](5, 0) --NOT NULL,
DECLARE @GPWKNO  [numeric](1, 0) --NOT NULL,
DECLARE @GPJBNO  [char](6) --NOT NULL,
DECLARE @GPSJNO  [char](3) --NOT NULL,
DECLARE @GPJCDI  [char](15) --NOT NULL,
DECLARE @GPCSTY  [char](1) --NOT NULL,
DECLARE @GPGLAN  [numeric](15, 0) --NOT NULL,
DECLARE @GPEQNO  [char](10) --NOT NULL,
DECLARE @GPEECL  [numeric](3, 0) --NOT NULL,
DECLARE @GPSTCD  [numeric](3, 0) --NOT NULL,
DECLARE @GPLCCD  [numeric](3, 0) --NOT NULL,
DECLARE @GPUNNO  [char](5) --NOT NULL,
DECLARE @GPDYWK  [numeric](1, 0) --NOT NULL,
DECLARE @GPEETY  [char](2) --NOT NULL,
DECLARE @GPWCCD  [numeric](4, 0) --NOT NULL,
DECLARE @GPWCRF  [numeric](2, 0) --NOT NULL,
DECLARE @GPRGHR  [numeric](5, 2) --NOT NULL,
DECLARE @GPOVHR  [numeric](5, 2) --NOT NULL,
DECLARE @GPOTHR  [numeric](5, 2) --NOT NULL,
DECLARE @GPOTTY  [char](2) --NOT NULL,
DECLARE @GPRGRT  [numeric](6, 3) --NOT NULL,
DECLARE @GPOVRT  [numeric](6, 3) --NOT NULL,
DECLARE @GPOTRT  [numeric](6, 3) --NOT NULL,
DECLARE @GPAJ01  [char](2) --NOT NULL,
DECLARE @GPAJ02  [char](2) --NOT NULL,
DECLARE @GPAJ03  [char](2) --NOT NULL,
DECLARE @GPAJ04  [char](2) --NOT NULL,
DECLARE @GPAJ05  [char](2) --NOT NULL,
DECLARE @GPAA01  [numeric](7, 2) --NOT NULL,
DECLARE @GPAA02  [numeric](7, 2) --NOT NULL,
DECLARE @GPAA03  [numeric](7, 2) --NOT NULL,
DECLARE @GPAA04  [numeric](7, 2) --NOT NULL,
DECLARE @GPAA05  [numeric](7, 2) --NOT NULL,
DECLARE @GPDN01  [numeric](3, 0) --NOT NULL,
DECLARE @GPDN02  [numeric](3, 0) --NOT NULL,
DECLARE @GPDN03  [numeric](3, 0) --NOT NULL,
DECLARE @GPDN04  [numeric](3, 0) --NOT NULL,
DECLARE @GPDN05  [numeric](3, 0) --NOT NULL,
DECLARE @GPUC01  [numeric](3, 0) --NOT NULL,
DECLARE @GPUC02  [numeric](3, 0) --NOT NULL,
DECLARE @GPUC03  [numeric](3, 0) --NOT NULL,
DECLARE @GPUC04  [numeric](3, 0) --NOT NULL,
DECLARE @GPUC05  [numeric](3, 0) --NOT NULL,
DECLARE @GPSHNO  [numeric](1, 0) --NOT NULL,
DECLARE @GPDPNO  [numeric](3, 0) --NOT NULL,
DECLARE @GPPYTY  [char](1) --NOT NULL,
DECLARE @GPSDDP  [numeric](3, 0) --NOT NULL,
DECLARE @GPGLBK  [numeric](15, 0) --NOT NULL,
DECLARE @GPDICO  [numeric](2, 0) --NOT NULL,
DECLARE @GPDIDV  [numeric](3, 0) --NOT NULL,
DECLARE @GPSLRY  [numeric](9, 2) --NOT NULL,
DECLARE @GPWONO  [numeric](6, 0) --NOT NULL,
DECLARE @GPCPNO  [char](3) --NOT NULL,
DECLARE @GPEQCT  [numeric](1, 0) --NOT NULL,
DECLARE @GPEQCD  [char](1) --NOT NULL,
DECLARE @GPTKNO  [numeric](5, 0) --NOT NULL,
DECLARE @GPTMPC  [char](1) --NOT NULL,
DECLARE @GPCUST  [numeric](5, 0) --NOT NULL,
DECLARE @GPWCST  [numeric](3, 0) --NOT NULL,
DECLARE @GPLN02  [numeric](2, 0) --NOT NULL,
DECLARE @GPDTWE  [numeric](8, 0) --NOT NULL,
DECLARE @GPEXCD  [char](1) --NOT NULL,
DECLARE @GPCRNO  [numeric](2, 0) --NOT NULL,
DECLARE @GPATCD  [char](1) --NOT NULL,
DECLARE @GPECCD  [char](1) --NOT NULL,
DECLARE @GPSDRG  [numeric](6, 3) --NOT NULL,
DECLARE @GPSDOV  [numeric](6, 3) --NOT NULL,
DECLARE @GPSDOT  [numeric](6, 3) --NOT NULL,
DECLARE @GPGLJC  [numeric](15, 0) --NOT NULL,
DECLARE @GPSCCD  [char](1) --NOT NULL,
DECLARE @GPLCD2  [numeric](3, 0) --NOT NULL,
DECLARE @GPCNWO  [char](20) --NOT NULL,
DECLARE @GPEQLN  [numeric](3, 0) --NOT NULL,
DECLARE @GPGA01  [numeric](15, 0) --NOT NULL,
DECLARE @GPGA02  [numeric](15, 0) --NOT NULL,
DECLARE @GPGA03  [numeric](15, 0) --NOT NULL,
DECLARE @GPGA04  [numeric](15, 0) --NOT NULL,
DECLARE @GPGA05  [numeric](15, 0) --NOT NULL,
DECLARE @GPRPCD  [char](1) --NOT NULL,
DECLARE @GPSDCD  [numeric](1, 0) --NOT NULL,
DECLARE @GPHWRG  [numeric](6, 3) --NOT NULL,
DECLARE @GPHWOV  [numeric](6, 3) --NOT NULL,
DECLARE @GPHWOT  [numeric](6, 3) --NOT NULL,
DECLARE @GPBT05  [numeric](5, 0) --NOT NULL,
DECLARE @GPCRGP  [char](2) --NOT NULL,
DECLARE @GPCKCD  [char](1) --NOT NULL,
DECLARE @GPSTD2  [numeric](3, 0) --NOT NULL,
DECLARE @GPHMUN  [char](5) --NOT NULL,
DECLARE @GPHMST  [numeric](3, 0) --NOT NULL,
DECLARE @GPSDST  [numeric](3, 0) --NOT NULL,
DECLARE @GPEQRH  [numeric](5, 2) --NOT NULL,
DECLARE @GPEQVH  [numeric](5, 2) --NOT NULL,
DECLARE @GPEQOH  [numeric](5, 2) --NOT NULL,
DECLARE @GPQTY   [numeric](9, 0) --NOT NULL,
DECLARE @GPRTQT  [numeric](6, 3) --NOT NULL,
DECLARE @GPPWCD  [char](1) --NOT NULL,
DECLARE @GPEQCL  [char](3) --NOT NULL,
DECLARE @GPPSLB  [char](1) --NOT NULL,
DECLARE @GPTYHR  [char](2) --NOT NULL,
DECLARE @GPEQUP  [char](1) --NOT NULL,
DECLARE @GPEXST  [char](1) --NOT NULL,
DECLARE @GPUN01  [char](5) --NOT NULL,
DECLARE @GPUN02  [char](5) --NOT NULL,
DECLARE @GPUN03  [char](5) --NOT NULL,
DECLARE @GPUN04  [char](5) --NOT NULL,
DECLARE @GPUN05  [char](5) --NOT NULL,
DECLARE @GPFABU  [numeric](7, 2) --NOT NULL,
DECLARE @GPFAB2  [numeric](7, 2) --NOT NULL,
DECLARE @GPFUBU  [numeric](7, 2) --NOT NULL,
DECLARE @GPSUBU  [numeric](7, 2) --NOT NULL,
DECLARE @GPWCBU  [numeric](7, 2) --NOT NULL,
DECLARE @GPBIBU  [numeric](7, 2) --NOT NULL,
DECLARE @GPPDBU  [numeric](7, 2) --NOT NULL,
DECLARE @GPSDBU  [numeric](7, 2) --NOT NULL,
DECLARE @GPAURV  [char](1) --NOT NULL,
DECLARE @GPFAEN  [numeric](7, 2) --NOT NULL,
DECLARE @GPFAE2  [numeric](7, 2) --NOT NULL,
DECLARE @GPFUEN  [numeric](7, 2) --NOT NULL,
DECLARE @GPSUEN  [numeric](7, 2) --NOT NULL,
DECLARE @GPWCEN  [numeric](7, 2) --NOT NULL,
DECLARE @GPBIEN  [numeric](7, 2) --NOT NULL,
DECLARE @GPPDEN  [numeric](7, 2) --NOT NULL,
DECLARE @GPSDEN  [numeric](7, 2) --NOT NULL,
DECLARE @GPDEWT  [numeric](9, 2) --NOT NULL,
DECLARE @GPFAWT  [numeric](7, 2) --NOT NULL,
DECLARE @GPSWWT  [numeric](7, 2) --NOT NULL,
DECLARE @GPSUWT  [numeric](7, 2) --NOT NULL,
DECLARE @GPSDWT  [numeric](7, 2) --NOT NULL,
DECLARE @GPLCWT  [numeric](7, 2) --NOT NULL,
DECLARE @GPWCWT  [numeric](7, 2) --NOT NULL,
DECLARE @GPSWW2  [numeric](7, 2) --NOT NULL,
DECLARE @GPLCW2  [numeric](7, 2) --NOT NULL,
DECLARE @GPTPRP  [numeric](7, 2) --NOT NULL,
DECLARE @GPTPGN  [numeric](7, 2) --NOT NULL,
DECLARE @GPTPXC  [numeric](7, 2) --NOT NULL,
DECLARE @GPTPDM  [numeric](7, 2) --NOT NULL,
DECLARE @GPMMWG  [numeric](7, 2) --NOT NULL,
DECLARE @GPTPEE  [char](1) --NOT NULL,
DECLARE @GPCSCO  [numeric](2, 0) --NOT NULL,
DECLARE @GPCSDV  [numeric](3, 0) --NOT NULL,
DECLARE @GPLCBU  [numeric](7, 2) --NOT NULL,
DECLARE @GPLCEN  [numeric](7, 2) --NOT NULL,
DECLARE @GPDCID  [numeric](20, 0) --NOT NULL,
DECLARE @GPEECO  [numeric](2, 0) --NOT NULL,
DECLARE @GPEEDV  [numeric](3, 0) --NOT NULL,
DECLARE @GPAYPR  [numeric](2, 0) --NOT NULL,
DECLARE @GPCPPE  [char](1) --NOT NULL

DECLARE @vpCo		tinyint
DECLARE @vpMonth	SMALLDATETIME
DECLARE @vpPostDate	SMALLDATETIME
DECLARE @vpJCCo tinyint
DECLARE @vpJob	VARCHAR(10)
DECLARE @vpPhaseGroup TINYINT
DECLARE @vpPhase varchar(20)
DECLARE @vpPREndDate SMALLDATETIME
DECLARE @vpPRGroup TINYINT
DECLARE @vpPaySeq tinyint
DECLARE @vpPRDept varchar(10)
DECLARE @vpGLCo		TINYINT

DECLARE @vpCraft varchar(10)
DECLARE @vpClass varchar(10)

DECLARE @vpEarnCode TINYINT
DECLARE @vpDayOfWeek TINYINT

DECLARE @vpRegualrEarnCode TINYINT
DECLARE @vpOvertimeEarnCode TINYINT
DECLARE @vpOtherEarnCode TINYINT
	
END

OPEN cgc_source
FETCH cgc_source INTO
     @GPSTAT  --[char](1) --NOT NULL,
,    @GPCONO  --[numeric](2, 0) --NOT NULL,
,    @GPDVNO  --[numeric](3, 0) --NOT NULL,
,    @GPLEEN  --[numeric](5, 0) --NOT NULL,
,    @GPGP05  --[numeric](5, 0) --NOT NULL,
,    @GPSQ05  --[numeric](5, 0) --NOT NULL,
,    @GPCKTY  --[char](2) --NOT NULL,
,    @GPERCD  --[char](1) --NOT NULL,
,    @GPEENO  --[numeric](5, 0) --NOT NULL,
,    @GPWKNO  --[numeric](1, 0) --NOT NULL,
,    @GPJBNO  --[char](6) --NOT NULL,
,    @GPSJNO  --[char](3) --NOT NULL,
,    @GPJCDI  --[char](15) --NOT NULL,
,    @GPCSTY  --[char](1) --NOT NULL,
,    @GPGLAN  --[numeric](15, 0) --NOT NULL,
,    @GPEQNO  --[char](10) --NOT NULL,
,    @GPEECL  --[numeric](3, 0) --NOT NULL,
,    @GPSTCD  --[numeric](3, 0) --NOT NULL,
,    @GPLCCD  --[numeric](3, 0) --NOT NULL,
,    @GPUNNO  --[char](5) --NOT NULL,
,    @GPDYWK  --[numeric](1, 0) --NOT NULL,
,    @GPEETY  --[char](2) --NOT NULL,
,    @GPWCCD  --[numeric](4, 0) --NOT NULL,
,    @GPWCRF  --[numeric](2, 0) --NOT NULL,
,    @GPRGHR  --[numeric](5, 2) --NOT NULL,
,    @GPOVHR  --[numeric](5, 2) --NOT NULL,
,    @GPOTHR  --[numeric](5, 2) --NOT NULL,
,    @GPOTTY  --[char](2) --NOT NULL,
,    @GPRGRT  --[numeric](6, 3) --NOT NULL,
,    @GPOVRT  --[numeric](6, 3) --NOT NULL,
,    @GPOTRT  --[numeric](6, 3) --NOT NULL,
,    @GPAJ01  --[char](2) --NOT NULL,
,    @GPAJ02  --[char](2) --NOT NULL,
,    @GPAJ03  --[char](2) --NOT NULL,
,    @GPAJ04  --[char](2) --NOT NULL,
,    @GPAJ05  --[char](2) --NOT NULL,
,    @GPAA01  --[numeric](7, 2) --NOT NULL,
,    @GPAA02  --[numeric](7, 2) --NOT NULL,
,    @GPAA03  --[numeric](7, 2) --NOT NULL,
,    @GPAA04  --[numeric](7, 2) --NOT NULL,
,    @GPAA05  --[numeric](7, 2) --NOT NULL,
,    @GPDN01  --[numeric](3, 0) --NOT NULL,
,    @GPDN02  --[numeric](3, 0) --NOT NULL,
,    @GPDN03  --[numeric](3, 0) --NOT NULL,
,    @GPDN04  --[numeric](3, 0) --NOT NULL,
,    @GPDN05  --[numeric](3, 0) --NOT NULL,
,    @GPUC01  --[numeric](3, 0) --NOT NULL,
,    @GPUC02  --[numeric](3, 0) --NOT NULL,
,    @GPUC03  --[numeric](3, 0) --NOT NULL,
,    @GPUC04  --[numeric](3, 0) --NOT NULL,
,    @GPUC05  --[numeric](3, 0) --NOT NULL,
,    @GPSHNO  --[numeric](1, 0) --NOT NULL,
,    @GPDPNO  --[numeric](3, 0) --NOT NULL,
,    @GPPYTY  --[char](1) --NOT NULL,
,    @GPSDDP  --[numeric](3, 0) --NOT NULL,
,    @GPGLBK  --[numeric](15, 0) --NOT NULL,
,    @GPDICO  --[numeric](2, 0) --NOT NULL,
,    @GPDIDV  --[numeric](3, 0) --NOT NULL,
,    @GPSLRY  --[numeric](9, 2) --NOT NULL,
,    @GPWONO  --[numeric](6, 0) --NOT NULL,
,    @GPCPNO  --[char](3) --NOT NULL,
,    @GPEQCT  --[numeric](1, 0) --NOT NULL,
,    @GPEQCD  --[char](1) --NOT NULL,
,    @GPTKNO  --[numeric](5, 0) --NOT NULL,
,    @GPTMPC  --[char](1) --NOT NULL,
,    @GPCUST  --[numeric](5, 0) --NOT NULL,
,    @GPWCST  --[numeric](3, 0) --NOT NULL,
,    @GPLN02  --[numeric](2, 0) --NOT NULL,
,    @GPDTWE  --[numeric](8, 0) --NOT NULL,
,    @GPEXCD  --[char](1) --NOT NULL,
,    @GPCRNO  --[numeric](2, 0) --NOT NULL,
,    @GPATCD  --[char](1) --NOT NULL,
,    @GPECCD  --[char](1) --NOT NULL,
,    @GPSDRG  --[numeric](6, 3) --NOT NULL,
,    @GPSDOV  --[numeric](6, 3) --NOT NULL,
,    @GPSDOT  --[numeric](6, 3) --NOT NULL,
,    @GPGLJC  --[numeric](15, 0) --NOT NULL,
,    @GPSCCD  --[char](1) --NOT NULL,
,    @GPLCD2  --[numeric](3, 0) --NOT NULL,
,    @GPCNWO  --[char](20) --NOT NULL,
,    @GPEQLN  --[numeric](3, 0) --NOT NULL,
,    @GPGA01  --[numeric](15, 0) --NOT NULL,
,    @GPGA02  --[numeric](15, 0) --NOT NULL,
,    @GPGA03  --[numeric](15, 0) --NOT NULL,
,    @GPGA04  --[numeric](15, 0) --NOT NULL,
,    @GPGA05  --[numeric](15, 0) --NOT NULL,
,    @GPRPCD  --[char](1) --NOT NULL,
,    @GPSDCD  --[numeric](1, 0) --NOT NULL,
,    @GPHWRG  --[numeric](6, 3) --NOT NULL,
,    @GPHWOV  --[numeric](6, 3) --NOT NULL,
,    @GPHWOT  --[numeric](6, 3) --NOT NULL,
,    @GPBT05  --[numeric](5, 0) --NOT NULL,
,    @GPCRGP  --[char](2) --NOT NULL,
,    @GPCKCD  --[char](1) --NOT NULL,
,    @GPSTD2  --[numeric](3, 0) --NOT NULL,
,    @GPHMUN  --[char](5) --NOT NULL,
,    @GPHMST  --[numeric](3, 0) --NOT NULL,
,    @GPSDST  --[numeric](3, 0) --NOT NULL,
,    @GPEQRH  --[numeric](5, 2) --NOT NULL,
,    @GPEQVH  --[numeric](5, 2) --NOT NULL,
,    @GPEQOH  --[numeric](5, 2) --NOT NULL,
,    @GPQTY   --[numeric](9, 0) --NOT NULL,
,    @GPRTQT  --[numeric](6, 3) --NOT NULL,
,    @GPPWCD  --[char](1) --NOT NULL,
,    @GPEQCL  --[char](3) --NOT NULL,
,    @GPPSLB  --[char](1) --NOT NULL,
,    @GPTYHR  --[char](2) --NOT NULL,
,    @GPEQUP  --[char](1) --NOT NULL,
,    @GPEXST  --[char](1) --NOT NULL,
,    @GPUN01  --[char](5) --NOT NULL,
,    @GPUN02  --[char](5) --NOT NULL,
,    @GPUN03  --[char](5) --NOT NULL,
,    @GPUN04  --[char](5) --NOT NULL,
,    @GPUN05  --[char](5) --NOT NULL,
,    @GPFABU  --[numeric](7, 2) --NOT NULL,
,    @GPFAB2  --[numeric](7, 2) --NOT NULL,
,    @GPFUBU  --[numeric](7, 2) --NOT NULL,
,    @GPSUBU  --[numeric](7, 2) --NOT NULL,
,    @GPWCBU  --[numeric](7, 2) --NOT NULL,
,    @GPBIBU  --[numeric](7, 2) --NOT NULL,
,    @GPPDBU  --[numeric](7, 2) --NOT NULL,
,    @GPSDBU  --[numeric](7, 2) --NOT NULL,
,    @GPAURV  --[char](1) --NOT NULL,
,    @GPFAEN  --[numeric](7, 2) --NOT NULL,
,    @GPFAE2  --[numeric](7, 2) --NOT NULL,
,    @GPFUEN  --[numeric](7, 2) --NOT NULL,
,    @GPSUEN  --[numeric](7, 2) --NOT NULL,
,    @GPWCEN  --[numeric](7, 2) --NOT NULL,
,    @GPBIEN  --[numeric](7, 2) --NOT NULL,
,    @GPPDEN  --[numeric](7, 2) --NOT NULL,
,    @GPSDEN  --[numeric](7, 2) --NOT NULL,
,    @GPDEWT  --[numeric](9, 2) --NOT NULL,
,    @GPFAWT  --[numeric](7, 2) --NOT NULL,
,    @GPSWWT  --[numeric](7, 2) --NOT NULL,
,    @GPSUWT  --[numeric](7, 2) --NOT NULL,
,    @GPSDWT  --[numeric](7, 2) --NOT NULL,
,    @GPLCWT  --[numeric](7, 2) --NOT NULL,
,    @GPWCWT  --[numeric](7, 2) --NOT NULL,
,    @GPSWW2  --[numeric](7, 2) --NOT NULL,
,    @GPLCW2  --[numeric](7, 2) --NOT NULL,
,    @GPTPRP  --[numeric](7, 2) --NOT NULL,
,    @GPTPGN  --[numeric](7, 2) --NOT NULL,
,    @GPTPXC  --[numeric](7, 2) --NOT NULL,
,    @GPTPDM  --[numeric](7, 2) --NOT NULL,
,    @GPMMWG  --[numeric](7, 2) --NOT NULL,
,    @GPTPEE  --[char](1) --NOT NULL,
,    @GPCSCO  --[numeric](2, 0) --NOT NULL,
,    @GPCSDV  --[numeric](3, 0) --NOT NULL,
,    @GPLCBU  --[numeric](7, 2) --NOT NULL,
,    @GPLCEN  --[numeric](7, 2) --NOT NULL,
,    @GPDCID  --[numeric](20, 0) --NOT NULL,
,    @GPEECO  --[numeric](2, 0) --NOT NULL,
,    @GPEEDV  --[numeric](3, 0) --NOT NULL,
,    @GPAYPR  --[numeric](2, 0) --NOT NULL,
,    @GPCPPE  --[char](1) --NOT NULL


WHILE @@fetch_status=0
BEGIN
	PRINT
		'Batch:' + CAST(@GPBT05 AS CHAR(10))
	+	'WeekEnding:' + CAST(@GPDTWE AS CHAR(10))
	+	'DayOfWeek:' + CAST(@GPDYWK AS CHAR(5))
	+	'Company:' + CAST(@GPCONO AS CHAR(5))
	+	'GroupNumber:' + CAST(@GPGP05 AS CHAR(5))
	+	'SequenceNumber:' + CAST(@GPSQ05 AS CHAR(5))
	+	'EmloyeeNumber:' + CAST(@GPEENO AS CHAR(5))
	+	'JobNumber:' + CAST(@GPJBNO AS CHAR(8))
	+	'SubJobNumber:' + CAST(@GPSJNO AS CHAR(5))
	+	'PayItem:' + CAST(@GPJCDI AS CHAR(10))
		
	
	--TODO: Convert CGC Dates to VP Dates
	SELECT @vpMonth = CAST(SUBSTRING(CAST(@GPDTWE AS CHAR(8)),5,2) + '/01/' + LEFT(CAST(@GPDTWE AS CHAR(8)),4) AS SMALLDATETIME)
	SELECT @vpPREndDate = CAST(dbo.fnCmsToSqlDate(@GPDTWE) AS SmallDatetime)
	SELECT @vpPostDate = CAST(GETDATE() AS SMALLDATETIME) --DATEADD(day,@GPDYWK,DATEADD(week,-1,@vpPREndDate))	
	SELECT @vpDayOfWeek = CASE WHEN (@GPDYWK < 1 OR @GPDYWK > 7) THEN 5 ELSE @GPDYWK END
	
	--TODO: Lookup JCCo, Job, Phase, etc.
	--Get new JobCompany and JobNumber from JC Job Master
	SELECT 
		@vpCo=PRCo, @vpPRDept=PRDept, @vpCraft=Craft, @vpClass=Class, @vpGLCo=GLCo
	FROM
		Viewpoint.dbo.bPREH
	WHERE
		 PRCo = CASE @GPCONO WHEN 15 THEN 1 WHEN 50 THEN 1 ELSE @GPCONO END
	AND	 Employee=@GPEENO
	--AND ActiveYN='Y'
	
	--Get PRGroup and PaySeq from Mapping xref table.
	--select * FROM Viewpoint.dbo.udxrefPRPaySeq 
	SELECT @vpPRGroup=PRGroup,@vpPaySeq=PaySeq
	FROM Viewpoint.dbo.udxrefPRPaySeq 
	WHERE PRCo=@vpCo
	AND CGCBatchId=CAST(@GPBT05 AS CHAR(10))
	
	--SELECT * FROM Viewpoint.dbo.bPREH WHERE Employee=1409
	
		--Get Craft/Class From Mapping
	--SELECT * FROM ViewpointPayroll.dbo.budxrefUnion
	SELECT @vpCraft=Craft, @vpClass=Class
	FROM Viewpoint.dbo.budxrefUnion
	WHERE CMSClass=@GPEECL AND CMSType=@GPEETY
	
	
	
	--SELECT JCCo, Job, udCGCJob FROM Viewpoint.dbo.bJCJM WHERE udCGCJob
	--SELECT JCCo, LTRIM(RTRIM(Job)), udCGCJob
	--FROM
	--	Viewpoint.dbo.bJCJM 
	--WHERE 
	--	JCCo = CASE @GPDICO WHEN 15 THEN 1 WHEN 50 THEN 1 ELSE @GPDICO END --IN (1,20,60)
	--and	(udCGCJob=CAST(@GPCONO AS VARCHAR(5)) + '-' + @GPJBNO
	--OR udCGCJob=CAST(@GPDICO AS VARCHAR(5)) + '-' + @GPJBNO)
	
	SELECT @vpJCCo=JCCo, @vpJob=LTRIM(RTRIM(Job))
	FROM
		Viewpoint.dbo.bJCJM 
	WHERE 
		JCCo = CASE WHEN @GPDICO = 15 THEN 1 WHEN @GPDICO = 50 THEN 1 ELSE @GPDICO END --IN (1,20,60)
	and	LTRIM(RTRIM(udCGCJob))=LTRIM(RTRIM(CAST(@GPCONO AS VARCHAR(5)) + '-' + @GPJBNO))
	
	--SELECT JCCo, Job,udCGCJob
	--FROM
	--	Viewpoint.dbo.bJCJM 
	--WHERE 
	--	JCCo = CASE WHEN 20=15 THEN 1 WHEN 20=50 THEN 1 ELSE 20 END --IN (1,20,60)
	--AND	LTRIM(RTRIM(udCGCJob)) = LTRIM(RTRIM('20-F10675'))

--SELECT udCGCJob,* FROM Viewpoint.dbo.bJCJM WHERE udCGCJob LIKE '%C1029%'
--SELECT * FROM CMS.S1017192.CMSFIL.JCPDSC WHERE GJBNO LIKE '%C1029%'
--SELECT * FROM CMS.S1017192.CMSFIL.PRPWKD WHERE GPJBNO LIKE '%C1029%'

	--Get new Phase from Phase XRef UD Table
	--select * from Viewpoint.dbo.budxrefPhase
	SELECT @vpPhase=newPhase --COALESCE(newPhase,'['+@GPJCDI+']','[NOCGCPI]') 
	FROM Viewpoint.dbo.budxrefPhase WHERE Company=CASE @GPCONO WHEN 15 THEN 1 WHEN 50 THEN 1 ELSE @GPCONO END AND oldPhase=@GPJCDI AND VPCo=@vpJCCo
	
	--Get PhaseGroup from Job Phase Assignment table [[ verify cost type and get new value if applicable ]]
	SELECT
		@vpPhaseGroup=PhaseGroup --COALESCE(PhaseGroup,'[NO_JCJP]'), @vpPhase=COALESCE(Phase,'['+@GPJCDI+']','[NOCGCPI]')		
	FROM
		Viewpoint.dbo.bJCJP
	WHERE
		JCCo=@vpJCCo
	AND LTRIM(RTRIM(Job))=@vpJob
	AND Phase=@vpPhase

	
			
	PRINT 
		REPLICATE(' ',16)
	+	'Month:' + convert(CHAR(10),@vpMonth,101)
	+	'PostDate:' + convert(CHAR(10),@vpPostDate,101)
	+	'JobCompany:' + COALESCE(cast(@vpJCCo AS CHAR(5)),'No JCCo')
	+	'Job:' + COALESCE(cast(@vpJob AS CHAR(15)),'No Job')
	+	'PhaseGroup:' + COALESCE(cast(@vpPhaseGroup AS CHAR(5)),'No PhaseGroup')
	+	'Phase:' + COALESCE(cast(@vpPhase AS CHAR(15)),'No Phase')
	

	SELECT @vpRegualrEarnCode = COALESCE(EarnCode,9999)
	FROM Viewpoint.dbo.bPREC
	WHERE PRCo=@vpCo AND Description = 'Regular'
	
	SELECT @vpOvertimeEarnCode = COALESCE(EarnCode,9999)
	FROM Viewpoint.dbo.bPREC
	WHERE PRCo=@vpCo AND Description = 'Overtime'
	
	SELECT
		@vpOtherEarnCode = COALESCE(EarnCode,9999)
	FROM
		Viewpoint.dbo.udxrefPREarn
	WHERE
		Company=@vpCo
	AND CMSDedCode = @GPOTTY
	AND CMSCode='OTH' 
	AND VPType='E'
	
	--TODO: Process Each Row and insert to @vp_IM_Payroll for export to CSV
	--If GPAA01 = 0  (Hours)
    --                            Map all hours in GPRGHR to EarnCode 1
    --                            Map all hours in GPOVHR to EarnCode 2
    --                            All hours in GPOTHR look up GPOTTY code in the xref and map to the EarnCode in the table.  (These will be alpha codes)

	IF @GPAA01 = 0 and @GPAJ01 <> 'OD'
	BEGIN

		IF @GPRGHR <> 0
		BEGIN
		
		--SELECT * FROM Viewpoint.dbo.udxrefPREarn ORDER BY 1,2
		--select * from Viewpoint.dbo.bPREC
		--SELECT * FROM ViewpointPayroll.dbo.bPREC WHERE Method='H' AND PRCo IN (1,20,60)
		--SELECT
		--	@vpEarnCode = EarnCode
		--FROM
		--	Viewpoint.dbo.bPREC
		--WHERE
		--	PRCo=@vpCo
		--AND Description = 'Regular'
		
		INSERT [cgcPayrollBatchForVPImport] (
			Co				--TINYINT				null
		,	Mth				--SMALLDATETIME		null
		,	BatchId			--INT					null
		,	BatchSequence	--int					null
		,	BatchTransType	--CHAR(1)				null
		,	Employee		--int					null
		,	PRGroup			--tinyint				null
		,	PREndDate		--smalldatetime		null
		,	PaySeq			--tinyint				null  -- Theresa to provide BatchNumber to Pay Sequence map.
		--,	PostSeq			--smallint			null
		,	[Type]			--CHAR(1)				null -- "J" 
		,	DayNum			--smallint			null
		--,	PostDate		--smalldatetime		null
		,	JCCo			--tinyint				null
		,	Job				--varchar(10)			null
		,	PhaseGroup		--tinyint				null
		,	Phase			--varchar(20)			null
		,	GLCo			--tinyint				null  -- Same as Employee Company
		--,	EMCo			--tinyint				null
		--,	WO				--varchar(10)			null
		--,	WOItem			--smallint			null
		--,	Equipment		--varchar(10)			null
		--,	EMGroup			--tinyint				null
		--,	EquipPhase		--varchar(20)			null
		--,	CostCode		--varchar(10)			null
		--,	CompType		--varchar(10)			null
		--,	Component		--varchar(10)			null
		--,	SMCo			--tinyint				null
		--,	SMWorkOrder		--int					null
		--,	SMScope			--int					null
		--,	SMPayType		--varchar(10)			null
		--,	RevCode			--varchar(10)			null
		--,	SMCostType		--smallint			null
		--,	SMJCCostType	--tinyint				null
		--,	EquipCType		--tinyint				null
		--,	UsageUnits		--numeric(10,2)		null
		--,	TaxState		--varchar(4)			null  -- Leave Blank and let IM Template populate
		--,	LocalCode		--varchar(10)			null  -- Leave Blank and let IM Template populate
		--,	UnempState		--varchar(4)			null  -- Leave Blank and let IM Template populate
		--,	InsState		--varchar(4)			null  -- Leave Blank and let IM Template populate
		--,	InsCode			--varchar(10)			null  -- Leave Blank and let IM Template populate
		,	PRDept			--varchar(10)			null
		--,	Crew			--varchar(10)			null
		/*  Where we left off */
		,	[Cert]			--CHAR(1)				null
		,	Craft			--varchar(10)			null  -- Not from PREH but converted from Time selection
		,	Class			--varchar(10)			null  -- Not from PREH but converted from Time selection
		,	EarnCode		--smallint			null
		,	Shift			--tinyint				null
		,	[Hours]			--numeric(10,2)		null
		--,	Rate			--numeric(16,5)		null
		--,	Amt				--numeric(12,2)		null
		,	Memo			--varchar(500)		null	
		,   udArea			--CGC Crew will populate udArea in bPRTB ( if CGC=38 then udArea=503 )
		)

		SELECT
			@vpCo
		,	@vpMonth
		,	@GPBT05
		,	cast(cast(@GPGP05 as varchar(10)) + replicate('0', 4-len(cast(@GPSQ05 as varchar(10)))) + cast(@GPSQ05 as varchar(10)) as int)
		,	'A'
		,	@GPEENO
		,	@vpPRGroup
		,	@vpPREndDate
		,	@vpPaySeq
		,	'J' --[Type]
		,	@vpDayOfWeek
		--,	@vpPostDate
		,	@vpJCCo
		,	@vpJob
		,	@vpPhaseGroup
		,	@vpPhase
		,	@vpGLCo	
		,	@vpPRDept
		,	@GPECCD -- Need to determine Certified or Not
		,	@vpCraft
		,	@vpClass
		,	@vpRegualrEarnCode
		,	@GPSHNO
		,	@GPRGHR
		--,	@GPRGRT
		--,	@GPRGHR * @GPRGRT
		,	'@@' + CAST(@GPCONO AS VARCHAR(5)) + '.' + CAST(@GPBT05 AS VARCHAR(10)) + '.' + CAST(@WeekEnding AS VARCHAR(10)) + '@@ CGC Parallel Batch: ' + CAST(@GPBT05 AS VARCHAR(10)) + ' : ' + cast(@GPGP05 as varchar(10)) + replicate('0', 4-len(cast(@GPSQ05 as varchar(10)))) + cast(@GPSQ05 as varchar(10)) + ' [' + CAST(@GPCONO AS VARCHAR(5)) + '.' + CAST(@GPEENO AS VARCHAR(10)) + '] ' + CAST(@GPCONO AS VARCHAR(5)) + '.' + CAST(@GPJBNO AS VARCHAR(10)) + '.' + CAST(@GPSJNO AS VARCHAR(5)) + '.' + CAST(@GPJCDI AS VARCHAR(10)) + ' / '+ CAST(@GPDICO AS VARCHAR(5)) + '.' + CAST(@GPJBNO AS VARCHAR(10)) + '.' + CAST(@GPSJNO AS VARCHAR(5)) + '.' + CAST(@GPJCDI AS VARCHAR(10))
		,	CASE
				WHEN @GPCRNO=38 THEN '503'
				ELSE NULL
			END
		END
		
		IF @GPOVHR <> 0
		BEGIN
		
		--SELECT * FROM ViewpointPayroll.dbo.bPREC WHERE Method='H' AND PRCo IN (1,20,60)
		--SELECT
		--	@vpEarnCode = EarnCode
		--FROM
		--	Viewpoint.dbo.bPREC
		--WHERE
		--	PRCo=@vpCo
		--AND Description = 'Overtime'
		
		INSERT [cgcPayrollBatchForVPImport] (
			Co				--TINYINT				null
		,	Mth				--SMALLDATETIME		null
		,	BatchId			--INT					null
		,	BatchSequence	--int					null
		,	BatchTransType	--CHAR(1)				null
		,	Employee		--int					null
		,	PRGroup			--tinyint				null
		,	PREndDate		--smalldatetime		null
		,	PaySeq			--tinyint				null  -- Theresa to provide BatchNumber to Pay Sequence map.
		--,	PostSeq			--smallint			null
		,	[Type]			--CHAR(1)				null -- "J" 
		,	DayNum			--smallint			null
		--,	PostDate		--smalldatetime		null
		,	JCCo			--tinyint				null
		,	Job				--varchar(10)			null
		,	PhaseGroup		--tinyint				null
		,	Phase			--varchar(20)			null
		,	GLCo			--tinyint				null  -- Same as Employee Company
		--,	EMCo			--tinyint				null
		--,	WO				--varchar(10)			null
		--,	WOItem			--smallint			null
		--,	Equipment		--varchar(10)			null
		--,	EMGroup			--tinyint				null
		--,	EquipPhase		--varchar(20)			null
		--,	CostCode		--varchar(10)			null
		--,	CompType		--varchar(10)			null
		--,	Component		--varchar(10)			null
		--,	SMCo			--tinyint				null
		--,	SMWorkOrder		--int					null
		--,	SMScope			--int					null
		--,	SMPayType		--varchar(10)			null
		--,	RevCode			--varchar(10)			null
		--,	SMCostType		--smallint			null
		--,	SMJCCostType	--tinyint				null
		--,	EquipCType		--tinyint				null
		--,	UsageUnits		--numeric(10,2)		null
		--,	TaxState		--varchar(4)			null  -- Leave Blank and let IM Template populate
		--,	LocalCode		--varchar(10)			null  -- Leave Blank and let IM Template populate
		--,	UnempState		--varchar(4)			null  -- Leave Blank and let IM Template populate
		--,	InsState		--varchar(4)			null  -- Leave Blank and let IM Template populate
		--,	InsCode			--varchar(10)			null  -- Leave Blank and let IM Template populate
		,	PRDept			--varchar(10)			null
		--,	Crew			--varchar(10)			null
		/*  Where we left off */
		,	[Cert]			--CHAR(1)				null
		,	Craft			--varchar(10)			null  -- Not from PREH but converted from Time selection
		,	Class			--varchar(10)			null  -- Not from PREH but converted from Time selection
		,	EarnCode		--smallint			null
		,	Shift			--tinyint				null
		,	[Hours]			--numeric(10,2)		null
		--,	Rate			--numeric(16,5)		null
		--,	Amt				--numeric(12,2)		null
		,	Memo			--varchar(500)		null	
		,   udArea			--CGC Crew will populate udArea in bPRTB ( if CGC=38 then udArea=503 )
		)

		SELECT
			@vpCo
		,	@vpMonth
		,	@GPBT05
		,	cast(cast(@GPGP05 as varchar(10)) + replicate('0', 4-len(cast(@GPSQ05 as varchar(10)))) + cast(@GPSQ05 as varchar(10)) as int)
		,	'A'
		,	@GPEENO
		,	@vpPRGroup
		,	@vpPREndDate
		,	@vpPaySeq
		,	'J' --[Type]
		,	@vpDayOfWeek
		--,	@vpPostDate
		,	@vpJCCo
		--,	coalesce(@vpJob,'['+@GPJBNO+']')
		,	@vpJob
		,	@vpPhaseGroup
		--,	coalesce(@vpPhase,'['+@GPJCDI+']')
		,	@vpPhase
		,	@vpGLCo	
		,	@vpPRDept
		,	@GPECCD -- Need to determine Certified or Not
		,	@vpCraft
		,	@vpClass
		,	@vpOvertimeEarnCode
		,	@GPSHNO
		,	@GPOVHR
		--,	@GPOVRT
		--,	@GPOVHR * @GPOVRT
		,	'@@' + CAST(@GPCONO AS VARCHAR(5)) + '.' + CAST(@GPBT05 AS VARCHAR(10)) + '.' + CAST(@WeekEnding AS VARCHAR(10)) + '@@ CGC Parallel Batch: ' + CAST(@GPBT05 AS VARCHAR(10)) + ' : ' + cast(@GPGP05 as varchar(10)) + replicate('0', 4-len(cast(@GPSQ05 as varchar(10)))) + cast(@GPSQ05 as varchar(10)) + ' [' + CAST(@GPCONO AS VARCHAR(5)) + '.' + CAST(@GPEENO AS VARCHAR(10)) + ']' + CAST(@GPCONO AS VARCHAR(5)) + '.' + CAST(@GPJBNO AS VARCHAR(10)) + '.' + CAST(@GPSJNO AS VARCHAR(5)) + '.' + CAST(@GPJCDI AS VARCHAR(10)) + ' / '+ CAST(@GPDICO AS VARCHAR(5)) + '.' + CAST(@GPJBNO AS VARCHAR(10)) + '.' + CAST(@GPSJNO AS VARCHAR(5)) + '.' + CAST(@GPJCDI AS VARCHAR(10))
		,	CASE
				WHEN @GPCRNO=38 THEN '503'
				WHEN @GPCRNO=66 THEN '66'
				ELSE NULL
			END
		END		
		
		IF @GPOTHR <> 0
		BEGIN
		
		--SELECT * FROM ViewpointPayroll.dbo.bPREC WHERE Method='H' AND PRCo IN (1,20,60)
		--SELECT
		--	@vpEarnCode = EarnCode
		--FROM
		--	Viewpoint.dbo.bPREC
		--WHERE
		--	PRCo=@vpCo
		--AND Description = 
		--	CASE @GPOTTY
		--		WHEN 'DT' THEN 'Double Time'
		--		WHEN 'PT' THEN 'PTO'
		--		WHEN 'HL' THEN 'Holiday'
		--		WHEN 'FL' THEN 'Floating Holiday'
		--		WHEN 'JD' THEN 'Jury Duty'
		--		WHEN 'BV' THEN 'Bereavement'
		--	END
		
		INSERT [cgcPayrollBatchForVPImport] (
			Co				--TINYINT				null
		,	Mth				--SMALLDATETIME		null
		,	BatchId			--INT					null
		,	BatchSequence	--int					null
		,	BatchTransType	--CHAR(1)				null
		,	Employee		--int					null
		,	PRGroup			--tinyint				null
		,	PREndDate		--smalldatetime		null
		,	PaySeq			--tinyint				null  -- Theresa to provide BatchNumber to Pay Sequence map.
		--,	PostSeq			--smallint			null
		,	[Type]			--CHAR(1)				null -- "J" 
		,	DayNum			--smallint			null
		--,	PostDate		--smalldatetime		null
		,	JCCo			--tinyint				null
		,	Job				--varchar(10)			null
		,	PhaseGroup		--tinyint				null
		,	Phase			--varchar(20)			null
		,	GLCo			--tinyint				null  -- Same as Employee Company
		--,	EMCo			--tinyint				null
		--,	WO				--varchar(10)			null
		--,	WOItem			--smallint			null
		--,	Equipment		--varchar(10)			null
		--,	EMGroup			--tinyint				null
		--,	EquipPhase		--varchar(20)			null
		--,	CostCode		--varchar(10)			null
		--,	CompType		--varchar(10)			null
		--,	Component		--varchar(10)			null
		--,	SMCo			--tinyint				null
		--,	SMWorkOrder		--int					null
		--,	SMScope			--int					null
		--,	SMPayType		--varchar(10)			null
		--,	RevCode			--varchar(10)			null
		--,	SMCostType		--smallint			null
		--,	SMJCCostType	--tinyint				null
		--,	EquipCType		--tinyint				null
		--,	UsageUnits		--numeric(10,2)		null
		--,	TaxState		--varchar(4)			null  -- Leave Blank and let IM Template populate
		--,	LocalCode		--varchar(10)			null  -- Leave Blank and let IM Template populate
		--,	UnempState		--varchar(4)			null  -- Leave Blank and let IM Template populate
		--,	InsState		--varchar(4)			null  -- Leave Blank and let IM Template populate
		--,	InsCode			--varchar(10)			null  -- Leave Blank and let IM Template populate
		,	PRDept			--varchar(10)			null
		--,	Crew			--varchar(10)			null
		/*  Where we left off */
		,	[Cert]			--CHAR(1)				null
		,	Craft			--varchar(10)			null  -- Not from PREH but converted from Time selection
		,	Class			--varchar(10)			null  -- Not from PREH but converted from Time selection
		,	EarnCode		--smallint			null
		,	Shift			--tinyint				null
		,	[Hours]			--numeric(10,2)		null
		--,	Rate			--numeric(16,5)		null
		--,	Amt				--numeric(12,2)		null
		,	Memo			--varchar(500)		null	
		,   udArea			--CGC Crew will populate udArea in bPRTB ( if CGC=38 then udArea=503 )
		)

		SELECT
			@vpCo
		,	@vpMonth
		,	@GPBT05
		,	cast(cast(@GPGP05 as varchar(10)) + replicate('0', 4-len(cast(@GPSQ05 as varchar(10)))) + cast(@GPSQ05 as varchar(10)) as int)
		,	'A'
		,	@GPEENO
		,	@vpPRGroup
		,	@vpPREndDate
		,	@vpPaySeq
		,	'J' --[Type]
		,	@vpDayOfWeek
		--,	@vpPostDate
		,	@vpJCCo
		--,	coalesce(@vpJob,'['+@GPJBNO+']')
		,	@vpJob
		,	@vpPhaseGroup
		--,	coalesce(@vpPhase,'['+@GPJCDI+']')
		,	@vpPhase
		,	@vpGLCo	
		,	@vpPRDept
		,	@GPECCD -- Need to determine Certified or Not
		,	@vpCraft
		,	@vpClass
		,	@vpOtherEarnCode
		,	@GPSHNO
		,	@GPOTHR
		--,	@GPOTRT
		--,	@GPOTHR * @GPOTRT
		,	'@@' + CAST(@GPCONO AS VARCHAR(5)) + '.' + CAST(@GPBT05 AS VARCHAR(10)) + '.' + CAST(@WeekEnding AS VARCHAR(10)) + '@@ CGC Parallel Batch: ' + CAST(@GPBT05 AS VARCHAR(10)) + ' : ' + cast(@GPGP05 as varchar(10)) + replicate('0', 4-len(cast(@GPSQ05 as varchar(10)))) + cast(@GPSQ05 as varchar(10)) + ' [' + CAST(@GPCONO AS VARCHAR(5)) + '.' + CAST(@GPEENO AS VARCHAR(10)) + ']' + CAST(@GPCONO AS VARCHAR(5)) + '.' + CAST(@GPJBNO AS VARCHAR(10)) + '.' + CAST(@GPSJNO AS VARCHAR(5)) + '.' + CAST(@GPJCDI AS VARCHAR(10)) + ' / '+ CAST(@GPDICO AS VARCHAR(5)) + '.' + CAST(@GPJBNO AS VARCHAR(10)) + '.' + CAST(@GPSJNO AS VARCHAR(5)) + '.' + CAST(@GPJCDI AS VARCHAR(10))
		,	CASE
				WHEN @GPCRNO=38 THEN '503'
				WHEN @GPCRNO=66 THEN '66'
				ELSE NULL
			END
		END		
	END
	
	IF @GPAA01 <> 0 AND @GPAJ01 <> 'OD'
	BEGIN
        --If GPAA01 <> 0  (Amounts)
        --        All amounts in GPAA01 look up GPDN01 code in xref and map to the EarnCode in the table.  (These will be numeric codes)
        SELECT
		@vpEarnCode = COALESCE(EarnCode,9999)
		FROM
			Viewpoint.dbo.udxrefPREarn
		WHERE
			Company=@vpCo
		AND CMSDedCode = @GPDN01
		AND CMSCode<>'OTH' 
		--AND VPType<>'E'
		
		--SELECT * FROM Viewpoint.dbo.udxrefPREarn WHERE CMSCode<>'OTH' 

		INSERT [cgcPayrollBatchForVPImport] (
			Co				--TINYINT				null
		,	Mth				--SMALLDATETIME		null
		,	BatchId			--INT					null
		,	BatchSequence	--int					null
		,	BatchTransType	--CHAR(1)				null
		,	Employee		--int					null
		,	PRGroup			--tinyint				null
		,	PREndDate		--smalldatetime		null
		,	PaySeq			--tinyint				null  -- Theresa to provide BatchNumber to Pay Sequence map.
		--,	PostSeq			--smallint			null
		,	[Type]			--CHAR(1)				null -- "J" 
		,	DayNum			--smallint			null
		--,	PostDate		--smalldatetime		null
		,	JCCo			--tinyint				null
		,	Job				--varchar(10)			null
		,	PhaseGroup		--tinyint				null
		,	Phase			--varchar(20)			null
		,	GLCo			--tinyint				null  -- Same as Employee Company
		--,	EMCo			--tinyint				null
		--,	WO				--varchar(10)			null
		--,	WOItem			--smallint			null
		--,	Equipment		--varchar(10)			null
		--,	EMGroup			--tinyint				null
		--,	EquipPhase		--varchar(20)			null
		--,	CostCode		--varchar(10)			null
		--,	CompType		--varchar(10)			null
		--,	Component		--varchar(10)			null
		--,	SMCo			--tinyint				null
		--,	SMWorkOrder		--int					null
		--,	SMScope			--int					null
		--,	SMPayType		--varchar(10)			null
		--,	RevCode			--varchar(10)			null
		--,	SMCostType		--smallint			null
		--,	SMJCCostType	--tinyint				null
		--,	EquipCType		--tinyint				null
		--,	UsageUnits		--numeric(10,2)		null
		--,	TaxState		--varchar(4)			null  -- Leave Blank and let IM Template populate
		--,	LocalCode		--varchar(10)			null  -- Leave Blank and let IM Template populate
		--,	UnempState		--varchar(4)			null  -- Leave Blank and let IM Template populate
		--,	InsState		--varchar(4)			null  -- Leave Blank and let IM Template populate
		--,	InsCode			--varchar(10)			null  -- Leave Blank and let IM Template populate
		,	PRDept			--varchar(10)			null
		--,	Crew			--varchar(10)			null
		/*  Where we left off */
		,	[Cert]			--CHAR(1)				null
		,	Craft			--varchar(10)			null  -- Not from PREH but converted from Time selection
		,	Class			--varchar(10)			null  -- Not from PREH but converted from Time selection
		,	EarnCode		--smallint			null
		,	Shift			--tinyint				null
		,	[Hours]			--numeric(10,2)		null
		--,	Rate			--numeric(16,5)		null
		,	Amt				--numeric(12,2)		null
		,	Memo			--varchar(500)		null	
		,   udArea			--CGC Crew will populate udArea in bPRTB ( if CGC=38 then udArea=503 )
		)

		SELECT
			@vpCo
		,	@vpMonth
		,	@GPBT05
		,	cast(cast(@GPGP05 as varchar(10)) + replicate('0', 4-len(cast(@GPSQ05 as varchar(10)))) + cast(@GPSQ05 as varchar(10)) as int)
		,	'A'
		,	@GPEENO
		,	@vpPRGroup
		,	@vpPREndDate
		,	@vpPaySeq
		,	'J' --[Type]
		,	@vpDayOfWeek
		--,	@vpPostDate
		,	@vpJCCo
		--,	coalesce(@vpJob,'['+@GPJBNO+']')
		,	@vpJob
		,	@vpPhaseGroup
		--,	coalesce(@vpPhase,'['+@GPJCDI+']')
		,	@vpPhase
		,	@vpGLCo	
		,	@vpPRDept
		,	@GPECCD -- Need to determine Certified or Not
		,	@vpCraft
		,	@vpClass
		,	@vpEarnCode
		,	@GPSHNO
		,	@GPOTHR
		--,	@GPOTRT
		,	@GPAA01
		,	'@@' + CAST(@GPCONO AS VARCHAR(5)) + '.' + CAST(@GPBT05 AS VARCHAR(10)) + '.' + CAST(@WeekEnding AS VARCHAR(10)) + '@@ CGC Parallel Batch: ' + CAST(@GPBT05 AS VARCHAR(10)) + ' : ' + cast(@GPGP05 as varchar(10)) + replicate('0', 4-len(cast(@GPSQ05 as varchar(10)))) + cast(@GPSQ05 as varchar(10)) + ' [' + CAST(@GPCONO AS VARCHAR(5)) + '.' + CAST(@GPEENO AS VARCHAR(10)) + ']' + CAST(@GPCONO AS VARCHAR(5)) + '.' + CAST(@GPJBNO AS VARCHAR(10)) + '.' + CAST(@GPSJNO AS VARCHAR(5)) + '.' + CAST(@GPJCDI AS VARCHAR(10)) + ' / '+ CAST(@GPDICO AS VARCHAR(5)) + '.' + CAST(@GPJBNO AS VARCHAR(10)) + '.' + CAST(@GPSJNO AS VARCHAR(5)) + '.' + CAST(@GPJCDI AS VARCHAR(10))
		,	CASE
				WHEN @GPCRNO=38 THEN '503'
				WHEN @GPCRNO=66 THEN '66'
				ELSE NULL
			END
		END		
	--END
	
	
	PRINT ''

	SELECT
		@vpCo=null
	,	@vpMonth=null
	,	@vpPRGroup=null
	,	@vpPREndDate=null
	,	@vpPostDate=null
	,	@vpJCCo=null
	,	@vpJob=null
	,	@vpPhaseGroup=null
	,	@vpPhase=null
	,	@vpGLCo	=null
	,	@vpPRDept=null
	,	@vpCraft=null
	,	@vpClass=null
	,	@vpEarnCode=null		
	,	 @GPSTAT=null  --[char](1) --NOT NULL,
	,    @GPCONO=null  --[numeric](2, 0) --NOT NULL,
	,    @GPDVNO=null  --[numeric](3, 0) --NOT NULL,
	,    @GPLEEN=null  --[numeric](5, 0) --NOT NULL,
	,    @GPGP05=null  --[numeric](5, 0) --NOT NULL,
	,    @GPSQ05=null  --[numeric](5, 0) --NOT NULL,
	,    @GPCKTY=null  --[char](2) --NOT NULL,
	,    @GPERCD=null  --[char](1) --NOT NULL,
	,    @GPEENO=null  --[numeric](5, 0) --NOT NULL,
	,    @GPWKNO=null  --[numeric](1, 0) --NOT NULL,
	,    @GPJBNO=null  --[char](6) --NOT NULL,
	,    @GPSJNO=null  --[char](3) --NOT NULL,
	,    @GPJCDI=null  --[char](15) --NOT NULL,
	,    @GPCSTY=null  --[char](1) --NOT NULL,
	,    @GPGLAN=null  --[numeric](15, 0) --NOT NULL,
	,    @GPEQNO=null  --[char](10) --NOT NULL,
	,    @GPEECL=null  --[numeric](3, 0) --NOT NULL,
	,    @GPSTCD=null  --[numeric](3, 0) --NOT NULL,
	,    @GPLCCD=null  --[numeric](3, 0) --NOT NULL,
	,    @GPUNNO=null  --[char](5) --NOT NULL,
	,    @GPDYWK=null  --[numeric](1, 0) --NOT NULL,
	,    @GPEETY=null  --[char](2) --NOT NULL,
	,    @GPWCCD=null  --[numeric](4, 0) --NOT NULL,
	,    @GPWCRF=null  --[numeric](2, 0) --NOT NULL,
	,    @GPRGHR=null  --[numeric](5, 2) --NOT NULL,
	,    @GPOVHR=null  --[numeric](5, 2) --NOT NULL,
	,    @GPOTHR=null  --[numeric](5, 2) --NOT NULL,
	,    @GPOTTY=null  --[char](2) --NOT NULL,
	,    @GPRGRT=null  --[numeric](6, 3) --NOT NULL,
	,    @GPOVRT=null  --[numeric](6, 3) --NOT NULL,
	,    @GPOTRT=null  --[numeric](6, 3) --NOT NULL,
	,    @GPAJ01=null  --[char](2) --NOT NULL,
	,    @GPAJ02=null  --[char](2) --NOT NULL,
	,    @GPAJ03=null  --[char](2) --NOT NULL,
	,    @GPAJ04=null  --[char](2) --NOT NULL,
	,    @GPAJ05=null  --[char](2) --NOT NULL,
	,    @GPAA01=null  --[numeric](7, 2) --NOT NULL,
	,    @GPAA02=null  --[numeric](7, 2) --NOT NULL,
	,    @GPAA03=null  --[numeric](7, 2) --NOT NULL,
	,    @GPAA04=null  --[numeric](7, 2) --NOT NULL,
	,    @GPAA05=null  --[numeric](7, 2) --NOT NULL,
	,    @GPDN01=null  --[numeric](3, 0) --NOT NULL,
	,    @GPDN02=null  --[numeric](3, 0) --NOT NULL,
	,    @GPDN03=null  --[numeric](3, 0) --NOT NULL,
	,    @GPDN04=null  --[numeric](3, 0) --NOT NULL,
	,    @GPDN05=null  --[numeric](3, 0) --NOT NULL,
	,    @GPUC01=null  --[numeric](3, 0) --NOT NULL,
	,    @GPUC02=null  --[numeric](3, 0) --NOT NULL,
	,    @GPUC03=null  --[numeric](3, 0) --NOT NULL,
	,    @GPUC04=null  --[numeric](3, 0) --NOT NULL,
	,    @GPUC05=null  --[numeric](3, 0) --NOT NULL,
	,    @GPSHNO=null  --[numeric](1, 0) --NOT NULL,
	,    @GPDPNO=null  --[numeric](3, 0) --NOT NULL,
	,    @GPPYTY=null  --[char](1) --NOT NULL,
	,    @GPSDDP=null  --[numeric](3, 0) --NOT NULL,
	,    @GPGLBK=null  --[numeric](15, 0) --NOT NULL,
	,    @GPDICO=null  --[numeric](2, 0) --NOT NULL,
	,    @GPDIDV=null  --[numeric](3, 0) --NOT NULL,
	,    @GPSLRY=null  --[numeric](9, 2) --NOT NULL,
	,    @GPWONO=null  --[numeric](6, 0) --NOT NULL,
	,    @GPCPNO=null  --[char](3) --NOT NULL,
	,    @GPEQCT=null  --[numeric](1, 0) --NOT NULL,
	,    @GPEQCD=null  --[char](1) --NOT NULL,
	,    @GPTKNO=null  --[numeric](5, 0) --NOT NULL,
	,    @GPTMPC=null  --[char](1) --NOT NULL,
	,    @GPCUST=null  --[numeric](5, 0) --NOT NULL,
	,    @GPWCST=null  --[numeric](3, 0) --NOT NULL,
	,    @GPLN02=null  --[numeric](2, 0) --NOT NULL,
	,    @GPDTWE=null  --[numeric](8, 0) --NOT NULL,
	,    @GPEXCD=null  --[char](1) --NOT NULL,
	,    @GPCRNO=null  --[numeric](2, 0) --NOT NULL,
	,    @GPATCD=null  --[char](1) --NOT NULL,
	,    @GPECCD=null  --[char](1) --NOT NULL,
	,    @GPSDRG=null  --[numeric](6, 3) --NOT NULL,
	,    @GPSDOV=null  --[numeric](6, 3) --NOT NULL,
	,    @GPSDOT=null  --[numeric](6, 3) --NOT NULL,
	,    @GPGLJC=null  --[numeric](15, 0) --NOT NULL,
	,    @GPSCCD=null  --[char](1) --NOT NULL,
	,    @GPLCD2=null  --[numeric](3, 0) --NOT NULL,
	,    @GPCNWO=null  --[char](20) --NOT NULL,
	,    @GPEQLN=null  --[numeric](3, 0) --NOT NULL,
	,    @GPGA01=null  --[numeric](15, 0) --NOT NULL,
	,    @GPGA02=null  --[numeric](15, 0) --NOT NULL,
	,    @GPGA03=null  --[numeric](15, 0) --NOT NULL,
	,    @GPGA04=null  --[numeric](15, 0) --NOT NULL,
	,    @GPGA05=null  --[numeric](15, 0) --NOT NULL,
	,    @GPRPCD=null  --[char](1) --NOT NULL,
	,    @GPSDCD=null  --[numeric](1, 0) --NOT NULL,
	,    @GPHWRG=null  --[numeric](6, 3) --NOT NULL,
	,    @GPHWOV=null  --[numeric](6, 3) --NOT NULL,
	,    @GPHWOT=null  --[numeric](6, 3) --NOT NULL,
	,    @GPBT05=null  --[numeric](5, 0) --NOT NULL,
	,    @GPCRGP=null  --[char](2) --NOT NULL,
	,    @GPCKCD=null  --[char](1) --NOT NULL,
	,    @GPSTD2=null  --[numeric](3, 0) --NOT NULL,
	,    @GPHMUN=null  --[char](5) --NOT NULL,
	,    @GPHMST=null  --[numeric](3, 0) --NOT NULL,
	,    @GPSDST=null  --[numeric](3, 0) --NOT NULL,
	,    @GPEQRH=null  --[numeric](5, 2) --NOT NULL,
	,    @GPEQVH=null  --[numeric](5, 2) --NOT NULL,
	,    @GPEQOH=null  --[numeric](5, 2) --NOT NULL,
	,    @GPQTY=null   --[numeric](9, 0) --NOT NULL,
	,    @GPRTQT=null  --[numeric](6, 3) --NOT NULL,
	,    @GPPWCD=null  --[char](1) --NOT NULL,
	,    @GPEQCL=null  --[char](3) --NOT NULL,
	,    @GPPSLB=null  --[char](1) --NOT NULL,
	,    @GPTYHR=null  --[char](2) --NOT NULL,
	,    @GPEQUP=null  --[char](1) --NOT NULL,
	,    @GPEXST=null  --[char](1) --NOT NULL,
	,    @GPUN01=null  --[char](5) --NOT NULL,
	,    @GPUN02=null  --[char](5) --NOT NULL,
	,    @GPUN03=null  --[char](5) --NOT NULL,
	,    @GPUN04=null  --[char](5) --NOT NULL,
	,    @GPUN05=null  --[char](5) --NOT NULL,
	,    @GPFABU=null  --[numeric](7, 2) --NOT NULL,
	,    @GPFAB2=null  --[numeric](7, 2) --NOT NULL,
	,    @GPFUBU=null  --[numeric](7, 2) --NOT NULL,
	,    @GPSUBU=null  --[numeric](7, 2) --NOT NULL,
	,    @GPWCBU=null  --[numeric](7, 2) --NOT NULL,
	,    @GPBIBU=null  --[numeric](7, 2) --NOT NULL,
	,    @GPPDBU=null  --[numeric](7, 2) --NOT NULL,
	,    @GPSDBU=null  --[numeric](7, 2) --NOT NULL,
	,    @GPAURV=null  --[char](1) --NOT NULL,
	,    @GPFAEN=null  --[numeric](7, 2) --NOT NULL,
	,    @GPFAE2=null  --[numeric](7, 2) --NOT NULL,
	,    @GPFUEN=null  --[numeric](7, 2) --NOT NULL,
	,    @GPSUEN=null  --[numeric](7, 2) --NOT NULL,
	,    @GPWCEN=null  --[numeric](7, 2) --NOT NULL,
	,    @GPBIEN=null  --[numeric](7, 2) --NOT NULL,
	,    @GPPDEN=null  --[numeric](7, 2) --NOT NULL,
	,    @GPSDEN=null  --[numeric](7, 2) --NOT NULL,
	,    @GPDEWT=null  --[numeric](9, 2) --NOT NULL,
	,    @GPFAWT=null  --[numeric](7, 2) --NOT NULL,
	,    @GPSWWT=null  --[numeric](7, 2) --NOT NULL,
	,    @GPSUWT=null  --[numeric](7, 2) --NOT NULL,
	,    @GPSDWT=null  --[numeric](7, 2) --NOT NULL,
	,    @GPLCWT=null  --[numeric](7, 2) --NOT NULL,
	,    @GPWCWT=null  --[numeric](7, 2) --NOT NULL,
	,    @GPSWW2=null  --[numeric](7, 2) --NOT NULL,
	,    @GPLCW2=null  --[numeric](7, 2) --NOT NULL,
	,    @GPTPRP=null  --[numeric](7, 2) --NOT NULL,
	,    @GPTPGN=null  --[numeric](7, 2) --NOT NULL,
	,    @GPTPXC=null  --[numeric](7, 2) --NOT NULL,
	,    @GPTPDM=null  --[numeric](7, 2) --NOT NULL,
	,    @GPMMWG=null  --[numeric](7, 2) --NOT NULL,
	,    @GPTPEE=null  --[char](1) --NOT NULL,
	,    @GPCSCO=null  --[numeric](2, 0) --NOT NULL,
	,    @GPCSDV=null  --[numeric](3, 0) --NOT NULL,
	,    @GPLCBU=null  --[numeric](7, 2) --NOT NULL,
	,    @GPLCEN=null  --[numeric](7, 2) --NOT NULL,
	,    @GPDCID=null  --[numeric](20, 0) --NOT NULL,
	,    @GPEECO=null  --[numeric](2, 0) --NOT NULL,
	,    @GPEEDV=null  --[numeric](3, 0) --NOT NULL,
	,    @GPAYPR=null  --[numeric](2, 0) --NOT NULL,
	,    @GPCPPE=null  --[char](1) --NOT NULL
		
	FETCH cgc_source INTO
		 @GPSTAT  --[char](1) --NOT NULL,
	,    @GPCONO  --[numeric](2, 0) --NOT NULL,
	,    @GPDVNO  --[numeric](3, 0) --NOT NULL,
	,    @GPLEEN  --[numeric](5, 0) --NOT NULL,
	,    @GPGP05  --[numeric](5, 0) --NOT NULL,
	,    @GPSQ05  --[numeric](5, 0) --NOT NULL,
	,    @GPCKTY  --[char](2) --NOT NULL,
	,    @GPERCD  --[char](1) --NOT NULL,
	,    @GPEENO  --[numeric](5, 0) --NOT NULL,
	,    @GPWKNO  --[numeric](1, 0) --NOT NULL,
	,    @GPJBNO  --[char](6) --NOT NULL,
	,    @GPSJNO  --[char](3) --NOT NULL,
	,    @GPJCDI  --[char](15) --NOT NULL,
	,    @GPCSTY  --[char](1) --NOT NULL,
	,    @GPGLAN  --[numeric](15, 0) --NOT NULL,
	,    @GPEQNO  --[char](10) --NOT NULL,
	,    @GPEECL  --[numeric](3, 0) --NOT NULL,
	,    @GPSTCD  --[numeric](3, 0) --NOT NULL,
	,    @GPLCCD  --[numeric](3, 0) --NOT NULL,
	,    @GPUNNO  --[char](5) --NOT NULL,
	,    @GPDYWK  --[numeric](1, 0) --NOT NULL,
	,    @GPEETY  --[char](2) --NOT NULL,
	,    @GPWCCD  --[numeric](4, 0) --NOT NULL,
	,    @GPWCRF  --[numeric](2, 0) --NOT NULL,
	,    @GPRGHR  --[numeric](5, 2) --NOT NULL,
	,    @GPOVHR  --[numeric](5, 2) --NOT NULL,
	,    @GPOTHR  --[numeric](5, 2) --NOT NULL,
	,    @GPOTTY  --[char](2) --NOT NULL,
	,    @GPRGRT  --[numeric](6, 3) --NOT NULL,
	,    @GPOVRT  --[numeric](6, 3) --NOT NULL,
	,    @GPOTRT  --[numeric](6, 3) --NOT NULL,
	,    @GPAJ01  --[char](2) --NOT NULL,
	,    @GPAJ02  --[char](2) --NOT NULL,
	,    @GPAJ03  --[char](2) --NOT NULL,
	,    @GPAJ04  --[char](2) --NOT NULL,
	,    @GPAJ05  --[char](2) --NOT NULL,
	,    @GPAA01  --[numeric](7, 2) --NOT NULL,
	,    @GPAA02  --[numeric](7, 2) --NOT NULL,
	,    @GPAA03  --[numeric](7, 2) --NOT NULL,
	,    @GPAA04  --[numeric](7, 2) --NOT NULL,
	,    @GPAA05  --[numeric](7, 2) --NOT NULL,
	,    @GPDN01  --[numeric](3, 0) --NOT NULL,
	,    @GPDN02  --[numeric](3, 0) --NOT NULL,
	,    @GPDN03  --[numeric](3, 0) --NOT NULL,
	,    @GPDN04  --[numeric](3, 0) --NOT NULL,
	,    @GPDN05  --[numeric](3, 0) --NOT NULL,
	,    @GPUC01  --[numeric](3, 0) --NOT NULL,
	,    @GPUC02  --[numeric](3, 0) --NOT NULL,
	,    @GPUC03  --[numeric](3, 0) --NOT NULL,
	,    @GPUC04  --[numeric](3, 0) --NOT NULL,
	,    @GPUC05  --[numeric](3, 0) --NOT NULL,
	,    @GPSHNO  --[numeric](1, 0) --NOT NULL,
	,    @GPDPNO  --[numeric](3, 0) --NOT NULL,
	,    @GPPYTY  --[char](1) --NOT NULL,
	,    @GPSDDP  --[numeric](3, 0) --NOT NULL,
	,    @GPGLBK  --[numeric](15, 0) --NOT NULL,
	,    @GPDICO  --[numeric](2, 0) --NOT NULL,
	,    @GPDIDV  --[numeric](3, 0) --NOT NULL,
	,    @GPSLRY  --[numeric](9, 2) --NOT NULL,
	,    @GPWONO  --[numeric](6, 0) --NOT NULL,
	,    @GPCPNO  --[char](3) --NOT NULL,
	,    @GPEQCT  --[numeric](1, 0) --NOT NULL,
	,    @GPEQCD  --[char](1) --NOT NULL,
	,    @GPTKNO  --[numeric](5, 0) --NOT NULL,
	,    @GPTMPC  --[char](1) --NOT NULL,
	,    @GPCUST  --[numeric](5, 0) --NOT NULL,
	,    @GPWCST  --[numeric](3, 0) --NOT NULL,
	,    @GPLN02  --[numeric](2, 0) --NOT NULL,
	,    @GPDTWE  --[numeric](8, 0) --NOT NULL,
	,    @GPEXCD  --[char](1) --NOT NULL,
	,    @GPCRNO  --[numeric](2, 0) --NOT NULL,
	,    @GPATCD  --[char](1) --NOT NULL,
	,    @GPECCD  --[char](1) --NOT NULL,
	,    @GPSDRG  --[numeric](6, 3) --NOT NULL,
	,    @GPSDOV  --[numeric](6, 3) --NOT NULL,
	,    @GPSDOT  --[numeric](6, 3) --NOT NULL,
	,    @GPGLJC  --[numeric](15, 0) --NOT NULL,
	,    @GPSCCD  --[char](1) --NOT NULL,
	,    @GPLCD2  --[numeric](3, 0) --NOT NULL,
	,    @GPCNWO  --[char](20) --NOT NULL,
	,    @GPEQLN  --[numeric](3, 0) --NOT NULL,
	,    @GPGA01  --[numeric](15, 0) --NOT NULL,
	,    @GPGA02  --[numeric](15, 0) --NOT NULL,
	,    @GPGA03  --[numeric](15, 0) --NOT NULL,
	,    @GPGA04  --[numeric](15, 0) --NOT NULL,
	,    @GPGA05  --[numeric](15, 0) --NOT NULL,
	,    @GPRPCD  --[char](1) --NOT NULL,
	,    @GPSDCD  --[numeric](1, 0) --NOT NULL,
	,    @GPHWRG  --[numeric](6, 3) --NOT NULL,
	,    @GPHWOV  --[numeric](6, 3) --NOT NULL,
	,    @GPHWOT  --[numeric](6, 3) --NOT NULL,
	,    @GPBT05  --[numeric](5, 0) --NOT NULL,
	,    @GPCRGP  --[char](2) --NOT NULL,
	,    @GPCKCD  --[char](1) --NOT NULL,
	,    @GPSTD2  --[numeric](3, 0) --NOT NULL,
	,    @GPHMUN  --[char](5) --NOT NULL,
	,    @GPHMST  --[numeric](3, 0) --NOT NULL,
	,    @GPSDST  --[numeric](3, 0) --NOT NULL,
	,    @GPEQRH  --[numeric](5, 2) --NOT NULL,
	,    @GPEQVH  --[numeric](5, 2) --NOT NULL,
	,    @GPEQOH  --[numeric](5, 2) --NOT NULL,
	,    @GPQTY   --[numeric](9, 0) --NOT NULL,
	,    @GPRTQT  --[numeric](6, 3) --NOT NULL,
	,    @GPPWCD  --[char](1) --NOT NULL,
	,    @GPEQCL  --[char](3) --NOT NULL,
	,    @GPPSLB  --[char](1) --NOT NULL,
	,    @GPTYHR  --[char](2) --NOT NULL,
	,    @GPEQUP  --[char](1) --NOT NULL,
	,    @GPEXST  --[char](1) --NOT NULL,
	,    @GPUN01  --[char](5) --NOT NULL,
	,    @GPUN02  --[char](5) --NOT NULL,
	,    @GPUN03  --[char](5) --NOT NULL,
	,    @GPUN04  --[char](5) --NOT NULL,
	,    @GPUN05  --[char](5) --NOT NULL,
	,    @GPFABU  --[numeric](7, 2) --NOT NULL,
	,    @GPFAB2  --[numeric](7, 2) --NOT NULL,
	,    @GPFUBU  --[numeric](7, 2) --NOT NULL,
	,    @GPSUBU  --[numeric](7, 2) --NOT NULL,
	,    @GPWCBU  --[numeric](7, 2) --NOT NULL,
	,    @GPBIBU  --[numeric](7, 2) --NOT NULL,
	,    @GPPDBU  --[numeric](7, 2) --NOT NULL,
	,    @GPSDBU  --[numeric](7, 2) --NOT NULL,
	,    @GPAURV  --[char](1) --NOT NULL,
	,    @GPFAEN  --[numeric](7, 2) --NOT NULL,
	,    @GPFAE2  --[numeric](7, 2) --NOT NULL,
	,    @GPFUEN  --[numeric](7, 2) --NOT NULL,
	,    @GPSUEN  --[numeric](7, 2) --NOT NULL,
	,    @GPWCEN  --[numeric](7, 2) --NOT NULL,
	,    @GPBIEN  --[numeric](7, 2) --NOT NULL,
	,    @GPPDEN  --[numeric](7, 2) --NOT NULL,
	,    @GPSDEN  --[numeric](7, 2) --NOT NULL,
	,    @GPDEWT  --[numeric](9, 2) --NOT NULL,
	,    @GPFAWT  --[numeric](7, 2) --NOT NULL,
	,    @GPSWWT  --[numeric](7, 2) --NOT NULL,
	,    @GPSUWT  --[numeric](7, 2) --NOT NULL,
	,    @GPSDWT  --[numeric](7, 2) --NOT NULL,
	,    @GPLCWT  --[numeric](7, 2) --NOT NULL,
	,    @GPWCWT  --[numeric](7, 2) --NOT NULL,
	,    @GPSWW2  --[numeric](7, 2) --NOT NULL,
	,    @GPLCW2  --[numeric](7, 2) --NOT NULL,
	,    @GPTPRP  --[numeric](7, 2) --NOT NULL,
	,    @GPTPGN  --[numeric](7, 2) --NOT NULL,
	,    @GPTPXC  --[numeric](7, 2) --NOT NULL,
	,    @GPTPDM  --[numeric](7, 2) --NOT NULL,
	,    @GPMMWG  --[numeric](7, 2) --NOT NULL,
	,    @GPTPEE  --[char](1) --NOT NULL,
	,    @GPCSCO  --[numeric](2, 0) --NOT NULL,
	,    @GPCSDV  --[numeric](3, 0) --NOT NULL,
	,    @GPLCBU  --[numeric](7, 2) --NOT NULL,
	,    @GPLCEN  --[numeric](7, 2) --NOT NULL,
	,    @GPDCID  --[numeric](20, 0) --NOT NULL,
	,    @GPEECO  --[numeric](2, 0) --NOT NULL,
	,    @GPEEDV  --[numeric](3, 0) --NOT NULL,
	,    @GPAYPR  --[numeric](2, 0) --NOT NULL,
	,    @GPCPPE  --[char](1) --NOT NULL


END

CLOSE cgc_source
DEALLOCATE cgc_source

SELECT * FROM [cgcPayrollBatchForVPImport] WHERE Memo LIKE '%@@' + CAST(@CompanyNumber AS VARCHAR(5)) + '.' + CAST(@BatchNumber AS VARCHAR(10))+ '.' + CAST(@WeekEnding AS VARCHAR(10)) + '@@%'


GO

/****** Object:  NumberedStoredProcedure [dbo].[mspGetCgcPayrollBatch];9    Script Date: 06/09/2014 13:21:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create PROCEDURE [dbo].[mspGetCgcPayrollBatch];9
(
	@WeekEnding	NUMERIC(8,0)
,	@DoRefresh	INT = 0
	
)
AS

--Create Local Tables if they do not exist
BEGIN 
	IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='cgcPRPBCH')
	BEGIN
		PRINT 'Create dbo.cgcPRPBCH'
		SELECT *,@WeekEnding AS DTWE INTO dbo.cgcPRPBCH FROM CMS.S1017192.CMSFIL.PRPBCH 
	END

	IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='cgcPRPBCI')
	BEGIN
		PRINT 'Create dbo.cgcPRPBCI'
		SELECT *,@WeekEnding AS DTWE INTO dbo.cgcPRPBCI FROM CMS.S1017192.CMSFIL.PRPBCI 
	END

	IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='cgcPRPIND')
	BEGIN
		PRINT 'Create dbo.cgcPRPIND'
		SELECT * INTO dbo.cgcPRPIND FROM CMS.S1017192.CMSFIL.PRPIND 
	END
	
	IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='cgcPRPWKD')
	BEGIN
		PRINT 'Create dbo.cgcPRPWKD'
		SELECT * INTO dbo.cgcPRPWKD FROM CMS.S1017192.CMSFIL.PRPWKD
	END
	
	IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND TABLE_SCHEMA='dbo' AND TABLE_NAME='cgcPayrollBatchForVPImport')
	BEGIN
		PRINT 'Create dbo.cgcPayrollBatchForVPImport'
		CREATE TABLE [dbo].[cgcPayrollBatchForVPImport](
			[Co] [tinyint] NULL,
			[Mth] [smalldatetime] NULL,
			[BatchId] [int] NULL,
			[BatchSequence] [int] NULL,
			[BatchTransType] [char](1) NULL,
			[Employee] [int] NULL,
			[PRGroup] [tinyint] NULL,
			[PREndDate] [smalldatetime] NULL,
			[PaySeq] [tinyint] NULL,
			[PostSeq] [smallint] NULL,
			[Type] [char](1) NULL,
			[DayNum] [smallint] NULL,
			[PostDate] [smalldatetime] NULL,
			[JCCo] [tinyint] NULL,
			[Job] [varchar](10) NULL,
			[PhaseGroup] [tinyint] NULL,
			[Phase] [varchar](20) NULL,
			[GLCo] [tinyint] NULL,
			[EMCo] [tinyint] NULL,
			[WO] [varchar](10) NULL,
			[WOItem] [smallint] NULL,
			[Equipment] [varchar](10) NULL,
			[EMGroup] [tinyint] NULL,
			[EquipPhase] [varchar](20) NULL,
			[CostCode] [varchar](10) NULL,
			[CompType] [varchar](10) NULL,
			[Component] [varchar](10) NULL,
			[SMCo] [tinyint] NULL,
			[SMWorkOrder] [int] NULL,
			[SMScope] [int] NULL,
			[SMPayType] [varchar](10) NULL,
			[RevCode] [varchar](10) NULL,
			[SMCostType] [smallint] NULL,
			[SMJCCostType] [tinyint] NULL,
			[EquipCType] [tinyint] NULL,
			[UsageUnits] [numeric](10, 2) NULL,
			[TaxState] [varchar](4) NULL,
			[LocalCode] [varchar](10) NULL,
			[UnempState] [varchar](4) NULL,
			[InsState] [varchar](4) NULL,
			[InsCode] [varchar](10) NULL,
			[PRDept] [varchar](10) NULL,
			[Crew] [varchar](10) NULL,
			[Cert] [char](1) NULL,
			[Craft] [varchar](10) NULL,
			[Class] [varchar](10) NULL,
			[EarnCode] [smallint] NULL,
			[Shift] [tinyint] NULL,
			[Hours] [numeric](10, 2) NULL,
			[Rate] [numeric](16, 5) NULL,
			[Amt] [numeric](12, 2) NULL,
			[Memo] [varchar](500) NULL,
			[udArea] [varchar](5) NULL
		) 
	END
	PRINT ''
END

DECLARE bcur CURSOR FOR
SELECT DISTINCT 
	GPDTWE, GPCONO, GPBT05 
FROM 
	CMS.S1017192.CMSFIL.PRPWKD
WHERE
	GPDTWE=CAST(@WeekEnding AS DECIMAL(8,0))
ORDER BY 1,2 
FOR READ ONLY

DECLARE @cgcWeekEnding		NUMERIC(8,0)
DECLARE	@cgcCompanyNumber	decimal(2,0)
DECLARE @cgcBatchNumber		decimal(5,0)

OPEN bcur
FETCH bcur INTO	
	@cgcWeekEnding
,	@cgcCompanyNumber
,	@cgcBatchNumber

WHILE @@fetch_status=0
BEGIN

	PRINT	'[[ '
	+		CAST(@cgcCompanyNumber AS VARCHAR(5)) + '.'
	+		CAST(@cgcBatchNumber AS VARCHAR(10)) + '.'
	+		CAST(@cgcWeekEnding AS VARCHAR(10)) + ' ]]'

	EXEC mspGetCgcPayrollBatch @CompanyNumber=@cgcCompanyNumber, @BatchNumber=@cgcBatchNumber, @WeekEnding=@cgcWeekEnding, @DoRefresh=@DoRefresh

	FETCH bcur INTO	
		@cgcWeekEnding
	,	@cgcCompanyNumber
	,	@cgcBatchNumber
END

CLOSE bcur
DEALLOCATE bcur


SELECT 
	* 
FROM 
	[cgcPayrollBatchForVPImport]  
WHERE 
	Memo LIKE '%@@' + CAST(@cgcCompanyNumber AS VARCHAR(5)) + '.' + CAST(@cgcBatchNumber AS VARCHAR(10))+ '.' + CAST(@cgcWeekEnding AS VARCHAR(10)) + '@@%'


GO

SELECT DISTINCT 
	'exec [mspGetCgcPayrollBatch]'
+	'  @CompanyNumber=' + CAST(GPCONO AS VARCHAR(10))
+	', @BatchNumber=' + CAST(GPBT05 AS VARCHAR(10))
+	', @WeekEnding=' + CAST(GPDTWE AS varchar(10))
+	', @DoRefresh=0'
FROM dbo.cgcPRPWKD
WHERE
	GPDTWE=20140601

exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140511, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=611, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52533, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=10953, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=532, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140511, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=290, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=611, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=11209, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140511, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=414, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52542, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=9, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52531, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=4102, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=100, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=521, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52534, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=290, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52548, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52532, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=11119, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=1750, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140511, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=415, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52546, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=11209, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52541, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140511, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52550, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=11242, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=380, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=11119, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=11242, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=4101, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=30, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=603, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=415, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140511, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140511, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=9, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=603, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=11223, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=20, @WeekEnding=20140511, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=51, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=414, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=11223, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=11028, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52545, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=413, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=8, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52535, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=10953, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=18, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52544, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=35, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=11028, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=16, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=38, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=602, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=13, @WeekEnding=20140511, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=12, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=25, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52549, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=53, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52547, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=15, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=100, @WeekEnding=20140511, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140511, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=191, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=412, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=20, @BatchNumber=26, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=9, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=19, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=20, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=31, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52543, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=1, @WeekEnding=20140511, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=411, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=5, @WeekEnding=20140511, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=4102, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=610, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=520, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=11, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=699, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=550, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=40, @WeekEnding=20140511, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=4101, @WeekEnding=20140608, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=6, @WeekEnding=20140518, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=7, @WeekEnding=20140601, @DoRefresh=0
exec [mspGetCgcPayrollBatch]  @CompanyNumber=1, @BatchNumber=52, @WeekEnding=20140601, @DoRefresh=0