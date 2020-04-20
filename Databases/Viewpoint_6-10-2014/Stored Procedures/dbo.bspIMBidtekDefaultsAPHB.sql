SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsAPHB]
/***********************************************************
* CREATED BY: Danf
* MODIFIED BY: CMW 04/03/02 - increased InvId from 5 char to 10 (issue # 16366)
*		RBT 09/05/03 - Issue #20131, allow record types <> table name.
*		RBT 08/13/04 - Issue #25361, default pay method from APVM.
*		RBT 08/30/05 - Issue #29441, fix Company default.
*		RBT 01/26/06 - Issue #119780, fix company query.
*		DANF 10/12/07 - Issue #122709, Add SeperatePay default
*		DANF 07/29/08 - Issue #124631, Only use payterms if one exists.
*		CC	 08/08/08 - Issue #129286, If Due Date is set to default, but is blank, and pay terms are not set, 
*							then default the Due Date to the Invoice Date or current date if Invoice is blank
*		TJL 02/11/09 - Issue #124739 - Add CMAcct in APVM as default and use here.
*		CC	02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
*		CC  05/29/09 - Issue #133516 - Correct defaulting of Company
*		DC  04/01/10 - Issue #137867 - Default DueDate same as AP Entry
*		GF  09/12/2010 - issue #141031 changed to use function vfDateOnly
*		AMR 01/24/2011 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
*	
*
* Usage:
*	Used by Imports to create values for needed or missing
*      data based upon Bidtek default rules.
*
* Input params:
*	@ImportId	Import Identifier
*	@ImportTemplate	Import ImportTemplate
*
* Output params:
*	@msg		error message
*
* Return code:
*	0 = success, 1 = failure
************************************************************/
    
(@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), @Form varchar(20), @rectype varchar(30), @msg varchar(120) output)

as

set nocount on

declare @rcode int, @recode int, @desc varchar(120),
	@ynactualdate bYN, @ynemgroup bYN, @yncostcode bYN, @yncosttype bYN, @ynmatlgroup bYN, @yninco bYN,
	@ynglco bYN, @yntaxgroup bYN, @yngltransacct bYN, @yngloffsetacct bYN, @ynvendorgroup bYN,
	@yndiscdate bYN, @ynduedate bYN, @ynpaymethod bYN, @yncmco bYN, @yncmacct bYN,@ynpaycontrol varchar(10),
	@equipid int, @CompanyID int, @BatchTransTypeID int, @vendorgroupid int, @discdateid int, @invdateID int,
	@duedateid int, @paymethodid int, @cmcoid int, @cmacctid int, @prepaidynid int, @v1099ynid int,@paycontrolid int,
	@v1099typeid int, @v1099boxid int, @payoverrideynid int, @prepaidprocynid int, @separatepayynid int,
	@defaultvalue varchar(30), @APVMEFT char(1)

select @ynactualdate ='N', @ynemgroup ='N', @yncostcode ='N', @yncosttype ='N', @ynmatlgroup ='N', @yninco ='N',
	@ynglco ='N', @yntaxgroup ='N', @yngltransacct ='N', @yngloffsetacct ='N', @ynvendorgroup = 'N',
	@yndiscdate = 'N', @ynduedate = 'N', @ynpaymethod = 'N', @yncmco ='N', @yncmacct ='N', @ynpaycontrol = 'N'
    
/* check required input params */
--Issue #20131
--if @rectype <> 'APHB' goto bspexit
    
if @ImportId is null
	begin
	select @desc = 'Missing ImportId.', @rcode = 1
	goto bspexit
	end
if @ImportTemplate is null
	begin
	select @desc = 'Missing ImportTemplate.', @rcode = 1
	goto bspexit
	end
if @Form is null
	begin
	select @desc = 'Missing Form.', @rcode = 1
	goto bspexit
	end

/****************************************************************************************
*																						*
*			RECORDS ALREADY EXIST IN THE IMWE TABLE FROM THE IMPORTED TEXTFILE			*
*																						*
*			All records with the same RecordSeq represent a single import record		*
*																						*
****************************************************************************************/

-- Check ImportTemplate detail for existence of columns to be defaulted Defaults
select IMTD.DefaultValue
from IMTD
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
	and IMTD.RecordType = @rectype
if @@rowcount = 0
	begin
	select @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.'
	goto bspexit
	end

/********* GET COLUMN IDENTIFIERS AND SET IMPORT DEFAULTS THAT APPLY TO ALL IMPORTED RECORDS EQUALLY **********/
	    
--issue #119780 - fixed query to include IMTR

DECLARE		  @OverwriteCo 	 				 bYN
			, @OverwriteBatchTransType 	 	 bYN
			, @OverwritePrePaidProcYN 	 	 bYN
			, @OverwriteInvDate 	 		 bYN
			, @OverwriteVendorGroup 	 	 bYN
			, @OverwriteDiscDate 	 		 bYN
			, @OverwriteDueDate 	 		 bYN
			, @OverwritePayMethod 	 		 bYN
			, @OverwriteCMCo 	 			 bYN
			, @OverwriteCMAcct 	 			 bYN
			, @OverwriteSeparatePayYN 	 	 bYN
			, @OverwritePrePaidYN 	 		 bYN
			, @OverwriteV1099YN 	 	 	 bYN
			, @OverwriteV1099Type 	 	 	 bYN
			, @OverwriteV1099Box 	 	 	 bYN
			, @OverwritePayOverrideYN 	 	 bYN
			, @OverwritePayControl 			 bYN
			,	@IsCoEmpty 				 	bYN
			,	@IsMthEmpty 			 	bYN
			,	@IsBatchIdEmpty 		 	bYN
			,	@IsBatchSeqEmpty 		 	bYN
			,	@IsBatchTransTypeEmpty 	 	bYN
			,	@IsAPTransEmpty 		 	bYN
			,	@IsVendorGroupEmpty 	 	bYN
			,	@IsVendorEmpty 			 	bYN
			,	@IsAPRefEmpty 			 	bYN
			,	@IsDescriptionEmpty 	 	bYN
			,	@IsInvDateEmpty 		 	bYN
			,	@IsDiscDateEmpty 		 	bYN
			,	@IsDueDateEmpty 		 	bYN
			,	@IsInvTotalEmpty 		 	bYN
			,	@IsHoldCodeEmpty 		 	bYN
			,	@IsPayControlEmpty 		 	bYN
			,	@IsPayMethodEmpty 		 	bYN
			,	@IsPrePaidProcYNEmpty 	 	bYN
			,	@IsPrePaidYNEmpty 		 	bYN
			,	@IsCMCoEmpty 			 	bYN
			,	@IsCMAcctEmpty 			 	bYN
			,	@IsPrePaidChkEmpty 		 	bYN
			,	@IsPrePaidDateEmpty 	 	bYN
			,	@IsPrePaidMthEmpty 		 	bYN
			,	@IsSeparatePayYNEmpty 	 	bYN
			,	@IsV1099YNEmpty 		 	bYN
			,	@IsV1099TypeEmpty 		 	bYN
			,	@IsV1099BoxEmpty 		 	bYN
			,	@IsPayOverrideYNEmpty 	 	bYN
			,	@IsPayNameEmpty 		 	bYN
			,	@IsPayAddressEmpty 		 	bYN
			,	@IsPayCityEmpty 		 	bYN
			,	@IsPayStateEmpty 		 	bYN
			,	@IsPayCountryEmpty 		 	bYN
			,	@IsPayZipEmpty 			 	bYN
			,	@IsPayAddInfoEmpty 		 	bYN
			,	@IsNotesEmpty 			 	bYN
			
SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype);
SELECT @OverwritePrePaidProcYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PrePaidProcYN', @rectype);
SELECT @OverwriteInvDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InvDate', @rectype);
SELECT @OverwriteVendorGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendorGroup', @rectype);
SELECT @OverwriteDiscDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DiscDate', @rectype);
SELECT @OverwriteDueDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DueDate', @rectype);
SELECT @OverwritePayMethod = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayMethod', @rectype);
SELECT @OverwriteCMCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CMCo', @rectype);
SELECT @OverwriteCMAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CMAcct', @rectype);
SELECT @OverwriteSeparatePayYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SeparatePayYN', @rectype);
SELECT @OverwritePrePaidYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PrePaidYN', @rectype);
SELECT @OverwriteV1099YN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'V1099YN', @rectype);
SELECT @OverwriteV1099Type = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'V1099Type', @rectype);
SELECT @OverwriteV1099Box = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'V1099Box', @rectype);
SELECT @OverwritePayOverrideYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayOverrideYN', @rectype);
SELECT @OverwritePayControl = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayControl', @rectype);


select @CompanyID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Co', @rectype, 'Y')
if @CompanyID IS NOT NULL AND (ISNULL(@OverwriteCo, 'Y') = 'Y')
	begin
	Update IMWE
	SET IMWE.UploadVal = @Company
	where IMWE.ImportTemplate=@ImportTemplate and
		IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID and IMWE.RecordType = @rectype
  	end

if @CompanyID IS NOT NULL AND (ISNULL(@OverwriteCo, 'Y') = 'N')
	begin
	Update IMWE
	SET IMWE.UploadVal = @Company
	where IMWE.ImportTemplate=@ImportTemplate and
		IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID and IMWE.RecordType = @rectype
		AND IMWE.UploadVal IS NULL
  	end
  
select @BatchTransTypeID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BatchTransType', @rectype, 'Y')
if ISNULL(@BatchTransTypeID, 0)<> 0 AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'Y')
	begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'A'		--Action = Add
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
		and IMWE.RecordType = @rectype
	end

if ISNULL(@BatchTransTypeID, 0)<> 0 AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'N')
	begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'A'		--Action = Add
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
		and IMWE.RecordType = @rectype
		AND IMWE.UploadVal IS NULL
	end
    
select @prepaidprocynid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PrePaidProcYN', @rectype, 'Y')
if isnull(@prepaidprocynid,0) <> 0 AND (ISNULL(@OverwritePrePaidProcYN , 'Y') = 'Y')
	begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'N'		--Pre-Paid = 'N'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @prepaidprocynid
		and IMWE.RecordType = @rectype
	end
	
if isnull(@prepaidprocynid,0) <> 0 AND (ISNULL(@OverwritePrePaidProcYN , 'Y') = 'N')
	begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'N'		--Pre-Paid = 'N'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @prepaidprocynid
		and IMWE.RecordType = @rectype
		AND IMWE.UploadVal IS NULL
	end
    
select @invdateID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'InvDate', @rectype, 'Y')
if isnull(@invdateID,0) <> 0 AND (ISNULL(@OverwriteInvDate , 'Y') = 'Y')
	begin
	UPDATE IMWE
	----#141031
	SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)		--Invoice Date = Todays Date
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @invdateID
		and IMWE.RecordType = @rectype
	end
	
if isnull(@invdateID,0) <> 0 AND (ISNULL(@OverwriteInvDate , 'Y') = 'N')
	begin
	UPDATE IMWE
	----#141031
	SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)		--Invoice Date = Todays Date
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @invdateID
		and IMWE.RecordType = @rectype
		AND IMWE.UploadVal IS NULL
	end

/***** GET COLUMN IDENTIFIERS FOR THOSE COLUMNS THAT MIGHT BE DEFAULTED BUT WHOSE DEFAULTS ARE UNIQUE FOR EACH IMPORTED RECORD *******/    

select @vendorgroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VendorGroup', @rectype, 'Y')

select @discdateid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DiscDate', @rectype, 'Y')

select @duedateid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'DueDate', @rectype, 'Y')

select @paymethodid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayMethod', @rectype, 'Y')

select @cmcoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CMCo', @rectype, 'Y')

select @cmacctid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CMAcct', @rectype, 'Y')

select @separatepayynid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SeparatePayYN', @rectype, 'Y')

select @prepaidynid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PrePaidYN', @rectype, 'Y')

select @v1099ynid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'V1099YN', @rectype, 'Y')

select @v1099typeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'V1099Type', @rectype, 'Y')

select @v1099boxid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'V1099Box', @rectype, 'Y')

select @payoverrideynid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayOverrideYN', @rectype, 'Y')

select @paycontrolid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayControl', @rectype, 'Y')

    
declare  @Co bCompany, @Mth bMonth, @BatchId bBatchID, @BatchSeq int, @BatchTransType char, @APTrans bTrans, @VendorGroup bGroup,
    @Vendor bVendor, @APRef bAPReference, @Description bDesc, @InvDate bDate, @DiscDate bDate, @DueDate bDate,
    @InvTotal bDollar, @HoldCode bHoldCode, @PayControl varchar(10), @PayMethod char, @CMCo bCompany, @CMAcct bCMAcct,
    @PrePaidYN bYN, @PrePaidMth bMonth, @PrePaidDate bDate, @PrePaidChk bCMRef, @PrePaidSeq tinyint, @PrePaidProcYN bYN,
    @V1099YN bYN, @V1099Type varchar(10), @V1099Box tinyint, @PayOverrideYN bYN, @PayName varchar(60), @PayAddress varchar(60),
    @PayCity varchar(30), @PayState bState, @PayZip bZip, @InvId char(10), @UIMth bMonth, @UISeq smallint, @PayAddInfo varchar(60),
    @DocName varchar(128), @MSCo bCompany, @MSInv varchar(10), @AddendaTypeId tinyint, @PRCo bCompany, @Employee bEmployee,
    @DLcode bEDLCode, @TaxPeriodEndDate bDate, @AmountType varchar(10), @Amount bDollar, @AmtType2 varchar(10), @Amount2 bDollar,
    @AmtType3 varchar(10), @Amount3 bDollar, @TaxFormCode varchar(10), @SeparatePayYN bYN, @ChkRev bYN, @PaidYN bYN
--#142350 - renaming @v1099yn,@v1099type,@v1099box,@discdate,@duedate,@separatepayyn
DECLARE @payterms bPayTerms,
    @v1099ynAPVM bYN,
    @v1099ynTypeAPVM varchar(10),
    @v1099BoxAPVM tinyint,
    @apvmcmacct bCMAcct,
    @apvmpaycontrol varchar(10),
    @DiscDateHQPayTermsDateCalc bDate,
    @DueDateHQPayTermsDateCalc bDate,
    @discrate bUnitCost,
    @SeparatePayYNAPVM bYN

/******BEGIN THE DEFAULT GENERATING PROCESS FOR THOSE COLUMNS WHOSE DEFAULT IS UNIQUE FOR EACH IMPORTED RECORD *****/

declare WorkEditCursor cursor local fast_forward for
select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
from IMWE
inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form and
	IMWE.RecordType = @rectype
Order by IMWE.RecordSeq, IMWE.Identifier
    
open WorkEditCursor
-- set open cursor flag
-- #142350 - remove @importid,@seq,@Identifier    
	DECLARE @Recseq int,
			@Tablename varchar(20),
			@Column varchar(30),
			@Uploadval varchar(60),
			@Ident int
        

declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
        @columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int

declare @costtypeout bEMCType

fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
    
select @currrecseq = @Recseq, @complete = 0, @counter = 1

-- while cursor is not empty
while @complete = 0
    begin
    
	if @@fetch_status <> 0 select @Recseq = -1

	if @Recseq = @currrecseq	--Moves on to defaulting process when the first record of a DIFFERENT import RecordSeq is detected
		begin
		/************************** GET UPLOADED VALUES FOR THIS IMPORT RECORD *****************************/
		/* For each imported record:  (Each imported record has multiple records in the IMWE table representing columns of the import record)
	       Cursor will cycle through each column of an imported record and set the imported value into a variable
		   that could be used during the defaulting process later if desired.  It may not be used at all. */
		If @Column='Co' and isnumeric(@Uploadval) =1 select @Co = Convert( int, @Uploadval)
		If @Column='Mth' and isdate(@Uploadval) =1 select @Mth = Convert( smalldatetime, @Uploadval)
	--	If @Column='BatchId' and  isnumeric(@Uploadval) =1 select @BatchSeq = @Uploadval
	--	If @Column='BatchSeq' select @BatchTransType = @Uploadval
		If @Column='BatchTransType' select @BatchTransType = @Uploadval
	--	If @Column='APTrans' select @Equipment = @Uploadval
		If @Column='VendorGroup' and isnumeric(@Uploadval) =1 select @VendorGroup = Convert( int, @Uploadval)
		If @Column='Vendor' and isnumeric(@Uploadval) =1 select @Vendor = Convert( int, @Uploadval)
		If @Column='APRef' select @APRef = @Uploadval
		If @Column='Description' select @Description = @Uploadval
		If @Column='InvDate' and isdate(@Uploadval) =1 select @InvDate =  Convert( smalldatetime, @Uploadval)
		If @Column='DiscDate' and isdate(@Uploadval) =1 select @DiscDate =  Convert( smalldatetime, @Uploadval)
		If @Column='DueDate' and isdate(@Uploadval) =1 select @DueDate = Convert( smalldatetime, @Uploadval)
		If @Column='InvTotal' and isnumeric(@Uploadval) =1 select @InvTotal = @Uploadval
 		If @Column='HoldCode' select @HoldCode = @Uploadval
		If @Column='PayControl' select @PayControl = @Uploadval
		If @Column='PayMethod' select @PayMethod = @Uploadval
		If @Column='CMCo' and isnumeric(@Uploadval) =1 select @CMCo = Convert( int, @Uploadval)
		If @Column='CMAcct' select @CMAcct = @Uploadval
		If @Column='PrePaidYN' select @PrePaidYN = @Uploadval
		If @Column='PrePaidMth' and  isdate(@Uploadval) =1 select @PrePaidMth = convert(smalldatetime,@Uploadval)
		If @Column='PrePaidDate' and  isdate(@Uploadval) =1 select @PrePaidDate = convert(smalldatetime,@Uploadval)
		If @Column='PrePaidChk' select @PrePaidChk = @Uploadval
	--	If @Column='PrePaidSeq' and  isnumeric(@Uploadval) =1 select @PRCo = convert(numeric,@Uploadval)
		If @Column='PrePaidProcYN' select @PrePaidProcYN = @Uploadval
		If @Column='V1099YN' select @V1099YN = @Uploadval
		If @Column='V1099Type' select @V1099Type = @Uploadval
		If @Column='V1099Box' select @V1099Box = @Uploadval
		If @Column='PayOverrideYN' select @PayOverrideYN = @Uploadval
		If @Column='PayName' select @PayName = @Uploadval
		If @Column='PayAddress' select @PayAddress = @Uploadval
		If @Column='PayCity' select @PayCity = @Uploadval
		If @Column='PayState' select @PayState = @Uploadval
 		If @Column='PayZip' select @PayZip = @Uploadval
		If @Column='AddendaTypeId' select @AddendaTypeId = @Uploadval

		
		IF @Column='Co' 
			IF @Uploadval IS NULL
				SET @IsCoEmpty = 'Y'
			ELSE
				SET @IsCoEmpty = 'N'
		IF @Column='Mth' 
			IF @Uploadval IS NULL
				SET @IsMthEmpty = 'Y'
			ELSE
				SET @IsMthEmpty = 'N'
		IF @Column='BatchId' 
			IF @Uploadval IS NULL
				SET @IsBatchIdEmpty = 'Y'
			ELSE
				SET @IsBatchIdEmpty = 'N'
		IF @Column='BatchSeq' 
			IF @Uploadval IS NULL
				SET @IsBatchSeqEmpty = 'Y'
			ELSE
				SET @IsBatchSeqEmpty = 'N'
		IF @Column='BatchTransType' 
			IF @Uploadval IS NULL
				SET @IsBatchTransTypeEmpty = 'Y'
			ELSE
				SET @IsBatchTransTypeEmpty = 'N'
		IF @Column='APTrans' 
			IF @Uploadval IS NULL
				SET @IsAPTransEmpty = 'Y'
			ELSE
				SET @IsAPTransEmpty = 'N'
		IF @Column='VendorGroup' 
			IF @Uploadval IS NULL
				SET @IsVendorGroupEmpty = 'Y'
			ELSE
				SET @IsVendorGroupEmpty = 'N'
		IF @Column='Vendor' 
			IF @Uploadval IS NULL
				SET @IsVendorEmpty = 'Y'
			ELSE
				SET @IsVendorEmpty = 'N'
		IF @Column='APRef' 
			IF @Uploadval IS NULL
				SET @IsAPRefEmpty = 'Y'
			ELSE
				SET @IsAPRefEmpty = 'N'
		IF @Column='Description' 
			IF @Uploadval IS NULL
				SET @IsDescriptionEmpty = 'Y'
			ELSE
				SET @IsDescriptionEmpty = 'N'
		IF @Column='InvDate' 
			IF @Uploadval IS NULL
				SET @IsInvDateEmpty = 'Y'
			ELSE
				SET @IsInvDateEmpty = 'N'
		IF @Column='DiscDate' 
			IF @Uploadval IS NULL
				SET @IsDiscDateEmpty = 'Y'
			ELSE
				SET @IsDiscDateEmpty = 'N'
		IF @Column='DueDate' 
			IF @Uploadval IS NULL
				SET @IsDueDateEmpty = 'Y'
			ELSE
				SET @IsDueDateEmpty = 'N'
		IF @Column='InvTotal' 
			IF @Uploadval IS NULL
				SET @IsInvTotalEmpty = 'Y'
			ELSE
				SET @IsInvTotalEmpty = 'N'
		IF @Column='HoldCode' 
			IF @Uploadval IS NULL
				SET @IsHoldCodeEmpty = 'Y'
			ELSE
				SET @IsHoldCodeEmpty = 'N'
		IF @Column='PayControl' 
			IF @Uploadval IS NULL
				SET @IsPayControlEmpty = 'Y'
			ELSE
				SET @IsPayControlEmpty = 'N'
		IF @Column='PayMethod' 
			IF @Uploadval IS NULL
				SET @IsPayMethodEmpty = 'Y'
			ELSE
				SET @IsPayMethodEmpty = 'N'
		IF @Column='PrePaidProcYN' 
			IF @Uploadval IS NULL
				SET @IsPrePaidProcYNEmpty = 'Y'
			ELSE
				SET @IsPrePaidProcYNEmpty = 'N'
		IF @Column='PrePaidYN' 
			IF @Uploadval IS NULL
				SET @IsPrePaidYNEmpty = 'Y'
			ELSE
				SET @IsPrePaidYNEmpty = 'N'
		IF @Column='CMCo' 
			IF @Uploadval IS NULL
				SET @IsCMCoEmpty = 'Y'
			ELSE
				SET @IsCMCoEmpty = 'N'
		IF @Column='CMAcct' 
			IF @Uploadval IS NULL
				SET @IsCMAcctEmpty = 'Y'
			ELSE
				SET @IsCMAcctEmpty = 'N'
		IF @Column='PrePaidChk' 
			IF @Uploadval IS NULL
				SET @IsPrePaidChkEmpty = 'Y'
			ELSE
				SET @IsPrePaidChkEmpty = 'N'
		IF @Column='PrePaidDate' 
			IF @Uploadval IS NULL
				SET @IsPrePaidDateEmpty = 'Y'
			ELSE
				SET @IsPrePaidDateEmpty = 'N'
		IF @Column='PrePaidMth' 
			IF @Uploadval IS NULL
				SET @IsPrePaidMthEmpty = 'Y'
			ELSE
				SET @IsPrePaidMthEmpty = 'N'
		IF @Column='SeparatePayYN' 
			IF @Uploadval IS NULL
				SET @IsSeparatePayYNEmpty = 'Y'
			ELSE
				SET @IsSeparatePayYNEmpty = 'N'
		IF @Column='V1099YN' 
			IF @Uploadval IS NULL
				SET @IsV1099YNEmpty = 'Y'
			ELSE
				SET @IsV1099YNEmpty = 'N'
		IF @Column='V1099Type' 
			IF @Uploadval IS NULL
				SET @IsV1099TypeEmpty = 'Y'
			ELSE
				SET @IsV1099TypeEmpty = 'N'
		IF @Column='V1099Box' 
			IF @Uploadval IS NULL
				SET @IsV1099BoxEmpty = 'Y'
			ELSE
				SET @IsV1099BoxEmpty = 'N'
		IF @Column='PayOverrideYN' 
			IF @Uploadval IS NULL
				SET @IsPayOverrideYNEmpty = 'Y'
			ELSE
				SET @IsPayOverrideYNEmpty = 'N'
		IF @Column='PayName' 
			IF @Uploadval IS NULL
				SET @IsPayNameEmpty = 'Y'
			ELSE
				SET @IsPayNameEmpty = 'N'
		IF @Column='PayAddress' 
			IF @Uploadval IS NULL
				SET @IsPayAddressEmpty = 'Y'
			ELSE
				SET @IsPayAddressEmpty = 'N'
		IF @Column='PayCity' 
			IF @Uploadval IS NULL
				SET @IsPayCityEmpty = 'Y'
			ELSE
				SET @IsPayCityEmpty = 'N'
		IF @Column='PayState' 
			IF @Uploadval IS NULL
				SET @IsPayStateEmpty = 'Y'
			ELSE
				SET @IsPayStateEmpty = 'N'
		IF @Column='PayCountry' 
			IF @Uploadval IS NULL
				SET @IsPayCountryEmpty = 'Y'
			ELSE
				SET @IsPayCountryEmpty = 'N'
		IF @Column='PayZip' 
			IF @Uploadval IS NULL
				SET @IsPayZipEmpty = 'Y'
			ELSE
				SET @IsPayZipEmpty = 'N'
		IF @Column='PayAddInfo' 
			IF @Uploadval IS NULL
				SET @IsPayAddInfoEmpty = 'Y'
			ELSE
				SET @IsPayAddInfoEmpty = 'N'
		IF @Column='Notes' 
			IF @Uploadval IS NULL
				SET @IsNotesEmpty = 'Y'
			ELSE
				SET @IsNotesEmpty = 'N'
				

		--fetch next record
		if @@fetch_status <> 0 select @complete = 1	--This will be set only after ALL records in IMWE have been processed

		select @oldrecseq = @Recseq

		fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
		end
	else
		begin
		/*************************************** SET DEFAULT VALUES ****************************************/
		/* A DIFFERENT import RecordSeq has been detected.  Before moving on, set the default values for our previous Import Record. */
		if @vendorgroupid <> 0 and isnull(@Co,'')<> '' AND (ISNULL(@OverwriteVendorGroup, 'Y') = 'Y' OR ISNULL(@IsVendorGroupEmpty, 'Y') = 'Y')
			begin
			select @VendorGroup = VendorGroup
			from bHQCO 
			where HQCo = @Co

			UPDATE IMWE
			SET IMWE.UploadVal = @VendorGroup
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @vendorgroupid and IMWE.RecordType = @rectype
			end
    
		-- select needed vendor information
		select @payterms = PayTerms, @v1099ynAPVM = V1099YN, @v1099ynTypeAPVM = V1099Type, @v1099BoxAPVM = V1099Box,
			@SeparatePayYNAPVM = SeparatePayInvYN, @apvmcmacct = CMAcct, @apvmpaycontrol = PayControl		
		from bAPVM with (nolock)
		where VendorGroup=@VendorGroup and Vendor = @Vendor

		select @DiscDateHQPayTermsDateCalc ='', @DueDateHQPayTermsDateCalc ='',@discrate =0
    
		if isnull(@payterms,'') <> ''
			begin
			exec @recode = bspHQPayTermsDateCalc @payterms, @InvDate, @DiscDateHQPayTermsDateCalc output, @DueDateHQPayTermsDateCalc output, @discrate output, @msg output
			end

		if @discdateid <> 0 and isnull(@DiscDateHQPayTermsDateCalc,'')<> '' AND (ISNULL(@OverwriteDiscDate, 'Y') = 'Y' OR ISNULL(@IsDiscDateEmpty, 'Y') = 'Y')
			begin
			UPDATE IMWE
			SET IMWE.UploadVal = @DiscDateHQPayTermsDateCalc
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @discdateid and IMWE.RecordType = @rectype
			end
    
    	if @duedateid <> 0 and isnull(@DueDateHQPayTermsDateCalc,'')<> '' AND (ISNULL(@OverwriteDueDate, 'Y') = 'Y' OR ISNULL(@IsDueDateEmpty, 'Y') = 'Y')
			begin
			UPDATE IMWE
			SET IMWE.UploadVal = @DueDateHQPayTermsDateCalc
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @duedateid and IMWE.RecordType = @rectype
			end
    
		--129286, If Due Date is set to default, but is blank, and pay terms are not set, 
		--then default the Due Date to the Invoice Date or current date if Invoice is blank
		IF @duedateid <> 0 AND ISNULL(@DueDateHQPayTermsDateCalc,'') = '' --AND ISNULL(@payterms,'') = ''  --DC #137867
			BEGIN
			UPDATE IMWE
			----#141031
			SET IMWE.UploadVal = ISNULL(@InvDate, CONVERT(VARCHAR(20), dbo.vfDateOnly(),101))
			WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
			AND IMWE.Identifier = @duedateid AND IMWE.RecordType = @rectype
			END
    
    	if @paymethodid <> 0 AND (ISNULL(@OverwritePayMethod, 'Y') = 'Y' OR ISNULL(@IsPayMethodEmpty, 'Y') = 'Y')
			begin
			--#25361, check EFT option in APVM.  According to MaryAnn, only type 'A' is EFT, otherwise check.
			select @APVMEFT = EFT from bAPVM with (nolock) where VendorGroup = @VendorGroup and Vendor = @Vendor
   
   			if isnull(@APVMEFT,'') = 'A'
   				select @PayMethod = 'E'
   			else
   				select @PayMethod = 'C'
    
			UPDATE IMWE
			SET IMWE.UploadVal = @PayMethod
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
			and IMWE.Identifier = @paymethodid and IMWE.RecordType = @rectype
			end

    	if @cmcoid <> 0 AND (ISNULL(@OverwriteCMCo, 'Y') = 'Y' OR ISNULL(@IsCMCoEmpty, 'Y') = 'Y')
     		begin
			select @CMCo = CMCo
			from bAPCO where APCo = @Co
    
			UPDATE IMWE
			SET IMWE.UploadVal = @CMCo
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @cmcoid and IMWE.RecordType = @rectype
			end
    
    	if @cmacctid <> 0 AND (ISNULL(@OverwriteCMAcct, 'Y') = 'Y' OR ISNULL(@IsCMAcctEmpty, 'Y') = 'Y')
			begin
			select @CMAcct = CMAcct
			from bAPCO where APCo = @Co
    
			UPDATE IMWE
			SET IMWE.UploadVal = isnull(@apvmcmacct, @CMAcct)
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
			and IMWE.Identifier = @cmacctid and IMWE.RecordType = @rectype
			end
    
	   	if @prepaidynid <> 0 AND (ISNULL(@OverwritePrePaidYN, 'Y') = 'Y' OR @PrePaidYN IS NULL) 
			begin
			select @PrePaidYN = 'N'
    
			if isnull(@PrePaidMth,'')<> '' and isnull(@PrePaidDate,'')<>'' and isnull(@PrePaidChk,'')<>''
			select @PrePaidYN = 'Y'
    
			UPDATE IMWE
			SET IMWE.UploadVal = @PrePaidYN
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
			and IMWE.Identifier = @prepaidynid and IMWE.RecordType = @rectype
			end

    	if @separatepayynid <> 0 AND (ISNULL(@OverwriteSeparatePayYN, 'Y') = 'Y' OR ISNULL(@IsSeparatePayYNEmpty, 'Y') = 'Y')
			begin
			if isnull(@SeparatePayYNAPVM,'') = '' select @SeparatePayYNAPVM = 'N'
    
			UPDATE IMWE
			SET IMWE.UploadVal = @SeparatePayYNAPVM
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @separatepayynid and IMWE.RecordType = @rectype
			end

    	if @v1099ynid <> 0 AND (ISNULL(@OverwriteV1099YN, 'Y') = 'Y' OR @V1099YN IS NULL) 
     		begin
			select @V1099YN = @v1099ynAPVM
    
			UPDATE IMWE
			SET IMWE.UploadVal = @V1099YN
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @v1099ynid and IMWE.RecordType = @rectype
			end
    
    	if @v1099typeid <> 0 AND (ISNULL(@OverwriteV1099Type, 'Y') = 'Y' OR @V1099Type IS NULL) 
     		begin
			select @V1099Type = @v1099ynTypeAPVM
    
			UPDATE IMWE
			SET IMWE.UploadVal = @V1099Type
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @v1099typeid and IMWE.RecordType = @rectype
			end
    
    	if @v1099boxid <> 0 AND (ISNULL(@OverwriteV1099Box, 'Y') = 'Y' OR ISNULL(@IsV1099BoxEmpty, 'Y') = 'Y')
     		begin
			select @V1099Box = @v1099BoxAPVM
    
			UPDATE IMWE
			SET IMWE.UploadVal = @V1099Box
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @v1099boxid and IMWE.RecordType = @rectype
			end
    
    	if @payoverrideynid <> 0 AND (ISNULL(@OverwritePayOverrideYN, 'Y') = 'Y' OR ISNULL(@IsPayOverrideYNEmpty, 'Y') = 'Y') 
     		begin
			select @PayOverrideYN = 'N'
			if isnull(@PayName,'')<> '' and isnull(@PayAddress,'')<>'' and isnull(@PayCity,'')<>'' and
				isnull(@PayState,'')<>'' and isnull(@PayZip,'')<>'' select @PayOverrideYN = 'Y'
    
			UPDATE IMWE
			SET IMWE.UploadVal = @PayOverrideYN
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @payoverrideynid and IMWE.RecordType = @rectype
			end

		if @paycontrolid <> 0 AND (ISNULL(@OverwritePayControl, 'Y') = 'Y' OR ISNULL(@IsPayControlEmpty, 'Y') = 'Y')
			begin
			    
			UPDATE IMWE
			SET IMWE.UploadVal = isnull(@apvmpaycontrol, @PayControl)
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
			and IMWE.Identifier = @paycontrolid and IMWE.RecordType = @rectype
			end
    
		select @currrecseq = @Recseq
		select @counter = @counter + 1
    
		end		--End SET DEFAULT VALUE process
    end		-- End @complete Loop, Last IMWE record has been processed

close WorkEditCursor
deallocate WorkEditCursor
    
bspexit:
    select @msg = isnull(@desc,'Header ') + char(13) + char(13) + '[bspBidtekDefaultAPHB]'

    return @rcode




    /*
           Case FIELD_PREPAID_PROCESSED
                btkUBound.FIELD.CntrlSetValue 'N'
           Case FIELD_CHECK#, FIELD_PAID_DATE
                If mBtkFormHeader.btkUbounds(FIELD_PREPAID).FIELD.CntrlValueFromForm = 'Y' Then
                   btkUBound.FIELD.CntrlPrevValueReset
                Else
                   btkUBound.FIELD.CntrlSetValue Null
                End If
    
           Case FIELD_PAID_MTH
                If mBtkFormHeader.btkUbounds(FIELD_PREPAID).FIELD.CntrlValueFromForm = 'Y' Then
                   btkUBound.FIELD.CntrlSetValue mBtkFormHeader.btkUbounds(FIELD_PAID_DATE).FIELD.CntrlValueFromForm
                Else
                   btkUBound.FIELD.CntrlSetValue Null
                End If
    
           Case FIELD_INV_TOTAL
                btkUBound.FIELD.CntrlSetValue 0
           Case FIELD_ADDENDA_TYPE_ID
                    mBtkForm.btkUbounds(FIELD_ADDENDA_TYPE_ID).FIELD.CntrlSetValue _
             mBtkForm.btkUbounds(FIELD_AP_ADDENDA_TYPE_ID).FIELD.CntrlValueFromForm
                    SetAddendaInfo
           Case FIELD_SEPARATEPAY
                If Not btkNull(mBtkForm.btkUbounds(FIELD_VENDOR).FIELD.CntrlValueFromForm) Then
                    btkUBound.FIELD.CntrlSetValue _
                      mBtkForm.btkUbounds(FIELD_SEPARATEPAY_DFLT).FIELD.CntrlValueFromForm
                Else
                    btkUBound.FIELD.CntrlSetValue 'N'
                End If
           Case FIELD_HEADER_PAIDYN
                    btkUBound.FIELD.CntrlSetValue 'N'
                    SetPaidHeaderFields
                    mBtkFormDetail.btkUbounds(FIELD_LINE_PAIDYN).FIELD.CntrlSetValue 'N'
                    SetPaidLineFields */




GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsAPHB] TO [public]
GO
