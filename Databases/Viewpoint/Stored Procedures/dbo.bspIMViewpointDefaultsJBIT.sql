SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsJBIT]
/***********************************************************
* CREATED BY:   RBT 7/30/04 for issue #19580
* MODIFIED BY:  RBT 10/4/05 - issue #29908, fix TaxAmount to be 0 if no TaxCode, extra isnulls on Previous values.
*		DANF 2/21/07 - Issue #30411 Correct Units Billed Viewpoint default.
*		CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
*		CC  05/29/09 - Issue #133516 - Correct defaulting of Company
*		TJL 06/08/09 - Issue #133822 - Add International Tax default logic to TaxBasis, RetgTax 
*
* Usage:
*	Used by Imports to create values for needed or missing
*      data based upon Viewpoint default rules.
*
* Input params:
*	@ImportId	 Import Identifier
*	@ImportTemplate	 Import Template
*
* Output params:
*	@msg		error message
*
* Return code:
*	0 = success, 1 = failure
************************************************************/
    
(@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), 
	@Form varchar(20), @rectype varchar(30), @msg varchar(120) output)
    
as

set nocount on

/**************************************************************************************************************
*																											  *
*								    Not Designed to handle SM and SMRetg									  *
*																											  *
**************************************************************************************************************/

/* General Declares */
declare @rcode int, @desc varchar(120), @status int, @defaultvalue varchar(30), @CursorOpen int,
	@recode int, @complete int, @currrecseq int, @oldrecseq int	
    
/* Column ID variables when based upon a 'bidtek' default setting - 'Use Viewpoint Default set 'Y' on Template. */
declare @JBCoID int, @RetgBilledID int, @TaxBasisID int, @TaxAmountID int, @AmountDueID int, 
	@UnitsBilledID int, @AmtBilledID int, @ItemID int, @BillMonthID int, @PrevAmtID int, @PrevUnitsID int, 
    @WCRetPctID int, @TaxGroupID int, @TaxCodeID int, @ContractID int, @WCID int, @WCUnitsID int, @WCRetgID int,
    @ToDateAmtBilledID int, @ToDateUnitsBilledID int, @nUnitsBilledID int, @RetgTaxID int, @AmtClaimedID int,
    @UnitsClaimedID int, @zRetgBilledID int, @zTaxBasisID int, @zTaxAmountID int, @zAmountDueID int, @zUnitsBilledID int, 
    @zAmtBilledID int, @zPrevAmtID int, @zPrevUnitsID int, @zRetgTaxID int, @zAmtClaimedID int, @zUnitsClaimedID int

/* Working variables */ 
declare @JBCo bCompany, @BillMonth bMonth, @Contract bContract, @RetgBilled bDollar, @TaxBasis bDollar, 
    @TaxAmount bDollar, @AmountDue bDollar, @AmtBilled bDollar, @UnitsBilled bUnits, @BillNumber int, @Item bContractItem,
    @TaxPhase bPhase, @TaxJCCType bJCCType, @SICode varchar(16), @ToDateAmtBilled bDollar, @ToDateUnitsBilled bUnits,
    @PrevAmt bDollar, @PrevUnits bUnits, @WCRetPct bPct, @TaxGroup bGroup, @TaxRate bRate, @TaxCode bTaxCode, 
    @InvDate bDate, @DefContract bContract, @UnitPrice bUnitCost, @UM bUM, @WC bDollar, @WCUnits bUnits, @WCRetg bDollar,
    @RetgTax bDollar, @AmtClaimed bDollar, @UnitsClaimed bUnits,
--
	@arcoinvoicetaxyn bYN, @arcotaxretgyn bYN, @arcosepretgtaxyn bYN, @arcodiscopt char(1), @arcodisctaxyn bYN,
	@jbcousecertifiedyn bYN, @jbincertifiedyn bYN
	
/* Cursor variables */
declare @Recseq int, @Tablename varchar(20), @Column varchar(30), @Uploadval varchar(60), @Ident int
                
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
    
select @CursorOpen = 0
    
-- Check ImportTemplate detail for columns to set Bidtek Defaults
if not exists(select top 1 1 From IMTD with (nolock)
Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
and IMTD.RecordType = @rectype)
goto bspexit

/* Not all fields are overwritable even though the template would indicate they are (Due to the presence of a checkbox).
   Only those fields that can likely be imported and where we can provide a useable default value will get processed here 
   as overwritable. The following list does not contain all fields shown on the Template Detail.  This can be modified as the need arises.
   Example:  UISeq is very unlikely to be provided by the import text file.  Therefore there is nothing to overwrite. */ 
declare @OverwriteRetgBilled 		bYN
	, @OverwriteTaxBasis 	 	 	bYN
	, @OverwriteTaxAmount 	 	 	bYN
	, @OverwriteAmountDue 	 	 	bYN
	, @OverwriteAmtBilled 	 	 	bYN
	, @OverwriteUnitsBilled 	 	bYN
	, @OverwriteItem 	 		 	bYN
	, @OverwritePrevAmt 	 	 	bYN
	, @OverwritePrevUnits 	 	 	bYN
	, @OverwriteWCRetPct 	 	 	bYN
	, @OverwriteTaxGroup 	 	 	bYN
	, @OverwriteTaxCode 	 	 	bYN
	, @OverwriteContract 	 	 	bYN
	, @OverwriteToDateAmtBilled 	bYN
	, @OverwriteToDateUnitsBilled 	bYN
	, @OverwriteCo					bYN
	, @OverwriteRetgTax				bYN
	, @OverwriteAmtClaimed			bYN
	, @OverwriteUnitsClaimed		bYN

/* This is pretty much a mirror of the list above EXCEPT it can exclude those columns that will be defaulted 
   as a record set and do not need to be defaulted per individual import record.  */	
declare	@IsItemEmpty 				 bYN
	,	@IsTaxGroupEmpty 			 bYN
	,	@IsTaxCodeEmpty 			 bYN
	,	@IsTaxBasisEmpty 			 bYN
	,	@IsTaxAmountEmpty 			 bYN
	,	@IsAmountDueEmpty 			 bYN
	,	@IsPrevUnitsEmpty 			 bYN
	,	@IsPrevAmtEmpty 			 bYN
	,	@IsRetgBilledEmpty 			 bYN
	,	@IsUnitsBilledEmpty 		 bYN
	,	@IsAmtBilledEmpty 			 bYN
	,	@IsWCRetPctEmpty 			 bYN
	,	@IsContractEmpty 			 bYN
	,	@IsToDateAmtBilledEmpty 	 bYN
	,	@IsToDateUnitsBilledEmpty 	 bYN
	,	@IsRetgTaxEmpty 			 bYN
	,	@IsAmtClaimedEmpty 			 bYN
	,	@IsUnitsClaimedEmpty 		 bYN

/* Return Overwrite value from Template. */	
SELECT @OverwriteRetgBilled = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RetgBilled', @rectype);
SELECT @OverwriteTaxBasis = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxBasis', @rectype);
SELECT @OverwriteTaxAmount = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxAmount', @rectype);
SELECT @OverwriteAmountDue = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AmountDue', @rectype);
SELECT @OverwriteAmtBilled = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AmtBilled', @rectype);
SELECT @OverwriteUnitsBilled = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UnitsBilled', @rectype);
SELECT @OverwriteItem = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Item', @rectype);
SELECT @OverwritePrevAmt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PrevAmt', @rectype);
SELECT @OverwritePrevUnits = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PrevUnits', @rectype);
SELECT @OverwriteWCRetPct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'WCRetPct', @rectype);
SELECT @OverwriteTaxGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxGroup', @rectype);
SELECT @OverwriteTaxCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxCode', @rectype);
SELECT @OverwriteContract = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Contract', @rectype);
SELECT @OverwriteToDateAmtBilled = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ToDateAmtBilled', @rectype);
SELECT @OverwriteToDateUnitsBilled = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ToDateUnitsBilled', @rectype);
SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JBCo', @rectype);      
SELECT @OverwriteRetgTax = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RetgTax', @rectype);
SELECT @OverwriteAmtClaimed = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AmtClaimed', @rectype);
SELECT @OverwriteUnitsClaimed = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UnitsClaimed', @rectype);

/* There are some columns that can be updated to ALL imported records as a set.  The value is NOT
   unique to the individual imported record. */
select @JBCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JBCo'  AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'
	begin
    UPDATE IMWE
    SET IMWE.UploadVal = @Company
    where IMWE.ImportTemplate=@ImportTemplate and 
	IMWE.ImportId=@ImportId and IMWE.Identifier = @JBCoID
	end

select @JBCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JBCo'  AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'
	begin
    UPDATE IMWE
    SET IMWE.UploadVal = @Company
    where IMWE.ImportTemplate=@ImportTemplate and 
	IMWE.ImportId=@ImportId and IMWE.Identifier = @JBCoID
	end    
    
/***** GET COLUMN IDENTIFIERS - Identifier will be returned ONLY when 'Use Viewpoint Default' is set. *******/ 
select @RetgBilledID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RetgBilled', @rectype, 'Y')
select @TaxBasisID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxBasis', @rectype, 'Y')
select @TaxAmountID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxAmount', @rectype, 'Y')
select @AmountDueID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AmountDue', @rectype, 'Y')
select @UnitsBilledID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UnitsBilled', @rectype, 'Y')
select @AmtBilledID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AmtBilled', @rectype, 'Y')
select @ItemID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Item', @rectype, 'Y')
select @PrevAmtID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PrevAmt', @rectype, 'Y')
select @PrevUnitsID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PrevUnits', @rectype, 'Y')
select @WCRetPctID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'WCRetPct', @rectype, 'Y')
select @TaxGroupID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxGroup', @rectype, 'Y')
select @TaxCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxCode', @rectype, 'Y')
select @ContractID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Contract', @rectype, 'Y')
select @ToDateAmtBilledID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ToDateAmtBilled', @rectype, 'Y')
select @ToDateUnitsBilledID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ToDateUnitsBilled', @rectype, 'Y')
select @RetgTaxID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RetgTax', @rectype, 'Y')
select @AmtClaimedID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AmtClaimed', @rectype, 'Y')
select @UnitsClaimedID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UnitsClaimed', @rectype, 'Y')

/***** GET COLUMN IDENTIFIERS - Identifier will be returned regardless of 'Use Viewpoint Default' setting. *******/
select @BillMonthID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BillMonth', @rectype, 'N')
select @WCID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'WC', @rectype, 'N')
select @WCUnitsID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'WCUnits', @rectype, 'N')
select @WCRetgID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'WCRetg', @rectype, 'N')
select @nUnitsBilledID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UnitsBilled', @rectype, 'N')

--Used to set required columns to ZERO when not otherwise set by a default. (Cleanup: See end of procedure) 
select @zRetgBilledID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RetgBilled', @rectype, 'N')
select @zTaxBasisID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxBasis', @rectype, 'N')
select @zTaxAmountID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TaxAmount', @rectype, 'N')
select @zAmountDueID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AmountDue', @rectype, 'N')
select @zUnitsBilledID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UnitsBilled', @rectype, 'N')
select @zAmtBilledID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AmtBilled', @rectype, 'N')
select @zPrevAmtID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PrevAmt', @rectype, 'N')
select @zPrevUnitsID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PrevUnits', @rectype, 'N')
select @zRetgTaxID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RetgTax', @rectype, 'N')
select @zAmtClaimedID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AmtClaimed', @rectype, 'N')
select @zUnitsClaimedID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UnitsClaimed', @rectype, 'N')
    
/* Begin default process.  Different concept here.  Multiple cursor records make up a single Import record
   determined by a change in the RecSeq value.  New RecSeq signals the beginning of the next Import record. */  
DECLARE WorkEditCursor CURSOR LOCAL FAST_FORWARD FOR
SELECT IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
FROM IMWE with (nolock)
INNER join DDUD with (nolock) on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
WHERE IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
ORDER BY IMWE.RecordSeq, IMWE.Identifier
    
open WorkEditCursor
-- set open cursor flag
select @CursorOpen = 1

select @complete = 0
    
fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval

select @complete = @@fetch_status
select @currrecseq = @Recseq
    
-- while cursor is not empty
while @complete = 0
	begin
	if @Recseq = @currrecseq	--Moves on to defaulting process when the first record of a DIFFERENT import RecordSeq is detected
		begin
		/************************** GET UPLOADED VALUES FOR THIS IMPORT RECORD *****************************/
		/* For each imported record:  (Each imported record has multiple records in the IMWE table representing columns of the import record)
	       Cursor will cycle through each column of an imported record and set the imported value into a variable
		   that could be used during the defaulting process later if desired.  
		   
		   The imported value here is only needed if the value will be used to help determine another
		   default value in some way. */
        If @Column = 'JBCo' and isnumeric(@Uploadval) = 1 select @JBCo = convert(int, @Uploadval)
    	If @Column = 'BillMonth'
    		begin
    		if len(@Uploadval) <= 5
    			begin
    			if charindex('/', @Uploadval) > 0
    				begin
    				select @BillMonth = substring(@Uploadval, 1, CHARINDEX('/', @Uploadval)) + '01' + 
    				substring(@Uploadval, charindex('/', @Uploadval), len(@Uploadval)-charindex('/', @Uploadval)+1)
    				end
    			end
    		else
    			select @BillMonth = convert(smalldatetime, @Uploadval)
    		end
    	If @Column = 'BillNumber' and isnumeric(@Uploadval) = 1 select @BillNumber = convert(int, @Uploadval)
    	If @Column = 'Item' select @Item = @Uploadval
    	If @Column = 'SICode' select @SICode = @Uploadval
    	If @Column = 'Contract' select @Contract = @Uploadval
    	If @Column = 'TaxGroup' select @TaxGroup = @Uploadval
    	If @Column = 'TaxCode' select @TaxCode = @Uploadval
    	If @Column = 'TaxBasis' and isnumeric(@Uploadval) = 1 select @TaxBasis = @Uploadval
    	If @Column = 'TaxAmount' and isnumeric(@Uploadval) = 1 select @TaxAmount = @Uploadval
    	If @Column = 'AmtBilled' and isnumeric(@Uploadval) = 1 select @AmtBilled = @Uploadval
    	If @Column = 'UnitsBilled' and isnumeric(@Uploadval) = 1 select @UnitsBilled = @Uploadval
    	If @Column = 'RetgBilled' and isnumeric(@Uploadval) = 1 select @RetgBilled = @Uploadval
    	If @Column = 'ToDateAmtBilled' and isnumeric(@Uploadval) = 1 select @ToDateAmtBilled = @Uploadval
    	If @Column = 'ToDateUnitsBilled' and isnumeric(@Uploadval) = 1 select @ToDateUnitsBilled = @Uploadval
    	If @Column = 'PrevAmt' and isnumeric(@Uploadval) = 1 select @PrevAmt = @Uploadval
    	If @Column = 'PrevUnits' select @PrevUnits = @Uploadval
    	If @Column = 'WCRetPct' and isnumeric(@Uploadval) = 1 select @WCRetPct = @Uploadval
		If @Column = 'RetgTax' and isnumeric(@Uploadval) = 1 select @RetgTax = @Uploadval

		/* Set IsNull variable for later */
		IF @Column='Item' 
			IF @Uploadval IS NULL
				SET @IsItemEmpty = 'Y'
			ELSE
				SET @IsItemEmpty = 'N'
		IF @Column='TaxGroup' 
			IF @Uploadval IS NULL
				SET @IsTaxGroupEmpty = 'Y'
			ELSE
				SET @IsTaxGroupEmpty = 'N'
		IF @Column='TaxCode' 
			IF @Uploadval IS NULL
				SET @IsTaxCodeEmpty = 'Y'
			ELSE
				SET @IsTaxCodeEmpty = 'N'
		IF @Column='TaxBasis' 
			IF @Uploadval IS NULL
				SET @IsTaxBasisEmpty = 'Y'
			ELSE
				SET @IsTaxBasisEmpty = 'N'
		IF @Column='TaxAmount' 
			IF @Uploadval IS NULL
				SET @IsTaxAmountEmpty = 'Y'
			ELSE
				SET @IsTaxAmountEmpty = 'N'
		IF @Column='AmountDue' 
			IF @Uploadval IS NULL
				SET @IsAmountDueEmpty = 'Y'
			ELSE
				SET @IsAmountDueEmpty = 'N'
		IF @Column='PrevUnits' 
			IF @Uploadval IS NULL
				SET @IsPrevUnitsEmpty = 'Y'
			ELSE
				SET @IsPrevUnitsEmpty = 'N'
		IF @Column='PrevAmt' 
			IF @Uploadval IS NULL
				SET @IsPrevAmtEmpty = 'Y'
			ELSE
				SET @IsPrevAmtEmpty = 'N'
		IF @Column='RetgBilled' 
			IF @Uploadval IS NULL
				SET @IsRetgBilledEmpty = 'Y'
			ELSE
				SET @IsRetgBilledEmpty = 'N'
		IF @Column='UnitsBilled' 
			IF @Uploadval IS NULL
				SET @IsUnitsBilledEmpty = 'Y'
			ELSE
				SET @IsUnitsBilledEmpty = 'N'
		IF @Column='AmtBilled' 
			IF @Uploadval IS NULL
				SET @IsAmtBilledEmpty = 'Y'
			ELSE
				SET @IsAmtBilledEmpty = 'N'
		IF @Column='WCRetPct' 
			IF @Uploadval IS NULL
				SET @IsWCRetPctEmpty = 'Y'
			ELSE
				SET @IsWCRetPctEmpty = 'N'
		IF @Column='Contract' 
			IF @Uploadval IS NULL
				SET @IsContractEmpty = 'Y'
			ELSE
				SET @IsContractEmpty = 'N'
		IF @Column='ToDateAmtBilled' 
			IF @Uploadval IS NULL
				SET @IsToDateAmtBilledEmpty = 'Y'
			ELSE
				SET @IsToDateAmtBilledEmpty = 'N'
		IF @Column='ToDateUnitsBilled' 
			IF @Uploadval IS NULL
				SET @IsToDateUnitsBilledEmpty = 'Y'
			ELSE
				SET @IsToDateUnitsBilledEmpty = 'N'
		IF @Column='RetgTax' 
			IF @Uploadval IS NULL
				SET @IsRetgTaxEmpty = 'Y'
			ELSE
				SET @IsRetgTaxEmpty = 'N'
		IF @Column='AmtClaimed' 
			IF @Uploadval IS NULL
				SET @IsAmtClaimedEmpty = 'Y'
			ELSE
				SET @IsAmtClaimedEmpty = 'N'
		IF @Column='UnitsClaimed' 
			IF @Uploadval IS NULL
				SET @IsUnitsClaimedEmpty = 'Y'
			ELSE
				SET @IsUnitsClaimedEmpty = 'N'
												
        select @oldrecseq = @Recseq
    
        --fetch next record
        fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
    
    	-- if this is the last record, set the sequence to -1 to process last record.
    	if @@fetch_status <> 0  select @Recseq = -1
		end
	else
		begin
		/* A DIFFERENT import RecordSeq has been detected.  Before moving on, set the default values for our previous Import Record. */
		
		/*************************************** SET DEFAULT VALUES ****************************************/
		/* At this moment, all columns of a single imported record have been processed above.  The defaults for 
		   this single imported record will be set below before the cursor moves on to the columns of the next
		   imported record.  
		   
		   For the most part (There are some exceptions), if a column identifier is present ('Use Viewpoint Default = Y)
		   and the 'Overwrite Import Value' = Y OR if the actual imported value is empty, we will then set a bidtek 
		   default. */

    	--Formatted BillMonth
    	UPDATE IMWE
    	SET IMWE.UploadVal = @BillMonth
    	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    	and IMWE.Identifier=@BillMonthID and IMWE.RecordType=@rectype
    
    	/* Get Contract and Invoice Date from header */
    	select @DefContract = null, @InvDate = null 
    	select @DefContract = Contract, @InvDate = InvDate, @jbincertifiedyn = Certified 
    	from JBIN with (nolock) where JBCo = @JBCo and BillMonth = @BillMonth
    		and BillNumber = @BillNumber
    
		--Contract
    	if @ContractID <> 0  AND (ISNULL(@OverwriteContract, 'Y') = 'Y' OR ISNULL(@IsContractEmpty, 'Y') = 'Y')
    		begin
    		select @Contract = @DefContract
    
    		UPDATE IMWE
    		SET IMWE.UploadVal = @DefContract
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@ContractID and IMWE.RecordType=@rectype
    		end
    
		--Item
    	if @ItemID <> 0 and @SICode is not null and @Contract is not null  AND (ISNULL(@OverwriteItem, 'Y') = 'Y' OR ISNULL(@IsItemEmpty, 'Y') = 'Y')
    		begin
    		-- Cross-reference SICode to JCCI to get Item code.
    		select @Item = a.Item 
    		from JCCI a with (nolock) 
    		join JBIT b with (nolock) on a.JCCo = b.JBCo and a.Contract = b.Contract and a.Item = b.Item
    		where b.Contract = @Contract and b.JBCo = @JBCo and a.SICode = @SICode
    			and b.BillMonth = @BillMonth and b.BillNumber = @BillNumber
    
    		UPDATE IMWE
    		SET IMWE.UploadVal = @Item
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@ItemID and IMWE.RecordType=@rectype
    		end
    
    	/* Get UnitPrice and UM. */
    	select @UnitPrice = null, @UM = null
    	select @UnitPrice = a.UnitPrice, @UM = a.UM 
    	from JCCI a with (nolock) 
    	join JBIT b with (nolock) on a.JCCo = b.JBCo and a.Contract = b.Contract and a.Item = b.Item
		where b.Contract = @Contract and b.JBCo = @JBCo and a.Item = @Item
    		and b.BillMonth = @BillMonth and b.BillNumber = @BillNumber
    
    	/* get values from existing JBIT record... */
    	--PrevAmt
    	if @PrevAmtID <> 0 AND (ISNULL(@OverwritePrevAmt, 'Y') = 'Y' OR ISNULL(@IsPrevAmtEmpty, 'Y') = 'Y')
    		begin
    		select @PrevAmt = isnull(isnull(PrevAmt, @PrevAmt),0)	--issue #29908, double isnull.
    		from JBIT with (nolock)
    		where JBCo = @JBCo and BillMonth = @BillMonth and BillNumber = @BillNumber and Item = @Item
    		
    		UPDATE IMWE
    		SET IMWE.UploadVal = @PrevAmt
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@PrevAmtID and IMWE.RecordType=@rectype
    		end
    		
    	--PrevUnits
    	if @PrevUnitsID <> 0 AND (ISNULL(@OverwritePrevUnits, 'Y') = 'Y' OR ISNULL(@IsPrevUnitsEmpty, 'Y') = 'Y')
    		begin
    		select @PrevUnits = isnull(isnull(PrevUnits, @PrevUnits),0)	--issue #29908, double isnull.
    		from JBIT with (nolock)
    		where JBCo = @JBCo and BillMonth = @BillMonth and BillNumber = @BillNumber and Item = @Item
    		
    		UPDATE IMWE
    		SET IMWE.UploadVal = @PrevUnits
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@PrevUnitsID and IMWE.RecordType=@rectype
    		end
    		
    	--WCRetPct
    	if @WCRetPctID <> 0  AND (ISNULL(@OverwriteWCRetPct, 'Y') = 'Y' OR ISNULL(@IsWCRetPctEmpty, 'Y') = 'Y')
    		begin
    		select @WCRetPct = isnull(isnull(WCRetPct, @WCRetPct),0)	--issue #29908, double isnull.
    		from JBIT with (nolock)
    		where JBCo = @JBCo and BillMonth = @BillMonth and BillNumber = @BillNumber and Item = @Item
    		
    		UPDATE IMWE
    		SET IMWE.UploadVal = @WCRetPct
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@WCRetPctID and IMWE.RecordType=@rectype
    		end

    	-- Begin calculated values....
		--AmtBilled
    	if @AmtBilledID <> 0  AND (ISNULL(@OverwriteAmtBilled, 'Y') = 'Y' OR ISNULL(@IsAmtBilledEmpty, 'Y') = 'Y')
    		begin
    		if @ToDateAmtBilled is not null
    			begin
    			select @AmtBilled = @ToDateAmtBilled - isnull(@PrevAmt, 0)
    			end
    		else
    			begin
    			if @AmtBilled is null
    				begin
    				if @UnitsBilled is not null
    					begin
    						if isnull(@UnitPrice, 0) > 0 select @AmtBilled = @UnitsBilled * @UnitPrice
    					else
    						begin
    						if @UM <> 'LS'
    							begin
    							select @msg = 'ERR: UnitPrice is null or zero - cannot calculate AmtBilled.'
    							insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    							values(@ImportId,@ImportTemplate,@Form,@currrecseq,0,@msg,@AmtBilledID)			
    					
    							select @rcode = 1
    							select @desc = @msg
    							end
    						end
    					end
    				else
    					begin
    					if @ToDateUnitsBilled is not null
    							if isnull(@UnitPrice, 0) > 0 select @AmtBilled = (@ToDateUnitsBilled - isnull(@PrevUnits,0)) * @UnitPrice
    						else
    							begin
    							if @UM <> 'LS'
    								begin
    								select @msg = 'ERR: UnitPrice is null or zero - cannot calculate AmtBilled.'
    								insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    								values(@ImportId,@ImportTemplate,@Form,@currrecseq,0,@msg,@AmtBilledID)			
    						
    								select @rcode = 1
    								select @desc = @msg
    								end
    							end
    					end
    				end
				end
				
    		UPDATE IMWE
    		SET IMWE.UploadVal = @AmtBilled
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@AmtBilledID and IMWE.RecordType=@rectype
    		end
    
		--UnitsBilled
    	if @UnitsBilledID <> 0 AND (ISNULL(@OverwriteUnitsBilled, 'Y') = 'Y' OR ISNULL(@IsUnitsBilledEmpty, 'Y') = 'Y')
    		begin
    		if @AmtBilled is not null
    			begin
    			if isnull(@UnitPrice, 0) > 0 select @UnitsBilled = @AmtBilled / @UnitPrice
    			else
    				begin
    				if @UM <> 'LS'
    					begin
    					select @msg = 'ERR: UnitPrice is null or zero - cannot calculate UnitsBilled.'
    					insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    					values(@ImportId,@ImportTemplate,@Form,@currrecseq,0,@msg,@nUnitsBilledID)			
    			
    					select @rcode = 1
    					select @desc = @msg
    					end
    				else
    					select @UnitsBilled = 0
    				end
    			end
    		else
    			begin
    			if @ToDateAmtBilled is not null
    				begin
    				if isnull(@UnitPrice, 0) > 0 select @UnitsBilled = (@ToDateAmtBilled - isnull(@PrevAmt,0)) / @UnitPrice
    				else
    					begin
    					if @UM <> 'LS'
    						begin
    						select @msg = 'ERR: UnitPrice is null or zero - cannot calculate UnitsBilled.'
    						insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    						values(@ImportId,@ImportTemplate,@Form,@currrecseq,0,@msg,@nUnitsBilledID)			
    				
    						select @rcode = 1
    						select @desc = @msg
    						end
    					else
    						select @UnitsBilled = 0
    					end
    				end
    			else
    				begin
    				if @ToDateUnitsBilled is not null select @UnitsBilled = @ToDateUnitsBilled - isnull(@PrevUnits,0)
    				end
    			end
    
    		UPDATE IMWE
    		SET IMWE.UploadVal = @UnitsBilled
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier=@nUnitsBilledID and IMWE.RecordType=@rectype
    		end
    
    	--WC:	SET WC and WCUnits REGARDLESS OF THEIR DEFAULT SETTING - MUST MATCH AmtBilled and UnitsBilled
    	UPDATE IMWE
    	SET IMWE.UploadVal = isnull(@AmtBilled,0)
    	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier=@WCID and IMWE.RecordType=@rectype
    
		--WCUnits
    	UPDATE IMWE
    	SET IMWE.UploadVal = isnull(@UnitsBilled,0)
    	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier=@WCUnitsID and IMWE.RecordType=@rectype
    
    	--RetgBilled
    	if @RetgBilledID <> 0 and @AmtBilled is not null and @WCRetPct is not null AND (ISNULL(@OverwriteRetgBilled, 'Y') = 'Y' OR ISNULL(@IsRetgBilledEmpty, 'Y') = 'Y')
    		begin
    		select @RetgBilled = @WCRetPct * @AmtBilled
    
    		UPDATE IMWE
    		SET IMWE.UploadVal = @RetgBilled
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@RetgBilledID and IMWE.RecordType=@rectype
    		end
    
    	--WCRetg	SET WCRetg to RetgBilled no matter what.
    	UPDATE IMWE
    	SET IMWE.UploadVal = isnull(@RetgBilled,0)
    	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier=@WCRetgID and IMWE.RecordType=@rectype

 		/* Get some ARCompany Tax Setup information. */
		select @arcoinvoicetaxyn = a.InvoiceTax, @arcotaxretgyn = a.TaxRetg, @arcosepretgtaxyn = a.SeparateRetgTax,
			@arcodiscopt = a.DiscOpt, @arcodisctaxyn = a.DiscTax, @jbcousecertifiedyn = b.UseCertified
		from ARCO a with (nolock)
		join JCCO c with (nolock) on c.ARCo = a.ARCo
		join JBCO b with (nolock) on b.JBCo = c.JCCo
		where c.JCCo = @JBCo

		if @arcoinvoicetaxyn = 'Y'
			begin	
			--TaxGroup	
     		if @TaxGroupID <> 0 AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'Y' OR ISNULL(@IsTaxGroupEmpty, 'Y') = 'Y')
    			begin
    			select @TaxGroup = isnull(TaxGroup, @TaxGroup)
    			from JBIT with (nolock)
    			where JBCo = @JBCo and BillMonth = @BillMonth and BillNumber = @BillNumber and Item = @Item
    		
    			UPDATE IMWE
    			SET IMWE.UploadVal = @TaxGroup
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier=@TaxGroupID and IMWE.RecordType=@rectype
    			end
    		
    		--TaxCode
    		if @TaxCodeID <> 0 AND (ISNULL(@OverwriteTaxCode, 'Y') = 'Y' OR ISNULL(@IsTaxCodeEmpty, 'Y') = 'Y')
    			begin
    			select @TaxCode = isnull(TaxCode, @TaxCode)
    			from JBIT with (nolock)
    			where JBCo = @JBCo and BillMonth = @BillMonth and BillNumber = @BillNumber and Item = @Item
    		
    			UPDATE IMWE
    			SET IMWE.UploadVal = @TaxCode
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier=@TaxCodeID and IMWE.RecordType=@rectype
    			end
 
			--TaxBasis   	   
    		if @TaxBasisID <> 0 AND (ISNULL(@OverwriteTaxBasis, 'Y') = 'Y' OR ISNULL(@IsTaxBasisEmpty, 'Y') = 'Y')
    			begin	
    			--@AmtBilled = WC (SM not part of Import)
    			--@RetgBilled = WCRetg  (SMRetg not part of Import)
    			select @TaxBasis = case when @arcotaxretgyn = 'Y' then 
    				case when @arcosepretgtaxyn = 'N' then isnull(@AmtBilled,0) else isnull(@AmtBilled,0) - isnull(@RetgBilled,0) end
    					else isnull(@AmtBilled,0) - isnull(@RetgBilled,0) end
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @TaxBasis
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier=@TaxBasisID and IMWE.RecordType=@rectype
    			end
    
			--TaxAmount
    		if @TaxAmountID <> 0 AND (ISNULL(@OverwriteTaxAmount, 'Y') = 'Y' OR ISNULL(@IsTaxAmountEmpty, 'Y') = 'Y')
    			begin
  				select @recode = 0
  				if @TaxGroup is not null and @TaxCode is not null and @InvDate is not null	--issue #29908, moved out of first IF.
  					begin
  	  				exec @recode = bspHQTaxRateGet @TaxGroup, @TaxCode, @InvDate, @TaxRate output, @TaxPhase output, @TaxJCCType output, @msg output
  	  				
      				if @recode <> 0 
    					begin
    					insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
    					values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@TaxAmountID)			
    	
    					select @rcode = 1
    					select @desc = @msg
    					end	  				
  	  				end
    			else
    				begin
  					select @TaxRate = 0		--issue #29908
  					end

    			select @TaxAmount = isnull(@TaxRate,0) * isnull(@TaxBasis,0)
    	
    			UPDATE IMWE
    			SET IMWE.UploadVal = @TaxAmount
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier=@TaxAmountID and IMWE.RecordType=@rectype
    			end
			
			--RetgTax
    		if @RetgTaxID <> 0 AND (ISNULL(@OverwriteRetgTax, 'Y') = 'Y' OR ISNULL(@IsRetgTaxEmpty, 'Y') = 'Y')
     			begin
     			--@RetgBilled = WCRetg  (SMRetg not part of Import)
    			select @RetgTax = case when @arcotaxretgyn = 'Y' then 
    				case when @arcosepretgtaxyn = 'N' then 0 else isnull(@TaxRate,0) * isnull(@RetgBilled,0) end
    					else 0 end
	    
				UPDATE IMWE
				SET IMWE.UploadVal = @RetgTax
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @RetgTaxID and IMWE.RecordType = @rectype
					
				/* Once RetgTax gets calculated, we must reset the RetgBilled default because JBIT.RetgBilled always includes
				   RetgTax.  (JBIT.RetgBilled = RetgBilled + RetgTax) */
				UPDATE IMWE
				SET IMWE.UploadVal = isnull(@RetgBilled,0) + isnull(@RetgTax,0)
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @RetgBilledID and IMWE.RecordType = @rectype
				end	
			end
		else
			begin
			select @TaxAmount = 0
			end
		
		--AmountDue:	?? Should AmountDue always get updated to factor in/out various tax calculations?
    	if @AmountDueID <> 0  AND (ISNULL(@OverwriteAmountDue, 'Y') = 'Y' OR ISNULL(@IsAmountDueEmpty, 'Y') = 'Y')
    		begin
    		select @AmountDue = isnull(@AmtBilled,0) - isnull(@RetgBilled,0) + isnull(@TaxAmount,0)
    
    		UPDATE IMWE
    		SET IMWE.UploadVal = @AmountDue
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@AmountDueID and IMWE.RecordType=@rectype
    		end
    
		/* As long as JBCO is set to 'UseCertified', then if template is set to 'Use Viewpoint Default' and
		   if the import value is empty or is set to be overwritten then we will set AmtClaimed same as AmtBilled. */
		if @jbcousecertifiedyn = 'Y' --and @jbincertifiedyn = 'N'
			begin
			--AmtClaimed
			if  @AmtClaimedID <> 0 AND (ISNULL(@OverwriteAmtClaimed, 'Y') = 'Y' OR ISNULL(@IsAmtClaimedEmpty, 'Y') = 'Y')
    			begin
    			UPDATE IMWE
    			SET IMWE.UploadVal = isnull(@AmtBilled,0)
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier=@AmtClaimedID and IMWE.RecordType=@rectype
        		end
        	
			--UnitsClaimed
			if  @UnitsClaimedID <> 0 AND (ISNULL(@OverwriteUnitsClaimed, 'Y') = 'Y' OR ISNULL(@IsUnitsClaimedEmpty, 'Y') = 'Y')
    			begin
    			UPDATE IMWE
    			SET IMWE.UploadVal = isnull(@UnitsBilled,0)
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier=@UnitsClaimedID and IMWE.RecordType=@rectype
        		end
			end
		
    	--Defaults for ToDateUnitsBilled and ToDateAmtBilled just so users don't wonder why they're blank...
    	--(These are not stored in JBIT)
    	if  @ToDateAmtBilledID <> 0 AND (ISNULL(@OverwriteToDateAmtBilled, 'Y') = 'Y' OR ISNULL(@IsToDateAmtBilledEmpty, 'Y') = 'Y')
    		begin
    		select @ToDateAmtBilled = isnull(@AmtBilled,0) + isnull(@PrevAmt,0)
    
    		UPDATE IMWE
    		SET IMWE.UploadVal = @ToDateAmtBilled
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@ToDateAmtBilledID and IMWE.RecordType=@rectype
        	end
    
    	if @ToDateUnitsBilledID <> 0 AND (ISNULL(@OverwriteToDateUnitsBilled, 'Y') = 'Y' OR ISNULL(@IsToDateUnitsBilledEmpty, 'Y') = 'Y')
    		begin
    		select @ToDateUnitsBilled = isnull(@UnitsBilled,0) + isnull(@PrevUnits,0)
    
    		UPDATE IMWE
    		SET IMWE.UploadVal = @ToDateUnitsBilled
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier=@ToDateUnitsBilledID and IMWE.RecordType=@rectype
        	end

    	/* Overrides */
    
    	--Do not allow units for lump sum.
    	if @UM = 'LS'
    		begin
    		select @UnitsBilled = 0
    		select @WCUnits = 0
    
    		UPDATE IMWE
    		SET IMWE.UploadVal = @UnitsBilled
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier=@nUnitsBilledID and IMWE.RecordType=@rectype
    
    		UPDATE IMWE
    		SET IMWE.UploadVal = @WCUnits
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier=@WCUnitsID and IMWE.RecordType=@rectype
    		end
   
   		select @ToDateAmtBilled = null, @ToDateUnitsBilled = null, @AmtBilled = null, @UnitsBilled = null, @PrevUnits = null,
   			@PrevAmt = null, @UnitPrice = null, @RetgBilled = null, @WCRetPct = null, @TaxBasis = null, @TaxAmount = null
 
		-- set Current Req Seq to next @Recseq unless we are processing last record.
		if @Recseq = -1
			select @complete = 1	-- exit the loop
		else
			select @currrecseq = @Recseq
		end
    end

/* Set required (dollar) inputs to 0 where not already set with some other value */          
UPDATE IMWE
SET IMWE.UploadVal = 0.00
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'')='' and
	(IMWE.Identifier = @zRetgBilledID	or IMWE.Identifier = @zTaxBasisID or IMWE.Identifier = @zTaxAmountID 
	or IMWE.Identifier = @zAmountDueID	or IMWE.Identifier = @zAmtBilledID or IMWE.Identifier = @zPrevAmtID
	or IMWE.Identifier = @zRetgTaxID	or IMWE.Identifier = @zAmtClaimedID or IMWE.Identifier = @zUnitsClaimedID)

/* Set required (units) inputs to 0 where not already set with some other value */ 
UPDATE IMWE
SET IMWE.UploadVal = 0.000
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'')='' and
	(IMWE.Identifier = @zUnitsBilledID or IMWE.Identifier = @zPrevUnitsID)
		   
bspexit:
    
if @CursorOpen = 1
	begin
	close WorkEditCursor
	deallocate WorkEditCursor	
	end

select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsJBIT]'

return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsJBIT] TO [public]
GO
