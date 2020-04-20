SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsARBL]
/***********************************************************
* CREATED BY: Danf
* MODIFIED BY: RBT 09/09/03 - Allow rectypes <> tablenames.
*		RBT 01/05/04 - #23432 Fix line number defaults, Line Type 'C'.
*		TJL 01/27/04 - #20394, Add output, return GLFCWriteOffAcct from bspARRecTypeValWithInfo
*		RBT 06/08/04 - #24751, check for "Record Key" as well as "RecKey".
*		RBT 07/06/04 - #25022, check DDUD for RecKey column, not IMTD.
*		RBT 08/29/05 - #29652, fix default TaxBasis/TaxAmount for "O" LineTypes, fix Company to not always default.
*		RBT 08/30/05 - #29694, fix ARLine default string -> int conversion, line wasn't going over 10.
*		RBT 01/12/06 - #119859, fix bug in issue #29652 - Co getting set to Amount if not defaulting Amount but defaulting TaxAmount for "O" lines.
*		RBT 01/26/06 - #120057, fix Company default query so it only returns the 1 correct row.
*		DANF 04/05/08 - #120001 Set tax basis and tax amount to zero if no tax code.
*		CC 05/23/08	- #128428 Removed clear for Contract UM
*		CC 09/05/08 - #129654 Default amount for "C" line type to imported amount if not using units and price, to be consistent with AR form.
*		CC 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
*		TJL 03/16/09 - Issue #132370 - Co default incorrectly being set to 0.00, added comments through-out
*		CC  05/29/09 - Issue #133516 - Correct defaulting of Company
*		TJL 06/03/09 - Issue #133818 - Add International Tax default logic to TaxBasis, RetgTax and TotalAmount
*		EN 1/11/2010 #137283  add condition to amount overwrite
*		AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
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

/**************************************************************************************************************
*																											  *
*                      Not Designed for  Adjustment, Credit or WriteOffs at this time						  *
*																											  *
**************************************************************************************************************/

/* General Declares */
declare @rcode int, @recode int, @desc varchar(120), @errmsg varchar(120), @HeaderReqSeq int,  
    @FormDetail varchar(20), @FormHeader varchar(20), @RecKey varchar(60), @HeaderRecordType varchar(10),
	@currrecseq int, @complete int, @counter int,  @oldrecseq int
 
/* Column ID variables when based upon a 'bidtek' default setting - 'Use Viewpoint Default set 'Y' on Template. */
declare @reckeyid int, @invreckeyid int, @CompanyID int, @TransTypeID int, @RecTypeid int, @LineTypeid int, @GLCoid int, @GLAcctid int, @TaxGroupid int,
	@TaxCodeid int, @Amountid int, @TaxBasisid int, @TaxAmountid int, @RetgPctid int, @Retainageid int, @DiscOfferedid int, @JCCoid int,
	@Contractid int, @UMid int, @MatlGroupid int, @UnitPriceid int, @ECMid int,
	@HeaderRecTypeid int, @HeaderContractid int, @HeaderJCCoid int, @HeaderCustomerid int, @HeaderCustGroupid int,
	@HeaderTransDateid int, @HeaderPayTermsid int, @HeaderCoid int, @TaxDiscid int, @RetgTaxid int, @ARLineid int

/* Column ID variables when setting required field to Zero */
declare	@zAmountid int, @zTaxBasisid int, @zTaxAmountid int, @zTaxDiscid int, @zRetgPctid int, @zRetainageid int, 
	@zDiscOfferedid int, @zFinanceChgdid int, @zRetgTaxid int
	
/* Column ID variables when setting required field to NULL */
declare	@nMaterialid int, @nMatlUnitsid int, @nUMid int, @nUnitPriceid int, 
	@nItemid int, @nContractUnitsid int  

/* Working variables */  
--#142350 renaming variables so we don't have duplicates
-- @UOM,@GLCompany,@RType
declare @Co bCompany, @LineNumber int,
    @RType tinyint, @LineType char(1), @GLCompany bCompany, @GLAcct bGLAcct, @TaxGroup bGroup, @TCode bTaxCode, @TaxDisc bDollar,
    @Amount bDollar, @TaxBasis bDollar, @TaxAmount bDollar, @RetgPct bPct, @Retainage bDollar, @RetgTax bDollar, @DiscOffered bDollar,
    @JCCo bCompany, @Contract bContract, @Item bContractItem, @ContractUnits bUnits, @UOM bUM, @MatlGroup bGroup, @Material bMatl, 
    @UnitPrice bUnitCost, @ECM bECM, @MatlUnits bUnits, 
--    
    @defaultamount bDollar, @taxrate bRate, @taxcode bTaxCode, @retainPct bPct, @defaultglaccount bGLAcct, 
	@glrevacct bGLAcct, @glwriteoffacct bGLAcct, @glfinchgacct bGLAcct, @glfcwriteoffacct bGLAcct, @glco bCompany,
	@unitcost bUnitCost, @price bUnitCost, @PriceECM bECM, @stdum bUM, @um bUM,	@ECMFact int, @discrate bUnitCost, @discdate bDate, 
	@duedate bDate,
--
	@arcoinvoicetaxyn bYN, @arcotaxretgyn bYN, @arcosepretgtaxyn bYN, @arcodiscopt char(1), @arcodisctaxyn bYN,
--
	@HeaderRecType tinyint,  @HeaderContract bContract, @HeaderJCCo bCompany, @HeaderCustomer bCustomer, @HeaderCustGroup bGroup, 
	@HeaderTransDate bDate, @HeaderPayTerms bPayTerms

/* Cursor variables */
declare @Recseq int, @Tablename varchar(20), @Column varchar(30), @Uploadval varchar(60), @Ident int
    
select @rcode =0

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
    
select @FormHeader = 'ARInvoiceEntry'
select @FormDetail = 'ARInvoiceEntryLines'
select @Form = 'ARInvoiceEntryLines'
    
select @HeaderRecordType = RecordType
from IMTR with (nolock)
where @ImportTemplate = ImportTemplate and Form = @FormHeader

/****************************************************************************************
*																						*
*			RECORDS ALREADY EXIST IN THE IMWE TABLE FROM THE IMPORTED TEXTFILE			*
*																						*
*			All records with the same RecordSeq represent a single import record		*
*																						*
****************************************************************************************/
    
/* Check ImportTemplate detail for columns to set Bidtek Defaults */
/* REM'D BECAUSE:  We cannot assume that user has imported every non-nullable value required by the table.
   If we exit this routine, then any non-nullable fields without an imported value will cause a
   table constraint error during the final upload process.  This procedure should provide enough
   defaults to SAVE the record, without error, if the import has not done so. */  
--if not exists(select IMTD.DefaultValue From IMTD with (nolock)
--		Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
--			and IMTD.RecordType = @rectype)
--goto bspexit

/* Not all fields are overwritable even though the template would indicate they are (Due to the presence of a checkbox).
   Only those fields that can likely be imported and where we can provide a useable default value will get processed here 
   as overwritable. The following list does not contain all fields shown on the Template Detail.  This can be modified as the need arises.
   Example:  UISeq is very unlikely to be provided by the import text file.  Therefore there is nothing to overwrite. */   
declare @OverwriteTransType bYN
	, @OverwriteRecType 	 	 bYN
	, @OverwriteLineType 	 	 bYN
	, @OverwriteGLCo 	 		 bYN
	, @OverwriteGLAcct 	 	  	 bYN
	, @OverwriteARLine 	 	 	 bYN
	, @OverwriteTaxGroup 	 	 bYN
	, @OverwriteTaxCode 	 	 bYN
	, @OverwriteAmount 	 	 	 bYN
	, @OverwriteTaxBasis 	 	 bYN
	, @OverwriteTaxAmount 	 	 bYN
	, @OverwriteTaxDisc 	 	 bYN
	, @OverwriteRetgPct 	 	 bYN
	, @OverwriteRetainage 	 	 bYN
	, @OverwriteDiscOffered 	 bYN
	, @OverwriteJCCo 	 	 	 bYN
	, @OverwriteContract 	 	 bYN
	, @OverwriteUM 	 	 	 	 bYN
	, @OverwriteMatlGroup 	 	 bYN
	, @OverwriteUnitPrice 	 	 bYN
	, @OverwriteECM 	 	 	 bYN
	, @OverwriteCo				 bYN
	, @OverwriteRetgTax			 bYN
	
/* This is pretty much a mirror of the list above EXCEPT it can exclude those columns that will be defaulted 
   as a record set and do not need to be defaulted per individual import record.  */
declare @IsARLineEmpty 			 bYN
	,	@IsRecTypeEmpty 		 bYN
	,	@IsLineTypeEmpty 		 bYN
	,	@IsGLCoEmpty 			 bYN
	,	@IsGLAcctEmpty 			 bYN
	,	@IsTaxGroupEmpty 		 bYN
	,	@IsTaxCodeEmpty 		 bYN
	,	@IsAmountEmpty 			 bYN
	,	@IsTaxBasisEmpty 		 bYN
	,	@IsTaxAmountEmpty 		 bYN
	,	@IsRetgPctEmpty 		 bYN
	,	@IsRetainageEmpty 		 bYN
	,	@IsDiscOfferedEmpty 	 bYN
	,	@IsTaxDiscEmpty 		 bYN
	,	@IsJCCoEmpty 			 bYN
	,	@IsContractEmpty 		 bYN
	,	@IsUMEmpty 				 bYN
	,	@IsMatlGroupEmpty 		 bYN
	,	@IsUnitPriceEmpty 		 bYN
	,	@IsECMEmpty 			 bYN
	,	@IsRetgTaxEmpty			 bYN

/* Return Overwrite value from Template. */	
SELECT @OverwriteTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'TransType', @rectype);
SELECT @OverwriteRecType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'RecType', @rectype);
SELECT @OverwriteLineType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'LineType', @rectype);
SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'GLCo', @rectype);
SELECT @OverwriteGLAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'GLAcct', @rectype);
SELECT @OverwriteARLine = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'ARLine', @rectype);
SELECT @OverwriteTaxGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'TaxGroup', @rectype);
SELECT @OverwriteTaxCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'TaxCode', @rectype);
SELECT @OverwriteAmount = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Amount', @rectype);
SELECT @OverwriteTaxBasis = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'TaxBasis', @rectype);
SELECT @OverwriteTaxAmount = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'TaxAmount', @rectype);
SELECT @OverwriteTaxDisc = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'TaxDisc', @rectype);
SELECT @OverwriteRetgPct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'RetgPct', @rectype);
SELECT @OverwriteRetainage = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Retainage', @rectype);
SELECT @OverwriteDiscOffered = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'DiscOffered', @rectype);
SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'JCCo', @rectype);
SELECT @OverwriteContract = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Contract', @rectype);
SELECT @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'UM', @rectype);
SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'MatlGroup', @rectype);
SELECT @OverwriteUnitPrice = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'UnitPrice', @rectype);
SELECT @OverwriteECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'ECM', @rectype);
SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Co', @rectype);
SELECT @OverwriteRetgTax = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'RetgTax', @rectype);

/* Record KeyID is the link between Header and Detail that will allow us to retrieve values
   from the Header, later, when needed. (Sometimes RecKey will need to be added to DDUD
   manually for both Form Header and Form Detail) */   
select @reckeyid = a.Identifier
From IMTD a  with (nolock) 
join DDUD b  with (nolock) on a.Identifier = b.Identifier
Where a.ImportTemplate=@ImportTemplate AND b.ColumnName = 'RecKey'
	and a.RecordType = @rectype and b.Form = @FormDetail
    
--select @invreckeyid = a.Identifier
--From IMTD a join DDUD b on a.Identifier = b.Identifier
--Where a.ImportTemplate=@ImportTemplate AND b.ColumnName = 'RecKey'
--and a.RecordType = @HeaderRecordType and b.Form = @FormHeader

/* There are some columns that can be updated to ALL imported records as a set.  The value is NOT
   unique to the individual imported record. */
select @TransTypeID=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TransType', @rectype, 'N')	--Non-Nullable
select @ARLineid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'ARLine', @rectype, 'N')		--Non-Nullable

--Co
--select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
--inner join DDUD on IMTD.Identifier = DDUD.Identifier inner join IMTR on IMTR.ImportTemplate = IMTD.ImportTemplate 
--	and IMTR.RecordType = IMTD.RecordType
--Where IMTD.ImportTemplate=@ImportTemplate and DDUD.Form = @Form 
--	and DDUD.ColumnName = 'Co' and IMTD.RecordType = @rectype
--if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
--	begin
--	Update IMWE
--	SET IMWE.UploadVal = @Company
--	where IMWE.ImportTemplate=@ImportTemplate and
--	IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID and IMWE.RecordType = @rectype
--	end

--select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
--inner join DDUD on IMTD.Identifier = DDUD.Identifier inner join IMTR on IMTR.ImportTemplate = IMTD.ImportTemplate 
--	and IMTR.RecordType = IMTD.RecordType
--Where IMTD.ImportTemplate=@ImportTemplate and DDUD.Form = @Form 
--	and DDUD.ColumnName = 'Co' and IMTD.RecordType = @rectype
--if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
--	begin
--	Update IMWE
--	SET IMWE.UploadVal = @Company
--	where IMWE.ImportTemplate=@ImportTemplate and
--	IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID and IMWE.RecordType = @rectype
--	end
    
--TransType:  ARBL Non-Nullable
if isnull(@TransTypeID,0) <> 0 AND (ISNULL(@OverwriteTransType, 'Y') = 'Y')
	begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'A'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @TransTypeID
		and IMWE.RecordType = @rectype
	end

if isnull(@TransTypeID,0) <> 0 AND (ISNULL(@OverwriteTransType, 'Y') = 'N')
	begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'A'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @TransTypeID
		AND IMWE.UploadVal IS NULL and IMWE.RecordType = @rectype
	end

--ARLine (Must clear existing imported values before beginning overwrite process using Viewpoint generated default Line#)
if ISNULL(@ARLineid, 0)<> 0 AND (ISNULL(@OverwriteARLine, 'Y') = 'Y')
	begin
	--'Use Viewpoint Default' = Y or N and 'Overwrite Import Value' = Y  (Clear all import records of ARLine values)
	Update IMWE
	SET IMWE.UploadVal = null
	where IMWE.ImportTemplate=@ImportTemplate and
		IMWE.ImportId=@ImportId and IMWE.Identifier = @ARLineid and IMWE.RecordType = @rectype
  	end
  	
/***** GET COLUMN IDENTIFIERS - Identifier will be returned ONLY when 'Use Viewpoint Default' is set. *******/    
select @RecTypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'RecType', @rectype, 'Y')
select @GLCoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'GLCo', @rectype, 'Y')
select @GLAcctid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'GLAcct', @rectype, 'Y')
select @TaxGroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxGroup', @rectype, 'Y')
select @TaxCodeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxCode', @rectype, 'Y')
select @Amountid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Amount', @rectype, 'Y')
select @TaxBasisid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxBasis', @rectype, 'Y')
select @TaxAmountid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxAmount', @rectype, 'Y')
select @TaxDiscid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxDisc', @rectype, 'Y')
select @RetgPctid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'RetgPct', @rectype, 'Y')
select @Retainageid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Retainage', @rectype, 'Y')
select @DiscOfferedid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'DiscOffered', @rectype, 'Y')
select @JCCoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'JCCo', @rectype, 'Y')
select @Contractid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Contract', @rectype, 'Y')
select @UMid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'UM', @rectype, 'Y')
select @MatlGroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'MatlGroup', @rectype, 'Y')
select @UnitPriceid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'UnitPrice', @rectype, 'Y')
select @ECMid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'ECM', @rectype, 'Y')
select @RetgTaxid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'RetgTax', @rectype, 'Y')

/***** GET COLUMN IDENTIFIERS - Identifier will be returned regardless of 'Use Viewpoint Default' setting. *******/
--Header
select @HeaderCoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Co', @HeaderRecordType, 'N')
select @HeaderRecTypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'RecType', @HeaderRecordType, 'N')
select @HeaderJCCoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'JCCo', @HeaderRecordType, 'N')
select @HeaderContractid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Contract', @HeaderRecordType, 'N')
select @HeaderCustGroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'CustGroup', @HeaderRecordType, 'N')
select @HeaderCustomerid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Customer', @HeaderRecordType, 'N')
select @HeaderTransDateid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'TransDate', @HeaderRecordType, 'N')
--Detail
select @CompanyID=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Co', @rectype, 'N')			--Non-Nullable
select @LineTypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'LineType', @rectype, 'N')	--Non-Nullable

--Used to set required columns to ZERO when not otherwise set by a default. (Cleanup: See end of procedure)   
select @zAmountid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Amount', @rectype, 'N')	--issue #119859
select @zTaxBasisid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxBasis', @rectype, 'N')
select @zTaxAmountid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxAmount', @rectype, 'N')
select @zTaxDiscid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxDisc', @rectype, 'N')
select @zRetgPctid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'RetgPct', @rectype, 'N')
select @zRetainageid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Retainage', @rectype, 'N')
select @zDiscOfferedid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'DiscOffered', @rectype, 'N')
select @zFinanceChgdid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'FinanceChg', @rectype, 'N')
select @zRetgTaxid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'RetgTax', @rectype, 'N')

--Used to set required columns to 'N' when not otherwise set by a default. (Cleanup: See end of procedure) 
select @nMaterialid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Material', @rectype, 'N')
select @nMatlUnitsid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'MatlUnits', @rectype, 'N')
select @nUMid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'UM', @rectype, 'N')
select @nUnitPriceid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'UnitPrice', @rectype, 'N')
select @nItemid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Item', @rectype, 'N')
select @nContractUnitsid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'ContractUnits', @rectype, 'N')

/* Begin default process.  Different concept here.  Multiple cursor records make up a single Import record
   determined by a change in the RecSeq value.  New RecSeq signals the beginning of the next Import record. */     		
declare WorkEditCursor cursor local fast_forward for
select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
from IMWE with (nolock)
inner join DDUD  with (nolock) on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form and
	IMWE.RecordType = @rectype
Order by IMWE.RecordSeq, IMWE.Identifier
    
open WorkEditCursor
-- set open cursor flag

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
		   that could be used during the defaulting process later if desired.  
		   
		   The imported value here is only needed if the value will be used to help determine another
		   default value in some way. */
        If @Column='RecType' and isnumeric(@Uploadval) =1 select @RType = @Uploadval
    	If @Column='LineType' select @LineType = @Uploadval
    	If @Column='TaxGroup' and isnumeric(@Uploadval) =1 select @TaxGroup =  Convert( smallint, @Uploadval)
    	If @Column='TaxCode' select @TCode = @Uploadval
    	If @Column='Amount' and isnumeric(@Uploadval) =1 select @Amount = convert(numeric(16,5),@Uploadval)
     	If @Column='TaxBasis' and isnumeric(@Uploadval) =1 select @TaxBasis = convert(numeric(16,5),@Uploadval)
    	If @Column='TaxAmount' and isnumeric(@Uploadval) =1 select @TaxAmount = Convert( numeric(16,5), @Uploadval)
    	If @Column='RetgPct' and isnumeric(@Uploadval) =1 select @RetgPct = convert(numeric(16,5),@Uploadval)
    	If @Column='Retainage' and isnumeric(@Uploadval) =1 select @Retainage = convert(numeric(16,5), @Uploadval)
		If @Column='RetgTax' and isnumeric(@Uploadval) =1 select @RetgTax = Convert(numeric(16,5), @Uploadval)
    	If @Column='DiscOffered' and isnumeric(@Uploadval) =1  select @DiscOffered = convert(numeric(16,5),@Uploadval)
    	If @Column='JCCo' and isnumeric(@Uploadval) =1  select @JCCo = convert(smallint,@Uploadval)
    	If @Column='Contract' select @Contract = @Uploadval
    	If @Column='Item' select @Item = @Uploadval
    	If @Column='ContractUnits' and isnumeric(@Uploadval) =1 select @ContractUnits = convert(numeric(16,5),@Uploadval)
    	If @Column='MatlGroup' and isnumeric(@Uploadval) =1 select @MatlGroup = Convert( tinyint,@Uploadval)
    	If @Column='Material' select @Material = @Uploadval
    	If @Column='UnitPrice' and isnumeric(@Uploadval) =1 select @UnitPrice = convert(numeric(16,5),@Uploadval)
    	If @Column='ECM' select @ECM = @Uploadval
    	If @Column='MatlUnits'and isnumeric(@Uploadval) =1 select @MatlUnits = convert(numeric(16,5),@Uploadval)

		/* Set IsNull variable for later */
		IF @Column='ARLine' 
			IF @Uploadval IS NULL
				SET @IsARLineEmpty = 'Y'
			ELSE
				SET @IsARLineEmpty = 'N'
		IF @Column='RecType' 
			IF @Uploadval IS NULL
				SET @IsRecTypeEmpty = 'Y'
			ELSE
				SET @IsRecTypeEmpty = 'N'
		IF @Column='LineType' 
			IF @Uploadval IS NULL
				SET @IsLineTypeEmpty = 'Y'
			ELSE
				SET @IsLineTypeEmpty = 'N'
		IF @Column='GLCo' 
			IF @Uploadval IS NULL
				SET @IsGLCoEmpty = 'Y'
			ELSE
				SET @IsGLCoEmpty = 'N'
		IF @Column='GLAcct' 
			IF @Uploadval IS NULL
				SET @IsGLAcctEmpty = 'Y'
			ELSE
				SET @IsGLAcctEmpty = 'N'
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
		IF @Column='Amount' 
			IF @Uploadval IS NULL
				SET @IsAmountEmpty = 'Y'
			ELSE
				SET @IsAmountEmpty = 'N'
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
		IF @Column='RetgPct' 
			IF @Uploadval IS NULL
				SET @IsRetgPctEmpty = 'Y'
			ELSE
				SET @IsRetgPctEmpty = 'N'
		IF @Column='Retainage' 
			IF @Uploadval IS NULL
				SET @IsRetainageEmpty = 'Y'
			ELSE
				SET @IsRetainageEmpty = 'N'
		IF @Column='RetgTax' 
			IF @Uploadval IS NULL
				SET @IsRetgTaxEmpty = 'Y'
			ELSE
				SET @IsRetgTaxEmpty = 'N'
		IF @Column='DiscOffered' 
			IF @Uploadval IS NULL
				SET @IsDiscOfferedEmpty = 'Y'
			ELSE
				SET @IsDiscOfferedEmpty = 'N'
		IF @Column='TaxDisc' 
			IF @Uploadval IS NULL
				SET @IsTaxDiscEmpty = 'Y'
			ELSE
				SET @IsTaxDiscEmpty = 'N'
		IF @Column='JCCo' 
			IF @Uploadval IS NULL
				SET @IsJCCoEmpty = 'Y'
			ELSE
				SET @IsJCCoEmpty = 'N'
		IF @Column='Contract' 
			IF @Uploadval IS NULL
				SET @IsContractEmpty = 'Y'
			ELSE
				SET @IsContractEmpty = 'N'
		IF @Column='UM' 
			IF @Uploadval IS NULL
				SET @IsUMEmpty = 'Y'
			ELSE
				SET @IsUMEmpty = 'N'
		IF @Column='MatlGroup' 
			IF @Uploadval IS NULL
				SET @IsMatlGroupEmpty = 'Y'
			ELSE
				SET @IsMatlGroupEmpty = 'N'
		IF @Column='UnitPrice' 
			IF @Uploadval IS NULL
				SET @IsUnitPriceEmpty = 'Y'
			ELSE
				SET @IsUnitPriceEmpty = 'N'
		IF @Column='ECM' 
			IF @Uploadval IS NULL
				SET @IsECMEmpty = 'Y'
			ELSE
				SET @IsECMEmpty = 'N'
 
		--fetch next record
		if @@fetch_status <> 0 select @complete = 1
    
		select @oldrecseq = @Recseq
    
		fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
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

		/* Retrieve necessary Header values here - This is a 3 step process. */
		--Step #1:  Get UploadVal for this RecKey column.  UploadVal is the pointer back to the Header record.
		select @RecKey=IMWE.UploadVal
		from IMWE with (nolock)
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
			and IMWE.Identifier = @reckeyid and IMWE.RecordType = @rectype 
			and IMWE.RecordSeq = @currrecseq

		--Step #2:  Get Header RecordSeq value for the Header record Type using the UploadVal retrieved in Step #1.
		select @HeaderReqSeq=IMWE.RecordSeq
		from IMWE with (nolock)
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
			and IMWE.Identifier = @reckeyid and IMWE.RecordType = @HeaderRecordType 
			and IMWE.UploadVal = @RecKey

        --Step #3:  Get the desired Header values from the Header RecordSeq retrieved in Step #2
		select @Co=IMWE.UploadVal
		from IMWE with (nolock)
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
			and IMWE.Identifier = @HeaderCoid and IMWE.RecordType = @HeaderRecordType 
			and IMWE.RecordSeq = @HeaderReqSeq

		select @HeaderRecType=IMWE.UploadVal
		from IMWE with (nolock)
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
			and IMWE.Identifier = @HeaderRecTypeid and IMWE.RecordType = @HeaderRecordType 
			and IMWE.RecordSeq = @HeaderReqSeq

		select @HeaderJCCo=IMWE.UploadVal
		from IMWE with (nolock)
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
			and IMWE.Identifier = @HeaderJCCoid and IMWE.RecordType = @HeaderRecordType 
			and IMWE.RecordSeq = @HeaderReqSeq
    
		select @HeaderContract=IMWE.UploadVal
		from IMWE with (nolock)
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
			and IMWE.Identifier = @HeaderContractid and IMWE.RecordType = @HeaderRecordType 
			and IMWE.RecordSeq = @HeaderReqSeq

		select @HeaderCustGroup=IMWE.UploadVal
		from IMWE with (nolock)
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
			and IMWE.Identifier = @HeaderCustGroupid and IMWE.RecordType = @HeaderRecordType 
			and IMWE.RecordSeq = @HeaderReqSeq

		select @HeaderCustomer=IMWE.UploadVal
		from IMWE with (nolock)
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
			and IMWE.Identifier = @HeaderCustomerid and IMWE.RecordType = @HeaderRecordType 
			and IMWE.RecordSeq = @HeaderReqSeq
    
		select @HeaderTransDate=IMWE.UploadVal
		from IMWE with (nolock)
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
			and IMWE.Identifier = @HeaderTransDateid and IMWE.RecordType = @HeaderRecordType 
			and IMWE.RecordSeq = @HeaderReqSeq

		select @HeaderPayTerms=IMWE.UploadVal
		from IMWE with (nolock)
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
			and IMWE.Identifier = @HeaderPayTermsid and IMWE.RecordType = @HeaderRecordType 
			and IMWE.RecordSeq = @HeaderReqSeq

		exec @recode = bspHQPayTermsDateCalc @HeaderPayTerms, @HeaderTransDate, @discdate output, @duedate output,
			@discrate output, @msg output

		--Co:  Non-Nullable
		if @CompanyID IS NOT NULL
			begin
			UPDATE IMWE
			SET IMWE.UploadVal = @Co		--Set same as Header
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @CompanyID and IMWE.RecordType = @rectype 
  			end
  			
 		--RecType  
    	if @RecTypeid <> 0 and isnull(@Co,'')<> '' AND (ISNULL(@OverwriteRecType, 'Y') = 'Y' OR ISNULL(@IsRecTypeEmpty, 'Y') = 'Y') 
     		begin
			select @RType = @HeaderRecType
			
			UPDATE IMWE
			SET IMWE.UploadVal = @RType
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @RecTypeid and IMWE.RecordType = @rectype
			end
    
		--MatlGroup
    	if @MatlGroupid <> 0 AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'Y' OR ISNULL(@IsMatlGroupEmpty, 'Y') = 'Y')
     		begin
    		select @MatlGroup = MatlGroup from HQCO with (nolock) where HQCo = @Co
    
			UPDATE IMWE
			SET IMWE.UploadVal = @MatlGroup
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
			and IMWE.Identifier = @MatlGroupid and IMWE.RecordType = @rectype
			end
    
		--JCCo
    	if @JCCoid <> 0 AND (ISNULL(@OverwriteJCCo, 'Y') = 'Y' OR ISNULL(@IsJCCoEmpty, 'Y') = 'Y')
     		begin
			select @JCCo = @HeaderJCCo
    		If @JCCo = 0 select @JCCo = null

			UPDATE IMWE
			SET IMWE.UploadVal = @JCCo
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @JCCoid and IMWE.RecordType = @rectype
			end
    
		--Contract
    	if @Contractid <> 0 and isnull(@Co,'')<> ''  AND (ISNULL(@OverwriteContract, 'Y') = 'Y' OR ISNULL(@IsContractEmpty, 'Y') = 'Y')
     		begin
			select @Contract = @HeaderContract

			UPDATE IMWE
			SET IMWE.UploadVal = @Contract
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @Contractid and IMWE.RecordType = @rectype
			end
    
		--LineType:	Non-Nullable
    	if @LineTypeid <> 0 AND (ISNULL(@OverwriteLineType, 'Y') = 'Y' OR ISNULL(@IsLineTypeEmpty, 'Y') = 'Y')
     		begin
			-- LINE TYPE M=Material, O=Other, C=Contract  
			select @LineType = 'O'
			If isnull(@Material,'') <> '' select @LineType = 'M'
    		If isnull(@HeaderContract,'') <> '' select @LineType = 'C'
    
			UPDATE IMWE
			SET IMWE.UploadVal = @LineType
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @LineTypeid and IMWE.RecordType = @rectype
			end
    
		--ARLine:  Non-Nullable
    	if @ARLineid <> 0 AND (ISNULL(@OverwriteARLine, 'Y') = 'Y' OR ISNULL(@IsARLineEmpty, 'Y') = 'Y') 
    		begin
    		-- Get the max line number in use for the current record's header record.
    		select @LineNumber = isnull(max(convert(int,UploadVal)),0)+1		
    		from IMWE with (nolock)
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
    			and IMWE.Identifier = @ARLineid and IMWE.RecordType = @rectype
    			and IMWE.RecordSeq in (select IMWE.RecordSeq from IMWE with (nolock)
    					where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
    					and IMWE.Identifier = @reckeyid and IMWE.RecordType = @rectype
    					and IMWE.UploadVal = @RecKey)
    
    		UPDATE IMWE
    		SET IMWE.UploadVal = @LineNumber
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier = @ARLineid and IMWE.RecordType = @rectype
    		end
    
    	/* get default gl revenue account from the receivable account */
    	exec @recode = bspARRecTypeValWithInfo @Co, @RType, @glrevacct output, @glwriteoffacct output, @glfinchgacct output, 
    		@glfcwriteoffacct output, @msg output
    
		If isnull(@Contract,'')<>''
			exec @recode = bspJCCIValWithInfo @JCCo, @Contract, @Item, @taxcode output, @retainPct output, @defaultglaccount output, @glco output, @um output, @unitcost output, @msg output
    
		--GLCo
    	if @GLCoid <> 0 AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
     		begin
			-- Use GLCo from AR Company or JC Company
			IF @LineType = 'C' 
				select @GLCompany = @glco
    		else
				select @GLCompany = GLCo from ARCO with (nolock) where @Co = ARCo 

			UPDATE IMWE
			SET IMWE.UploadVal = @GLCompany
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
			and IMWE.Identifier = @GLCoid and IMWE.RecordType = @rectype
			end
    
		--GLAcct
    	if @GLAcctid <> 0 AND (ISNULL(@OverwriteGLAcct, 'Y') = 'Y' OR ISNULL(@IsGLAcctEmpty, 'Y') = 'Y')
     		begin
			-- Use GLCo from AR Company or JC Company
			IF @LineType = 'C' 
				select @GLAcct = @defaultglaccount
    		else
				select @GLAcct = @glrevacct
    
            UPDATE IMWE
			SET IMWE.UploadVal = @GLAcct
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
			and IMWE.Identifier = @GLAcctid and IMWE.RecordType = @rectype
			end

    	if @LineType = 'M'
    		select @price=isNull(Price,0), @PriceECM=PriceECM, @stdum=StdUM
    		from HQMT with (nolock)
    		where MatlGroup=@MatlGroup and Material=@Material
    
		--UM
    	if @UMid <> 0  AND (ISNULL(@OverwriteUM, 'Y') = 'Y' OR ISNULL(@IsUMEmpty, 'Y') = 'Y')
     		begin
    		IF @LineType = 'C' select @UOM = @um
    		IF @LineType = 'M' select @UOM = @stdum
    
			UPDATE IMWE
			SET IMWE.UploadVal = @UOM
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @UMid and IMWE.RecordType = @rectype
			end
    
		--ECM
    	if @ECMid <> 0 AND (ISNULL(@OverwriteECM, 'Y') = 'Y' OR ISNULL(@IsECMEmpty, 'Y') = 'Y')
     		begin
    		IF @LineType = 'M' select @ECM = @PriceECM
    
			UPDATE IMWE
			SET IMWE.UploadVal = @ECM
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @ECMid and IMWE.RecordType = @rectype
			end
    
		--UnitPrice
    	if @UnitPriceid <> 0 AND (ISNULL(@OverwriteUnitPrice, 'Y') = 'Y' OR ISNULL(@IsUnitPriceEmpty, 'Y') = 'Y')
     		begin
    		IF @LineType = 'M' select @UnitPrice = @price
    		IF @LineType = 'C' select @UnitPrice = @unitcost
    
			UPDATE IMWE
			SET IMWE.UploadVal = @UnitPrice
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
			and IMWE.Identifier = @UnitPriceid and IMWE.RecordType = @rectype
			end

		/*  BaseAmount used in most other calculations. (This is DIFFERENT from the TotalAmount or ARBL.Amount value).  
			This initial value can come from either the import 'Amount' value or will be calculated when the import value
			is to be overridden.  This value gets used to determine other values such as Retainage, TaxBasis, TaxAmount,
			and RetgTax. Tax values will then be added to this amount to finally generate the 'TotalAmount' which gets saved
			to ARBL.Amount field.  If the imported 'Amount' already includes Tax values, then tax fields should not be
			set to default on the template. */
       	if @Amountid <> 0  AND (ISNULL(@OverwriteAmount, 'Y') = 'Y' OR ISNULL(@IsAmountEmpty, 'Y') = 'Y') 
			begin
			--Calculate our own BaseAmount
			select @ECMFact =  CASE @ECM WHEN 'M' then  1000
						WHEN 'C' then  100
						else  1 end
			IF @LineType = 'M'
				if @UnitPrice is not null and @MatlUnits is not null select @defaultamount =  ( @MatlUnits / @ECMFact)* @UnitPrice
			IF @LineType = 'C'
				BEGIN
				if @UnitPrice is not null and @ContractUnits is not null 
					select @defaultamount =  ( @ContractUnits / @ECMFact)* @UnitPrice				
				ELSE
					SELECT @defaultamount = ISNULL(@Amount,0) --added for issue #129654
				END
			IF @LineType = 'O'	--added for issue #29626
   				select @defaultamount = isnull(@Amount,0)
			end
		else
			begin
			--Use imported value.
			select @defaultamount = isnull(@Amount,0)
			end
			
		--RetgPct
    	if @RetgPctid <> 0 AND (ISNULL(@OverwriteRetgPct, 'Y') = 'Y' OR ISNULL(@IsRetgPctEmpty, 'Y') = 'Y')
     		begin
            select @RetgPct = isnull(@retainPct,0)		--Comes from JCCI otherwise will remain 0
    
			UPDATE IMWE
			SET IMWE.UploadVal = @RetgPct
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @RetgPctid and IMWE.RecordType = @rectype
			end

		--Retainage
		/* Base retainage is first determined.  Later RetgTax will be calculated and then combined with this value. */
    	if @Retainageid <> 0  AND (ISNULL(@OverwriteRetainage, 'Y') = 'Y' OR ISNULL(@IsRetainageEmpty, 'Y') = 'Y')
     		begin
            select @Retainage = isnull(@retainPct,0) * isnull(@defaultamount,0)

			UPDATE IMWE
			SET IMWE.UploadVal = @Retainage
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @Retainageid and IMWE.RecordType = @rectype
			end
			
		/* Get some ARCompany Tax Setup information. */
		select @arcoinvoicetaxyn = InvoiceTax, @arcotaxretgyn = TaxRetg, @arcosepretgtaxyn = SeparateRetgTax,
			@arcodiscopt = DiscOpt, @arcodisctaxyn = DiscTax
		from ARCO with (nolock)
		where ARCo = @Co
		
		if @arcoinvoicetaxyn = 'Y'
			begin
			--TaxGroup
    		if @TaxGroupid <> 0 AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'Y' OR ISNULL(@IsTaxGroupEmpty, 'Y') = 'Y')
     			begin
    			IF @LineType = 'C' 
           			select @TaxGroup = TaxGroup from HQCO with (nolock) where HQCo = @JCCo
    			else
    				select @TaxGroup = TaxGroup from HQCO with (nolock) where HQCo = @Co
	    
				UPDATE IMWE
				SET IMWE.UploadVal = @TaxGroup
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @TaxGroupid and IMWE.RecordType = @rectype
				end
	    
			--TaxCode
    		if @TaxCodeid <> 0 AND (ISNULL(@OverwriteTaxCode, 'Y') = 'Y' OR ISNULL(@IsTaxCodeEmpty, 'Y') = 'Y')
     			begin
    			IF @LineType = 'C' 
           			select @TCode = @taxcode		--Retrieved earlier from bJCCI
    			else
    				select @TCode = TaxCode from ARCM with (nolock) where CustGroup = @HeaderCustGroup and Customer = @HeaderCustomer
	   
				UPDATE IMWE
				SET IMWE.UploadVal = @TCode
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @TaxCodeid and IMWE.RecordType = @rectype
				end
			
			/* If user has elected to default TaxAmount or RetgTax amount then we must assume that the imported Amount
			   value does NOT already include these additional values.  Remember the ARBL.Amount value always includes
			   TaxAmount and RetgTax values. */
			   
			--TaxBasis
    		if @TaxBasisid <> 0 AND (ISNULL(@OverwriteTaxBasis, 'Y') = 'Y' OR ISNULL(@IsTaxBasisEmpty, 'Y') = 'Y')
     			begin
    			select @TaxBasis = case when @arcotaxretgyn = 'Y' then 
    				case when @arcosepretgtaxyn = 'N' then isnull(@defaultamount,0) else isnull(@defaultamount,0) - isnull(@Retainage,0) end
    					else isnull(@defaultamount,0) - isnull(@Retainage,0) end
	    
				UPDATE IMWE
				SET IMWE.UploadVal = @TaxBasis
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @TaxBasisid and IMWE.RecordType = @rectype
				end
	    
			--TaxAmount
    		if @TaxAmountid <> 0 AND (ISNULL(@OverwriteTaxAmount, 'Y') = 'Y' OR ISNULL(@IsTaxAmountEmpty, 'Y') = 'Y') 
     			begin
    			exec @recode =  bspHQTaxRateGet @TaxGroup, @TCode, @HeaderTransDate, @taxrate output, @msg output

				select @TaxAmount = isnull(@taxrate,0) * isnull(@TaxBasis,0)
	    
				UPDATE IMWE
				SET IMWE.UploadVal = @TaxAmount
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @TaxAmountid and IMWE.RecordType = @rectype
				end
				
			--RetgTax
    		if @RetgTaxid <> 0 AND (ISNULL(@OverwriteRetgTax, 'Y') = 'Y' OR ISNULL(@IsRetgTaxEmpty, 'Y') = 'Y')
     			begin
    			select @RetgTax = case when @arcotaxretgyn = 'Y' then 
    				case when @arcosepretgtaxyn = 'N' then 0 else isnull(@taxrate,0) * isnull(@Retainage,0) end
    					else 0 end
	    
				UPDATE IMWE
				SET IMWE.UploadVal = @RetgTax
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @RetgTaxid and IMWE.RecordType = @rectype
					
				/* Once RetgTax gets calculated, we must reset the Retainage default because ARBL.Retainage always includes
				   RetgTax.  (ARBL.Retainage = Retainage + RetgTax) */
				UPDATE IMWE
				SET IMWE.UploadVal = isnull(@Retainage,0) + isnull(@RetgTax,0)
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @Retainageid and IMWE.RecordType = @rectype
				end			
			end
		else
			begin
			select @TaxAmount = 0
			end
		
		/* Double check.  Don't want a TaxBasis or TaxAmount or RetgTax without a TaxCode.  Again we assume if user is 
		   defaulting these Tax related inputs then we need to adjust the Amount and Retainage values even when using
		   the imported value of either. */	
		if isnull(@TCode,'') = '' and (isnull(@TaxBasis ,0) <> 0 or isnull(@TaxAmount,0) <> 0 or isnull(@RetgTax,0) <> 0) 
			begin
    		select @TaxBasis = 0
	    
			UPDATE IMWE
			SET IMWE.UploadVal = @TaxBasis
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
			and IMWE.Identifier = @zTaxBasisid and IMWE.RecordType = @rectype

			select @TaxAmount = 0
	    
			UPDATE IMWE
			SET IMWE.UploadVal = @TaxAmount
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
			   and IMWE.Identifier = @zTaxAmountid and IMWE.RecordType = @rectype
			   
			select @RetgTax = 0
	    
			UPDATE IMWE
			SET IMWE.UploadVal = @RetgTax
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
			   and IMWE.Identifier = @zRetgTaxid and IMWE.RecordType = @rectype

			/* Any change to the above will affect Amount and Retainage as well. */			   
			UPDATE IMWE
			SET IMWE.UploadVal = isnull(@Retainage,0) + isnull(@RetgTax,0)
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
			   and IMWE.Identifier = @zRetainageid and IMWE.RecordType = @rectype
			   
			UPDATE IMWE
			SET IMWE.UploadVal = isnull(@Amount,0) + isnull(@TaxAmount,0) + isnull(@RetgTax,0)
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
			   and IMWE.Identifier = @zAmountid and IMWE.RecordType = @rectype			   			   
			end
    
		--TotalAmount:  
		/* TotalAmount is what we have after we combine the starting Amount value with Tax and RetgTax.  'TotalAmount' is not a separate
		   field!  It is simply a recalculated ARBL.Amount.  Therefore once we have determined all other values, we must reset the 
		   'Amount' to include such values as TaxAmount and RetgTax.  This recalculation must always occur and is not dependent
		   upon the import template setup.  (Only the initial 'Amount' default value used to determine all other values such as retainage,
		   tax and retainage tax is controlled by the template setup. - See 'DefaultAmount' code above.)  */
		-- #137283 added condition to only overwrite amount when 'Use Viewpoint Default' in template is checked 
		--			to resolve Company value getting overwritten with amount.
    	if @Amountid <> 0
			begin
			select @Amount = isnull(@defaultamount,0) + isnull(@TaxAmount,0) + isnull(@RetgTax,0)
	    
			UPDATE IMWE
			SET IMWE.UploadVal = @Amount
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
			   and IMWE.Identifier = @Amountid and IMWE.RecordType = @rectype
			end

		--DiscOffered
		if @arcodiscopt = 'I'
			begin
    		if @DiscOfferedid <> 0  AND (ISNULL(@OverwriteDiscOffered, 'Y') = 'Y' OR ISNULL(@IsDiscOfferedEmpty, 'Y') = 'Y')
     			begin
				select @DiscOffered = isnull(@defaultamount,0) * @discrate

				UPDATE IMWE
				SET IMWE.UploadVal = @DiscOffered
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @DiscOfferedid and IMWE.RecordType = @rectype
				end
			end

		--TaxDisc
		if @arcodisctaxyn = 'Y'
			begin
    		if @TaxDiscid <> 0 AND (ISNULL(@OverwriteTaxDisc, 'Y') = 'Y' OR ISNULL(@IsTaxDiscEmpty, 'Y') = 'Y')
     			begin
				select @TaxDisc = isnull(@DiscOffered,0) * isnull(@taxrate,0)

				UPDATE IMWE
				SET IMWE.UploadVal = @TaxDisc
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @TaxDiscid and IMWE.RecordType = @rectype
				end
			end
			
    	if @LineType = 'O'
    		-- clear Material, MatlUnits, UMid, UnitPrice, Item, ContractUnits 
    		begin 
    		UPDATE IMWE
    		SET IMWE.UploadVal = null
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
    		( IMWE.Identifier = @nMaterialid or IMWE.Identifier = @nMatlUnitsid or IMWE.Identifier = @nUMid 
    			or IMWE.Identifier = @nUnitPriceid or IMWE.Identifier = @nItemid or IMWE.Identifier = @nContractUnitsid )
    		end
    
    	if @LineType = 'C'
    		-- clear Material, MatlUnits, UnitPrice (Issue #128428 Do not clear Contract UM, but clear Contract UnitPrice as is done in the form)
    		begin 
    		UPDATE IMWE
    		SET IMWE.UploadVal = null
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
    		( IMWE.Identifier = @nMaterialid or IMWE.Identifier = @nMatlUnitsid /*or IMWE.Identifier = @nUMid */
    			or IMWE.Identifier = @nUnitPriceid )
    		end
    
    	if @LineType = 'M'
    		-- clear Item, ContractUnits 
    		begin 
    		UPDATE IMWE
    		SET IMWE.UploadVal = null
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
    		( IMWE.Identifier = @nItemid or IMWE.Identifier = @nContractUnitsid )
    		end
    
		select @currrecseq = @Recseq	--Defaults have been set for all columns on this seq/record.  Moving on to next sequence/record now.
		select @counter = @counter + 1

		/* Reset working variables */
		select @Co = null, @RType = null, @LineType = null, @GLCompany = null, @GLAcct = null, @TaxGroup = null, @TCode = null,
    		@Amount = null, @TaxBasis = null, @TaxAmount = null, @RetgPct = null, @Retainage = null, @RetgTax = null, @DiscOffered = null,
    		@TaxDisc = null, @JCCo = null, @Contract = null, @Item = null, @ContractUnits = null, @UOM = null, 
    		@MatlGroup = null, @Material = null, @UnitPrice = null, @ECM = null, @MatlUnits = null

		select @HeaderRecType = null,  @HeaderContract  = null, @HeaderJCCo  = null,
    		@HeaderCustomer  = null, @HeaderCustGroup  = null, @HeaderTransDate  = null,
    		@HeaderPayTerms  = null, @glrevacct  = null, @glwriteoffacct  = null, @glfinchgacct  = null,
    		@taxcode  = null, @retainPct  = null, @defaultglaccount  = null, @glco  = null,
    		@unitcost  = null, @price  = null, @PriceECM  = null, @stdum  = null, @um  = null,
    		@ECMFact  = null, @defaultamount  = null, @discrate  = null, @discdate  = null, @duedate  = null
    
		end		--End single Record/Sequence loop
    end		--End WorkEdit loop, All imported records have been processed with defaults

close WorkEditCursor
deallocate WorkEditCursor
    
/* Set required (dollar) inputs to 0 where not already set with some other value */    
UPDATE IMWE
SET IMWE.UploadVal = 0.00
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'')='' and
	(IMWE.Identifier = @zAmountid or IMWE.Identifier = @zTaxBasisid or IMWE.Identifier = @zTaxAmountid
     or IMWE.Identifier = @zTaxDiscid or IMWE.Identifier = @zRetainageid or IMWE.Identifier = @zRetgTaxid
     or IMWE.Identifier = @zDiscOfferedid or IMWE.Identifier = @zFinanceChgdid)

UPDATE IMWE
SET IMWE.UploadVal = 0.0000
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'')='' and
	(IMWE.Identifier = @zRetgPctid)
        
bspexit:
select @msg = isnull(@desc,'AR Invoice Line') + char(13) + char(13) + '[bspIMBidtekDefaultARBL]'
    
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsARBL] TO [public]
GO
