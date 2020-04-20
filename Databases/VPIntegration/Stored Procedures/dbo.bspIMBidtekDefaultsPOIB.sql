SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsPOIB]
    /***********************************************************
     * CREATED BY: Danf
     * MODIFIED BY: RBT 09/09/03 - #20131, Allow rectype <> tablename.
     *				RBT 06/08/04 - #24751, check for "Record Key" or "RecKey".
     *				RBT 07/06/04 - #25022, check DDUD for RecKey column, not IMTD.
     *				RBT 11/01/04 - #25857, fix @origecmid to look at OrigECM, not ECM.
     *				RBT 07/26/05 - #29388, provide default for POItem.
     *				RBT 11/09/05 - #30302, add default for OrigCost.
	 *				RBT 01/17/06 - #119728, fix defaults for PostToCo and OrigECM.
     *				RBT 01/26/06 - #120057, fix company default.
	 *				CC  09/30/08 - #123273, Added default for Material Description
	 *				DC  10/27/08 - #130742, Add INCo, JCCo, EMCo to import for PO Entry
	 *				CC	02/16/09 - #125933, Add PayType and PayCategory defaults
	 *				CC	02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
	 *				CC  05/29/09 - Issue #133516 - Correct defaulting of Company
	 *				DC  07/29/09 - Issue #124246 - Need UM default for PO Imports when not using material
	 *				TJL 08/04/09 - Issue #133825, Add Intl VAT TaxType default
	 *				DC  8/13/09 - #133625 - Pay Type and Pay Category should only inmport if Co flags are checked
	 *				TJL 01/22/10 - #137464, Import Error 'Conversion failed when converting the varchar value 'EA' to data type int.'
	 *				DC  01/29/10 - #137780 - Can't Import into PO Entry - Co being overwritten
	 *				DC 3/19/10 - #137114 - UM on Job type PO needs to default from Material if present, then phase
	 *				GF 09/14/2010 - issue #141031 change to use function vfDateOnly
	 *				AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
	 *				JVH 04/25/11 - Added the SM Paytype parameters for vspPOCommonInfoGetForPOEntry and bspAPPayCategoryVal
	 *				LDG 05/27/11 - Added SM Scope to PO Entry Import
     *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
     *				GF 09/24/2011 TK-08649 added tax rate and gst rate
     *				MV	10/25/11 TK-09243 - added NULL param to bspHQTaxRateGetAll
     *				LG 05/11/12 TK-13130 Added SMPhaseGroup, SMPhase, and SMJCCostType for Job imports
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
    	@defaultvalue varchar(30), @errmsg varchar(120), 
    	@filler varchar(1), @fillerPhase bPhase, @fillerCostType bJCCType, @umout bUM,
    	@InvDate bDate, @FormDetail varchar(20), @FormHeader varchar(20),
    	@InvReqSeq int, @RecKey varchar(60), @HeaderRecordType varchar(10),
    	@burdenyn bYN, @netamtopt bYN, @HeaderReqSeq int, @VendorGroup smallint, @Vendor int,
    	@hqdfltcountry char(2)
    
    declare @CompanyID int, @BatchTransTypeID int, @ReqDateID int,
    	@linetypeid int, @aplineid int, @itemtypeid int, @jccooid int, 
    	@jobid int, @phasegroupid int, @Phaseid int, @jcctypeid int,
    	@emcoid int, @woid int, @woitemid int, @equipid int, 
    	@emgroupid int, @costcodeid int, @emctypeid int, 
    	@comptypeid int, @componentid int,
    	@locid int, @matlgroupid int, @materialid  int, 
    	@glcoid int, @glacctid int, @umid int, @unitcostid int,
    	@origecmid int, @vendorgroupid int, @supplierid int, @paytypeid int, @paycategoryid int, @grossamtid int,
    	@miscynid int, @taxcodeid int, @taxbasisid int, @taxamtid int,
    	@taxgroupid int, @taxtypeid int, @reckeyid int, @poreckeyid int,
    	@zorigunitsid int, @zorigunitcostid int, @zorigcostid int, @zorigtaxid int,
    	@cpoid int, @cpoitemid int, @cslid int, @cslitemid int, @cemcoid int,
    	@cwoid int, @cwoitemid int, @cequipid int, @cemgroupid int, @ccostcodeid int,
    	@cemctypeid int, @ccomptypeid int, @ccomponentid int, @cjccoid int, @cjobid int,
    	@cphasegroupid int, @cphaseid int, @cjcctypeid int, @cincoid int, @clocid int,
    	@cecmid int, @vendorid int, @vendmatidid int, @nrecvyn int, @origcostid int, @DescriptionID int,
    	@jccoid int, @incoid int,  --DC #130742
    	@hqmtum bUM,  --DC #124246
    	@vendmtum bUM,
    	@smcoid int, @smworkorderid int, @smscopeid INT,  --DC #137114
    	@smphasegroupid int, @smphaseid int, @smjccosttypeid int,
    	----TK-08649
    	@TaxRateId INT, @GSTRateId INT
    
    declare @poitemid int, @headerpoid int, @headerjccoid int, @headerincoid int, @headerjobid int, @headerlocid int,
    		@posttocoid int
    
	select @rcode = 0, @msg=''
	/* check required input params */
	--20131
	--if @rectype <> 'POIB' goto bspexit

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

	select @FormHeader = 'POEntry'
 	select @FormDetail = 'POEntryItems'
    select @Form = 'POEntryItems'
    
	select @HeaderRecordType = RecordType
	from IMTR
	where @ImportTemplate = ImportTemplate and Form = @FormHeader
    
	-- Check ImportTemplate detail for columns to set Bidtek Defaults

	if not exists(select IMTD.DefaultValue From IMTD
	Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
	and IMTD.RecordType = @rectype)
	goto bspexit

	DECLARE 
	 	  @OverwriteBatchTransType 	 bYN
		, @OverwriteReqDate 	 	 bYN
		, @OverwritePOItem 	 		 bYN
		, @OverwriteItemType 	 	 bYN
		, @OverwritePostToCo 	 	 bYN
		, @OverwriteJob 	 		 bYN
		, @OverwritePhaseGroup 	 	 bYN
		, @OverwritePhase 	 		 bYN
		, @OverwriteJCCType 	 	 bYN
		, @OverwriteEMCo 	 		 bYN
		, @OverwriteWO 	 			 bYN
		, @OverwriteWOItem 	 		 bYN
		, @OverwriteEquip 	 		 bYN
		, @OverwriteEMGroup 	 	 bYN
		, @OverwriteCostCode 	 	 bYN
		, @OverwriteEMCType 	 	 bYN
		, @OverwriteCompType 	 	 bYN
		, @OverwriteComponent 	 	 bYN
		, @OverwriteLoc 	 		 bYN
		, @OverwriteMatlGroup 	 	 bYN
		, @OverwriteMaterial 	 	 bYN
		, @OverwriteVendMatId 	 	 bYN
		, @OverwriteGLCo 	 		 bYN
		, @OverwriteGLAcct 	 		 bYN
		, @OverwriteUM 	 			 bYN
		, @OverwriteOrigECM 	 	 bYN
		, @OverwriteTaxCode 	 	 bYN
		, @OverwriteOrigTax 	 	 bYN
		, @OverwriteTaxGroup 	 	 bYN
		, @OverwriteTaxType 	 	 bYN
		, @OverwriteOrigCost 	 	 bYN
		, @OverwritePayCategory 	 bYN
		, @OverwritePayType		 	 bYN
		, @OverwriteDescription	 	 bYN
		, @OverwriteCo				 bYN
		, @OverwriteSMPhaseGroup     bYN
		, @OverwriteSMPhase          bYN
		,	@IsCoEmpty 				 bYN
		,	@IsMthEmpty 			 bYN
		,	@IsBatchIdEmpty 		 bYN
		,	@IsBatchSeqEmpty 		 bYN
		,	@IsPOItemEmpty 			 bYN
		,	@IsBatchTransTypeEmpty 	 bYN
		,	@IsItemTypeEmpty 		 bYN
		,	@IsPostToCoEmpty 		 bYN
		,	@IsJobEmpty 			 bYN
		,	@IsPhaseGroupEmpty 		 bYN
		,	@IsPhaseEmpty 			 bYN
		,	@IsJCCTypeEmpty 		 bYN
		,	@IsLocEmpty 			 bYN
		,	@IsEMGroupEmpty 		 bYN
		,	@IsEquipEmpty 			 bYN
		,	@IsCompTypeEmpty 		 bYN
		,	@IsComponentEmpty 		 bYN
		,	@IsWOEmpty 				 bYN
		,	@IsWOItemEmpty 			 bYN
		,	@IsCostCodeEmpty 		 bYN
		,	@IsEMCTypeEmpty 		 bYN
		,	@IsMatlGroupEmpty 		 bYN
		,	@IsMaterialEmpty 		 bYN
		,	@IsVendMatIdEmpty 		 bYN
		,	@IsRecvYNEmpty 			 bYN
		,	@IsDescriptionEmpty 	 bYN
		,	@IsUMEmpty 				 bYN
		,	@IsGLCoEmpty 			 bYN
		,	@IsGLAcctEmpty 			 bYN
		,	@IsReqDateEmpty 		 bYN
		,	@IsPayCategoryEmpty 	 bYN
		,	@IsPayTypeEmpty 		 bYN
		,	@IsTaxGroupEmpty 		 bYN
		,	@IsTaxTypeEmpty 		 bYN
		,	@IsTaxCodeEmpty 		 bYN
		,	@IsOrigUnitsEmpty 		 bYN
		,	@IsOrigUnitCostEmpty 	 bYN
		,	@IsOrigECMEmpty 		 bYN
		,	@IsOrigCostEmpty 		 bYN
		,	@IsOrigTaxEmpty 		 bYN
		,	@IsRequisitionNumEmpty 	 bYN
		,	@IsNotesEmpty 			 bYN
		----TK-08649
		,	@OverwriteTaxRate 	 	 bYN
		,	@IsTaxRateEmpty 	 	 bYN
		,	@OverwriteGSTRate		bYN
		,	@IsGSTRateEmpty 	 	 bYN
		,	@IsSMPhaseGroupEmpty     bYN
		,	@IsSMPhaseEmpty          bYN


	SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'BatchTransType', @rectype);
	SELECT @OverwriteReqDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'ReqDate', @rectype);
	SELECT @OverwritePOItem = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'POItem', @rectype);
	SELECT @OverwriteItemType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'ItemType', @rectype);
	SELECT @OverwritePostToCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'PostToCo', @rectype);
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
	SELECT @OverwriteLoc = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Loc', @rectype);
	SELECT @OverwriteMatlGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'MatlGroup', @rectype);
	SELECT @OverwriteMaterial = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Material', @rectype);
	SELECT @OverwriteVendMatId = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'VendMatId', @rectype);
	SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'GLCo', @rectype);
	SELECT @OverwriteGLAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'GLAcct', @rectype);
	SELECT @OverwriteUM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'UM', @rectype);
	SELECT @OverwriteOrigECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'OrigECM', @rectype);
	SELECT @OverwriteTaxCode = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'TaxCode', @rectype);
	----TK-08649
	SELECT @OverwriteTaxRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'TaxRate', @rectype);
	SELECT @OverwriteGSTRate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'GSTRate', @rectype);
	
	SELECT @OverwriteOrigTax = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'OrigTax', @rectype);
	SELECT @OverwriteTaxGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'TaxGroup', @rectype);
	SELECT @OverwriteTaxType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'TaxType', @rectype);
	SELECT @OverwriteOrigCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'OrigCost', @rectype);
	SELECT @OverwritePayCategory = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'PayCategory', @rectype);
	SELECT @OverwritePayType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'PayType', @rectype);
	SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'Co', @rectype);
	SELECT @OverwriteSMPhaseGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'SMPhaseGroup', @rectype);
	SELECT @OverwriteSMPhase = dbo.vfIMTemplateOverwrite(@ImportTemplate, @FormDetail, 'SMPhase', @rectype);

	select @reckeyid = a.Identifier
	From IMTD a join DDUD b on a.Identifier = b.Identifier
	Where a.ImportTemplate=@ImportTemplate AND b.ColumnName = 'RecKey'
	and a.RecordType = @rectype and b.Form = @FormDetail

	select @poreckeyid = a.Identifier
	From IMTD a join DDUD b on a.Identifier = b.Identifier
	Where a.ImportTemplate=@ImportTemplate AND b.ColumnName = 'RecKey'
	and a.RecordType = @HeaderRecordType and b.Form = @FormHeader
    
	--issue #119780 - fixed query to include IMTR
	select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
	inner join DDUD on IMTD.Identifier = DDUD.Identifier inner join IMTR on
	IMTR.ImportTemplate = IMTD.ImportTemplate and IMTR.RecordType = IMTD.RecordType
	Where IMTD.ImportTemplate=@ImportTemplate and DDUD.Form = @Form 
	and DDUD.ColumnName = 'Co' and IMTD.RecordType = @rectype
	if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
		begin
			Update IMWE
			SET IMWE.UploadVal = @Company
			where IMWE.ImportTemplate=@ImportTemplate and
			IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID and IMWE.RecordType = @rectype
		end
        
	select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
	inner join DDUD on IMTD.Identifier = DDUD.Identifier inner join IMTR on
	IMTR.ImportTemplate = IMTD.ImportTemplate and IMTR.RecordType = IMTD.RecordType
	Where IMTD.ImportTemplate=@ImportTemplate and DDUD.Form = @Form 
	and DDUD.ColumnName = 'Co' and IMTD.RecordType = @rectype
	if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
		begin
			Update IMWE
			SET IMWE.UploadVal = @Company
			where IMWE.ImportTemplate=@ImportTemplate and
			IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID and IMWE.RecordType = @rectype
		end
    
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
        
    select @ReqDateID=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'ReqDate', @rectype, 'Y')
    if isnull(@ReqDateID,0) <> 0 AND (ISNULL(@OverwriteReqDate, 'Y') = 'Y')
    	begin
    		UPDATE IMWE
    		----#141031
    		SET IMWE.UploadVal =  convert(varchar(20), dbo.vfDateOnly(),101)
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ReqDateID
    		and IMWE.RecordType = @rectype
    	end
		
	if isnull(@ReqDateID,0) <> 0 AND (ISNULL(@OverwriteReqDate, 'Y') = 'N')
    	begin
    		UPDATE IMWE
    		----#141031
    		SET IMWE.UploadVal =  convert(varchar(20), dbo.vfDateOnly(),101)
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ReqDateID
    		and IMWE.RecordType = @rectype
    		AND IMWE.UploadVal IS NULL
    	end
    
	SELECT @poitemid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'POItem', @rectype, 'Y')
	SELECT @itemtypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'ItemType', @rectype, 'Y')
	SELECT @vendorid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Vendor', @HeaderRecordType, 'N')
	SELECT @vendorgroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'VendorGroup', @HeaderRecordType, 'N')  --DC #137114

	SELECT @headerpoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'PO', @HeaderRecordType, 'N')
	SELECT @headerjccoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'JCCo', @HeaderRecordType, 'N')
	SELECT @headerincoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'INCo', @HeaderRecordType, 'N')
	SELECT @headerjobid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Job', @HeaderRecordType, 'N')
	SELECT @headerlocid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormHeader, 'Loc', @HeaderRecordType, 'N')
	SELECT @itemtypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'ItemType', @rectype, 'Y')
	SELECT @posttocoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'PostToCo', @rectype, 'Y')
	
	--DC #130742
	SELECT @jccoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'JCCo', @rectype, 'N')
	SELECT @incoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'INCo', @rectype, 'N')
	SELECT @emcoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'EMCo', @rectype, 'Y')

	SELECT @jobid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Job', @rectype, 'Y')
	SELECT @phasegroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'PhaseGroup', @rectype, 'Y')
	SELECT @Phaseid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Phase', @rectype, 'Y')
	SELECT @jcctypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'JCCType', @rectype, 'Y')
	SELECT @woid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'WO', @rectype, 'Y')
	SELECT @woitemid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'WOItem', @rectype, 'Y')
	SELECT @equipid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Equip', @rectype, 'Y')
	SELECT @emgroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'EMGroup', @rectype, 'Y')
	SELECT @costcodeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'CostCode', @rectype, 'Y')
	SELECT @emctypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'EMCType', @rectype, 'Y')
	SELECT @comptypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'CompType', @rectype, 'Y')
	SELECT @componentid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Component', @rectype, 'Y')
	SELECT @locid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Loc', @rectype, 'Y')
	SELECT @matlgroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'MatlGroup', @rectype, 'Y')
	SELECT @materialid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Material', @rectype, 'Y')
	SELECT @vendmatidid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'VendMatId', @rectype, 'Y')
	SELECT @glcoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'GLCo', @rectype, 'Y')
	SELECT @glacctid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'GLAcct', @rectype, 'Y')
	SELECT @umid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'UM', @rectype, 'Y')
	SELECT @origecmid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'OrigECM', @rectype, 'Y')
	SELECT @taxcodeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxCode', @rectype, 'Y')
	-----TK-08649
	SELECT @TaxRateId=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxRate', @rectype, 'Y')
	SELECT @GSTRateId=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'GSTRate', @rectype, 'Y')
	
	SELECT @taxamtid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'OrigTax', @rectype, 'Y')
	SELECT @taxgroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxGroup', @rectype, 'Y')
	SELECT @taxtypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'TaxType', @rectype, 'Y')
	SELECT @origcostid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'OrigCost', @rectype, 'Y')
	SELECT @zorigunitsid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'OrigUnits', @rectype, 'N')
	SELECT @zorigunitcostid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'OrigUnitCost', @rectype, 'N')
	SELECT @zorigcostid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'OrigCost', @rectype, 'N')
	SELECT @zorigtaxid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'OrigTax', @rectype, 'N')
	SELECT @cjobid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Job', @rectype, 'N')
	SELECT @cphaseid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Phase', @rectype, 'N')
	SELECT @cjcctypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'JCCType', @rectype, 'N')
	SELECT @cwoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'WO', @rectype, 'N')
	SELECT @cwoitemid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'WOItem', @rectype, 'N')
	SELECT @cequipid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Equip', @rectype, 'N')
	SELECT @ccostcodeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'CostCode', @rectype, 'N')
	SELECT @cemctypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'EMCType', @rectype, 'N')
	SELECT @ccomptypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'CompType', @rectype, 'N')
	SELECT @ccomponentid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Component', @rectype, 'N')
	SELECT @clocid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Loc', @rectype, 'N')
	SELECT @cecmid=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'OrigECM', @rectype, 'N')
	SELECT @nrecvyn=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'RecvYN', @rectype, 'N')
	SELECT @DescriptionID=dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'Description', @rectype, 'N')
	SELECT @paytypeid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'PayType', @rectype, 'Y')
	SELECT @paycategoryid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'PayCategory', @rectype, 'Y')
	SELECT @smcoid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'SMCo', @rectype, 'N')
	SELECT @smworkorderid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'SMWorkOrder', @rectype, 'N')
	SELECT @smscopeid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'SMScope', @rectype, 'N')
	SELECT @smphasegroupid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'SMPhaseGroup', @rectype, 'N')
	SELECT @smphaseid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'SMPhase', @rectype, 'N')
	SELECT @smjccosttypeid = dbo.bfIMTemplateDefaults(@ImportTemplate, @FormDetail, 'SMJCCostType', @rectype, 'N')
		
    declare  @Co bCompany, @Mth bMonth, @BatchId bBatchID, @BatchSeq int, @POItem bItem, @BatchTransType char, 
		@ItemType tinyint, @MatlGroup bGroup, @Material bMatl, @VendMatId varchar(30), @Description bItemDesc, @UM bUM, @RecvYN bYN, @PostToCo bCompany,
		@Loc bLoc, @Job bJob, @PhaseGroup bGroup, @Phase bPhase, @JCCType bJCCType, @WO bWO, @WOItem bItem,
		@Equip bEquip, @EMGroup bGroup, @CostCode bCostCode, @EMCType bEMCType, @CompType varchar(10), @Component bEquip,
		@GLCo bCompany, @GLAcct bGLAcct, @ReqDate bDate, @TaxGroup bGroup, @TaxCode bTaxCode, @TaxType tinyint, 
		@OrigUnits bUnits, @OrigUnitCost bUnitCost, @OrigECM bECM, @OrigCost bDollar, @OrigTax bDollar,
		@RequisitionNum varchar(20), @PayType tinyint, @PayCategory int, @SMCo bCompany, @SMWorkOrder int,
		@SMScope INT,
		@SMPhaseGroup bGroup, @SMPhase bPhase, @SMJCCostType bJCCType,
		----TK-08649
		@TaxRate bRate, @GSTRate bRate, @filterTaxRate bRate
    
    declare @PO varchar(30), @HeaderJCCo  bCompany, @HeaderJob bJob, @HeaderINCo bCompany, @HeaderLoc bLoc,
    		@MaterialPhase bPhase, @MaterialJCCT bJCCType
    
    declare @payterms bPayTerms, @v1099yn bYN, @v1099type varchar(10), @v1099box tinyint,   
    	@discdate bDate, @duedate bDate, @discrate bUnitCost
    
    declare WorkEditCursor cursor local fast_forward for
    select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
    from IMWE
    inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
    where IMWE.ImportId = @ImportId and 
    	IMWE.ImportTemplate = @ImportTemplate and 
    	IMWE.Form = @Form and
    	IMWE.RecordType = @rectype
    Order by IMWE.RecordSeq, IMWE.Identifier
    
	open WorkEditCursor
	-- set open cursor flag
    --#142350 removing @importid, @seq
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
		if @@fetch_status <> 0
			select @Recseq = -1
    
    		--if rec sequence = current rec sequence flag
    		if @Recseq = @currrecseq
    		begin
    
    			If @Column='Co' and isnumeric(@Uploadval) = 1 select @Co = Convert( int, @Uploadval)
    			If @Column='Mth' and isdate(@Uploadval) = 1 select @Mth = Convert( smalldatetime, @Uploadval)
    			If @Column='BatchId' and  isnumeric(@Uploadval) =1 select @BatchSeq = @Uploadval
    			If @Column='BatchSeq' and isnumeric(@Uploadval) =1 select @BatchTransType = @Uploadval
    			If @Column='POItem' and isnumeric(@Uploadval) =1 select @POItem = @Uploadval 
    			If @Column='BatchTransType' select @BatchTransType = @Uploadval
    			If @Column='ItemType' and isnumeric(@Uploadval) =1 select @ItemType = @Uploadval
    			If @Column='MatlGroup' and isnumeric(@Uploadval) =1 select @MatlGroup = Convert( int, @Uploadval)
    			If @Column='Material' select @Material = @Uploadval
    			If @Column='VendMatId' select @VendMatId = @Uploadval
    			If @Column='Description' select @Description = @Uploadval
    			If @Column='UM' select @UM =  @Uploadval
    			If @Column='RecvYN' select @RecvYN =  @Uploadval
    			If @Column='PostToCo' and isnumeric(@Uploadval) =1  select @PostToCo = convert(int,@Uploadval)
    			If @Column='Loc' select @Loc = @Uploadval
    			If @Column='Job' select @Job = @Uploadval
    			If @Column='PhaseGroup' and isnumeric(@Uploadval) =1 select @PhaseGroup = Convert( smallint, @Uploadval)
    			If @Column='Phase' select @Phase = @Uploadval
    			If @Column='JCCType' and isnumeric(@Uploadval) =1 select @JCCType = convert(int,@Uploadval)
    			If @Column='Equip' select @Equip = @Uploadval
    			If @Column='WO' select @WO = @Uploadval
    			If @Column='WOItem' and  isnumeric(@Uploadval) =1 select @WOItem = convert(smallint,@Uploadval)
    			If @Column='EMGroup' and  isnumeric(@Uploadval) =1 select @EMGroup = convert(smallint,@Uploadval)
    			If @Column='CostCode' select @CostCode = @Uploadval
    			If @Column='EMCType' and isnumeric(@Uploadval) =1 select @EMCType = convert(smallint,@Uploadval)
    			If @Column='CompType' select @CompType = @Uploadval
    			If @Column='Component' select @Component = @Uploadval
    			If @Column='GLCo' and isnumeric(@Uploadval) =1  select @GLCo = convert(smallint,@Uploadval)
    			If @Column='GLAcct' select @GLAcct = @Uploadval
    			If @Column='ReqDate' and isdate(@Uploadval) =1 select @ReqDate = convert(smalldatetime,@Uploadval)
    			If @Column='TaxGroup' and isnumeric(@Uploadval) =1 select @TaxGroup = convert(smallint,@Uploadval)
    			If @Column='TaxCode' select @TaxCode = @Uploadval
    			If @Column='TaxType' and isnumeric(@Uploadval) =1 select @TaxType = Convert(smallint, @Uploadval)
    			If @Column='OrigUnits' and isnumeric(@Uploadval) =1 select @OrigUnits = Convert( numeric(16,5),@Uploadval)
    			If @Column='OrigUnitCost' and isnumeric(@Uploadval) =1 select @OrigUnitCost = convert(numeric(16,5),@Uploadval) 	
    			If @Column='OrigECM' select @OrigECM = @Uploadval
    			If @Column='OrigCost' and isnumeric(@Uploadval) =1 select @OrigCost = convert(numeric(16,5),@Uploadval)
    			If @Column='OrigTax' and isnumeric(@Uploadval) =1 select @OrigTax = Convert( numeric(16,5),@Uploadval)
    			If @Column='RequisitionNum'select @RequisitionNum = @Uploadval
    			If @Column='PayType' and isnumeric(@Uploadval) =1  select @PayType = convert(tinyint,@Uploadval)
    			If @Column='PayCategory' and isnumeric(@Uploadval) =1  select @PayCategory = convert(int,@Uploadval)
    			If @Column='SMCo' and isnumeric(@Uploadval) =1  select @SMCo = convert(smallint,@Uploadval)
    			If @Column='SMWorkOrder' and isnumeric(@Uploadval) =1  select @SMWorkOrder = convert(int,@Uploadval)
    			If @Column='SMScope' and isnumeric(@Uploadval) =1  select @SMScope = convert(int,@Uploadval)
    			If @Column='SMPhaseGroup' select @SMPhaseGroup = convert(smallint,@Uploadval)
    			If @Column='SMPhase' select @SMPhase = @Uploadval
    			If @Column='SMJCCostType' and isnumeric(@Uploadval) =1  select @SMJCCostType = convert(int,@Uploadval)
    			
				----TK-08649
				If @Column='TaxRate' and isnumeric(@Uploadval) =1  select @TaxRate = convert(NUMERIC(16,5), @Uploadval)
				If @Column='GSTRate' and isnumeric(@Uploadval) =1  select @GSTRate = convert(NUMERIC(16,5), @Uploadval)
				
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
				IF @Column='POItem' 
					IF @Uploadval IS NULL
						SET @IsPOItemEmpty = 'Y'
					ELSE
						SET @IsPOItemEmpty = 'N'
				IF @Column='BatchTransType' 
					IF @Uploadval IS NULL
						SET @IsBatchTransTypeEmpty = 'Y'
					ELSE
						SET @IsBatchTransTypeEmpty = 'N'
				IF @Column='ItemType' 
					IF @Uploadval IS NULL
						SET @IsItemTypeEmpty = 'Y'
					ELSE
						SET @IsItemTypeEmpty = 'N'
				IF @Column='PostToCo' 
					IF @Uploadval IS NULL
						SET @IsPostToCoEmpty = 'Y'
					ELSE
						SET @IsPostToCoEmpty = 'N'
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
				IF @Column='Loc' 
					IF @Uploadval IS NULL
						SET @IsLocEmpty = 'Y'
					ELSE
						SET @IsLocEmpty = 'N'
				IF @Column='EMGroup' 
					IF @Uploadval IS NULL
						SET @IsEMGroupEmpty = 'Y'
					ELSE
						SET @IsEMGroupEmpty = 'N'
				IF @Column='Equip' 
					IF @Uploadval IS NULL
						SET @IsEquipEmpty = 'Y'
					ELSE
						SET @IsEquipEmpty = 'N'
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
				IF @Column='VendMatId' 
					IF @Uploadval IS NULL
						SET @IsVendMatIdEmpty = 'Y'
					ELSE
						SET @IsVendMatIdEmpty = 'N'
				IF @Column='RecvYN' 
					IF @Uploadval IS NULL
						SET @IsRecvYNEmpty = 'Y'
					ELSE
						SET @IsRecvYNEmpty = 'N'
				IF @Column='Description' 
					IF @Uploadval IS NULL
						SET @IsDescriptionEmpty = 'Y'
					ELSE
						SET @IsDescriptionEmpty = 'N'
				IF @Column='UM' 
					IF @Uploadval IS NULL
						SET @IsUMEmpty = 'Y'
					ELSE
						SET @IsUMEmpty = 'N'
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
				IF @Column='ReqDate' 
					IF @Uploadval IS NULL
						SET @IsReqDateEmpty = 'Y'
					ELSE
						SET @IsReqDateEmpty = 'N'
				IF @Column='PayCategory' 
					IF @Uploadval IS NULL
						SET @IsPayCategoryEmpty = 'Y'
					ELSE
						SET @IsPayCategoryEmpty = 'N'
				IF @Column='PayType' 
					IF @Uploadval IS NULL
						SET @IsPayTypeEmpty = 'Y'
					ELSE
						SET @IsPayTypeEmpty = 'N'
				IF @Column='TaxGroup' 
					IF @Uploadval IS NULL
						SET @IsTaxGroupEmpty = 'Y'
					ELSE
						SET @IsTaxGroupEmpty = 'N'
				IF @Column='TaxType' 
					IF @Uploadval IS NULL
						SET @IsTaxTypeEmpty = 'Y'
					ELSE
						SET @IsTaxTypeEmpty = 'N'
				IF @Column='TaxCode' 
					IF @Uploadval IS NULL
						SET @IsTaxCodeEmpty = 'Y'
					ELSE
						SET @IsTaxCodeEmpty = 'N'
				IF @Column='OrigUnits' 
					IF @Uploadval IS NULL
						SET @IsOrigUnitsEmpty = 'Y'
					ELSE
						SET @IsOrigUnitsEmpty = 'N'
				IF @Column='OrigUnitCost' 
					IF @Uploadval IS NULL
						SET @IsOrigUnitCostEmpty = 'Y'
					ELSE
						SET @IsOrigUnitCostEmpty = 'N'
				IF @Column='OrigECM' 
					IF @Uploadval IS NULL
						SET @IsOrigECMEmpty = 'Y'
					ELSE
						SET @IsOrigECMEmpty = 'N'
				IF @Column='OrigCost' 
					IF @Uploadval IS NULL
						SET @IsOrigCostEmpty = 'Y'
					ELSE
						SET @IsOrigCostEmpty = 'N'
				IF @Column='OrigTax' 
					IF @Uploadval IS NULL
						SET @IsOrigTaxEmpty = 'Y'
					ELSE
						SET @IsOrigTaxEmpty = 'N'
				IF @Column='RequisitionNum' 
					IF @Uploadval IS NULL
						SET @IsRequisitionNumEmpty = 'Y'
					ELSE
						SET @IsRequisitionNumEmpty = 'N'
				IF @Column='Notes' 
					IF @Uploadval IS NULL
						SET @IsNotesEmpty = 'Y'
					ELSE
						SET @IsNotesEmpty = 'N'   
				IF @Column='SMPhaseGroup' 
					IF @Uploadval IS NULL
						SET @IsSMPhaseGroupEmpty = 'Y'
					ELSE
						SET @IsSMPhaseGroupEmpty = 'N'   
				IF @Column='SMPhase' 
					IF @Uploadval IS NULL
						SET @IsSMPhaseEmpty = 'Y'
					ELSE
						SET @IsSMPhaseEmpty = 'N'    
    			--fetch next record
    
    			if @@fetch_status <> 0
    				select @complete = 1
    
    			select @oldrecseq = @Recseq
    
    			fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
    
    		end
    
    		else
    
    		begin
     
    			--Find Vendor from header by RecKey
    
    			select @RecKey=IMWE.UploadVal
    			from IMWE
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
    				and IMWE.Identifier = @reckeyid and IMWE.RecordType = @rectype 
    				and IMWE.RecordSeq = @currrecseq
    
    			select @HeaderReqSeq=IMWE.RecordSeq
    			from IMWE
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
    				and IMWE.Identifier = @reckeyid and IMWE.RecordType = @HeaderRecordType 
    				and IMWE.UploadVal = @RecKey
    				
    			select @Vendor=IMWE.UploadVal
    			from IMWE
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
    				and IMWE.Identifier = @vendorid and IMWE.RecordType = @HeaderRecordType 
    				and IMWE.RecordSeq = @HeaderReqSeq
    				
				select @VendorGroup=IMWE.UploadVal
				from IMWE
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
    				and IMWE.Identifier = @vendorgroupid and IMWE.RecordType = @HeaderRecordType 
    				and IMWE.RecordSeq = @HeaderReqSeq
    
    			select @PO=IMWE.UploadVal
    			from IMWE
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
    				and IMWE.Identifier = @headerpoid and IMWE.RecordType = @HeaderRecordType 
    				and IMWE.RecordSeq = @HeaderReqSeq
    
    			select @HeaderJCCo=IMWE.UploadVal
    			from IMWE
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
    				and IMWE.Identifier = @headerjccoid and IMWE.RecordType = @HeaderRecordType 
    				and IMWE.RecordSeq = @HeaderReqSeq
    
    			select @HeaderJob=IMWE.UploadVal
    			from IMWE
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
    				and IMWE.Identifier = @headerjobid and IMWE.RecordType = @HeaderRecordType 
    				and IMWE.RecordSeq = @HeaderReqSeq
    
    			select @HeaderINCo=IMWE.UploadVal
    			from IMWE
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
    				and IMWE.Identifier = @headerincoid and IMWE.RecordType = @HeaderRecordType 
    				and IMWE.RecordSeq = @HeaderReqSeq
    
    			select @HeaderLoc=IMWE.UploadVal
    			from IMWE
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
    				and IMWE.Identifier = @headerlocid and IMWE.RecordType = @HeaderRecordType 
    				and IMWE.RecordSeq = @HeaderReqSeq
 
      			/* Get HQ Company, Country value.  Company can be different from one RecSeq to another. */
				select @hqdfltcountry = DefaultCountry
				from HQCO with (nolock)
				where HQCo = @Co
				  
   				--Issue #29388
    		if @poitemid <> 0
    			begin
    				-- Default PO Item to Max Plus One of existing Items Including Item in PO
   				if @currrecseq = 1 
   					begin
   					--reset all POItem fields to zero, so auto sequencing starts at 1.
   					UPDATE IMWE
   					SET IMWE.UploadVal = 0
   					where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
   						and IMWE.Identifier=@poitemid and IMWE.RecordType=@rectype
   					end
   				
   				select @RecKey=IMWE.UploadVal
   				from IMWE with (nolock)
   				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId
   					and IMWE.Identifier = @reckeyid and IMWE.RecordType = @rectype 
   					and IMWE.RecordSeq = @currrecseq
   		
   				select @POItem = isnull(Max(convert(int,w.UploadVal)),0) + 1
   				from IMWE w with (nolock)
   					inner join IMWE e with (nolock)
   				on w.ImportTemplate=e.ImportTemplate and w.ImportId=e.ImportId
   					and w.RecordType=e.RecordType and w.Identifier=@poitemid and e.Identifier=@reckeyid
   					and w.RecordSeq=e.RecordSeq
   				where w.ImportTemplate=@ImportTemplate and w.ImportId=@ImportId
   					and w.RecordType = @rectype and e.UploadVal = @RecKey
   
    			UPDATE IMWE
    			SET IMWE.UploadVal = @POItem
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @poitemid and IMWE.RecordType = @rectype
    			end
       
    		if @itemtypeid <> 0  AND (ISNULL(@OverwriteItemType, 'Y') = 'Y' OR ISNULL(@IsItemTypeEmpty, 'Y') = 'Y')
    			begin
    			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=SM Work Order
     			select @ItemType = 3
    			If isnull(@WO,'') <> '' select @ItemType = 5
    			If isnull(@Equip,'') <> '' and isnull(@WO,'') = '' select @ItemType = 4
    			If isnull(@Loc,'') <> '' and isnull(@Equip,'') = '' and isnull(@WO,'') = '' select @ItemType = 2
    			If isnull(@Job,'') <> '' select @ItemType = 1
    			If isnull(@SMWorkOrder,0) <> 0 select @ItemType = 6
        
    			UPDATE IMWE
    			SET IMWE.UploadVal = @ItemType
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @itemtypeid and IMWE.RecordType = @rectype
    			end
    
    		if @posttocoid <> 0	AND (ISNULL(@OverwritePostToCo, 'Y') = 'Y' OR ISNULL(@IsPostToCoEmpty, 'Y') = 'Y') --fix for #119728
    			begin
    
    			if @ItemType = 1 select @PostToCo = @HeaderJCCo
    			if @ItemType = 2 select @PostToCo = @HeaderINCo
    			if @ItemType = 3 select @PostToCo = GLCo from bAPCO with (nolock) where APCo = @Co
    			if @ItemType = 4 or @ItemType = 5 select @PostToCo = @Co
    			if @ItemType = 6 select @PostToCo = @SMCo
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @PostToCo
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @posttocoid and IMWE.RecordType = @rectype
    			end
    
    		if @matlgroupid <> 0 AND (ISNULL(@OverwriteMatlGroup, 'Y') = 'Y' OR ISNULL(@IsMatlGroupEmpty, 'Y') = 'Y')
    			begin
    			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
    			--select @MatlGroup = MatlGroup from bHQCO where HQCo = @Co
    			--DC #124246
				select @MatlGroup = MatlGroup from bHQCO where HQCo = @PostToCo
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @MatlGroup
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @matlgroupid and IMWE.RecordType = @rectype
    			end
        
    		if @materialid <> 0  AND (ISNULL(@OverwriteMaterial, 'Y') = 'Y' OR ISNULL(@IsMaterialEmpty, 'Y') = 'Y')
     			begin
    			select @Material = Material
    			from bPOVM with (nolock)
    			where VendorGroup = @VendorGroup and Vendor = @Vendor and
    				MatlGroup = @MatlGroup and VendMatId = @VendMatId
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @Material
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @materialid and IMWE.RecordType = @rectype
    			end
        
    		if @vendmatidid <> 0 AND (ISNULL(@OverwriteVendMatId, 'Y') = 'Y' OR ISNULL(@IsVendMatIdEmpty, 'Y') = 'Y')
     			begin   
     			--DC #137114
				select @VendMatId=VendMatId
				from bPOVM p with (nolock)
				join bHQMT h with (nolock) on p.MatlGroup=h.MatlGroup and p.Material=h.Material and p.UM=h.PurchaseUM
				where p.MatlGroup=@MatlGroup and p.Material=@Material and p.VendorGroup=@VendorGroup and p.Vendor=@Vendor
				if @@rowcount = 0 
					begin 
					 /*Get the first Vend Mat combination regardless of UM */					 
					 select @hqmtum = min(UM) from bPOVM where Vendor = @Vendor and VendorGroup = @VendorGroup and MatlGroup = @MatlGroup and Material = @Material
					 if @hqmtum is not null
	 					begin
	 					select @VendMatId=VendMatId
						from bPOVM
						where Vendor = @Vendor and VendorGroup=@VendorGroup and
							MatlGroup = @MatlGroup and Material = @Material and UM = @hqmtum
	 					end
					end
					     		    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @VendMatId
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @vendmatidid and IMWE.RecordType = @rectype
    			end    		    		
    		
			--DC #130742 START
    		if @jccoid <> 0 and @ItemType = 1
     			begin    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @PostToCo
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @jccoid and IMWE.RecordType = @rectype
    			end
    		if @incoid <> 0 and @ItemType = 2
     			begin    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @PostToCo
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @incoid and IMWE.RecordType = @rectype
    			end
    		if @emcoid <> 0 and @ItemType in(4,5) --AND (ISNULL(@OverwriteEMCo, 'Y') = 'Y' OR @PostToCo IS NULL) 
     			begin    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @PostToCo
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @emcoid and IMWE.RecordType = @rectype
    			end
			-- END
			
    		if @phasegroupid <> 0 and @ItemType = 1 AND (ISNULL(@OverwritePhaseGroup, 'Y') = 'Y' OR ISNULL(@IsPhaseGroupEmpty, 'Y') = 'Y')
     			begin
    			select @PhaseGroup = PhaseGroup
    			from bHQCO with (nolock)
    			where HQCo = @PostToCo
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @PhaseGroup
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @phasegroupid and IMWE.RecordType = @rectype
    			end
    		if @jobid <> 0  and @ItemType = 1 AND (ISNULL(@OverwriteJob, 'Y') = 'Y' OR ISNULL(@IsJobEmpty, 'Y') = 'Y')
     			begin
    			select @Job = @HeaderJob
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @Job
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @jobid and IMWE.RecordType = @rectype
    			end
    
    		if @ItemType = 1
    			begin
    			select @MaterialPhase = MatlPhase, @MaterialJCCT = MatlJCCostType
    			from bHQMT
    			where MatlGroup = @MatlGroup and Material = @Material
    			end
    
    		if @Phaseid <> 0  and @ItemType = 1 AND (ISNULL(@OverwritePhase, 'Y') = 'Y' OR ISNULL(@IsPhaseEmpty, 'Y') = 'Y')
     			begin
    			select @Phase = @MaterialPhase
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @Phase
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @Phaseid and IMWE.RecordType = @rectype
    			end
    
    		if @jcctypeid <> 0  and @ItemType = 1 AND (ISNULL(@OverwriteJCCType, 'Y') = 'Y' OR ISNULL(@IsJCCTypeEmpty, 'Y') = 'Y')
     			begin
    			select @JCCType = @MaterialJCCT
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @JCCType
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @jcctypeid and IMWE.RecordType = @rectype
    			end
    		    
    		if @locid <> 0  and @ItemType = 2 AND (ISNULL(@OverwriteLoc, 'Y') = 'Y' OR ISNULL(@IsLocEmpty, 'Y') = 'Y')
     			begin
    			select @Loc = @HeaderLoc
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @Loc
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @locid and IMWE.RecordType = @rectype
    			end
    
    		if @emgroupid <> 0 and ( @ItemType = 4 or @ItemType = 5 ) AND (ISNULL(@OverwriteEMGroup, 'Y') = 'Y' OR ISNULL(@IsEMGroupEmpty, 'Y') = 'Y')
    			begin
    			select @EMGroup=EMGroup from bHQCO with (nolock)
    			where HQCo = @PostToCo
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @EMGroup
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @emgroupid and IMWE.RecordType = @rectype
    
    			end
    
    		if @equipid <> 0 and @ItemType = 5 AND (ISNULL(@OverwriteEquip, 'Y') = 'Y' OR ISNULL(@IsEquipEmpty, 'Y') = 'Y')
    			begin
    			select @Equip=Equipment from bEMWH with (nolock)
    			where EMCo = @PostToCo and WorkOrder = @WO
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @Equip
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @equipid and IMWE.RecordType = @rectype
    			end
    
    		if @costcodeid <> 0 and @ItemType = 5 AND (ISNULL(@OverwriteCostCode, 'Y') = 'Y' OR ISNULL(@IsCostCodeEmpty, 'Y') = 'Y')
    			begin
    			select @CostCode=CostCode from bEMWI with (nolock)
    			where EMCo = @PostToCo and WorkOrder = @WO and WOItem=@WOItem
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @CostCode
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @costcodeid and IMWE.RecordType = @rectype
    			end
    
    		if @componentid <> 0 and @ItemType = 5 AND (ISNULL(@OverwriteComponent, 'Y') = 'Y' OR ISNULL(@IsComponentEmpty, 'Y') = 'Y')
    			begin
    			select @Component=Component from bEMWI with (nolock)
    			where EMCo = @PostToCo and WorkOrder = @WO and WOItem=@WOItem
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @Component
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @componentid and IMWE.RecordType = @rectype
    			end
    
    		if @comptypeid <> 0 and @ItemType = 5 AND (ISNULL(@OverwriteCompType, 'Y') = 'Y' OR ISNULL(@IsCompTypeEmpty, 'Y') = 'Y')
    			begin
    			select @CompType=ComponentTypeCode from bEMWI with (nolock)
    			where EMCo = @PostToCo and WorkOrder = @WO and WOItem=@WOItem
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @CompType
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @comptypeid and IMWE.RecordType = @rectype
    			end
			
			--DC #124246
			IF @umid <> 0 AND (ISNULL(@OverwriteUM, 'Y') = 'Y' OR ISNULL(@IsUMEmpty, 'Y') = 'Y')
				BEGIN
    		
    			--DC #137114
    			IF isnull(@VendMatId,'') <> ''
    				BEGIN
    				SELECT @vendmtum  = UM  
    				FROM bPOVM with (nolock)  				    				
    				WHERE VendorGroup = @VendorGroup and Vendor = @Vendor and MatlGroup = @MatlGroup and VendMatId = @VendMatId
    				END
    			
    			IF isnull(@Material,'') <> ''
    				BEGIN
    				SELECT @hqmtum = PurchaseUM
    				FROM bHQMT with (nolock)
    				WHERE MatlGroup = @MatlGroup and Material = @Material
    				END
    			
    			SELECT @hqmtum = isnull(@vendmtum, isnull(@hqmtum,''))    			    				        		
				
				IF isnull(@hqmtum, '') = ''
					BEGIN
					IF @ItemType = 1 
						BEGIN
						select @hqmtum = UM
						from bJCCH with (nolock) 
						where JCCo = @PostToCo and Job = @Job and Phase = @Phase and CostType = @JCCType    					
						END
						
					IF @ItemType = 4
						BEGIN
						select @hqmtum = UM 
						from bEMCH with (nolock)
						where EMCo = @PostToCo and Equipment = @Equip and EMGroup = @EMGroup 
							and CostCode = @CostCode and CostType = @EMCType
						if @@rowcount = 0
							BEGIN
							select @hqmtum = UM 
							from EMCX with (nolock)
							where EMGroup = @EMGroup and CostCode = @CostCode and CostType = @EMCType
							END    					
						END  
					IF @ItemType not in (1,4)
						BEGIN
						select @hqmtum = PurchaseUM
						from bHQMT with (nolock)
						where MatlGroup = @MatlGroup and Material = @Material											
						END  										
					END
					
				SELECT @UM = @hqmtum
	    		   
				UPDATE IMWE
				SET IMWE.UploadVal = @UM
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @umid and IMWE.RecordType = @rectype
				END    			    		     		    		
    
    		if @glcoid <> 0 AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
    			begin
    			if @ItemType = 1 select @GLCo = GLCo from bJCCO with ( nolock) where JCCo = @PostToCo 
    			if @ItemType = 2 select @GLCo = GLCo from bINCO with ( nolock) where INCo = @PostToCo 
    			if @ItemType = 3 select @GLCo = GLCo from bAPCO with ( nolock) where APCo = @Co
    			if @ItemType = 4 or @ItemType = 5 select @GLCo = GLCo from bEMCO with ( nolock) where EMCo = @PostToCo
    			if @ItemType = 6 select @GLCo = GLCo from SMCO where SMCo = @SMCo
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @GLCo
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @glcoid and IMWE.RecordType = @rectype
    			end
    
    		if @glacctid <> 0 AND (ISNULL(@OverwriteGLAcct, 'Y') = 'Y' OR ISNULL(@IsGLAcctEmpty, 'Y') = 'Y')
     			begin
    			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
    			if @ItemType = 1
    				begin
    				exec @recode =  bspJCCAGlacctDflt @PostToCo, @Job, @PhaseGroup, @Phase, @JCCType, 'N', @GLAcct output, @errmsg output
    				end
				
    			if @ItemType = 2
    				begin
    				select @filler = null
    				exec @recode =  bspINGlacctDflt @PostToCo, @Loc, @Material, @MatlGroup, @GLAcct output, @filler output, @errmsg output
    				end
				
    			if @ItemType = 3
    				begin
    				exec @recode =  bspAPGlacctDflt @VendorGroup, @Vendor, @MatlGroup, @Material, @GLAcct output, @errmsg output
    				end
				
    			if @ItemType = 4 or @ItemType = 5
    				begin
    				exec @recode =  bspEMCostTypeValForCostCode @PostToCo, @EMGroup, @EMCType, @CostCode, @Equip, 'N', @costtypeout output, @GLAcct output, @errmsg output
    				end
    			
    			if @ItemType = 6
    				begin
    				exec @recode = vspSMWorkOrderScopeValForPO @SMCo = @SMCo, @SMWorkOrder = @SMWorkOrder, @Scope = @SMScope, @GLCo = @GLCo OUTPUT, @CostAccount = @GLAcct OUTPUT, @PhaseGroup = @PhaseGroup OUTPUT, @Phase = @Phase OUTPUT
    				end
				
    			UPDATE IMWE
    			SET IMWE.UploadVal = @GLAcct
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @glacctid and IMWE.RecordType = @rectype
    			end
    	    
    		if @taxtypeid <> 0 AND (ISNULL(@OverwriteTaxType, 'Y') = 'Y' OR ISNULL(@IsTaxTypeEmpty, 'Y') = 'Y')
    			begin
    			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
    			select @TaxType = case when isnull(@hqdfltcountry, 'US') = 'US' then 1 else 3 end

    			UPDATE IMWE
    			SET IMWE.UploadVal = @TaxType
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @taxtypeid and IMWE.RecordType = @rectype
    			end
			
    		if @taxgroupid <> 0 AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'Y' OR ISNULL(@IsTaxGroupEmpty, 'Y') = 'Y')
    			begin
    			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
    			select @TaxGroup = TaxGroup from bHQCO where HQCo = @Co
    			If @TaxType = 2
    			begin
    				if @ItemType = 1 select @TaxGroup = TaxGroup from bHQCO where HQCo = @PostToCo
    				if @ItemType = 2 select @TaxGroup = TaxGroup from bHQCO where HQCo = @PostToCo
    				if @ItemType = 3 or @ItemType = 6 select @TaxGroup = TaxGroup from bHQCO where HQCo = @PostToCo
    				if @ItemType = 4 or @ItemType = 5 select @TaxGroup = TaxGroup from bHQCO where HQCo = @PostToCo
    			end
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @TaxGroup
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @taxgroupid and IMWE.RecordType = @rectype
    			end
			
    		if @taxcodeid <> 0 AND (ISNULL(@OverwriteTaxCode, 'Y') = 'Y' OR ISNULL(@IsTaxCodeEmpty, 'Y') = 'Y')
    			begin
    			-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
    			-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order
    			if @ItemType = 1 select @TaxCode = TaxCode from bJCJM where JCCo = @PostToCo and Job = @Job
    			if @ItemType = 2 select @TaxCode = TaxCode from bINLM where INCo = @PostToCo and Loc = @Loc
    			if @ItemType > 2 and @ItemType <= 6 select @TaxCode = TaxCode from bAPVM where VendorGroup = @VendorGroup and Vendor = @Vendor
    
    			UPDATE IMWE
    			SET IMWE.UploadVal = @TaxCode
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @taxcodeid and IMWE.RecordType = @rectype
    			END
    			
    		----TK-08649
    		IF @TaxRateId <> 0 AND (ISNULL(@OverwriteTaxRate, 'Y') = 'Y' OR ISNULL(@IsTaxRateEmpty, 'Y') = 'Y')
    			BEGIN
    			IF ISNULL(@TaxCode,'') = ''
    				BEGIN
    				SET @TaxRate = 0
    				END
				ELSE
					BEGIN
					---- get tax rates
					exec @recode = bspHQTaxRateGetAll @TaxGroup, @TaxCode, @ReqDate, NULL, @TaxRate output, @GSTRate output,
								null, null, null, null, null, null, null,NULL, @errmsg output
					END
					
				UPDATE IMWE
					SET IMWE.UploadVal = @TaxRate
				WHERE IMWE.ImportTemplate=@ImportTemplate
					AND IMWE.ImportId=@ImportId
					AND IMWE.RecordSeq=@currrecseq
					AND IMWE.Identifier = @TaxRateId and IMWE.RecordType = @rectype
				END
				
    		----TK-08649
    		IF @GSTRateId <> 0 AND (ISNULL(@OverwriteGSTRate, 'Y') = 'Y' OR ISNULL(@IsGSTRateEmpty, 'Y') = 'Y')
    			BEGIN
    			IF ISNULL(@TaxCode,'') = ''
    				BEGIN
    				SET @GSTRate = 0
    				END
				ELSE
					BEGIN
					---- get tax rates
					exec @recode = bspHQTaxRateGetAll @TaxGroup, @TaxCode, @ReqDate, NULL, @TaxRate output, @GSTRate output,
								null, null, null, null, null, null, null, NULL, @errmsg output
					END
					
				UPDATE IMWE
					SET IMWE.UploadVal = @GSTRate
				WHERE IMWE.ImportTemplate=@ImportTemplate
					AND IMWE.ImportId=@ImportId
					AND IMWE.RecordSeq=@currrecseq
					AND IMWE.Identifier = @GSTRateId and IMWE.RecordType = @rectype
				END
					
			----SELECT @msg = 'TaxCode and Rates: ' + dbo.vfToString(@TaxCode) + ',' + dbo.vfToString(@TaxRate) + ',' + dbo.vfToString(@GSTRate)
			----SET @rcode = 1
			----GOTO bspexit
				
    		if @origecmid <> 0 AND (ISNULL(@OverwriteOrigECM, 'Y') = 'Y' OR ISNULL(@IsOrigECMEmpty, 'Y') = 'Y')
    			begin
				if rtrim(@Job) = '' select @Job = null		--fix for #119728
				if rtrim(@Loc) = '' select @Loc = null		--fix for #119728

				if @UM <> 'LS'	--fix for #119728				
					exec @recode = bspHQMatUnitCostDflt @VendorGroup, @Vendor, @MatlGroup, @Material, @UM, @PostToCo, @Job, @PostToCo, @Loc, null, @OrigECM output, null, @errmsg output
				else
					select @OrigECM = 'E'

				if isnull(@OrigECM,'') = '' select @OrigECM = 'E'		--fix for #119728

    			UPDATE IMWE
    			SET IMWE.UploadVal = @OrigECM
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @origecmid and IMWE.RecordType = @rectype
    			end
    
    		--#30302, OrigCost default
 		if @origcostid <> 0 AND (ISNULL(@OverwriteOrigCost, 'Y') = 'Y' OR ISNULL(@IsOrigCostEmpty, 'Y') = 'Y')
 			begin
 			if @UM<>'LS'
 				begin	
 				If isnull(@OrigECM,'') = 'C'
 					begin
 					select @OrigCost=(@OrigUnits * @OrigUnitCost)/100
 					UPDATE IMWE
 					SET IMWE.UploadVal = @OrigCost
					where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
 						and IMWE.Identifier = @origcostid and IMWE.RecordType = @rectype
 				
 					end
 				else If isnull(@OrigECM,'') = 'M'
 					begin
 					select @OrigCost=(@OrigUnits * @OrigUnitCost)/1000
 					UPDATE IMWE
 					SET IMWE.UploadVal = @OrigCost
 					where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
 						and IMWE.Identifier = @origcostid and IMWE.RecordType = @rectype
 				
 					end
 				else
 					begin
 					select @OrigCost=@OrigUnits * @OrigUnitCost
 					UPDATE IMWE
 					SET IMWE.UploadVal = @OrigCost
 					where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
 						and IMWE.Identifier = @origcostid and IMWE.RecordType = @rectype
 					end
 				end
 			end

 		--DC #133625 		
		DECLARE @PODefaultjcco bCompany,
				@PODefaultemco bCompany,
				@PODefaultglco bCompany,
				@PODefaultpaycategoryyn bYN,
				@PODefaultvendorgroup bGroup, 
				@PODefaulttaxgroup bGroup, 
				@PODefaultreceiptupdateyn bYN,
				@PODefaultglrecexpinterfacelvl tinyint,
				@PODefaultrecjcinterfacelvl tinyint,
				@PODefaultreceminterfacelvl tinyint,
				@PODefaultrecininterfacelvl tinyint,
				@PODefaultpaytypeyn bYN,
				@PODefaultexppaytype tinyint,
				@PODefaultjobpaytype tinyint,
				@PODefaultSMPayType tinyint,
				@PODefaultuserprofilepaycategory int,
				@PODefaultpaycategoryapco int, 
				@PODefaultmatlgroup bGroup,
				@PODefaulthqcountry char(2),
				@PODefaulterrmsg varchar(255)
				
		EXEC vspPOCommonInfoGetForPOEntry
			@co = @Company, 
			@jcco = @PODefaultjcco OUTPUT, 
			@emco = @PODefaultemco OUTPUT, 
			@glco = @PODefaultglco OUTPUT, 
			@paycategoryyn = @PODefaultpaycategoryyn  OUTPUT, 
			@vendorgroup = @PODefaultvendorgroup  OUTPUT, 
			@taxgroup = @PODefaulttaxgroup  OUTPUT, 
			@receiptupdateyn = @PODefaultreceiptupdateyn  OUTPUT, 
			@glrecexpinterfacelvl = @PODefaultglrecexpinterfacelvl  OUTPUT, 
			@recjcinterfacelvl = @PODefaultrecjcinterfacelvl  OUTPUT, 
			@receminterfacelvl = @PODefaultreceminterfacelvl  OUTPUT, 
			@recininterfacelvl = @PODefaultrecininterfacelvl  OUTPUT, 
			@paytypeyn = @PODefaultpaytypeyn  OUTPUT, 
			@exppaytype = @PODefaultexppaytype  OUTPUT, 
			@jobpaytype = @PODefaultjobpaytype  OUTPUT, 
			@SMPayType = @PODefaultSMPayType  OUTPUT, 
			@userprofilepaycategory = @PODefaultuserprofilepaycategory  OUTPUT, 
			@paycategoryapco = @PODefaultpaycategoryapco  OUTPUT, 
			@matlgroup = @PODefaultmatlgroup  OUTPUT, 
			@hqcountry = @PODefaulthqcountry  OUTPUT, 
			@errmsg = @PODefaulterrmsg  OUTPUT
 		
 		--DC #133625
		IF @paytypeid <> 0 AND (ISNULL(@OverwritePayType, 'Y') = 'Y' OR ISNULL(@IsPayTypeEmpty, 'Y') = 'Y')
			BEGIN
			DECLARE
			@POAPDefaultexppaytype tinyint,
			@POAPDefaultjobpaytype tinyint,
			@POAPDefaultsubpaytype tinyint,
			@POAPDefaultretpaytype tinyint,
			@POAPDefaultSMPayType tinyint,
			@POAPDefaultdiscoffglacct bGLAcct,
			@POAPDefaultdisctakenglacct bGLAcct,
			@POAPDefaultmsg varchar(60)

			--DC #137780
			IF ISNULL(@PayCategory,'') = '' 
				BEGIN
				SET @PayCategory = COALESCE(@PODefaultuserprofilepaycategory, @PODefaultpaycategoryapco)							
				END				

			EXEC bspAPPayCategoryVal
			@apco = @Company, 
			@paycategory = @PayCategory, 
			@exppaytype = @POAPDefaultexppaytype OUTPUT, 
			@jobpaytype = @POAPDefaultjobpaytype OUTPUT, 
			@subpaytype = @POAPDefaultsubpaytype OUTPUT, 
			@retpaytype = @POAPDefaultretpaytype OUTPUT,
			@SMPayType = @POAPDefaultSMPayType OUTPUT,
			@discoffglacct = @POAPDefaultdiscoffglacct OUTPUT, 
			@disctakenglacct = @POAPDefaultdisctakenglacct OUTPUT, 
			@msg = @POAPDefaultmsg OUTPUT
						
			IF ISNULL(@PODefaultpaytypeyn, 'N') = 'Y' AND ISNULL(@PayCategory, '') <> '' AND ISNULL(@PODefaultpaycategoryyn,'N')='Y'
				IF @ItemType = 1
					SET @PayType = @POAPDefaultjobpaytype
				ELSE
					SET @PayType = @POAPDefaultexppaytype
			ELSE
				IF ISNULL(@PODefaultpaytypeyn, 'N') = 'Y'
				BEGIN
					IF @ItemType = 1
						SET @PayType = @PODefaultjobpaytype
					ELSE
						SET @PayType = @PODefaultexppaytype
				END
			
			IF @PayType IS NOT NULL
		 		UPDATE IMWE
				SET IMWE.UploadVal = @PayType
				WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
					AND IMWE.Identifier = @paytypeid AND IMWE.RecordType = @rectype
			
			END
 		    
		IF @paycategoryid <> 0 AND (ISNULL(@OverwritePayCategory, 'Y') = 'Y' OR ISNULL(@IsPayCategoryEmpty, 'Y') = 'Y')
			BEGIN
					
			EXEC vspPOCommonInfoGetForPOEntry
				@co = @Company, 
				@jcco = @PODefaultjcco OUTPUT, 
				@emco = @PODefaultemco OUTPUT, 
				@glco = @PODefaultglco OUTPUT, 
				@paycategoryyn = @PODefaultpaycategoryyn  OUTPUT, 
				@vendorgroup = @PODefaultvendorgroup  OUTPUT, 
				@taxgroup = @PODefaulttaxgroup  OUTPUT, 
				@receiptupdateyn = @PODefaultreceiptupdateyn  OUTPUT, 
				@glrecexpinterfacelvl = @PODefaultglrecexpinterfacelvl  OUTPUT, 
				@recjcinterfacelvl = @PODefaultrecjcinterfacelvl  OUTPUT, 
				@receminterfacelvl = @PODefaultreceminterfacelvl  OUTPUT, 
				@recininterfacelvl = @PODefaultrecininterfacelvl  OUTPUT, 
				@paytypeyn = @PODefaultpaytypeyn  OUTPUT, 
				@exppaytype = @PODefaultexppaytype  OUTPUT, 
				@jobpaytype = @PODefaultjobpaytype  OUTPUT, 
				@SMPayType = @PODefaultSMPayType  OUTPUT, 
				@userprofilepaycategory = @PODefaultuserprofilepaycategory  OUTPUT, 
				@paycategoryapco = @PODefaultpaycategoryapco  OUTPUT, 
				@matlgroup = @PODefaultmatlgroup  OUTPUT, 
				@hqcountry = @PODefaulthqcountry  OUTPUT, 
				@errmsg = @PODefaulterrmsg  OUTPUT			
			
			IF ISNULL(@PODefaultpaytypeyn,'N') = 'Y' AND ISNULL(@PODefaultpaycategoryyn, 'N') = 'Y'
				BEGIN
				SET @PayCategory = COALESCE(@PODefaultuserprofilepaycategory, @PODefaultpaycategoryapco)
				
 				UPDATE IMWE
				SET IMWE.UploadVal = @PayCategory
				WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
					AND IMWE.Identifier = @paycategoryid AND IMWE.RecordType = @rectype
				END					
			END		    
		
		--DC #133625 & #137780  
		IF isnull(@PODefaultpaytypeyn, 'N') = 'N' 
			BEGIN
			IF @paycategoryid <>0  --DC #137780
				BEGIN
				UPDATE IMWE
				SET IMWE.UploadVal = NULL
				WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
					AND IMWE.Identifier = @paycategoryid AND IMWE.RecordType = @rectype								
				END
			
			IF @paytypeid<>0  --DC #137780
				BEGIN
 				UPDATE IMWE
				SET IMWE.UploadVal = NULL
				WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
					AND IMWE.Identifier = @paytypeid AND IMWE.RecordType = @rectype							
				END
			END			
		ELSE							
			BEGIN
			IF isnull(@PODefaultpaycategoryyn, 'N') = 'N'  --DC #137780
				BEGIN
				UPDATE IMWE
				SET IMWE.UploadVal = NULL
				WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
					AND IMWE.Identifier = @paycategoryid AND IMWE.RecordType = @rectype
				END			
			END		  
		 
		IF @taxamtid <> 0 AND (ISNULL(@OverwriteOrigTax, 'Y') = 'Y' OR ISNULL(@IsOrigTaxEmpty, 'Y') = 'Y')
			BEGIN
			IF isnull(@TaxCode,'') = ''
				SET @OrigTax = 0
			ELSE
				BEGIN

				select @filterTaxRate = NULL, @fillerPhase = null, @fillerCostType=NULL
				
				exec @recode = bspHQTaxRateGet @TaxGroup, @TaxCode, @ReqDate, @filterTaxRate output, @fillerPhase output, @fillerCostType output, @errmsg output

				select @OrigTax = isnull(@filterTaxRate,0) * isnull(@OrigCost,0)
				END

			UPDATE IMWE
			SET IMWE.UploadVal = @OrigTax
			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
				and IMWE.Identifier = @taxamtid and IMWE.RecordType = @rectype
			END

		IF @SMCo IS NOT NULL AND @SMWorkOrder IS NOT NULL AND @SMScope IS NOT NULL
		BEGIN 
		
			IF @smphasegroupid <> 0 AND (ISNULL(@OverwriteSMPhaseGroup, 'Y') = 'Y' OR ISNULL(@IsSMPhaseGroupEmpty, 'Y') = 'Y')
			BEGIN
				UPDATE IMWE
				SET IMWE.UploadVal = @PhaseGroup
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @smphasegroupid and IMWE.RecordType = @rectype
			END
			
			IF @smphaseid <> 0 AND (ISNULL(@OverwriteSMPhase, 'Y') = 'Y' OR ISNULL(@IsSMPhaseEmpty, 'Y') = 'Y')
			BEGIN
				UPDATE IMWE
				SET IMWE.UploadVal = @Phase
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @smphaseid and IMWE.RecordType = @rectype
			END
			
		END
		
    	-- Clean up columns based on linetype
    	-- LINE TYPE 1=Job,2=Inventory, 3=Expense, 4=Equipment, 5=Work Order, 6=Purchase Order, 7=Subcontract
    
    	-- PO Item Type 1 = Job, 2 = Inventory, 3 = Expense, 4 = Equipment, 5 = Work Order, 6 = SM Work Order
    	if @ItemType = 1
    		begin 
    		 UPDATE IMWE
    		 SET IMWE.UploadVal = null
    		 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
    		 (IMWE.Identifier = @clocid
    		 or IMWE.Identifier = @cequipid or IMWE.Identifier = @ccostcodeid or IMWE.Identifier = @cemctypeid or IMWE.Identifier = @ccomptypeid or IMWE.Identifier = @ccomponentid
    		 or IMWE.Identifier = @cwoid or IMWE.Identifier = @cwoitemid or IMWE.Identifier = @smcoid or IMWE.Identifier = @smworkorderid or IMWE.Identifier = @smscopeid
    		 or IMWE.Identifier = @smphasegroupid or IMWE.Identifier = @smphaseid or IMWE.Identifier = @smjccosttypeid)
    		end
    
    	if @ItemType = 2
    		begin 
    		 UPDATE IMWE
    		 SET IMWE.UploadVal = null
    		 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
    		 (IMWE.Identifier = @cjobid or IMWE.Identifier = @cphaseid or IMWE.Identifier = @cjcctypeid
    		 or IMWE.Identifier = @cwoid or IMWE.Identifier = @cwoitemid
    		 or IMWE.Identifier = @cequipid or IMWE.Identifier = @ccostcodeid or IMWE.Identifier = @cemctypeid or IMWE.Identifier = @ccomptypeid or IMWE.Identifier = @ccomponentid
    		 or IMWE.Identifier = @smcoid or IMWE.Identifier = @smworkorderid or IMWE.Identifier = @smscopeid
    		 or IMWE.Identifier = @smphasegroupid or IMWE.Identifier = @smphaseid or IMWE.Identifier = @smjccosttypeid)
    		end
    
    	if @ItemType = 3 or @ItemType = 6
    		begin 
    		 UPDATE IMWE
    		 SET IMWE.UploadVal = null
    		 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
    		 (IMWE.Identifier = @clocid or IMWE.Identifier = @cwoid or IMWE.Identifier = @cwoitemid
    		 or IMWE.Identifier = @cequipid or IMWE.Identifier = @ccostcodeid or IMWE.Identifier = @cemctypeid or IMWE.Identifier = @ccomptypeid or IMWE.Identifier = @ccomponentid
    		 or IMWE.Identifier = @cjobid or IMWE.Identifier = @cphaseid or IMWE.Identifier = @cjcctypeid)
    		end

    	if @ItemType = 3
    		begin
    		 UPDATE IMWE
    		 SET IMWE.UploadVal = null
    		 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
    		 (IMWE.Identifier = @smcoid or IMWE.Identifier = @smworkorderid or IMWE.Identifier = @smscopeid
    		 or IMWE.Identifier = @smphasegroupid or IMWE.Identifier = @smphaseid or IMWE.Identifier = @smjccosttypeid)
    		end
    
    	if @ItemType = 4
    		begin 
    		 UPDATE IMWE
    		 SET IMWE.UploadVal = null
    		 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
    		 (IMWE.Identifier = @clocid or IMWE.Identifier = @cwoid or IMWE.Identifier = @cwoitemid
    		 or IMWE.Identifier = @cjobid or IMWE.Identifier = @cphaseid or IMWE.Identifier = @cjcctypeid
    		 or IMWE.Identifier = @smcoid or IMWE.Identifier = @smworkorderid or IMWE.Identifier = @smscopeid
    		 or IMWE.Identifier = @smphasegroupid or IMWE.Identifier = @smphaseid or IMWE.Identifier = @smjccosttypeid)
    		end
    
    	if @ItemType = 5
    		begin 
    		 UPDATE IMWE
    		 SET IMWE.UploadVal = null
    		 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
    		 ( IMWE.Identifier = @clocid
    		 or IMWE.Identifier = @cjobid or IMWE.Identifier = @cphaseid or IMWE.Identifier = @cjcctypeid
    		 or IMWE.Identifier = @smcoid or IMWE.Identifier = @smworkorderid or IMWE.Identifier = @smscopeid
    		 or IMWE.Identifier = @smphasegroupid or IMWE.Identifier = @smphaseid or IMWE.Identifier = @smjccosttypeid)
    		end
    
    	if @UM = 'LS' and @cecmid <> 0
    		begin 
    		 UPDATE IMWE
    		 SET IMWE.UploadVal = null
    		 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype and
    		 IMWE.Identifier = @cecmid 
    		end

		IF @DescriptionID <> 0 AND ISNULL(@Material,'')<>'' AND (ISNULL(@OverwriteDescription, 'Y') = 'Y' OR ISNULL(@IsDescriptionEmpty, 'Y') = 'Y')
			BEGIN							
			DECLARE @TmpDescription VARCHAR(100)
			IF @ItemType = 1 OR @ItemType = 3 OR @ItemType=6
				BEGIN
				--#142350 change @vendmatid
				DECLARE @vendmatidOUTItemType1 varchar(30),
						@purchaseum bUM,
						@matphase bPhase,
						@matcosttype bJCCType,
						@taxable bYN,
						@MatValMsg varchar(60)

				EXEC bspHQMatValForPO 
						@poco = @Co,
						@matlgroup = @MatlGroup,
						@material = @Material,
						@potype = @ItemType,
						@vendor = @Vendor,
						@description = @TmpDescription OUTPUT,
						@vendmatid = @vendmatidOUTItemType1 OUTPUT,
						@purchaseum = @purchaseum OUTPUT, 
						@matphase = @matphase OUTPUT, 
						@matcosttype = @matcosttype OUTPUT, 
						@taxable = @taxable OUTPUT,
						@msg = @MatValMsg OUTPUT
				END
			IF @ItemType = 2
				BEGIN
				DECLARE @vendmatidOUT varchar(30), @purchaseumOUT bUM, @taxableOUT bYN, @taxcodeOUT bTaxCode, @onhandOUT bUnits, @onorderOUT bUnits, @msgOUT varchar(60) 

				EXEC bspINLocMatlValForPO
					@inco = @Co, 
					@location = @HeaderLoc, 
					@material = @Material,
					@matlgroup = @MatlGroup, 
					@vendor = @Vendor, 
					@description = @TmpDescription output,
					@vendmatid = @vendmatidOUT output,  
					@purchaseum = @purchaseumOUT output, 
					@taxable = @taxableOUT output,
					@taxcode = @taxcodeOUT output, 
					@onhand = @onhandOUT output, 
					@onorder = @onorderOUT output,
					@msg = @msgOUT output
				END

			IF @ItemType = 4 OR @ItemType = 5
				BEGIN
					--#142350 change @umOUT
					DECLARE @umOUTItemType4 bUM,
							@taxcodeflagOUT char(1),
							@EMvendmatidOUT varchar(30),
							@UseDateOUT bDate,
							@EMmsgOUT varchar(255)
							 
					EXEC bspPOMatlValForEM
							@vendorgroup =@VendorGroup, 
							@vendor = @Vendor,
							@emco = @Co,
							@equipment = @Equip,
							@matlgroup = @MatlGroup,
							@material = @Material,
							@defum = @UM, 
							@um = @umOUTItemType4 OUTPUT,
							@matldesc = @TmpDescription OUTPUT,
							@taxcodeflag = @taxcodeflagOUT OUTPUT, 
							@vendmatid = @EMvendmatidOUT OUTPUT,
							@matllastuseddate = @UseDateOUT OUTPUT, 
							@msg = @EMmsgOUT OUTPUT
				END

			IF ISNULL(@TmpDescription, '') <> 'Not in this material file.'
				SELECT @Description = @TmpDescription

			 UPDATE IMWE
			 SET IMWE.UploadVal = @Description
			 where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.RecordType = @rectype 
				and IMWE.Identifier = @DescriptionID 
			END

    	select @currrecseq = @Recseq
    	select @counter = @counter + 1
    
    select @Co =null, @Mth =null, @BatchId =null, @BatchSeq =null, @POItem =null, @BatchTransType =null, 
    @ItemType =null, @MatlGroup =null, @Material =null, @VendMatId =null, @Description =null, @UM =null, @RecvYN =null, @PostToCo =null,
    @Loc =null, @Job =null, @PhaseGroup =null, @Phase =null, @JCCType =null, @WO =null, @WOItem =null,
    @Equip =null, @EMGroup =null, @CostCode =null, @EMCType =null, @CompType =null, @Component =null,
    @GLCo =null, @GLAcct =null, @ReqDate =null, @TaxGroup =null, @TaxCode =null, @TaxType =null, 
    @OrigUnits =null, @OrigUnitCost =null, @OrigECM =null, @OrigCost =null, @OrigTax =null,
    @RequisitionNum =null, @PayType = null, @PayCategory = null,
    @hqmtum = null, @vendmtum = NULL,  --DC #124246 --DC #137114
    ----TK-08649
    @TaxRate = NULL, @GSTRate = NULL
    
    	end
    
    end
    
    
    
    close WorkEditCursor
    deallocate WorkEditCursor
    
    
    	UPDATE IMWE
    	SET IMWE.UploadVal = 0
    	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
    	  and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'')='' and
    	 (IMWE.Identifier = @zorigunitsid or IMWE.Identifier = @zorigunitcostid or IMWE.Identifier = @zorigcostid
    	 or IMWE.Identifier = @zorigtaxid)
    
    	UPDATE IMWE
    	SET IMWE.UploadVal = 'N'
    	where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId 
    	  and IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'') not in ('N','Y') and
    	 (IMWE.Identifier = @nrecvyn)
    
    
    bspexit:
    	----select @msg = isnull(@desc,'Item') + char(13) + char(13) + '[bspBidtekDefaultPOIB]'
    
    	return @rcode









GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsPOIB] TO [public]
GO
