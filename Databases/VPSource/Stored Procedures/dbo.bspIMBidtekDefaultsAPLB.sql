SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsAPLB]
/***********************************************************
* CREATED BY:   Danf
* MODIFIED BY:  DANF 09/05/02 - #17738 Added Phase Group to bspJCCAGlacctDflt
*		DANF 11/7/02 - #19123 Corrected AP Line Default
*		DANF 04/14/03 - #20899 Added UM Default.
*		RBT 09/05/03 - #20131, allow record type <> table name.
*		RBT 06/08/04 - #24751, check for "Record Key" or "RecKey".
*		RBT 07/06/04 - #25022, check DDUD for RecKey column, not IMTD.
*		RBT 03/14/05 - #27364, add default for PayCategory, change default for PayType.
*		RBT 03/28/05 - #27477, fix ECM default.
*		RBT 08/19/05 - #29620, fixed GLAcct default IF statements.
*		RBT 08/29/05 - #29626, add default for Discount.
*		RBT 08/30/05 - #29441, Fix Company default.
*		RBT 01/26/06 - #120057, fix company query.
*		DANF 07/31/07 = # 125077, Added UM default for Job line types set from the Job/ Phase / Cost Type.
*		DANF 07/29/08 - #124631, Only use payterms if one exists.
*		CC	02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
*		GF 05/11/2009 - issue #133555 - default material group for INCo was using incorrect company
*		TJL 07/31/09 - Issue #133825, Add Intl VAT TaxType default, correct LineType, APLine, Discount, TaxBasis defaults
*		MV	03/17/10 - #136500 - taxbasis net retainage
*		TJL 03/23/10 - Issue #138559, TaxGroup not Defaulting when "Use VP Defaults" selected on SL type lines.
*		GF  06/25/2010 - issue #135813 expanded SL to varchar(30)
*       ECV 05/24/11 - TK-05443 - Added SM feilds
*		TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*		MH  08/19/2011 - TK-07482 Swap SM MiscellaneousType for SMCostType
*		JG 01/26/2012 - TK-12040 - Added SMJCCostType and SMPhaseGroup
*		JG 02/01/2012 - TK-12012 - Grabbing the SMJCCostType and SMPhaseGroup when SMCostType is supplied.
*		JG 02/10/2012 - TK-00000 - Renamed @OverwriteSMMiscType to @OverwriteSMCostType.
*       JayR 10/16/2012 TK-16099   Fix overlapping variables.
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

/* General Declares */        
declare @rcode int, @recode int, @desc varchar(120), @defaultvalue varchar(30), @errmsg varchar(120), 
	@filler varchar(1), @umout bUM, @taxrate bRate,	@InvDate bDate, @FormDetail varchar(20), @FormHeader varchar(20),
	@RecKey varchar(60), @HeaderRecordType varchar(10),	@HeaderReqSeq int, @burdenyn bYN, @netamtopt bYN

/* Column ID's */        
declare @CompanyID int, @BatchTransTypeID int, 
	@linetypeid int, @aplineid int, @itemtypeid int, @jccooid int, @jobid int, @phasegroupid int, @Phaseid int,
	@jcctypeid int, @emcoid int, @woid int, @woitemid int, @equipid int, @emgroupid int, @costcodeid int, @emctypeid int, 
	@comptypeid int, @componentid int, @incoid int, @locid int, @matlgroupid int, @materialid  int, @glcoid int,
	@glacctid int, @umid int, @ecmid int, @vendorgroupid int, @supplierid int, @paytypeid int, @miscynid int, @taxcodeid int,
	@taxbasisid int, @taxamtid int, @taxgroupid int, @taxtypeid int, @reckeyid int, @invdateid int,
	@zunitsid int, @zunitcostid int, @zgrossamtid int, @zmiscamtid int,
	@ztaxbasisid int, @ztaxamtid int, @zretainageid int, @zdiscountid int, 
	@nmiscynid int, @cpoid int, @cpoitemid int, @cslid int, @cslitemid int, @cemcoid int, @cwoid int, 
	@cwoitemid int, @cequipid int, @cemgroupid int, @ccostcodeid int, @cemctypeid int, @ccomptypeid int, @ccomponentid int,
	@cjccoid int, @cjobid int, @cphasegroupid int, @cphaseid int, @cjcctypeid int, @cincoid int, @clocid int, @cecmid int, 
	@retainageid int, @vendorid int, @paycategoryid int, @discountid int,
	@burunitcostid int, @becmid int, @smchangeid int,
	@zburunitcostid int, @zsmchangeid int, @npaidynid int, @headercompanyid int,
	@smcoid int, @smworkorderid int, @smscopeid int, @smcosttypeid int, @smjccosttype_lower int, @smphasegroup int
	
/* Working variables */ 
declare  @Co bCompany,    
	@Vendor bVendor, @APLine smallint, @LineType tinyint, @PO varchar(30), @POItem bItem, @ItemType tinyint, @SL VARCHAR(30), @SLItem bItem,
	@JCCo bCompany, @Job bJob, @PhaseGroup bGroup, @Phase bPhase, @JCCType bJCCType, @EMCO bCompany, @WO bWO, @WOItem bItem,
	@Equip bEquip, @EMGroup bGroup, @CostCode bCostCode, @EMCType bEMCType, @CompType varchar(10), @Component bEquip,
	@INCo bCompany, @Loc bLoc, @MatlGroup bGroup, @Material bMatl, @GLCo bCompany, @GLAcct bGLAcct, @UM bUM, @Units bUnits, 
	@ECM bECM, @VendorGroup bGroup, @Supplier bVendor, @PayType tinyint, @GrossAmt bDollar, @MiscAmt bDollar, @MiscYN bYN,
	@TaxGroup bGroup, @TaxCode bTaxCode, @TaxType tinyint, @TaxBasis bDollar, @TaxAmt bDollar, @Retainage bDollar,
	@Discount bDollar, @WCRetPct bPct, @PayCategory int, @LineTaxGroup bGroup, @LineTaxType tinyint,
	@defexppaytype tinyint, @defjobpaytype tinyint, @defsmpaytype tinyint, @defsubpaytype tinyint, @defretpaytype tinyint, @defdiscoffglact bGLAcct,
	@defdisctakenglacct bGLAcct, @defpaycategory int, @payterms bPayTerms, @discrate bPct, @costtypeout bEMCType,
	@BECM bECM, @SMChange bDollar, @BurUnitCost bDollar, @hqdfltcountry char(2),
	@apcousetaxdiscyn bYN, @VPLineType tinyint, @taxbasisnetretgyn bYN,
	@SMCo bCompany, @SMWorkOrder int, @SMScope int, @SMCostType SMALLINT, @SMJCCostType dbo.bJCCType, @SMPhaseGroup dbo.bGroup
	

/* Cursor variables */
declare @Recseq int, @Tablename varchar(20), @Column varchar(30), @Uploadval varchar(60), @Ident int,
	@currrecseq int, @complete int, @counter int, @oldrecseq int
        	
select @rcode = 0, @msg='' 

/* check required input params */
--Issue #20131
--if @rectype <> 'APLB' goto bspexit

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
        
select @FormHeader = 'APEntry'
select @FormDetail = 'APEntryDetail'
select @Form = 'APEntryDetail'
        
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
--if not exists(select IMTD.DefaultValue From IMTD
--		Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
--			and IMTD.RecordType = @rectype)
--goto bspexit

/* Record KeyID is the link between Header and Detail that will allow us retrieve values
   from the Header, later, when needed. (Sometimes RecKey will need to be added to DDUD
   manually for both Form Header and Form Detail) */
select @reckeyid = a.Identifier			--1000
From IMTD a with (nolock) 
join DDUD b with (nolock) on a.Identifier = b.Identifier
Where a.ImportTemplate=@ImportTemplate AND b.ColumnName = 'RecKey'
	and a.RecordType = @rectype and b.Form = @FormDetail

--select @invreckeyid = a.Identifier
--From IMTD a join DDUD b on a.Identifier = b.Identifier
--Where a.ImportTemplate=@ImportTemplate AND b.ColumnName = 'RecKey'
--and a.RecordType = @HeaderRecordType and b.Form = @FormHeader

/* Not all fields are overwritable even though the template would indicate they are (Due to the presence of a checkbox).
   Only those fields that can likely be imported and where we can provide a useable default value will get processed here 
   as overwritable. The following list does not contain all fields shown on the Template Detail.  This can be modified as the need arises.
   Example:  UISeq is very unlikely to be provided by the import text file.  Therefore there is nothing to overwrite. */          
DECLARE @OverwriteBatchTransType	bYN
		,@OverwriteLineType 		bYN
		,@OverwriteAPLine 	 		bYN
		,@OverwriteItemType 		bYN
		,@OverwriteJCCo 	 		bYN
		,@OverwriteJob 	 			bYN
		,@OverwritePhaseGroup 		bYN
		,@OverwritePhase 	 		bYN
		,@OverwriteJCCType 	 		bYN
		,@OverwriteEMCo 	 		bYN
		,@OverwriteWO 	 	 		bYN
		,@OverwriteWOItem 	 		bYN
		,@OverwriteEquip 	 		bYN
		,@OverwriteEMGroup 	 		bYN
		,@OverwriteCostCode 		bYN
		,@OverwriteEMCType 	 		bYN
		,@OverwriteCompType 		bYN
		,@OverwriteComponent 		bYN
		,@OverwriteINCo 	 		bYN
		,@OverwriteLoc 	 	 		bYN
		,@OverwriteMatlGroup 		bYN
		,@OverwriteMaterial 		bYN
		,@OverwriteGLCo 	 		bYN
		,@OverwriteGLAcct 	 		bYN
		,@OverwriteUM 	 	 		bYN
		,@OverwriteECM 	 	 		bYN
		,@OverwriteVendorGroup 		bYN
		,@OverwriteSupplier 		bYN
		,@OverwritePayType 	 		bYN
		,@OverwritePayCategory 		bYN
		,@OverwriteMiscYN 	 		bYN
		,@OverwriteTaxGroup 		bYN
		,@OverwriteTaxCode 	 		bYN
		,@OverwriteTaxBasis 		bYN
		,@OverwriteTaxAmt 	 		bYN
		,@OverwriteTaxType 	 		bYN
		,@OverwriteRetainage 		bYN
		,@OverwriteDiscount 		bYN
		,@OverwriteBurUnitCost 		bYN
		,@OverwriteBECM 			bYN
		,@OverwriteSMChange 		bYN
		,@OverwriteSMCo		 		bYN
		,@OverwriteSMWorkOrder 		bYN
		,@OverwriteSMScope	 		bYN
		,@OverwriteSMCostType 		bYN
		,@OverwriteSMJCCostType 	bYN
		,@OverwriteSMPhaseGroup		bYN

/* This is pretty much a mirror of the list above EXCEPT it excludes those columns that will be defaulted 
   as a record set and do not need to be defaulted per individual import record.  */						
DECLARE @IsAPLineEmpty 				bYN
		,@IsLineTypeEmpty 			bYN
		,@IsItemTypeEmpty 			bYN
		,@IsJCCoEmpty 				bYN
		,@IsJobEmpty 				bYN
		,@IsPhaseGroupEmpty 		bYN
		,@IsPhaseEmpty 				bYN
		,@IsJCCTypeEmpty 			bYN
		,@IsEMCoEmpty 				bYN
		,@IsWOEmpty 				bYN
		,@IsWOItemEmpty 			bYN
		,@IsEquipEmpty 				bYN
		,@IsEMGroupEmpty 			bYN
		,@IsCostCodeEmpty 			bYN
		,@IsEMCTypeEmpty 			bYN
		,@IsCompTypeEmpty 			bYN
		,@IsComponentEmpty 			bYN
		,@IsINCoEmpty 				bYN
		,@IsLocEmpty 				bYN
		,@IsMatlGroupEmpty 			bYN
		,@IsMaterialEmpty 			bYN
		,@IsGLCoEmpty 				bYN
		,@IsGLAcctEmpty 			bYN
		,@IsUMEmpty 				bYN
		,@IsECMEmpty 				bYN
		,@IsVendorGroupEmpty 		bYN
		,@IsSupplierEmpty 			bYN
		,@IsPayTypeEmpty 			bYN
		,@IsPayCategoryEmpty 		bYN
		,@IsMiscYNEmpty 			bYN
		,@IsTaxGroupEmpty 			bYN
		,@IsTaxCodeEmpty 			bYN
		,@IsTaxTypeEmpty 			bYN
		,@IsTaxBasisEmpty 			bYN
		,@IsTaxAmtEmpty 			bYN
		,@IsRetainageEmpty 			bYN
		,@IsDiscountEmpty 			bYN
		,@IsBurUnitCostEmpty 		bYN
		,@IsBECMEmpty 				bYN
		,@IsSMChangeEmpty 			bYN
		,@IsSMCoEmpty	 			bYN
		,@IsSMWorkOrderEmpty		bYN
		,@IsSMScopeEmpty 			bYN
		,@IsSMCostTypeEmpty			bYN
		,@IsSMJCCostTypeEmpty		bYN
		,@IsSMPhaseGroupEmpty		bYN

/* Return Overwrite value from Template. */	
SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'BatchTransType', @rectype);
SELECT @OverwriteLineType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'LineType', @rectype);
SELECT @OverwriteAPLine = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'APLine', @rectype);
SELECT @OverwriteItemType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'ItemType', @rectype);
SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'JCCo', @rectype);
SELECT @OverwriteJob = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Job', @rectype);
SELECT @OverwritePhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'PhaseGroup', @rectype);
SELECT @OverwritePhase = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Phase', @rectype);
SELECT @OverwriteJCCType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'JCCType', @rectype);
SELECT @OverwriteEMCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'EMCo', @rectype);
SELECT @OverwriteWO = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'WO', @rectype);
SELECT @OverwriteWOItem = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'WOItem', @rectype);
SELECT @OverwriteEquip = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Equip', @rectype);
SELECT @OverwriteEMGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'EMGroup', @rectype);
SELECT @OverwriteCostCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'CostCode', @rectype);
SELECT @OverwriteEMCType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'EMCType', @rectype);
SELECT @OverwriteCompType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'CompType', @rectype);
SELECT @OverwriteComponent = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Component', @rectype);
SELECT @OverwriteINCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'INCo', @rectype);
SELECT @OverwriteLoc = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Loc', @rectype);
SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'MatlGroup', @rectype);
SELECT @OverwriteMaterial = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Material', @rectype);
SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'GLCo', @rectype);
SELECT @OverwriteGLAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'GLAcct', @rectype);
SELECT @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'UM', @rectype);
SELECT @OverwriteECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'ECM', @rectype);
SELECT @OverwriteVendorGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'VendorGroup', @rectype);
SELECT @OverwriteSupplier = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Supplier', @rectype);
SELECT @OverwritePayType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'PayType', @rectype);
SELECT @OverwritePayCategory = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'PayCategory', @rectype);
SELECT @OverwriteMiscYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'MiscYN', @rectype);
SELECT @OverwriteTaxCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'TaxCode', @rectype);
SELECT @OverwriteTaxBasis = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'TaxBasis', @rectype);
SELECT @OverwriteTaxAmt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'TaxAmt', @rectype);
SELECT @OverwriteTaxGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'TaxGroup', @rectype);
SELECT @OverwriteTaxType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'TaxType', @rectype);
SELECT @OverwriteRetainage = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Retainage', @rectype);
SELECT @OverwriteDiscount = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Discount', @rectype);
SELECT @OverwriteBurUnitCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'BurUnitCost', @rectype);
SELECT @OverwriteBECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'BECM', @rectype);
SELECT @OverwriteSMChange = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'SMChange', @rectype);
SELECT @OverwriteSMCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'SMCo', @rectype);
SELECT @OverwriteSMWorkOrder = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'SMWorkOrder', @rectype);
SELECT @OverwriteSMScope = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Scope', @rectype);
SELECT @OverwriteSMCostType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'SMCostType', @rectype);
SELECT @OverwriteSMJCCostType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'SMJCCostType', @rectype);
SELECT @OverwriteSMPhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'SMPhaseGroup', @rectype);

/* There are some columns that can be updated to ALL imported records as a set.  The value is NOT
   unique to the individual imported record. */
select @aplineid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'APLine', @rectype, 'N')		--Non-Nullable

--Co	(Comes from directly from Header value later while processing Line values)       	         	    
--select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
--inner join DDUD on IMTD.Identifier = DDUD.Identifier inner join IMTR on
--IMTR.ImportTemplate = IMTD.ImportTemplate and IMTR.RecordType = IMTD.RecordType
--Where IMTD.ImportTemplate=@ImportTemplate and DDUD.Form = @Form 
--and DDUD.ColumnName = 'Co' and IMTD.RecordType = @rectype
--	if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y')
--	begin
--	Update IMWE
--	SET IMWE.UploadVal = @Company
--	where IMWE.ImportTemplate=@ImportTemplate and
--	IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID and IMWE.RecordType = @rectype
--	end
   		
--select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
--inner join DDUD on IMTD.Identifier = DDUD.Identifier inner join IMTR on
--IMTR.ImportTemplate = IMTD.ImportTemplate and IMTR.RecordType = IMTD.RecordType
--Where IMTD.ImportTemplate=@ImportTemplate and DDUD.Form = @Form 
--and DDUD.ColumnName = 'Co' and IMTD.RecordType = @rectype
--if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N')  		
--	begin
--	Update IMWE
--	SET IMWE.UploadVal = @Company
--	where IMWE.ImportTemplate=@ImportTemplate and
--	IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID and IMWE.RecordType = @rectype
--	AND IMWE.UploadVal IS NULL
--	end
       
--Batch TransType        
select @BatchTransTypeID=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'BatchTransType', @rectype, 'Y')
if isnull(@BatchTransTypeID,0) <> 0 AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'Y')
begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'A'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
	and IMWE.RecordType = @rectype
end

if isnull(@BatchTransTypeID,0) <> 0 AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'N')
begin
	UPDATE IMWE
	SET IMWE.UploadVal = 'A'
	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
	and IMWE.RecordType = @rectype
	AND IMWE.UploadVal IS NULL
end

--APLine (Must clear existing imported values before beginning overwrite process using Viewpoint generated default Line#)
if ISNULL(@aplineid, 0)<> 0 AND (ISNULL(@OverwriteAPLine, 'Y') = 'Y')
	begin
	--'Use Viewpoint Default' = Y or N and 'Overwrite Import Value' = Y  (Clear all import records of APLine values)
	Update IMWE
	SET IMWE.UploadVal = null
	where IMWE.ImportTemplate=@ImportTemplate and
		IMWE.ImportId=@ImportId and IMWE.Identifier = @aplineid and IMWE.RecordType = @rectype
  	end
  	  
/***** GET COLUMN IDENTIFIERS - Identifier will be returned ONLY when 'Use Viewpoint Default' is set. *******/       
select @itemtypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'ItemType', @rectype, 'Y')
select @jccooid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'JCCo', @rectype, 'Y')
select @jobid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Job', @rectype, 'Y')
select @phasegroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'PhaseGroup', @rectype, 'Y')
select @Phaseid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Phase', @rectype, 'Y')
select @jcctypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'JCCType', @rectype, 'Y')
select @emcoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'EMCo', @rectype, 'Y')
select @woid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'WO', @rectype, 'Y')
select @woitemid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'WOItem', @rectype, 'Y')
select @equipid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Equip', @rectype, 'Y')
select @emgroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'EMGroup', @rectype, 'Y')
select @costcodeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'CostCode', @rectype, 'Y')
select @emctypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'EMCType', @rectype, 'Y')
select @comptypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'CompType', @rectype, 'Y')
select @componentid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Component', @rectype, 'Y')
select @incoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'INCo', @rectype, 'Y')
select @locid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Loc', @rectype, 'Y')
select @matlgroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'MatlGroup', @rectype, 'Y')
select @materialid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Material', @rectype, 'Y')       	
select @glcoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'GLCo', @rectype, 'Y')
select @glacctid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'GLAcct', @rectype, 'Y')
select @umid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'UM', @rectype, 'Y')
select @ecmid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'ECM', @rectype, 'Y')
select @vendorgroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'VendorGroup', @rectype, 'Y')
select @supplierid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Supplier', @rectype, 'Y')
select @paytypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'PayType', @rectype, 'Y')
select @paycategoryid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'PayCategory', @rectype, 'Y')
select @miscynid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'MiscYN', @rectype, 'Y')
select @taxcodeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxCode', @rectype, 'Y')
select @taxbasisid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxBasis', @rectype, 'Y')
select @taxamtid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxAmt', @rectype, 'Y')
select @taxgroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxGroup', @rectype, 'Y')
select @taxtypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxType', @rectype, 'Y')
select @retainageid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Retainage', @rectype, 'Y')        	                  
select @discountid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Discount', @rectype, 'Y')
select @burunitcostid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'BurUnitCost', @rectype, 'Y')
select @becmid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'BECM', @rectype, 'Y')
select @smchangeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'SMChange', @rectype, 'Y')
select @smcoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'SMCo', @rectype, 'Y')
select @smworkorderid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'SMWorkOrder', @rectype, 'Y')
select @smscopeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Scope', @rectype, 'Y')
select @smcosttypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'SMCostType', @rectype, 'Y')
        	   		
/***** GET COLUMN IDENTIFIERS - Identifier will be returned regardless of 'Use Viewpoint Default' setting. *******/ 
--Header
select @headercompanyid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Co', @HeaderRecordType, 'N')
select @vendorid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Vendor', @HeaderRecordType, 'N')
select @invdateid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'InvDate', @HeaderRecordType, 'N') 
--Detail  
select @CompanyID=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Co', @rectype, 'N')			--Non-Nullable		       	        	
select @linetypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'LineType', @rectype, 'N')	--Non-Nullable

--Used to set required columns to ZERO when not otherwise set by a default. (Cleanup: See end of procedure) 
select @zunitsid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Units', @rectype, 'N')
select @zunitcostid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'UnitCost', @rectype, 'N')
select @zgrossamtid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'GrossAmt', @rectype, 'N')
select @zmiscamtid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'MiscAmt', @rectype, 'N')
select @ztaxbasisid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxBasis', @rectype, 'N')
select @ztaxamtid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxAmt', @rectype, 'N')
select @zretainageid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Retainage', @rectype, 'N')
select @zdiscountid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Discount', @rectype, 'N')
select @zburunitcostid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'BurUnitCost', @rectype, 'N')
select @zsmchangeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'SMChange', @rectype, 'N')
      
--Used to set required columns to 'N' when not otherwise set by a default. (Cleanup: See end of procedure) 
select @nmiscynid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'MiscYN', @rectype, 'N')
select @npaidynid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'PaidYN', @rectype, 'N')
        
--Used to set columns to NULL when not otherwise set by a default. (Cleanup:  Usually based upon unused LineType values)        
select @cpoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'PO', @rectype, 'N')
select @cpoitemid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'POItem', @rectype, 'N')
select @cslid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'SL', @rectype, 'N')
select @cslitemid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'SLItem', @rectype, 'N')
select @cemcoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'EMCo', @rectype, 'N')
select @cwoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'WO', @rectype, 'N')
select @cwoitemid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'WOItem', @rectype, 'N')
select @cequipid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Equip', @rectype, 'N')
select @cemgroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'EMGroup', @rectype, 'N')
select @ccostcodeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'CostCode', @rectype, 'N')
select @cemctypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'EMCType', @rectype, 'N')
select @ccomptypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'CompType', @rectype, 'N')
select @ccomponentid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Component', @rectype, 'N')
select @cjccoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'JCCo', @rectype, 'N')
select @cjobid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Job', @rectype, 'N')
--select @cphasegroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'PhaseGroup', @rectype, 'N')
select @cphaseid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Phase', @rectype, 'N')
select @cjcctypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'JCCType', @rectype, 'N')
select @cincoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'INCo', @rectype, 'N')
select @clocid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Loc', @rectype, 'N')
select @cecmid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'ECM', @rectype, 'N')
select @smjccosttype_lower=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'SMJCCostType', @rectype, 'N')
select @smphasegroup=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'SMPhaseGroup', @rectype, 'N')
        
/* Begin default process.  Different concept here.  Multiple cursor records make up a single Import record
   determined by a change in the RecSeq value.  New RecSeq signals the beginning of the next Import record. */  
declare WorkEditCursor cursor local fast_forward for
select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
from IMWE with (nolock)
inner join DDUD with (nolock) on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form 
	and	IMWE.RecordType = @rectype
Order by IMWE.RecordSeq, IMWE.Identifier
        
open WorkEditCursor
        
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
		If @Column='LineType' and isnumeric(@Uploadval) =1 select @LineType = @Uploadval
		If @Column='PO' select @PO = @Uploadval
		If @Column='POItem' and isnumeric(@Uploadval) =1 select @POItem = Convert( int, @Uploadval)
		If @Column='ItemType' select @ItemType = @Uploadval
		If @Column='SL' select @SL = @Uploadval
		If @Column='SLItem' and isnumeric(@Uploadval) =1 select @SLItem =  Convert( int, @Uploadval)
		If @Column='JCCo' and isnumeric(@Uploadval) =1 select @JCCo =  Convert( smallint, @Uploadval)
		If @Column='Job' select @Job = @Uploadval
		If @Column='PhaseGroup' and isnumeric(@Uploadval) =1 select @PhaseGroup = convert(int,@Uploadval)
		If @Column='Phase' select @Phase = @Uploadval
		If @Column='JCCType' and isnumeric(@Uploadval) =1 select @JCCType = Convert( smallint, @Uploadval)
		If @Column='EMCo' and isnumeric(@Uploadval) =1 select @EMCO = convert(smallint,@Uploadval)
		If @Column='WO' select @WO = @Uploadval
		If @Column='WOItem' and isnumeric(@Uploadval) =1  select @WOItem = convert(int,@Uploadval)
		If @Column='Equip' select @Equip = @Uploadval
		If @Column='EMGroup' and  isnumeric(@Uploadval) =1 select @EMGroup = convert(smallint,@Uploadval)
		If @Column='CostCode' select @CostCode = @Uploadval
		If @Column='EMCType' and isnumeric(@Uploadval) =1 select @EMCType = convert(smallint,@Uploadval)
		If @Column='INCo' and isnumeric(@Uploadval) =1  select @INCo = convert(smallint,@Uploadval)
		If @Column='Loc' select @Loc = @Uploadval
		If @Column='MatlGroup' and isnumeric(@Uploadval) =1  select @MatlGroup = convert(smallint,@Uploadval)
		If @Column='Material' select @Material = @Uploadval
		If @Column='GLCo' and isnumeric(@Uploadval) =1  select @GLCo = convert(smallint,@Uploadval)
		If @Column='UM' select @UM = @Uploadval
		If @Column='Units' and isnumeric(@Uploadval) =1 select @Units = convert(numeric(16,5),@Uploadval)
		If @Column='VendorGroup' and isnumeric(@Uploadval) =1 select @VendorGroup = convert(smallint,@Uploadval)
		If @Column='GrossAmt' and isnumeric(@Uploadval) =1 select @GrossAmt = Convert( numeric(16,5),@Uploadval)
		If @Column='MiscAmt' and isnumeric(@Uploadval) =1 select @MiscAmt = convert(numeric(16,5),@Uploadval) 
		If @Column='TaxGroup' and isnumeric(@Uploadval) =1 select @TaxGroup = convert(smallint,@Uploadval)
		If @Column='TaxCode' select @TaxCode = @Uploadval
		If @Column='TaxType' and isnumeric(@Uploadval) =1 select @TaxType = convert(tinyint,@Uploadval)
		If @Column='TaxBasis' and isnumeric(@Uploadval) =1 select @TaxBasis = convert(numeric(16,5),@Uploadval)
		If @Column='TaxAmt' and isnumeric(@Uploadval) =1 select @TaxAmt = Convert( numeric(16,5),@Uploadval)
		If @Column='Retainage' and isnumeric(@Uploadval) =1 select @Retainage = Convert( numeric(16,5),@Uploadval)
		If @Column='Discount' and isnumeric(@Uploadval) =1 select @Discount = Convert( numeric(16,5),@Uploadval)
		If @Column='Supplier' and isnumeric(@Uploadval) =1 select @Supplier = @Uploadval
		If @Column='PayType' and isnumeric(@Uploadval) =1 select @PayType = convert(int,@Uploadval)
		If @Column='PayCategory' and isnumeric(@Uploadval)=1 select @PayCategory=convert(int,@Uploadval)
		If @Column='ECM' select @ECM = @Uploadval
		If @Column='GLAcct' select @GLAcct = @Uploadval
		If @Column='CompType' select @CompType = @Uploadval
		If @Column='Component' select @Component = @Uploadval
		If @Column='APLine' and isnumeric(@Uploadval) =1 select @APLine = @Uploadval 
		If @Column='BurUnitCost' and isnumeric(@Uploadval) =1 select @BurUnitCost = Convert( numeric(16,5),@Uploadval)
		If @Column='BECM' and isnumeric(@Uploadval) =1 select @BECM = @Uploadval
		If @Column='SMChange' and isnumeric(@Uploadval) =1 select @SMChange = Convert( numeric(16,5), @Uploadval)
		If @Column='MiscYN' select @MiscYN = @Uploadval
		If @Column='SMCo' select @SMCo = @Uploadval
		If @Column='SMWorkOrder' select @SMWorkOrder = @Uploadval
		If @Column='Scope' select @SMScope = @Uploadval
		If @Column='SMCostType' select @SMCostType = @Uploadval
		If @Column='SMJCCostType' select @SMJCCostType = @Uploadval
		If @Column='SMPhaseGroup' select @SMPhaseGroup = @Uploadval
		
		/* UNUSED */
		--If @Column='Co' and isnumeric(@Uploadval) = 1 select @Co = Convert( int, @Uploadval)

		/* Set IsNull variable for later */
		IF @Column='APLine' 
			IF @Uploadval IS NULL
				SET @IsAPLineEmpty = 'Y'
			ELSE
				SET @IsAPLineEmpty = 'N'
		IF @Column='LineType' 
			IF @Uploadval IS NULL
				SET @IsLineTypeEmpty = 'Y'
			ELSE
				SET @IsLineTypeEmpty = 'N'
		IF @Column='ItemType' 
			IF @Uploadval IS NULL
				SET @IsItemTypeEmpty = 'Y'
			ELSE
				SET @IsItemTypeEmpty = 'N'
		IF @Column='JCCo' 
			IF @Uploadval IS NULL
				SET @IsJCCoEmpty = 'Y'
			ELSE
				SET @IsJCCoEmpty = 'N'
		IF @Column='Job' 
			IF @Uploadval IS NULL
				SET @IsJobEmpty = 'Y'
			ELSE
				SET @IsJobEmpty = 'N'
		IF @Column='PhaseGroup' 
			IF @Uploadval IS NULL
				SET @IsPhaseGroupEmpty = 'Y'
			ELSE
				SET @IsPhaseGroupEmpty = 'N'
		IF @Column='Phase' 
			IF @Uploadval IS NULL
				SET @IsPhaseEmpty = 'Y'
			ELSE
				SET @IsPhaseEmpty = 'N'
		IF @Column='JCCType' 
			IF @Uploadval IS NULL
				SET @IsJCCTypeEmpty = 'Y'
			ELSE
				SET @IsJCCTypeEmpty = 'N'
		IF @Column='EMCo' 
			IF @Uploadval IS NULL
				SET @IsEMCoEmpty = 'Y'
			ELSE
				SET @IsEMCoEmpty = 'N'
		IF @Column='WO' 
			IF @Uploadval IS NULL
				SET @IsWOEmpty = 'Y'
			ELSE
				SET @IsWOEmpty = 'N'
		IF @Column='WOItem' 
			IF @Uploadval IS NULL
				SET @IsWOItemEmpty = 'Y'
			ELSE
				SET @IsWOItemEmpty = 'N'
		IF @Column='Equip' 
			IF @Uploadval IS NULL
				SET @IsEquipEmpty = 'Y'
			ELSE
				SET @IsEquipEmpty = 'N'
		IF @Column='EMGroup' 
			IF @Uploadval IS NULL
				SET @IsEMGroupEmpty = 'Y'
			ELSE
				SET @IsEMGroupEmpty = 'N'
		IF @Column='CostCode' 
			IF @Uploadval IS NULL
				SET @IsCostCodeEmpty = 'Y'
			ELSE
				SET @IsCostCodeEmpty = 'N'
		IF @Column='EMCType' 
			IF @Uploadval IS NULL
				SET @IsEMCTypeEmpty = 'Y'
			ELSE
				SET @IsEMCTypeEmpty = 'N'
		IF @Column='CompType' 
			IF @Uploadval IS NULL
				SET @IsCompTypeEmpty = 'Y'
			ELSE
				SET @IsCompTypeEmpty = 'N'
		IF @Column='Component' 
			IF @Uploadval IS NULL
				SET @IsComponentEmpty = 'Y'
			ELSE
				SET @IsComponentEmpty = 'N'
		IF @Column='INCo' 
			IF @Uploadval IS NULL
				SET @IsINCoEmpty = 'Y'
			ELSE
				SET @IsINCoEmpty = 'N'
		IF @Column='Loc' 
			IF @Uploadval IS NULL
				SET @IsLocEmpty = 'Y'
			ELSE
				SET @IsLocEmpty = 'N'
		IF @Column='MatlGroup' 
			IF @Uploadval IS NULL
				SET @IsMatlGroupEmpty = 'Y'
			ELSE
				SET @IsMatlGroupEmpty = 'N'
		IF @Column='Material' 
			IF @Uploadval IS NULL
				SET @IsMaterialEmpty = 'Y'
			ELSE
				SET @IsMaterialEmpty = 'N'
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
		IF @Column='UM' 
			IF @Uploadval IS NULL
				SET @IsUMEmpty = 'Y'
			ELSE
				SET @IsUMEmpty = 'N'
		IF @Column='ECM' 
			IF @Uploadval IS NULL
				SET @IsECMEmpty = 'Y'
			ELSE
				SET @IsECMEmpty = 'N'
		IF @Column='VendorGroup' 
			IF @Uploadval IS NULL
				SET @IsVendorGroupEmpty = 'Y'
			ELSE
				SET @IsVendorGroupEmpty = 'N'
		IF @Column='Supplier' 
			IF @Uploadval IS NULL
				SET @IsSupplierEmpty = 'Y'
			ELSE
				SET @IsSupplierEmpty = 'N'
		IF @Column='PayType' 
			IF @Uploadval IS NULL
				SET @IsPayTypeEmpty = 'Y'
			ELSE
				SET @IsPayTypeEmpty = 'N'
		IF @Column='PayCategory' 
			IF @Uploadval IS NULL
				SET @IsPayCategoryEmpty = 'Y'
			ELSE
				SET @IsPayCategoryEmpty = 'N'
		IF @Column='MiscYN' 
			IF @Uploadval IS NULL
				SET @IsMiscYNEmpty = 'Y'
			ELSE
				SET @IsMiscYNEmpty = 'N'
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
		IF @Column='TaxType' 
			IF @Uploadval IS NULL
				SET @IsTaxTypeEmpty = 'Y'
			ELSE
				SET @IsTaxTypeEmpty = 'N'
		IF @Column='TaxBasis' 
			IF @Uploadval IS NULL
				SET @IsTaxBasisEmpty = 'Y'
			ELSE
				SET @IsTaxBasisEmpty = 'N'
		IF @Column='TaxAmt' 
			IF @Uploadval IS NULL
				SET @IsTaxAmtEmpty = 'Y'
			ELSE
				SET @IsTaxAmtEmpty = 'N'
		IF @Column='Retainage' 
			IF @Uploadval IS NULL
				SET @IsRetainageEmpty = 'Y'
			ELSE
				SET @IsRetainageEmpty = 'N'
		IF @Column='Discount' 
			IF @Uploadval IS NULL
				SET @IsDiscountEmpty = 'Y'
			ELSE
				SET @IsDiscountEmpty = 'N'
		IF @Column='BurUnitCost' 
			IF @Uploadval IS NULL
				SET @IsBurUnitCostEmpty = 'Y'
			ELSE
				SET @IsBurUnitCostEmpty = 'N'
		IF @Column='BECM' 
			IF @Uploadval IS NULL
				SET @IsBECMEmpty = 'Y'
			ELSE
				SET @IsBECMEmpty = 'N'
		IF @Column='SMChange'
			IF @Uploadval IS NULL
				SET @IsSMChangeEmpty = 'Y'
			ELSE
				SET @IsSMChangeEmpty = 'N'
		IF @Column='SMCo'
			IF @Uploadval IS NULL
				SET @IsSMCoEmpty = 'Y'
			ELSE
				SET @IsSMCoEmpty = 'N'
		IF @Column='SMWorkOrder'
			IF @Uploadval IS NULL
				SET @IsSMWorkOrderEmpty = 'Y'
			ELSE
				SET @IsSMWorkOrderEmpty = 'N'
		IF @Column='Scope'
			IF @Uploadval IS NULL
				SET @IsSMScopeEmpty = 'Y'
			ELSE
				SET @IsSMScopeEmpty = 'N'
		IF @Column='SMCostType'
			IF @Uploadval IS NULL
				SET @IsSMCostTypeEmpty = 'Y'
			ELSE
				SET @IsSMCostTypeEmpty = 'N'
		IF @Column='SMJCCostType'
			IF @Uploadval IS NULL
				SET @IsSMJCCostTypeEmpty = 'Y'
			ELSE
				SET @IsSMJCCostTypeEmpty = 'N'
		IF @Column='SMPhaseGroup'
			IF @Uploadval IS NULL
				SET @IsSMPhaseGroupEmpty = 'Y'
			ELSE
				SET @IsSMPhaseGroupEmpty = 'N'
        
		--fetch next record
		if @@fetch_status <> 0
		select @complete = 1
        
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
			and IMWE.Identifier = @headercompanyid and IMWE.RecordType = @HeaderRecordType 
			and IMWE.RecordSeq = @HeaderReqSeq

		select @Vendor=IMWE.UploadVal
		from IMWE with (nolock)
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
			and IMWE.Identifier = @vendorid and IMWE.RecordType = @HeaderRecordType 
			and IMWE.RecordSeq = @HeaderReqSeq

		/* Get HQ Company, Country value.  Company can be different from one RecSeq to another. */
		select @hqdfltcountry = h.DefaultCountry, @apcousetaxdiscyn = a.UseTaxDiscountYN,
			@taxbasisnetretgyn = TaxBasisNetRetgYN
		from APCO a with (nolock)
		join HQCO h with (nolock) on h.HQCo = a.APCo
		where a.APCo = @Co
	    
		--Co:  Non-Nullable
		if @CompanyID IS NOT NULL
			begin
			UPDATE IMWE
			SET IMWE.UploadVal = @Co		--Set same as Header
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @CompanyID and IMWE.RecordType = @rectype 
  			end
  
  		--APLine:  Non-Nullable   
		if @aplineid <> 0 AND (ISNULL(@OverwriteAPLine, 'Y') = 'Y' OR ISNULL(@IsAPLineEmpty, 'Y') = 'Y')
			begin
			select @APLine=isnull(Max(convert(int,w.UploadVal)),0)+1
			from IMWE w with (nolock)
			inner join IMWE e  with (nolock) on w.ImportTemplate=e.ImportTemplate and w.ImportId=w.ImportId
				and w.RecordType=e.RecordType and e.Identifier=@reckeyid and w.RecordSeq=e.RecordSeq
				and w.Identifier=@aplineid 
			where w.ImportTemplate=@ImportTemplate and w.ImportId=@ImportId
				and w.RecordType = @rectype and e.UploadVal = @RecKey and isnumeric(w.UploadVal) =1 

			UPDATE IMWE
			SET IMWE.UploadVal = @APLine
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @aplineid and IMWE.RecordType = @rectype
			end 		
  					     
 		--VendorGroup  
		if @vendorgroupid <> 0 and isnull(@Co,'')<> '' AND (ISNULL(@OverwriteVendorGroup, 'Y') = 'Y' OR ISNULL(@IsVendorGroupEmpty, 'Y') = 'Y')
			begin
			select @VendorGroup = VendorGroup
			from HQCO with (nolock)
			where HQCo = @Co

			UPDATE IMWE
			SET IMWE.UploadVal = @VendorGroup
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @vendorgroupid and IMWE.RecordType = @rectype
			end
 
   		--LineType:  Non-Nullable    
		if @linetypeid <> 0 AND (ISNULL(@OverwriteLineType, 'Y') = 'Y' OR ISNULL(@IsLineTypeEmpty, 'Y') = 'Y')
			begin
			 -- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract1  
			If isnull(@PO,'') <> '' select @VPLineType = 6
			If isnull(@SL,'') <> '' select @VPLineType = 7
			If isnull(@WO,'') <> '' select @VPLineType = 5
			If isnull(@Equip,'') <> '' and isnull(@WO,'') = '' and isnull(@PO,'') = '' select @VPLineType = 4
			If isnull(@Loc,'') <> '' and isnull(@PO,'') = '' select @VPLineType = 2
			If isnull(@Job,'') <> '' and isnull(@PO,'') = '' and isnull(@SL,'') = '' select @VPLineType = 1
			If isnull(@VPLineType,'') = '' select @VPLineType = 3
			select @LineType = @VPLineType

			UPDATE IMWE
			SET IMWE.UploadVal = @LineType
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @linetypeid and IMWE.RecordType = @rectype
			end
        
		--ItemType
		if @itemtypeid <> 0 AND (ISNULL(@OverwriteItemType, 'Y') = 'Y' OR ISNULL(@IsItemTypeEmpty, 'Y') = 'Y')
			begin
			select @ItemType = null
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType = 6 select @ItemType = ItemType from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem

			UPDATE IMWE
			SET IMWE.UploadVal = @ItemType
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @itemtypeid and IMWE.RecordType = @rectype
			end
  
        --JCCo
		if @jccooid <> 0 AND (ISNULL(@OverwriteJCCo, 'Y') = 'Y' OR ISNULL(@IsJCCoEmpty, 'Y') = 'Y')
			begin
			if @LineType = 1 select @JCCo = @Co
			if @LineType = 6 and @ItemType = 1 select @JCCo = PostToCo from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem
			if @LineType = 7 select @JCCo = JCCo from SLIT with (nolock) where SLCo = @Co and SL = @SL and SLItem = @SLItem

			UPDATE IMWE
			SET IMWE.UploadVal = @JCCo
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @jccooid and IMWE.RecordType = @rectype
			end
        
        --Job
		if @jobid <> 0 AND (ISNULL(@OverwriteJob, 'Y') = 'Y' OR ISNULL(@IsJobEmpty, 'Y') = 'Y')
			begin
			if @LineType = 6 and @ItemType = 1 select @Job = Job from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem
			if @LineType = 7 select @Job = Job from SLIT with (nolock) where SLCo = @Co and SL = @SL and SLItem = @SLItem

			UPDATE IMWE
			SET IMWE.UploadVal = @Job
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @jobid and IMWE.RecordType = @rectype
			end
        
        --PhaseGroup
		if @phasegroupid <> 0 AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y' OR ISNULL(@IsPhaseGroupEmpty, 'Y') = 'Y')
			begin
			select @PhaseGroup = PhaseGroup from HQCO with (nolock) where HQCo = @Co
			if isnull(@JCCo,'') <> '' select @PhaseGroup = PhaseGroup from HQCO with (nolock) where HQCo = @JCCo

			UPDATE IMWE
			SET IMWE.UploadVal = @PhaseGroup
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @phasegroupid and IMWE.RecordType = @rectype
			end
        
        --Phase
		if @Phaseid <> 0 AND (ISNULL(@OverwritePhase, 'Y') = 'Y' OR ISNULL(@IsPhaseEmpty, 'Y') = 'Y') 
			begin
			if @LineType = 6 and @ItemType = 1  select @Phase = Phase from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem
			if @LineType = 7 select @Phase = Phase from SLIT with (nolock) where SLCo = @Co and SL = @SL and SLItem = @SLItem

			UPDATE IMWE
			SET IMWE.UploadVal = @Phase
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @Phaseid and IMWE.RecordType = @rectype
			end
       
		--JCCostType 
		if @jcctypeid <> 0 AND (ISNULL(@OverwriteJCCType, 'Y') = 'Y' OR ISNULL(@IsJCCTypeEmpty, 'Y') = 'Y')
			begin
			if @LineType = 6 and @ItemType = 1  select @JCCType = JCCType from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem
			if @LineType = 7 select @JCCType = JCCType from SLIT with (nolock) where SLCo = @Co and SL = @SL and SLItem = @SLItem

			UPDATE IMWE
			SET IMWE.UploadVal = @JCCType
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @jcctypeid and IMWE.RecordType = @rectype
			end
        
		--EMCo
		if @emcoid <> 0 AND (ISNULL(@OverwriteEMCo, 'Y') = 'Y' OR ISNULL(@IsEMCoEmpty, 'Y') = 'Y') 
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType = 4 or @LineType = 5 select @EMCO = @Co
			if @LineType = 6 and (@ItemType = 4 or @ItemType = 5) select @EMCO = PostToCo from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem

			UPDATE IMWE
			SET IMWE.UploadVal = @EMCO
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @emcoid and IMWE.RecordType = @rectype
			end
 
		--WO
		if @woid <> 0 AND (ISNULL(@OverwriteWO, 'Y') = 'Y' OR ISNULL(@IsWOEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType = 6 and @ItemType = 5 select @WO = WO from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem

			UPDATE IMWE
			SET IMWE.UploadVal = @WO
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @woid and IMWE.RecordType = @rectype
			end
        
		--WOItem
		if @woitemid <> 0 AND (ISNULL(@OverwriteWOItem, 'Y') = 'Y' OR ISNULL(@IsWOItemEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType = 6 and @ItemType = 5 select @WOItem = WOItem from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem

			UPDATE IMWE
			SET IMWE.UploadVal = @WOItem
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @woitemid and IMWE.RecordType = @rectype
			end

		--Equip         
		if @equipid <> 0 AND (ISNULL(@OverwriteEquip, 'Y') = 'Y' OR ISNULL(@IsEquipEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType = 5 select @Equip = Equipment from EMWH with (nolock) where EMCo = @EMCO and WorkOrder = @WO
			if @LineType = 6 and (@ItemType = 4 or @ItemType = 5) select @Equip = Equip from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem

			UPDATE IMWE
			SET IMWE.UploadVal = @Equip
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @equipid and IMWE.RecordType = @rectype
			end
 
		--EMGroup       
		if @emgroupid <> 0 AND (ISNULL(@OverwriteEMGroup, 'Y') = 'Y' OR ISNULL(@IsEMGroupEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType = 4 or @LineType = 5  or (@LineType = 6 and (@ItemType = 4 or @ItemType = 5)) select @EMGroup = EMGroup from HQCO with (nolock) where HQCo = @EMCO

			UPDATE IMWE
			SET IMWE.UploadVal = @EMGroup
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @emgroupid and IMWE.RecordType = @rectype
			end
 
		--CostCode       
		if @costcodeid <> 0 AND (ISNULL(@OverwriteCostCode, 'Y') = 'Y' OR ISNULL(@IsCostCodeEmpty, 'Y') = 'Y')	 
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType = 5 select @CostCode = CostCode from EMWI with (nolock) where EMCo = @EMCO and WorkOrder = @WO and WOItem = @WOItem
			if @LineType = 6 and (@ItemType = 4 or @ItemType = 5) select @CostCode = CostCode from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem

			UPDATE IMWE
			SET IMWE.UploadVal = @CostCode
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @costcodeid and IMWE.RecordType = @rectype
			end
  
		--EMCostType      
		if @emctypeid <> 0  AND (ISNULL(@OverwriteEMCType, 'Y') = 'Y' OR ISNULL(@IsEMCTypeEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			--if @LineType = 5 select @EMCType = CostCode from bEMWI where EMCo = @EMCO and WorkOrder = @WO and WOItem = @WOItem
			if @LineType = 6 and (@ItemType = 4 or @ItemType = 5) select @EMCType = EMCType from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem

			UPDATE IMWE
			SET IMWE.UploadVal = @EMCType
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @emctypeid and IMWE.RecordType = @rectype
			end
  
		--CompType      
		if @comptypeid <> 0 AND (ISNULL(@OverwriteCompType, 'Y') = 'Y' OR ISNULL(@IsCompTypeEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType = 5 select @CompType = ComponentTypeCode from EMWI with (nolock) where EMCo = @EMCO and WorkOrder = @WO and WOItem = @WOItem
			if @LineType = 6 and (@ItemType = 4 or @ItemType = 5) select @CompType = CompType from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem

			UPDATE IMWE
			SET IMWE.UploadVal = @CompType
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @comptypeid and IMWE.RecordType = @rectype
			end
    
		--Component    
		if @componentid <> 0 AND (ISNULL(@OverwriteComponent, 'Y') = 'Y' OR ISNULL(@IsComponentEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType = 5 select @Component = Component from EMWI with (nolock) where EMCo = @EMCO and WorkOrder = @WO and WOItem = @WOItem
			if @LineType = 6 and (@ItemType = 4 or @ItemType = 5) select @Component = Component from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem

			UPDATE IMWE
			SET IMWE.UploadVal = @Component
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @componentid and IMWE.RecordType = @rectype
			end
        
        --INCo
		if @incoid <> 0  AND (ISNULL(@OverwriteINCo, 'Y') = 'Y' OR ISNULL(@IsINCoEmpty, 'Y') = 'Y') 
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType = 2 select @INCo = @Co
			if @LineType = 6 and @ItemType = 2 select @INCo = PostToCo from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem

			UPDATE IMWE
			SET IMWE.UploadVal = @INCo
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @incoid and IMWE.RecordType = @rectype
			end
   
		--Loc     
		if @locid <> 0 AND (ISNULL(@OverwriteLoc, 'Y') = 'Y' OR ISNULL(@IsLocEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType = 6 and @ItemType = 2 select @Loc = Loc from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem

			UPDATE IMWE
			SET IMWE.UploadVal = @Loc
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @locid and IMWE.RecordType = @rectype
			end
       
		--MatlGroup 
		if @matlgroupid <> 0 AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'Y' OR ISNULL(@IsMatlGroupEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			select @MatlGroup = MatlGroup from HQCO with (nolock) where HQCo = @Co
			---- #133555
			if isnull(@INCo,'') <> '' select @MatlGroup = MatlGroup from HQCO with (nolock) where HQCo = @INCo
			if isnull(@JCCo,'') <> '' select @MatlGroup = MatlGroup from HQCO with (nolock) where HQCo = @JCCo
			
			UPDATE IMWE
			SET IMWE.UploadVal = @MatlGroup
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @matlgroupid and IMWE.RecordType = @rectype
			end

		--Material        
		if @materialid <> 0 AND (ISNULL(@OverwriteMaterial, 'Y') = 'Y' OR ISNULL(@IsMaterialEmpty, 'Y') = 'Y')
 			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType = 6 select @Material = Material from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem

			UPDATE IMWE
			SET IMWE.UploadVal = @Material
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @materialid and IMWE.RecordType = @rectype
			end
  
		--Supplier      
		if @supplierid <> 0 and isnull(@Co,'')<> '' AND (ISNULL(@OverwriteSupplier, 'Y') = 'Y' OR ISNULL(@IsSupplierEmpty, 'Y') = 'Y')
 			begin
			if @LineType = 7 select @Supplier = Supplier from SLIT with (nolock) where SLCo = @Co and SL = @SL and SLItem = @SLItem

			UPDATE IMWE
			SET IMWE.UploadVal = @Supplier
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @supplierid and IMWE.RecordType = @rectype
			end
  
		--GLCo      
		if @glcoid <> 0 AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType = 1 select @GLCo = GLCo from JCCO with (nolock) where JCCo = @JCCo
			if @LineType = 2 select @GLCo = GLCo from INCO with (nolock) where INCo = @INCo
			if @LineType = 3 select @GLCo = GLCo from APCO with (nolock) where APCo = @Co
			if @LineType = 4 or @LineType = 5 select @GLCo = GLCo from EMCO with (nolock) where EMCo = @EMCO
			if @LineType = 6 select @GLCo = GLCo from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem
			if @LineType = 7 select @GLCo = GLCo from SLIT with (nolock) where SLCo = @Co and SL = @SL and SLItem = @SLItem
			if @LineType = 8 select @GLCo = GLCo from SMCO with (nolock) where SMCo = @SMCo

			UPDATE IMWE
			SET IMWE.UploadVal = @GLCo
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @glcoid and IMWE.RecordType = @rectype
			end
 
		--GLAcct       
		if @glacctid <> 0 AND (ISNULL(@OverwriteGLAcct, 'Y') = 'Y' OR ISNULL(@IsGLAcctEmpty, 'Y') = 'Y') 
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
  			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
        
   			--#29620, IF statements fixed.
   			if @LineType = 1 
				begin
				select @GLCo = GLCo from JCCO with (nolock) where JCCo = @JCCo 
				exec @recode =  bspJCCAGlacctDflt @JCCo, @Job, @PhaseGroup, @Phase, @JCCType, 'N', @GLAcct output, @errmsg output
				end

			if @LineType = 2  
				begin
				select @GLCo = GLCo from INCO with (nolock) where INCo = @INCo
				select @filler = null
				exec @recode =  bspINGlacctDflt @INCo, @Loc, @Material, @MatlGroup, @GLAcct output, @filler output, @errmsg output
				end

			if @LineType = 3 
				begin
				select @GLCo = GLCo from APCO with (nolock) where APCo = @Co
				exec @recode =  bspAPGlacctDflt @VendorGroup, @Vendor, @MatlGroup, @Material, @GLAcct output, @errmsg output
				end

			if @LineType = 4 or @LineType = 5 
				begin
				select @GLCo = GLCo from EMCO with (nolock) where EMCo = @EMCO
				exec @recode =  bspEMCostTypeValForCostCodeUM @EMCO, @EMGroup, @EMCType, @CostCode, @Equip, @costtypeout output, @GLAcct output, @umout output, @errmsg output
				end

			if @LineType = 6 select @GLAcct = GLAcct from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem
			if @LineType = 7 select @GLAcct = GLAcct from SLIT with (nolock) where SLCo = @Co and SL = @SL and SLItem = @SLItem
			if @LineType = 8 
				BEGIN
				DECLARE @Temp varchar(10), @TempGLCo int
				exec @recode = vspAPGLAcctDefaultGet @linetype=@LineType, @co=@Co, @smco=@SMCo, @smworkorder=@SMWorkOrder, @smscope=@SMScope, @smcosttype=@SMCostType, @smglco=@TempGLCo OUTPUT, @glacct=@GLAcct OUTPUT, @msg=@errmsg OUTPUT, @reviewergroup=@Temp OUTPUT
				END

			UPDATE IMWE
			SET IMWE.UploadVal = @GLAcct
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @glacctid and IMWE.RecordType = @rectype			       		end
   
		--UM     
		if @umid <> 0 AND (ISNULL(@OverwriteUM, 'Y') = 'Y' OR ISNULL(@IsUMEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType < 6  and isnull(@Material,'') <> ''
				select @UM = PurchaseUM from HQMT with (nolock) where MatlGroup = @MatlGroup and Material = @Material

			if @LineType = 1 
				begin
				if isnull(@Units,0)<> 0 
					select @UM = isnull(UM,'LS') 
					from JCCH with (nolock)
					where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@JCCType
				else
					select @UM = 'LS'
				end

			if @LineType = 6 select @UM = UM from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem
			if @LineType = 7 select @UM = UM from SLIT with (nolock) where SLCo = @Co and SL = @SL and SLItem = @SLItem
			if @LineType = 8 select @UM = 'LS'

			UPDATE IMWE
			SET IMWE.UploadVal = @UM
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @umid and IMWE.RecordType = @rectype
			end
        
		--issue #27477, fix ECM default
		--ECM
		if @ecmid <> 0  AND (ISNULL(@OverwriteECM, 'Y') = 'Y' OR ISNULL(@IsECMEmpty, 'Y') = 'Y')
			begin
 			select @ECM = null
 			if @UM <> 'LS' 
 				begin
 				exec @recode = bspHQMatUnitCostDflt @VendorGroup, @Vendor, @MatlGroup, @Material, @UM, @JCCo, @Job, @INCo, @Loc,
 					null, @ECM output, null, @msg output
 
 				if @recode <> 0 
 					begin
 					insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
 					values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@ecmid)			
 			
 					select @rcode = 1
 					select @desc = @msg
 					end
 				end
		   
			UPDATE IMWE
			SET IMWE.UploadVal = @ECM
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @ecmid and IMWE.RecordType = @rectype
			end
        
		--PayType   
		--issue #27364, Redo paytype default and add PayCategory default.
  		select @defexppaytype = null, @defjobpaytype = null, @defsubpaytype = null, @defsmpaytype = null,
  			@defretpaytype = null, @defdiscoffglact = null, @defdisctakenglacct = null, @defpaycategory = null 
      
		exec @recode = dbo.bspAPPayTypeGet @Co, SUSER_SNAME, @defexppaytype output, @defjobpaytype output, 
      		@defsmpaytype output, @defsubpaytype output, @defretpaytype output, @defdiscoffglact output,
      		@defdisctakenglacct output, @defpaycategory output, @msg output
      
		if @paytypeid <> 0 and @LineType is not null AND (ISNULL(@OverwritePayType, 'Y') = 'Y' OR ISNULL(@IsPayTypeEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job, 2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract, 8=SM
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType = 1 select @PayType = @defjobpaytype
			if @LineType > 1 and @LineType < 6 select @PayType = @defexppaytype
			if @LineType = 6
				begin
				if isnull(@ItemType,0) = 1 select @PayType = @defjobpaytype
				else if isnull(@ItemType,0) = 6 select @PayType = @defsmpaytype
					else select @PayType = @defexppaytype
				end
			if @LineType = 7 select @PayType = @defsubpaytype
			if @LineType = 8 select @PayType = @defsmpaytype
			
			UPDATE IMWE
			SET IMWE.UploadVal = @PayType
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @paytypeid and IMWE.RecordType = @rectype
			end
		
		--PayCategory     
  		if @paycategoryid <> 0 and @defpaycategory is not null  AND (ISNULL(@OverwritePayCategory, 'Y') = 'Y' OR ISNULL(@IsPayCategoryEmpty, 'Y') = 'Y')
  			begin
  			select @PayCategory = @defpaycategory
  
			UPDATE IMWE
			SET IMWE.UploadVal = @PayCategory
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @paycategoryid and IMWE.RecordType = @rectype
  			end

		--Retainage        
		if @retainageid <> 0 and @LineType=7 and isnull(@Co,'')<> '' AND (ISNULL(@OverwriteRetainage, 'Y') = 'Y' OR ISNULL(@IsRetainageEmpty, 'Y') = 'Y') 
			begin
			select @WCRetPct = WCRetPct from SLIT with (nolock) where SLCo = @Co and SL = @SL and SLItem = @SLItem
			select @Retainage = isnull(@WCRetPct,0) * isnull(@GrossAmt,0)

			UPDATE IMWE
			SET IMWE.UploadVal = @Retainage
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @retainageid and IMWE.RecordType = @rectype
			end
  
		--Discount
  		if @discountid <> 0	AND (ISNULL(@OverwriteDiscount, 'Y') = 'Y' OR ISNULL(@IsDiscountEmpty, 'Y') = 'Y') 	--issue #29626
  			begin
  			select @payterms = PayTerms 
  			from APVM with (nolock) 
   			where VendorGroup = @VendorGroup and Vendor = @Vendor

			select @discrate = 0, @Discount = 0 
			if isnull(@payterms,'') <> '' 
				begin
  				exec @recode = bspHQPayTermsVal @payterms, 'N', @discrate output, @msg output
  				if @recode <> 0
  					begin
  					insert into IMWM(ImportId,ImportTemplate,Form,RecordSeq,Error,Message,Identifier)
  					values(@ImportId,@ImportTemplate,@Form,@currrecseq,@recode,@msg,@ecmid)			
		  		
  					select @rcode = 1
  					select @desc = @msg
  					end
  				else
  					begin
  					select @Discount = (isnull(@GrossAmt,0) - isnull(@Retainage,0)) * @discrate
					end
				end
  				
			UPDATE IMWE
      		SET IMWE.UploadVal = @Discount
      		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
      			and IMWE.Identifier = @discountid and IMWE.RecordType = @rectype
			end

		--TaxCode
		--Issue #138559 - Same code but moved before TaxType & TaxGroup     
		if @taxcodeid <> 0 AND (ISNULL(@OverwriteTaxCode, 'Y') = 'Y' OR ISNULL(@IsTaxCodeEmpty, 'Y') = 'Y') 
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			if @LineType = 1 select @TaxCode = TaxCode from JCJM with (nolock) where JCCo = @JCCo and Job = @Job
			if @LineType = 2 select @TaxCode = TaxCode from INLM with (nolock) where INCo = @INCo and Loc = @Loc
			if @LineType > 2 and @LineType < 6 select @TaxCode = TaxCode from APVM with (nolock) where VendorGroup = @VendorGroup and Vendor = @Vendor
			if @LineType = 6 select @TaxCode = TaxCode from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem
			if @LineType = 7 select @TaxCode = TaxCode from SLIT with (nolock) where SLCo = @Co and SL = @SL and SLItem = @SLItem
			
			UPDATE IMWE
			SET IMWE.UploadVal = @TaxCode
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @taxcodeid and IMWE.RecordType = @rectype
			end
						 
		--TaxType 	
		--No sense setting TaxType default without a TaxCode value.  TaxCode has come from either the Imported Value
		--or from the default logic above.	
		--Issue #138559 - Use LineTaxType if available else use TaxType based on Culture		      
		if @taxtypeid <> 0  AND (ISNULL(@OverwriteTaxType, 'Y') = 'Y' OR ISNULL(@IsTaxTypeEmpty, 'Y') = 'Y')
			begin
			select @LineTaxType = null
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			select @TaxType = case when isnull(@hqdfltcountry, 'US') = 'US' then 1 else 3 end
			if @LineType = 6 select @LineTaxType = TaxType from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem
			if @LineType = 7 select @LineTaxType = TaxType from SLIT with (nolock) where SLCo = @Co and SL = @SL and SLItem = @SLItem 

			if isnull(@TaxCode, '') = '' select @TaxType = null else select @TaxType = isnull(@LineTaxType, @TaxType)
			
			UPDATE IMWE
			SET IMWE.UploadVal = @TaxType
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @taxtypeid and IMWE.RecordType = @rectype
			end

		--TaxGroup 
		--Default a TaxGroup regardless of a TaxCode.  User may go into AP Entry batch later and attempt to 
		--add TaxType and TaxCode. 
		--Issue #138559 - Fix this issue where TaxGroup was not defaulting because Line TaxGroup was null.   
		if @taxgroupid <> 0 AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'Y' OR ISNULL(@IsTaxGroupEmpty, 'Y') = 'Y')
			begin
			select @LineTaxGroup = null
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
			select @TaxGroup = TaxGroup from HQCO with (nolock) where HQCo = @Co
			If isnull(@TaxType, 255) = 2
				begin
				if @LineType = 1 select @TaxGroup = TaxGroup from HQCO with (nolock) where HQCo = @JCCo
				if @LineType = 2 select @TaxGroup = TaxGroup from HQCO with (nolock) where HQCo = @INCo
				if @LineType = 3 select @TaxGroup = TaxGroup from HQCO with (nolock) where HQCo = @GLCo
				if @LineType = 4 or @LineType = 5 select @TaxGroup = TaxGroup from HQCO with (nolock) where HQCo = @EMCO
				end
			if @LineType = 6 select @LineTaxGroup = TaxGroup from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem
			if @LineType = 7 select @LineTaxGroup = TaxGroup from SLIT with (nolock) where SLCo = @Co and SL = @SL and SLItem = @SLItem	
			
			select @TaxGroup = isnull(@LineTaxGroup, @TaxGroup)
			
			UPDATE IMWE
			SET IMWE.UploadVal = @TaxGroup
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @taxgroupid and IMWE.RecordType = @rectype
			end
        
		--TaxBasis
		if @taxbasisid <> 0  AND (ISNULL(@OverwriteTaxBasis, 'Y') = 'Y' OR ISNULL(@IsTaxBasisEmpty, 'Y') = 'Y') 
			begin
			If isnull(@TaxCode,'') = ''
				select @TaxBasis = 0
			else
				if @apcousetaxdiscyn = 'N'
					if @taxbasisnetretgyn = 'Y'
						select @TaxBasis = isnull(@GrossAmt,0) - isnull(@Retainage,0)
					else
						select @TaxBasis = isnull(@GrossAmt,0)
				else
					select @TaxBasis = isnull(@GrossAmt,0) - isnull(@Discount,0) 

			UPDATE IMWE
			SET IMWE.UploadVal = @TaxBasis
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @taxbasisid and IMWE.RecordType = @rectype
			end
        
		--TaxAmount      
		if @taxamtid <> 0 AND (ISNULL(@OverwriteTaxAmt, 'Y') = 'Y' OR ISNULL(@IsTaxAmtEmpty, 'Y') = 'Y')
			begin
			If isnull(@TaxCode,'') = ''
				select @TaxAmt = 0
			else
				begin
				select @filler = null
				select @InvDate=convert(smalldatetime,IMWE.UploadVal)
				from IMWE with (nolock) 
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
					and IMWE.Identifier = @invdateid and IMWE.RecordType = @HeaderRecordType 
					and IMWE.RecordSeq = @HeaderReqSeq

				exec @recode =  bspHQTaxRateGet @TaxGroup, @TaxCode, @InvDate, @taxrate output, @filler output, @filler output, @errmsg output
				select @TaxAmt = isnull(@taxrate,0) * isnull(@TaxBasis,0)
				end
        
    			UPDATE IMWE
    			SET IMWE.UploadVal = @TaxAmt
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
        			and IMWE.Identifier = @taxamtid and IMWE.RecordType = @rectype
        		end
  
		--MiscYN      
    	if @miscynid <> 0  AND (ISNULL(@OverwriteMiscYN, 'Y') = 'Y' OR ISNULL(@IsMiscYNEmpty, 'Y') = 'Y')
     		begin
       		select @MiscYN = 'Y'
    
    		UPDATE IMWE
    		SET IMWE.UploadVal = @MiscYN
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier = @miscynid and IMWE.RecordType = @rectype
    		end
      
		--Burden UnitCost
      	if @burunitcostid <> 0 AND (ISNULL(@OverwriteBurUnitCost, 'Y') = 'Y' OR ISNULL(@IsBurUnitCostEmpty, 'Y') = 'Y')
    		begin
    		select @BurUnitCost = 0
    
    		if @LineType = 2 or (@LineType = 6 and @ItemType = 2)
    			begin
    			select @burdenyn = BurdenCost
    			from INCO with (nolock) where INCo = @INCo
    			if @burdenyn = 'Y' and isnull(@Units,0)<>0
    				begin
    				select @netamtopt = NetAmtOpt
    				from APCO with (nolock) where APCo = @Co
    				if @netamtopt = 'Y'
    					select @BurUnitCost = (isnull(@GrossAmt,0) + isnull(@MiscAmt,0) - isnull(@TaxAmt,0)) / @Units
    				else
    					select @BurUnitCost = ((isnull(@GrossAmt,0) + isnull(@MiscAmt,0)) - (isnull(@TaxAmt,0) + isnull(@Discount,0))) / @Units
    				end
        		end
        
    		UPDATE IMWE
    		SET IMWE.UploadVal = @BurUnitCost
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier = @burunitcostid and IMWE.RecordType = @rectype
        	end
  
		--Burden ECM      
    	if @becmid <> 0  AND (ISNULL(@OverwriteBECM, 'Y') = 'Y' OR ISNULL(@IsBECMEmpty, 'Y') = 'Y') 
    		begin
       		select @BECM = 'E'
    
    		UPDATE IMWE
    		SET IMWE.UploadVal = @BECM
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier = @becmid and IMWE.RecordType = @rectype
    		end
  
		--SMChange      
		if @smchangeid <> 0 AND (ISNULL(@OverwriteSMChange, 'Y') = 'Y' OR ISNULL(@IsSMChangeEmpty, 'Y') = 'Y') 
        	begin
       		select @SMChange = 0
    
    		UPDATE IMWE
    		SET IMWE.UploadVal = @SMChange
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier = @smchangeid and IMWE.RecordType = @rectype
        	end
        	
   
		-- SMCo
		if @smcoid <> 0 AND (ISNULL(@OverwriteSMCo, 'Y') = 'Y' OR ISNULL(@IsSMCoEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract, 8=SMCo
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order, 6=SM Work Order
			if @LineType = 6 AND @ItemType=6
				BEGIN
				select @SMCo = SMCo from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem
				
				UPDATE IMWE
				SET IMWE.UploadVal = @SMCo
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @smcoid and IMWE.RecordType = @rectype
				END
			end
		
		-- SM Work Order
		if @smworkorderid <> 0 AND (ISNULL(@OverwriteSMWorkOrder, 'Y') = 'Y' OR ISNULL(@IsSMWorkOrderEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract, 8=SMCo
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order, 6=SM Work Order
			if @LineType = 6 AND @ItemType=6
				BEGIN
				select @SMWorkOrder = SMWorkOrder from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem

				UPDATE IMWE
				SET IMWE.UploadVal = @SMWorkOrder
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @smworkorderid and IMWE.RecordType = @rectype
				END				
			end
		
		-- SM Scope
		if @smscopeid <> 0 AND (ISNULL(@OverwriteSMScope, 'Y') = 'Y' OR ISNULL(@IsSMScopeEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract, 8=SMCo
			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order, 6=SM Work Order
			if @LineType = 6 AND @ItemType=6
				BEGIN
				select @SMScope = SMScope from POIT with (nolock) where POCo = @Co and PO = @PO and POItem = @POItem

				UPDATE IMWE
				SET IMWE.UploadVal = @SMScope
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @smscopeid and IMWE.RecordType = @rectype
				END				
			END
			
		-- SM JC Cost Type
		if @smjccosttype_lower <> 0 AND (ISNULL(@OverwriteSMJCCostType, 'Y') = 'Y' OR ISNULL(@IsSMJCCostTypeEmpty, 'Y') = 'Y')
			begin
			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract, 8=SMCo
			if @LineType = 8
				BEGIN
				
				SELECT @SMJCCostType = JCCostType, @SMPhaseGroup = PhaseGroup
				FROM dbo.SMCostType 
				WHERE SMCo = @SMCo 
					AND SMCostType = @SMCostType
				
				UPDATE IMWE
				SET IMWE.UploadVal = @SMJCCostType
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @smjccosttype_lower and IMWE.RecordType = @rectype
				
				UPDATE IMWE
				SET IMWE.UploadVal = @SMPhaseGroup
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @smphasegroup and IMWE.RecordType = @rectype
				END	
			end
        
  
    	-- Clean up columns based on linetype
    	-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
    	if @LineType = 1
    		begin 
			UPDATE IMWE
			SET IMWE.UploadVal = null
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
				(IMWE.Identifier = @cpoid or IMWE.Identifier = @cpoitemid or IMWE.Identifier = @cslid or IMWE.Identifier = @cslitemid
				or IMWE.Identifier = @cemcoid or IMWE.Identifier = @cwoid or IMWE.Identifier = @cwoitemid or IMWE.Identifier = @cequipid
				or IMWE.Identifier = @cemgroupid or IMWE.Identifier = @ccostcodeid or IMWE.Identifier = @cemctypeid or IMWE.Identifier = @ccomptypeid
				or IMWE.Identifier = @ccomponentid or IMWE.Identifier = @cincoid or IMWE.Identifier = @clocid)
    		end
        
    	if @LineType = 2
    		begin 
			UPDATE IMWE
			SET IMWE.UploadVal = null
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
				(IMWE.Identifier = @cpoid or IMWE.Identifier = @cpoitemid or IMWE.Identifier = @cslid or IMWE.Identifier = @cslitemid
				or IMWE.Identifier = @cemcoid or IMWE.Identifier = @cwoid or IMWE.Identifier = @cwoitemid or IMWE.Identifier = @cequipid
				or IMWE.Identifier = @cemgroupid or IMWE.Identifier = @ccostcodeid or IMWE.Identifier = @cemctypeid or IMWE.Identifier = @ccomptypeid
				or IMWE.Identifier = @ccomponentid or IMWE.Identifier = @cjccoid or IMWE.Identifier = @cjobid
				or IMWE.Identifier = @cphasegroupid or IMWE.Identifier = @cphaseid or IMWE.Identifier = @cjcctypeid)
    		end
        
    	if @LineType = 3
    		begin 
			UPDATE IMWE
			SET IMWE.UploadVal = null
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
				(IMWE.Identifier = @cpoid or IMWE.Identifier = @cpoitemid or IMWE.Identifier = @cslid or IMWE.Identifier = @cslitemid
				or IMWE.Identifier = @cemcoid or IMWE.Identifier = @cwoid or IMWE.Identifier = @cwoitemid or IMWE.Identifier = @cequipid
				or IMWE.Identifier = @cemgroupid or IMWE.Identifier = @ccostcodeid or IMWE.Identifier = @cemctypeid or IMWE.Identifier = @ccomptypeid
				or IMWE.Identifier = @ccomponentid or IMWE.Identifier = @cjccoid or IMWE.Identifier = @cjobid
				or IMWE.Identifier = @cphasegroupid or IMWE.Identifier = @cphaseid or IMWE.Identifier = @cjcctypeid
				or IMWE.Identifier = @cincoid or IMWE.Identifier = @clocid)
    		end
        
    	if @LineType = 4
    		begin 
			UPDATE IMWE
			SET IMWE.UploadVal = null
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
				(IMWE.Identifier = @cpoid or IMWE.Identifier = @cpoitemid or IMWE.Identifier = @cslid or IMWE.Identifier = @cslitemid
				or IMWE.Identifier = @cwoid or IMWE.Identifier = @cwoitemid
				or IMWE.Identifier = @cjccoid or IMWE.Identifier = @cjobid
				or IMWE.Identifier = @cphasegroupid or IMWE.Identifier = @cphaseid or IMWE.Identifier = @cjcctypeid
				or IMWE.Identifier = @cincoid or IMWE.Identifier = @clocid)
    		end
        
    	if @LineType = 5
    		begin 
			UPDATE IMWE
			SET IMWE.UploadVal = null
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
				(IMWE.Identifier = @cpoid or IMWE.Identifier = @cpoitemid or IMWE.Identifier = @cslid or IMWE.Identifier = @cslitemid
				or IMWE.Identifier = @cjccoid or IMWE.Identifier = @cjobid
				or IMWE.Identifier = @cphasegroupid or IMWE.Identifier = @cphaseid or IMWE.Identifier = @cjcctypeid
				or IMWE.Identifier = @cincoid or IMWE.Identifier = @clocid)
    		end
        
    	if @LineType = 7
    		begin 
			UPDATE IMWE
			SET IMWE.UploadVal = null
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
				(IMWE.Identifier = @cpoid or IMWE.Identifier = @cpoitemid
				or IMWE.Identifier = @cemcoid or IMWE.Identifier = @cwoid or IMWE.Identifier = @cwoitemid or IMWE.Identifier = @cequipid
				or IMWE.Identifier = @cemgroupid or IMWE.Identifier = @ccostcodeid or IMWE.Identifier = @cemctypeid or IMWE.Identifier = @ccomptypeid
				or IMWE.Identifier = @ccomponentid or IMWE.Identifier = @cincoid or IMWE.Identifier = @clocid)
    		end
        
    	-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
    	if @LineType = 6 and @ItemType = 1
    		begin 
			UPDATE IMWE
			SET IMWE.UploadVal = null
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
				(IMWE.Identifier = @cslid or IMWE.Identifier = @cslitemid
				or IMWE.Identifier = @cemcoid or IMWE.Identifier = @cwoid or IMWE.Identifier = @cwoitemid or IMWE.Identifier = @cequipid
				or IMWE.Identifier = @cemgroupid or IMWE.Identifier = @ccostcodeid or IMWE.Identifier = @cemctypeid or IMWE.Identifier = @ccomptypeid
				or IMWE.Identifier = @ccomponentid or IMWE.Identifier = @cincoid or IMWE.Identifier = @clocid)
    		end
    
    	if @LineType = 6 and @ItemType = 2
    		begin 
			UPDATE IMWE
			SET IMWE.UploadVal = null
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
				(IMWE.Identifier = @cslid or IMWE.Identifier = @cslitemid
				or IMWE.Identifier = @cemcoid or IMWE.Identifier = @cwoid or IMWE.Identifier = @cwoitemid or IMWE.Identifier = @cequipid
				or IMWE.Identifier = @cemgroupid or IMWE.Identifier = @ccostcodeid or IMWE.Identifier = @cemctypeid or IMWE.Identifier = @ccomptypeid
				or IMWE.Identifier = @ccomponentid or IMWE.Identifier = @cjccoid or IMWE.Identifier = @cjobid
				or IMWE.Identifier = @cphasegroupid or IMWE.Identifier = @cphaseid or IMWE.Identifier = @cjcctypeid)
    		end
        
    	if @LineType = 6 and @ItemType = 3
    		begin 
			UPDATE IMWE
			SET IMWE.UploadVal = null
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
				(IMWE.Identifier = @cslid or IMWE.Identifier = @cslitemid
				or IMWE.Identifier = @cemcoid or IMWE.Identifier = @cwoid or IMWE.Identifier = @cwoitemid or IMWE.Identifier = @cequipid
				or IMWE.Identifier = @cemgroupid or IMWE.Identifier = @ccostcodeid or IMWE.Identifier = @cemctypeid or IMWE.Identifier = @ccomptypeid
				or IMWE.Identifier = @ccomponentid or IMWE.Identifier = @cjccoid or IMWE.Identifier = @cjobid
				or IMWE.Identifier = @cphasegroupid or IMWE.Identifier = @cphaseid or IMWE.Identifier = @cjcctypeid
				or IMWE.Identifier = @cincoid or IMWE.Identifier = @clocid)
    		end
        
    	if @LineType = 6 and @ItemType = 4
    		begin 
			UPDATE IMWE
			SET IMWE.UploadVal = null
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
				(IMWE.Identifier = @cslid or IMWE.Identifier = @cslitemid
				or IMWE.Identifier = @cwoid or IMWE.Identifier = @cwoitemid
				or IMWE.Identifier = @cjccoid or IMWE.Identifier = @cjobid
				or IMWE.Identifier = @cphasegroupid or IMWE.Identifier = @cphaseid or IMWE.Identifier = @cjcctypeid
				or IMWE.Identifier = @cincoid or IMWE.Identifier = @clocid)
    		end
        
		if @LineType = 6 and @ItemType = 5
			begin 
			UPDATE IMWE
			SET IMWE.UploadVal = null
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
				( IMWE.Identifier = @cslid or IMWE.Identifier = @cslitemid
				or IMWE.Identifier = @cjccoid or IMWE.Identifier = @cjobid
				or IMWE.Identifier = @cphasegroupid or IMWE.Identifier = @cphaseid or IMWE.Identifier = @cjcctypeid
				or IMWE.Identifier = @cincoid or IMWE.Identifier = @clocid)
			end
        
    	if @UM = 'LS'
    		begin 
			UPDATE IMWE
			SET IMWE.UploadVal = null
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
			IMWE.Identifier = @cecmid 
    		end
        
    	select @currrecseq = @Recseq
    	select @counter = @counter + 1
 
 		/* Reset working variables */        	
		select @Co =null,  
			@Vendor =null,  @LineType =null, @PO =null, @POItem =null, @ItemType =null, @SL =null, @SLItem =null, 
        	@JCCo =null, @Job =null, @PhaseGroup =null, @Phase =null, @JCCType =null, @EMCO =null, @WO =null, @WOItem =null, 
        	@Equip =null, @EMGroup =null, @CostCode =null, @EMCType =null, @INCo =null, @Loc =null, @MatlGroup =null, @Material =null, 
			@GLCo =null, @UM =null, @Units =null,   @VendorGroup =null, @GrossAmt =null, @MiscAmt =null, @TaxGroup =null, @TaxCode =null, 
        	@TaxType =null, @TaxBasis =null, @TaxAmt =null, @Retainage =null, @Discount =null, @BurUnitCost =null, @BECM =null, @SMChange =null,
        	@VPLineType = null, @APLine =null, 
			@CompType =null, @Component =null, @GLAcct =null, @ECM =null, @PayType =null, @Supplier =null, @MiscYN =null,
			@SMCo=null, @SMWorkOrder=null, @SMScope=null, @SMCostType=NULL, @SMJCCostType=NULL, @SMPhaseGroup=NULL

			
		end		--End single Record/Sequence loop
	end		--End WorkEdit loop, All imported records have been processed with defaults
 
close WorkEditCursor
deallocate WorkEditCursor
        
 /* Set required (dollar) inputs to 0 where not already set with some other value */       
UPDATE IMWE
SET IMWE.UploadVal = 0.00
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'')='' and
	(IMWE.Identifier = @zgrossamtid or IMWE.Identifier = @zmiscamtid or IMWE.Identifier = @ztaxbasisid
	or IMWE.Identifier = @ztaxamtid or IMWE.Identifier = @zretainageid or IMWE.Identifier = @zdiscountid
	or IMWE.Identifier = @zburunitcostid or IMWE.Identifier = @zsmchangeid)

UPDATE IMWE
SET IMWE.UploadVal = 0.000
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'')='' and
	(IMWE.Identifier = @zunitsid)
	
UPDATE IMWE
SET IMWE.UploadVal = 0.00000
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'')='' and
	(IMWE.Identifier = @zunitcostid)

/* Set required (Y/N) inputs to 'N' where not already set with some other value */ 		
UPDATE IMWE
SET IMWE.UploadVal = 'N'
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
	and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'') not in ('N','Y') and
	(IMWE.Identifier = @nmiscynid or IMWE.Identifier = @npaidynid)
 
bspexit:
select @msg = isnull(@desc,'Line') + char(13) + char(13) + '[bspBidtekDefaultAPLB]'

return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsAPLB] TO [public]
GO
