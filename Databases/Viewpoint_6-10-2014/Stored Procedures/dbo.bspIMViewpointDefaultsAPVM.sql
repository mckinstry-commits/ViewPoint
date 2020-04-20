SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsAPVM]
    /***********************************************************
     * CREATED BY:   RBT 02/20/04 for issue #23725
     * MODIFIED BY:  RBT 05/16/05 - issue #28683, change default for AuditYN to Y.
     *			     DANF 02/14/07 - issue 120854 Create unique sort name during import process.
	 *				 DANF 04/16/07 - Issue 122202 Upper case sortname 
	 *				 CC 08/07/08   - Issue 129154 Clear 1099 Box and 1099 Type when V1099YN = N
	 *				 CC  02/18/09  - Issue #24531 - Use default only if set to overwrite or value is null
	 *				 MV	03/22/10 - #137714 - Add missing AU and CA fields.
	 *				 MV 04/13/10 - #137714 - fixed rej 1 issues.
	 *				 MV 04/27/10 - #137714 - fixed rej 2 issues.
	 *				 MV 05/04/10 - #137714 - fixed sortname, ActiveYN, TempYN defaults when no Viewpoint default
	 *				 MV 06/07/10 - #139733 - for AU, if AUEFTYN = 'Y' then set EFT to 'A' - Active.  
	 *				AMR 01/12/11 - #142350, making case sensitive by removing unused vars and renaming same named variables
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
    
    declare @rcode int, @desc varchar(120), @status int, @defaultvalue varchar(30), @CursorOpen int	
    
    --Identifiers
    declare @SortNameID int, @VendorGroupID int, @TypeID int, @TempID int, @ActiveID int, 
    @AuditID int, @PurgeID int, @EFTID int, @SeparatePayInvID int, @V1099YNID int, @V1099TypeID int, 
    @V1099BoxID int, @OverrideMinAmtID int, @APRefUnqOvrID int, @TaxGroupID int, @GLCoID int,
    @AcctTypeID int, @CustGroupID int, @PayInfoDelivMthdID int,
	-- US IAT fields
	@IATYNID int,@ISODestinationCountryCodeID int, @RDFIBankNameID int,                 
	@BranchCountryCodeID int,@RDFIIdentNbrQualifierID int,@GatewayOperatorRDFIIdentID int,
	-- AU fields
	@AUVendorEFTID int, @AusBusNbrID int, @AusCorpNbrID int,@AUVendorAccountNumberID int,         
	@AUVendorBSBID int, @AUVendorReferenceID int,             
	-- CA WC fields
    @CASubjToWCID int,@CAClearanceCertID int,@CACertEffectiveDateID int,
	-- CA T5018 fields
	@T5FirstNameID int,@T5MiddleInitID int,@T5LastNameID int,@T5SocInsNbrID int, @T5BusinessNbrID int,
	@T5BusTypeCodeID int,@T5PartnerFINID int 
    
    --Values
    declare @SortName bSortName, @ynSortName bYN, @DefVendorGroup bGroup, @VendorGroup bGroup,
    	@Name varchar(60), @Vendor bVendor, @DefTaxGroup bGroup, @DefGLCo bCompany, @EFT char(1),
    	@ynAcctType bYN, @DefCustGroup bGroup, @ynV1099YN bYN, @ynIATYN bYN, @PayInfoDelivMth char(1),
		@ynAUVendorEFTYN bYN, @ynCASubjToWC bYN, @hqcodefaultcountry varchar(3)
    
    /* check required input params */
    
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
    
    DECLARE 
			  @OverwriteVendorGroup 	 	 bYN
			, @OverwriteType 	 			 bYN
			, @OverwriteTempYN 	 			 bYN
			, @OverwriteActiveYN 	 		 bYN
			, @OverwriteAuditYN 	 		 bYN
			, @OverwritePurge 	 			 bYN
			, @OverwriteEFT 	 			 bYN
			, @OverwriteSeparatePayInvYN 	 bYN
			, @OverwriteV1099YN 	 	 	 bYN
			, @OverwriteV1099Type 	 	 	 bYN
			, @OverwriteV1099Box 	 	 	 bYN
			, @OverwriteOverrideMinAmtYN 	 bYN
			, @OverwriteAPRefUnqOvr 	 	 bYN
			, @OverwriteTaxGroup 	 		 bYN
			, @OverwriteGLCo 	 			 bYN
			, @OverwriteCustGroup 	 		 bYN
			, @OverwriteSortName 	 		 bYN
			, @OverwriteAcctType 	 		 bYN
			, @OverwriteIATYN 	 			 bYN
			, @OverwriteAUVendorEFTYN 		 bYN
			, @OverwriteCASubjToWC 	 		 bYN
			,	@IsVendorGroupEmpty 		 bYN
			,	@IsVendorEmpty 				 bYN
			,	@IsAuditYNEmpty 			 bYN
			,	@IsNameEmpty 				 bYN
			,	@IsSortNameEmpty 			 bYN
			,	@IsContactEmpty 			 bYN
			,	@IsPhoneEmpty 				 bYN
			,	@IsFaxEmpty 				 bYN
			,	@IsTempYNEmpty 				 bYN
			,	@IsActiveYNEmpty 			 bYN
			,	@IsPurgeEmpty 				 bYN
			,	@IsTypeEmpty 				 bYN
			,	@IsPayTermsEmpty 			 bYN
			,	@IsTaxGroupEmpty 			 bYN
			,	@IsTaxCodeEmpty 			 bYN
			,	@IsGLCoEmpty 				 bYN
			,	@IsGLAcctEmpty 				 bYN
			,	@IsAddnlInfoEmpty 			 bYN
			,	@IsAddressEmpty 			 bYN
			,	@IsCityEmpty 				 bYN
			,	@IsStateEmpty 				 bYN
			,	@IsCountryEmpty 			 bYN
			,	@IsZipEmpty 				 bYN
			,	@IsAddress2Empty 			 bYN
			,	@IsPOAddressEmpty 			 bYN
			,	@IsPOCityEmpty 				 bYN
			,	@IsPOStateEmpty 			 bYN
			,	@IsPOCountryEmpty 			 bYN
			,	@IsPOZipEmpty 				 bYN
			,	@IsPOAddress2Empty 			 bYN
			,	@IsV1099YNEmpty 			 bYN
			,	@IsV1099TypeEmpty 			 bYN
			,	@IsV1099BoxEmpty 			 bYN
			,	@IsTaxIdEmpty 				 bYN
			,	@IsPropEmpty 				 bYN
			,	@IsLastInvDateEmpty 		 bYN
			,	@IsOverrideMinAmtYNEmpty 	 bYN
			,	@IsSeparatePayInvYNEmpty 	 bYN
			,	@IsEFTEmpty 				 bYN
			,	@IsRoutingIdEmpty 			 bYN
			,	@IsBankAcctEmpty 			 bYN
			,	@IsAcctTypeEmpty 			 bYN
			,	@IsEMailEmpty 				 bYN
			,	@IsURLEmpty 				 bYN
			,	@IsCustGroupEmpty 			 bYN
			,	@IsCustomerEmpty 			 bYN
			,	@IsReviewerEmpty 			 bYN
			,	@IsAddendaTypeIdEmpty 		 bYN
			,	@IsMasterVendorEmpty 		 bYN
			,	@IsAPRefUnqOvrEmpty 		 bYN
			,	@IsICFirstNameEmpty 		 bYN
			,	@IsICMInitialEmpty 			 bYN
			,	@IsICLastNameEmpty 			 bYN
			,	@IsICSocSecNbrEmpty 		 bYN
			,	@IsICStreetNbrEmpty 		 bYN
			,	@IsICStreetNameEmpty 		 bYN
			,	@IsICAptNbrEmpty 			 bYN
			,	@IsICCityEmpty 				 bYN
			,	@IsICStateEmpty 			 bYN
			,	@IsICCountryEmpty 			 bYN
			,	@IsICZipEmpty 				 bYN
			,	@IsICLastRptDateEmpty 		 bYN
			,	@IsNotesEmpty 				 bYN
			,	@IsIATYNEmpty		 				 bYN
			,	@IsISODestCountryCodeEmpty 			 bYN
			,	@IsRDFIIdentNbrQualEmpty 			 bYN
			,	@IsBranchCountryCodeEmpty			 bYN
			,	@IsRDFIBankNameEmpty 				 bYN
			,	@IsGatewayOpRDFIIdentEmpty 			 bYN
			,	@IsAUVendorBSBEmpty		 			 bYN
			,	@IsAUVendorAccountNumberEmpty 		 bYN
			,	@IsAUVendorReferenceEmpty			 bYN
			,	@IsAUVendorEFTYNEmpty		 		 bYN
			,	@IsPayInfoDelivMthdEmpty	 		 bYN
			,	@IsT5FirstNameEmpty			 		 bYN
			,	@IsT5MiddleInitEmpty	 			 bYN
			,	@IsT5LastNameEmpty					 bYN
			,	@IsT5SocInsNbrEmpty			 		 bYN
			,	@IsT5BusinessNbrEmpty				 bYN
			,	@IsT5BusTypeCodeEmpty		 		 bYN
			,	@IsT5PartnerFINEmpty				 bYN
			,	@IsAusBusNbrEmpty					 bYN
			,	@IsAusCorpNbrEmpty					 bYN
			,	@IsPayControlEmpty		 			 bYN
			,	@IsCASubjToWCEmpty 					 bYN
			,	@IsCAClearanceCertEmpty				 bYN
			,	@IsCMAcctEmpty		 				 bYN
			,	@IsCACertEffectiveDateEmpty			 bYN


			

SELECT @OverwriteVendorGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendorGroup', @rectype);
SELECT @OverwriteType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Type', @rectype);
SELECT @OverwriteTempYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TempYN', @rectype);
SELECT @OverwriteActiveYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActiveYN', @rectype);
SELECT @OverwriteAuditYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AuditYN', @rectype);
SELECT @OverwritePurge = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Purge', @rectype);
SELECT @OverwriteEFT = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'EFT', @rectype);
SELECT @OverwriteSeparatePayInvYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SeparatePayInvYN', @rectype);
SELECT @OverwriteV1099YN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'V1099YN', @rectype);
SELECT @OverwriteV1099Type = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'V1099Type', @rectype);
SELECT @OverwriteV1099Box = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'V1099Box', @rectype);
SELECT @OverwriteOverrideMinAmtYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OverrideMinAmtYN', @rectype);
SELECT @OverwriteAPRefUnqOvr = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'APRefUnqOvr', @rectype);
SELECT @OverwriteTaxGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxGroup', @rectype);
SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
SELECT @OverwriteCustGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CustGroup', @rectype);
SELECT @OverwriteSortName = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SortName', @rectype);
SELECT @OverwriteAcctType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AcctType', @rectype);
SELECT @OverwriteIATYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'IATYN', @rectype);
SELECT @OverwriteAUVendorEFTYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'AUVendorEFTYN', @rectype);
SELECT @OverwriteCASubjToWC = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CASubjToWC', @rectype);

  
 
    --get database default values
    select @DefVendorGroup = VendorGroup, @hqcodefaultcountry = DefaultCountry from bHQCO with (nolock) where HQCo = @Company
    select @DefTaxGroup = TaxGroup from bHQCO with (nolock) where HQCo = @Company
    select @DefGLCo = GLCo from bAPCO where APCo = @Company
    select @DefCustGroup = CustGroup from bHQCO with (nolock) where HQCo = @Company
    
    --set common defaults
    select @VendorGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'VendorGroup'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteVendorGroup, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = @DefVendorGroup
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @VendorGroupID
    end
    
    select @TypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Type'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteType, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'R'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @TypeID
    end
    
    select @TempID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TempYN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteTempYN, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @TempID
    end
    
    select @ActiveID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActiveYN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteActiveYN, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'Y'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActiveID
    end
    
    select @AuditID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AuditYN'  AND (ISNULL(@OverwriteAuditYN, 'Y') = 'Y')
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'Y'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @AuditID
    end
    
    select @PurgeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Purge'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePurge, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @PurgeID
    end
    
    select @EFTID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EFT'  
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteEFT, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @EFTID
    end
    
    select @SeparatePayInvID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SeparatePayInvYN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSeparatePayInvYN, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @SeparatePayInvID
    end
    
    select @V1099YNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'V1099YN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteV1099YN, 'Y') = 'Y')
    begin
		if @hqcodefaultcountry = 'US'
			BEGIN
			UPDATE IMWE
			SET IMWE.UploadVal = 'Y'
			where IMWE.ImportTemplate=@ImportTemplate and 
    		IMWE.ImportId=@ImportId and IMWE.Identifier = @V1099YNID
    		AND IMWE.UploadVal IS NULL
			END
		else
			BEGIN
			UPDATE IMWE
			SET IMWE.UploadVal = 'N'
			where IMWE.ImportTemplate=@ImportTemplate and 
    		IMWE.ImportId=@ImportId and IMWE.Identifier = @V1099YNID
    		AND IMWE.UploadVal IS NULL
			END
    end
    
    select @V1099TypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'V1099Type'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteV1099Type, 'Y') = 'Y')
     begin
	if @hqcodefaultcountry = 'US'
		BEGIN
		UPDATE IMWE
		SET IMWE.UploadVal = 'MISC'
		where IMWE.ImportTemplate=@ImportTemplate and 
		IMWE.ImportId=@ImportId and IMWE.Identifier = @V1099TypeID
		AND IMWE.UploadVal IS NULL
		END
    end
    
    select @V1099BoxID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'V1099Box'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteV1099Box, 'Y') = 'Y')
    begin
	if @hqcodefaultcountry = 'US'
		BEGIN
        UPDATE IMWE
        SET IMWE.UploadVal = '7'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @V1099BoxID
    	AND IMWE.UploadVal IS NULL
		END
    end
    
    select @OverrideMinAmtID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OverrideMinAmtYN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteOverrideMinAmtYN, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @OverrideMinAmtID
    end
    
    select @APRefUnqOvrID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'APRefUnqOvr'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAPRefUnqOvr, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @APRefUnqOvrID
    end
    
    select @TaxGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxGroup'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = @DefTaxGroup
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @TaxGroupID
    end
    
    select @GLCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLCo'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = @DefGLCo
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @GLCoID
    end
    
    select @CustGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CustGroup'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteCustGroup, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = @DefCustGroup
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @CustGroupID
    end

	select @IATYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'IATYN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteIATYN, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @IATYNID
    end

	select @AUVendorEFTID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AUVendorEFTYN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteAUVendorEFTYN, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @AUVendorEFTID
    end

	 select @CASubjToWCID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CASubjToWC'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteCASubjToWC, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @CASubjToWCID
    end
   
    
    ------------------------------------------
    
    select @VendorGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'VendorGroup'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteVendorGroup, 'Y') = 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = @DefVendorGroup
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @VendorGroupID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @TypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Type'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteType, 'Y') = 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'R'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @TypeID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @TempID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TempYN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteTempYN, 'Y') = 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @TempID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @ActiveID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ActiveYN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteActiveYN, 'Y') = 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'Y'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @ActiveID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @AuditID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AuditYN'  AND (ISNULL(@OverwriteAuditYN, 'Y') = 'N')
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'Y'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @AuditID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @PurgeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Purge'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwritePurge, 'Y') = 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @PurgeID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @EFTID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EFT'  
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteEFT, 'Y') = 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @EFTID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @SeparatePayInvID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SeparatePayInvYN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSeparatePayInvYN, 'Y') = 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @SeparatePayInvID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @V1099YNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'V1099YN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteV1099YN, 'Y') = 'N') 
    begin
		if @hqcodefaultcountry = 'US'
			BEGIN
			UPDATE IMWE
			SET IMWE.UploadVal = 'Y'
			where IMWE.ImportTemplate=@ImportTemplate and 
    		IMWE.ImportId=@ImportId and IMWE.Identifier = @V1099YNID
    		AND IMWE.UploadVal IS NULL
			END
		else
			BEGIN
			UPDATE IMWE
			SET IMWE.UploadVal = 'N'
			where IMWE.ImportTemplate=@ImportTemplate and 
    		IMWE.ImportId=@ImportId and IMWE.Identifier = @V1099YNID
    		AND IMWE.UploadVal IS NULL
			END
    end
    
    select @V1099TypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'V1099Type'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteV1099Type, 'Y') = 'N')
    begin
	if @hqcodefaultcountry = 'US'
		BEGIN
		UPDATE IMWE
		SET IMWE.UploadVal = 'MISC'
		where IMWE.ImportTemplate=@ImportTemplate and 
		IMWE.ImportId=@ImportId and IMWE.Identifier = @V1099TypeID
		AND IMWE.UploadVal IS NULL
		END
    end
    
    select @V1099BoxID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'V1099Box'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteV1099Box, 'Y') = 'N')
    begin
	if @hqcodefaultcountry = 'US'
		BEGIN
        UPDATE IMWE
        SET IMWE.UploadVal = '7'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @V1099BoxID
    	AND IMWE.UploadVal IS NULL
		END
    end
    
    select @OverrideMinAmtID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'OverrideMinAmtYN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteOverrideMinAmtYN, 'Y') = 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @OverrideMinAmtID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @APRefUnqOvrID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'APRefUnqOvr'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteAPRefUnqOvr, 'Y') = 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @APRefUnqOvrID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @TaxGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxGroup'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = @DefTaxGroup
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @TaxGroupID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @GLCoID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLCo'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteGLCo, 'Y') = 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = @DefGLCo
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @GLCoID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @CustGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CustGroup'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteCustGroup, 'Y') = 'N')
    begin
        UPDATE IMWE
   SET IMWE.UploadVal = @DefCustGroup
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @CustGroupID
    	AND IMWE.UploadVal IS NULL
    end

	select @IATYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'IATYN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteIATYN, 'Y') = 'N')
    begin
    UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @IATYNID
    	AND IMWE.UploadVal IS NULL
    end

	select @AUVendorEFTID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'AUVendorEFTYN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteAUVendorEFTYN, 'Y') = 'N')
    begin
    UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @AUVendorEFTID
    	AND IMWE.UploadVal IS NULL
    end

	select @CASubjToWCID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CASubjToWC'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteCASubjToWC, 'Y') = 'N')
    begin
    UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @CASubjToWCID
    	AND IMWE.UploadVal IS NULL
    end
----------------------------------------------------------------------------------------------------------
   
    --Get Identifiers for dependent defaults.
    select @ynSortName = 'N'
    select @SortNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SortName', @rectype, 'N')
    if @SortNameID <> 0 select @ynSortName = 'Y'
    
    select @ynAcctType = 'N'
    select @AcctTypeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AcctType', @rectype, 'N')
    if @AcctTypeID <> 0 select @ynAcctType = 'Y'

	-- Get identifiers for dependent fields
	select @ISODestinationCountryCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ISODestinationCountryCode', @rectype, 'N')
	select @RDFIBankNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RDFIBankName', @rectype, 'N')
	select @BranchCountryCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BranchCountryCode', @rectype, 'N')
	select @RDFIIdentNbrQualifierID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RDFIIdentNbrQualifier', @rectype, 'N')
	select @GatewayOperatorRDFIIdentID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GatewayOperatorRDFIIdent', @rectype, 'N')
	select @AusBusNbrID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AusBusNbr', @rectype, 'N')
	select @AusCorpNbrID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AusCorpNbr', @rectype, 'N')
	select @AUVendorAccountNumberID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AUVendorAccountNumber', @rectype, 'N')
	select @AUVendorBSBID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AUVendorBSB', @rectype, 'N')
	select @AUVendorReferenceID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'AUVendorReference', @rectype, 'N')
	select @CAClearanceCertID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CAClearanceCert', @rectype, 'N')
	select @CACertEffectiveDateID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CACertEffectiveDate', @rectype, 'N')
	select @T5FirstNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'T5FirstName', @rectype, 'N')
	select @T5MiddleInitID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'T5MiddleInit', @rectype, 'N')
	select @T5LastNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'T5LastName', @rectype, 'N')
	select @T5SocInsNbrID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'T5SocInsNbr', @rectype, 'N')
	select @T5BusinessNbrID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'T5BusinessNbr', @rectype, 'N')
	select @T5BusTypeCodeID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'T5BusTypeCode', @rectype, 'N')
	select @T5PartnerFINID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'T5PartnerFIN', @rectype, 'N')
	select @PayInfoDelivMthdID = DDUD.Identifier From IMTD with (nolock)
        inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form and IMTD.RecordType = @rectype
        Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName like 'PayInfoDelivMthd%'


    --Start Processing
    DECLARE WorkEditCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
    FROM IMWE with (nolock)
    INNER join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
    WHERE IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
    ORDER BY IMWE.RecordSeq, IMWE.Identifier
    
    open WorkEditCursor
    -- set open cursor flag
    select @CursorOpen = 1
    --#142350 removing @importid, @seq
    DECLARE @Recseq int,
			@Tablename varchar(20),
			@Column varchar(30),
			@Uploadval varchar(60),
			@Ident int,
			@complete int
    
    declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
            @columnlist varchar(255), @records int, @oldrecseq int
    
    select @complete = 0
    
    fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
    select @complete = @@fetch_status
    select @currrecseq = @Recseq
    
    -- while cursor is not empty
    while @complete = 0
    begin
      -- if rec sequence = current rec sequence flag
      if @Recseq = @currrecseq
      begin
    
        If @Column = 'Vendor' select @Vendor = @Uploadval
        If @Column = 'Name' select @Name = @Uploadval
        If @Column = 'VendorGroup' select @VendorGroup = @Uploadval
        If @Column = 'EFT' select @EFT = @Uploadval
		If @Column = 'V1099YN' select @ynV1099YN = @Uploadval

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
		IF @Column='AuditYN' 
			IF @Uploadval IS NULL
				SET @IsAuditYNEmpty = 'Y'
			ELSE
				SET @IsAuditYNEmpty = 'N'
		IF @Column='Name' 
			IF @Uploadval IS NULL
				SET @IsNameEmpty = 'Y'
			ELSE
				SET @IsNameEmpty = 'N'
		IF @Column='SortName' 
			IF @Uploadval IS NULL
				SET @IsSortNameEmpty = 'Y'
			ELSE
				SET @IsSortNameEmpty = 'N'
		IF @Column='Contact' 
			IF @Uploadval IS NULL
				SET @IsContactEmpty = 'Y'
			ELSE
				SET @IsContactEmpty = 'N'
		IF @Column='Phone' 
			IF @Uploadval IS NULL
				SET @IsPhoneEmpty = 'Y'
			ELSE
				SET @IsPhoneEmpty = 'N'
		IF @Column='Fax' 
			IF @Uploadval IS NULL
				SET @IsFaxEmpty = 'Y'
			ELSE
				SET @IsFaxEmpty = 'N'
		IF @Column='TempYN' 
			IF @Uploadval IS NULL
				SET @IsTempYNEmpty = 'Y'
			ELSE
				SET @IsTempYNEmpty = 'N'
		IF @Column='ActiveYN' 
			IF @Uploadval IS NULL
				SET @IsActiveYNEmpty = 'Y'
			ELSE
				SET @IsActiveYNEmpty = 'N'
		IF @Column='Purge' 
			IF @Uploadval IS NULL
				SET @IsPurgeEmpty = 'Y'
			ELSE
				SET @IsPurgeEmpty = 'N'
		IF @Column='Type' 
			IF @Uploadval IS NULL
				SET @IsTypeEmpty = 'Y'
			ELSE
				SET @IsTypeEmpty = 'N'
		IF @Column='PayTerms' 
			IF @Uploadval IS NULL
				SET @IsPayTermsEmpty = 'Y'
			ELSE
				SET @IsPayTermsEmpty = 'N'
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
		IF @Column='AddnlInfo' 
			IF @Uploadval IS NULL
				SET @IsAddnlInfoEmpty = 'Y'
			ELSE
				SET @IsAddnlInfoEmpty = 'N'
		IF @Column='Address' 
			IF @Uploadval IS NULL
				SET @IsAddressEmpty = 'Y'
			ELSE
				SET @IsAddressEmpty = 'N'
		IF @Column='City' 
			IF @Uploadval IS NULL
				SET @IsCityEmpty = 'Y'
			ELSE
				SET @IsCityEmpty = 'N'
		IF @Column='State' 
			IF @Uploadval IS NULL
				SET @IsStateEmpty = 'Y'
			ELSE
				SET @IsStateEmpty = 'N'
		IF @Column='Country' 
			IF @Uploadval IS NULL
				SET @IsCountryEmpty = 'Y'
			ELSE
				SET @IsCountryEmpty = 'N'
		IF @Column='Zip' 
			IF @Uploadval IS NULL
				SET @IsZipEmpty = 'Y'
			ELSE
				SET @IsZipEmpty = 'N'
		IF @Column='Address2' 
			IF @Uploadval IS NULL
				SET @IsAddress2Empty = 'Y'
			ELSE
				SET @IsAddress2Empty = 'N'
		IF @Column='POAddress' 
			IF @Uploadval IS NULL
				SET @IsPOAddressEmpty = 'Y'
			ELSE
				SET @IsPOAddressEmpty = 'N'
		IF @Column='POCity' 
			IF @Uploadval IS NULL
				SET @IsPOCityEmpty = 'Y'
			ELSE
				SET @IsPOCityEmpty = 'N'
		IF @Column='POState' 
			IF @Uploadval IS NULL
				SET @IsPOStateEmpty = 'Y'
			ELSE
				SET @IsPOStateEmpty = 'N'
		IF @Column='POCountry' 
			IF @Uploadval IS NULL
				SET @IsPOCountryEmpty = 'Y'
			ELSE
				SET @IsPOCountryEmpty = 'N'
		IF @Column='POZip' 
			IF @Uploadval IS NULL
				SET @IsPOZipEmpty = 'Y'
			ELSE
				SET @IsPOZipEmpty = 'N'
		IF @Column='POAddress2' 
			IF @Uploadval IS NULL
				SET @IsPOAddress2Empty = 'Y'
			ELSE
				SET @IsPOAddress2Empty = 'N'
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
		IF @Column='TaxId' 
			IF @Uploadval IS NULL
				SET @IsTaxIdEmpty = 'Y'
			ELSE
				SET @IsTaxIdEmpty = 'N'
		IF @Column='Prop' 
			IF @Uploadval IS NULL
				SET @IsPropEmpty = 'Y'
			ELSE
				SET @IsPropEmpty = 'N'
		IF @Column='LastInvDate' 
			IF @Uploadval IS NULL
				SET @IsLastInvDateEmpty = 'Y'
			ELSE
				SET @IsLastInvDateEmpty = 'N'
		IF @Column='OverrideMinAmtYN' 
			IF @Uploadval IS NULL
				SET @IsOverrideMinAmtYNEmpty = 'Y'
			ELSE
				SET @IsOverrideMinAmtYNEmpty = 'N'
		IF @Column='SeparatePayInvYN' 
			IF @Uploadval IS NULL
				SET @IsSeparatePayInvYNEmpty = 'Y'
			ELSE
				SET @IsSeparatePayInvYNEmpty = 'N'
		IF @Column='EFT' 
			IF @Uploadval IS NULL
				SET @IsEFTEmpty = 'Y'
			ELSE
				SET @IsEFTEmpty = 'N'
		IF @Column='RoutingId' 
			IF @Uploadval IS NULL
				SET @IsRoutingIdEmpty = 'Y'
			ELSE
				SET @IsRoutingIdEmpty = 'N'
		IF @Column='BankAcct' 
			IF @Uploadval IS NULL
				SET @IsBankAcctEmpty = 'Y'
			ELSE
				SET @IsBankAcctEmpty = 'N'
		IF @Column='AcctType' 
			IF @Uploadval IS NULL
				SET @IsAcctTypeEmpty = 'Y'
			ELSE
				SET @IsAcctTypeEmpty = 'N'
		IF @Column='EMail' 
			IF @Uploadval IS NULL 
				SET @IsEMailEmpty = 'Y'
			ELSE
				SET @IsEMailEmpty = 'N'
		IF @Column='URL' 
			IF @Uploadval IS NULL
				SET @IsURLEmpty = 'Y'
			ELSE
				SET @IsURLEmpty = 'N'
		IF @Column='CustGroup' 
			IF @Uploadval IS NULL
				SET @IsCustGroupEmpty = 'Y'
			ELSE
				SET @IsCustGroupEmpty = 'N'
		IF @Column='Customer' 
			IF @Uploadval IS NULL
				SET @IsCustomerEmpty = 'Y'
			ELSE
				SET @IsCustomerEmpty = 'N'
		IF @Column='Reviewer' 
			IF @Uploadval IS NULL
				SET @IsReviewerEmpty = 'Y'
			ELSE
				SET @IsReviewerEmpty = 'N'
		IF @Column='AddendaTypeId' 
			IF @Uploadval IS NULL
				SET @IsAddendaTypeIdEmpty = 'Y'
			ELSE
				SET @IsAddendaTypeIdEmpty = 'N'
		IF @Column='MasterVendor' 
			IF @Uploadval IS NULL
				SET @IsMasterVendorEmpty = 'Y'
			ELSE
				SET @IsMasterVendorEmpty = 'N'
		IF @Column='APRefUnqOvr' 
			IF @Uploadval IS NULL
				SET @IsAPRefUnqOvrEmpty = 'Y'
			ELSE
				SET @IsAPRefUnqOvrEmpty = 'N'
		IF @Column='ICFirstName' 
			IF @Uploadval IS NULL
				SET @IsICFirstNameEmpty = 'Y'
			ELSE
				SET @IsICFirstNameEmpty = 'N'
		IF @Column='ICMInitial' 
			IF @Uploadval IS NULL
				SET @IsICMInitialEmpty = 'Y'
			ELSE
				SET @IsICMInitialEmpty = 'N'
		IF @Column='ICLastName' 
			IF @Uploadval IS NULL
				SET @IsICLastNameEmpty = 'Y'
			ELSE
				SET @IsICLastNameEmpty = 'N'
		IF @Column='ICSocSecNbr' 
			IF @Uploadval IS NULL
				SET @IsICSocSecNbrEmpty = 'Y'
			ELSE
				SET @IsICSocSecNbrEmpty = 'N'
		IF @Column='ICStreetNbr' 
			IF @Uploadval IS NULL
				SET @IsICStreetNbrEmpty = 'Y'
			ELSE
				SET @IsICStreetNbrEmpty = 'N'
		IF @Column='ICStreetName' 
			IF @Uploadval IS NULL
				SET @IsICStreetNameEmpty = 'Y'
			ELSE
				SET @IsICStreetNameEmpty = 'N'
		IF @Column='ICAptNbr' 
			IF @Uploadval IS NULL
				SET @IsICAptNbrEmpty = 'Y'
			ELSE
				SET @IsICAptNbrEmpty = 'N'
		IF @Column='ICCity' 
			IF @Uploadval IS NULL
				SET @IsICCityEmpty = 'Y'
			ELSE
				SET @IsICCityEmpty = 'N'
		IF @Column='ICState' 
			IF @Uploadval IS NULL
				SET @IsICStateEmpty = 'Y'
			ELSE
				SET @IsICStateEmpty = 'N'
		IF @Column='ICCountry' 
			IF @Uploadval IS NULL
				SET @IsICCountryEmpty = 'Y'
			ELSE
				SET @IsICCountryEmpty = 'N'
		IF @Column='ICZip' 
			IF @Uploadval IS NULL
				SET @IsICZipEmpty = 'Y'
			ELSE
				SET @IsICZipEmpty = 'N'
		IF @Column='ICLastRptDate' 
			IF @Uploadval IS NULL
				SET @IsICLastRptDateEmpty = 'Y'
			ELSE
				SET @IsICLastRptDateEmpty = 'N'
		IF @Column='Notes' 
			IF @Uploadval IS NULL
				SET @IsNotesEmpty = 'Y'
			ELSE
				SET @IsNotesEmpty = 'N'
		IF @Column='IATYN' 
			IF @Uploadval IS NULL
				SET @IsIATYNEmpty = 'Y'
			ELSE
				SET @IsIATYNEmpty = 'N'
		IF @Column='ISODestinationCountryCode' 
			IF @Uploadval IS NULL
				SET @IsISODestCountryCodeEmpty = 'Y'
			ELSE
				SET @IsISODestCountryCodeEmpty = 'N'
		IF @Column='RDFIIdentNbrQualifier' 
			IF @Uploadval IS NULL
				SET @IsRDFIIdentNbrQualEmpty  = 'Y'
			ELSE
				SET @IsRDFIIdentNbrQualEmpty = 'N'
		IF @Column='BranchCountryCode' 
			IF @Uploadval IS NULL
				SET @IsBranchCountryCodeEmpty = 'Y'
			ELSE
				SET @IsBranchCountryCodeEmpty = 'N'
		IF @Column='RDFIBankName' 
			IF @Uploadval IS NULL
				SET @IsRDFIBankNameEmpty  = 'Y'
			ELSE
				SET @IsRDFIBankNameEmpty = 'N'
		IF @Column='GatewayOperatorRDFIIdent' 
			IF @Uploadval IS NULL
				SET @IsGatewayOpRDFIIdentEmpty  = 'Y'
			ELSE
				SET @IsGatewayOpRDFIIdentEmpty = 'N'
		IF @Column='AUVendorBSB' 
			IF @Uploadval IS NULL
				SET @IsAUVendorBSBEmpty = 'Y'
			ELSE
				SET @IsAUVendorBSBEmpty = 'N'
		IF @Column='AUVendorAccountNumber' 
			IF @Uploadval IS NULL
				SET @IsAUVendorAccountNumberEmpty  = 'Y'
			ELSE
				SET @IsAUVendorAccountNumberEmpty = 'N'
		IF @Column='AUVendorReference' 
			IF @Uploadval IS NULL
				SET @IsAUVendorReferenceEmpty = 'Y'
			ELSE
				SET @IsAUVendorReferenceEmpty = 'N'
		IF @Column='AUVendorEFTYN' 
			IF @Uploadval IS NULL
				SET @IsAUVendorEFTYNEmpty = 'Y'
			ELSE
				SET @IsAUVendorEFTYNEmpty = 'N'
		IF @Column like 'PayInfoDelivMthd%' 
			IF @Uploadval IS NULL
				SET @IsPayInfoDelivMthdEmpty = 'Y'
			ELSE
				SET @IsPayInfoDelivMthdEmpty = 'N'
		IF @Column='T5FirstName' 
			IF @Uploadval IS NULL
				SET @IsT5FirstNameEmpty = 'Y'
			ELSE
				SET @IsT5FirstNameEmpty = 'N'
		IF @Column='T5MiddleInit' 
			IF @Uploadval IS NULL
				SET @IsT5MiddleInitEmpty = 'Y'
			ELSE
				SET @IsT5MiddleInitEmpty = 'N'
		IF @Column='T5LastName' 
			IF @Uploadval IS NULL
				SET @IsT5LastNameEmpty = 'Y'
			ELSE
				SET @IsT5LastNameEmpty = 'N'
		IF @Column='T5SocInsNbr' 
			IF @Uploadval IS NULL
				SET @IsT5SocInsNbrEmpty = 'Y'
			ELSE
				SET @IsT5SocInsNbrEmpty = 'N'
		IF @Column='T5BusinessNbr' 
			IF @Uploadval IS NULL
				SET @IsT5BusinessNbrEmpty = 'Y'
			ELSE
				SET @IsT5BusinessNbrEmpty = 'N'
		IF @Column='T5BusTypeCode' 
			IF @Uploadval IS NULL
				SET @IsT5BusTypeCodeEmpty = 'Y'
			ELSE
				SET @IsT5BusTypeCodeEmpty = 'N'
		IF @Column='T5PartnerFIN' 
			IF @Uploadval IS NULL
				SET @IsT5PartnerFINEmpty = 'Y'
			ELSE
				SET @IsT5PartnerFINEmpty = 'N'
		IF @Column='AusBusNbr' 
			IF @Uploadval IS NULL
				SET @IsAusBusNbrEmpty = 'Y'
			ELSE
				SET @IsAusBusNbrEmpty = 'N'
		IF @Column='AusCorpNbr' 
			IF @Uploadval IS NULL
				SET @IsAusCorpNbrEmpty = 'Y'
			ELSE
				SET @IsAusCorpNbrEmpty = 'N'
		IF @Column='PayControl' 
			IF @Uploadval IS NULL
				SET @IsPayControlEmpty = 'Y'
			ELSE
				SET @IsPayControlEmpty = 'N'
		IF @Column='CASubjToWC' 
			IF @Uploadval IS NULL
				SET @IsCASubjToWCEmpty  = 'Y'
			ELSE
				SET @IsCASubjToWCEmpty  = 'N'
		IF @Column='CAClearanceCert' 
			IF @Uploadval IS NULL
				SET @IsCAClearanceCertEmpty = 'Y'
			ELSE
				SET @IsCAClearanceCertEmpty = 'N'
		IF @Column='CMAcct' 
			IF @Uploadval IS NULL
				SET @IsCMAcctEmpty = 'Y'
			ELSE
				SET @IsCMAcctEmpty = 'N'
		IF @Column='CACertEffectiveDate' 
			IF @Uploadval IS NULL
				SET @IsCACertEffectiveDateEmpty = 'Y'
			ELSE
				SET @IsCACertEffectiveDateEmpty = 'N'

    
        select @oldrecseq = @Recseq
    
        --fetch next record
        fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
    
    	-- if this is the last record, set the sequence to -1 to process last record.
    	if @@fetch_status <> 0 
    	   select @Recseq = -1
    
      end
      else
      begin

			-- set defaults for non null fields
			if @IsVendorGroupEmpty = 'Y'
				begin
				update IMWE
    			set IMWE.UploadVal = @DefVendorGroup
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @VendorGroupID and IMWE.RecordType = @rectype
				end

			if @IsPurgeEmpty = 'Y'
				begin
				update IMWE
    			set IMWE.UploadVal = 'N'
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @PurgeID and IMWE.RecordType = @rectype
				end

			if @IsTypeEmpty = 'Y'
				begin
				update IMWE
    			set IMWE.UploadVal = 'R'
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @TypeID and IMWE.RecordType = @rectype
				end

			if @IsGLCoEmpty = 'Y'
				begin
				update IMWE
    			set IMWE.UploadVal = @DefGLCo
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @GLCoID and IMWE.RecordType = @rectype
				end

			if @IsActiveYNEmpty = 'Y'
				begin
				update IMWE
    			set IMWE.UploadVal = 'Y'
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @ActiveID and IMWE.RecordType = @rectype
				end

			if @IsTempYNEmpty = 'Y'
				begin
				update IMWE
    			set IMWE.UploadVal = 'N'
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @TempID and IMWE.RecordType = @rectype
				end

			if @IsEFTEmpty = 'Y'
				begin
				update IMWE
    			set IMWE.UploadVal = 'N'
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @EFTID and IMWE.RecordType = @rectype
				end

			if @IsV1099YNEmpty = 'Y'
				begin
				select @ynV1099YN = 'N'
				update IMWE
    			set IMWE.UploadVal = @ynV1099YN
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @V1099YNID and IMWE.RecordType = @rectype
				end

			if @IsAPRefUnqOvrEmpty = 'Y'
				begin
				update IMWE
    			set IMWE.UploadVal = 0
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @APRefUnqOvrID and IMWE.RecordType = @rectype
				end

			if @IsIATYNEmpty = 'Y'
				begin
				select @ynIATYN = 'N'
				update IMWE
    			set IMWE.UploadVal = @ynIATYN
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @IATYNID and IMWE.RecordType = @rectype
				end	
			else
				-- if Country isn't US set to 'N'
				if @hqcodefaultcountry <> 'US' or @OverwriteIATYN='Y'
				begin
				select @ynIATYN = 'N'
				update IMWE
    			set IMWE.UploadVal = @ynIATYN
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @IATYNID and IMWE.RecordType = @rectype
				end

			if @IsAUVendorEFTYNEmpty = 'Y'
				begin
				select @ynAUVendorEFTYN = 'N'
				update IMWE
    			set IMWE.UploadVal = @ynAUVendorEFTYN
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @AUVendorEFTID and IMWE.RecordType = @rectype
				end	
			else
				-- if Country is AU -- #139733
				if @hqcodefaultcountry = 'AU'
				begin
					-- and AUVendorEFTYN = 'Y' 
					if exists(select * from IMWE 
						where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    					and IMWE.Identifier = @AUVendorEFTID and IMWE.RecordType = @rectype and IMWE.UploadVal = 'Y')
					begin
					-- then update EFT to 'A' - Active
					select @EFTID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
					inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
					Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EFT'  
					if @@rowcount <> 0 
						begin
						UPDATE IMWE
						SET IMWE.UploadVal = 'A'
						where IMWE.ImportTemplate=@ImportTemplate and 
    					IMWE.ImportId=@ImportId and IMWE.Identifier = @EFTID
						end
					end
				end
				-- if Country isn't AU set to 'N'
				if @hqcodefaultcountry <> 'AU' or @OverwriteAUVendorEFTYN = 'Y'
				begin
				select @ynAUVendorEFTYN = 'N'
				update IMWE
    			set IMWE.UploadVal = @ynAUVendorEFTYN
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @AUVendorEFTID and IMWE.RecordType = @rectype
				end

			if @IsCASubjToWCEmpty = 'Y'
				begin
				select @ynCASubjToWC = 'N'
				update IMWE
    			set IMWE.UploadVal = @ynCASubjToWC
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @CASubjToWCID and IMWE.RecordType = @rectype
				end
			else
				-- if Country isn't CA set to 'N'
				if @hqcodefaultcountry <> 'CA' or @OverwriteCASubjToWC = 'Y'
				begin
				select @ynCASubjToWC = 'N'
				update IMWE
    			set IMWE.UploadVal = @ynCASubjToWC
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @CASubjToWCID and IMWE.RecordType = @rectype	
				end

			-- Set a default for Pay Info Delivery Method.  If there is no email then default should be 'N'
			if @IsPayInfoDelivMthdEmpty = 'Y' or @IsEMailEmpty = 'Y'
				begin
				update IMWE
				set IMWE.UploadVal = 'N'
				where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
					and IMWE.Identifier = @PayInfoDelivMthdID and IMWE.RecordType = @rectype
				end	

    		-- set values that depend on other columns
    		if @ynSortName = 'Y' AND (ISNULL(@OverwriteSortName, 'Y') = 'Y' OR ISNULL(@IsSortNameEmpty, 'Y') = 'Y')
    		BEGIN
  			declare @vreccount int, @vendtemp varchar(10), @wreccount int
  			select @SortName = upper(@Name)
  			--check if the sortname is in use by another Vendor
  			select @vreccount = count(*) from bAPVM with (nolock) where VendorGroup = @VendorGroup and SortName = @SortName
			and Vendor <> @Vendor	--exclude existing record for this Vendor

  			if @vreccount > 0 --if sortname is already in use, append vendor number
  				begin	--(max length of SortName is 15 characters)
  					select @vendtemp = convert(varchar(10),@Vendor)	--max val is 10 digits
  					select @SortName = upper(rtrim(left(@Name, 15-len(@vendtemp)))) + @vendtemp
  				end
			--issue #123214, also check IMWE for existing SortName.
			select @vreccount = count(*) from IMWE where IMWE.ImportTemplate = @ImportTemplate and 
			IMWE.Identifier = @SortNameID and IMWE.RecordType = @rectype and 
			IMWE.UploadVal = @SortName

			if @vreccount > 0	--if sortname is already in use, append vendor number
				begin	--(max length of SortName is 15 characters)
 					select @vendtemp = convert(varchar(10),@Vendor)	--max val is 10 digits
 					select @SortName = upper(left(@Name, 15-len(@vendtemp))) + @vendtemp
				end

    		Update IMWE
    		set IMWE.UploadVal = @SortName
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    				and IMWE.Identifier = @SortNameID and IMWE.RecordType = @rectype
    		END
    
    	if @ynAcctType = 'Y' AND (ISNULL(@OverwriteAcctType, 'Y') = 'Y' OR ISNULL(@IsAcctTypeEmpty, 'Y') = 'Y')
    	begin
    	    if isnull(@EFT, 'N') = 'N'
    			begin
    			UPDATE IMWE
    			SET IMWE.UploadVal = null
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier = @AcctTypeID and IMWE.RecordType = @rectype
    			end
    	    else
    			begin
    			UPDATE IMWE
    			SET IMWE.UploadVal = 'C'
    			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    			and IMWE.Identifier = @AcctTypeID and IMWE.RecordType = @rectype
    			end
    	end
    
		-- Clear dependent fields for V1099YN (Subject to 1099 filing) - CA uses V1099YN for Suject to T5 filing.
		IF @ynV1099YN = 'N'  
			BEGIN
    		UPDATE IMWE
			SET IMWE.UploadVal = null
    		WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    		AND IMWE.Identifier = @V1099TypeID AND IMWE.RecordType = @rectype

    		UPDATE IMWE
			SET IMWE.UploadVal = null
    		WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    		AND IMWE.Identifier = @V1099BoxID AND IMWE.RecordType = @rectype

			-- CA uses V1099YN for it's T5019 filing.  So if V1099YN is N then clear T5018 fields
			UPDATE IMWE
			SET IMWE.UploadVal = null
    		WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    		AND IMWE.Identifier = @T5FirstNameID AND IMWE.RecordType = @rectype

			UPDATE IMWE
			SET IMWE.UploadVal = null
    		WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    		AND IMWE.Identifier = @T5MiddleInitID AND IMWE.RecordType = @rectype

			UPDATE IMWE
			SET IMWE.UploadVal = null
    		WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    		AND IMWE.Identifier = @T5LastNameID AND IMWE.RecordType = @rectype

			UPDATE IMWE
			SET IMWE.UploadVal = null
    		WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    		AND IMWE.Identifier = @T5SocInsNbrID AND IMWE.RecordType = @rectype

			UPDATE IMWE
			SET IMWE.UploadVal = null
    		WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    		AND IMWE.Identifier = @T5BusinessNbrID AND IMWE.RecordType = @rectype

			UPDATE IMWE
			SET IMWE.UploadVal = null
    		WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    		AND IMWE.Identifier = @T5BusTypeCodeID AND IMWE.RecordType = @rectype

			UPDATE IMWE
			SET IMWE.UploadVal = null
    		WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    		AND IMWE.Identifier = @T5PartnerFINID AND IMWE.RecordType = @rectype

			END
		ELSE
			BEGIN
				-- For CA set T5 Business Type Code default
				UPDATE IMWE
				SET IMWE.UploadVal = 'C'
				WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
				AND IMWE.Identifier = @T5BusTypeCodeID AND IMWE.RecordType = @rectype and isnull(IMWE.UploadVal,'') = ''
				AND @hqcodefaultcountry = 'CA'

				-- For CA and AU clear 1099 defaults
				UPDATE IMWE
				SET IMWE.UploadVal = null
    			WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    			AND IMWE.Identifier = @V1099TypeID AND IMWE.RecordType = @rectype and @hqcodefaultcountry <> 'US'

    			UPDATE IMWE
				SET IMWE.UploadVal = null
    			WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    			AND IMWE.Identifier = @V1099BoxID AND IMWE.RecordType = @rectype and @hqcodefaultcountry <> 'US'

				-- For US and AU clear CA T5 defaults
				UPDATE IMWE
				SET IMWE.UploadVal = null
    			WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    			AND IMWE.Identifier = @T5FirstNameID AND IMWE.RecordType = @rectype and @hqcodefaultcountry <> 'CA'

				UPDATE IMWE
				SET IMWE.UploadVal = null
    			WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    			AND IMWE.Identifier = @T5MiddleInitID AND IMWE.RecordType = @rectype and @hqcodefaultcountry <> 'CA'

				UPDATE IMWE
				SET IMWE.UploadVal = null
    			WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    			AND IMWE.Identifier = @T5LastNameID AND IMWE.RecordType = @rectype and @hqcodefaultcountry <> 'CA'

				UPDATE IMWE
				SET IMWE.UploadVal = null
    			WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    			AND IMWE.Identifier = @T5SocInsNbrID AND IMWE.RecordType = @rectype and @hqcodefaultcountry <> 'CA'

				UPDATE IMWE
				SET IMWE.UploadVal = null
    			WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    			AND IMWE.Identifier = @T5BusinessNbrID AND IMWE.RecordType = @rectype and @hqcodefaultcountry <> 'CA'

				UPDATE IMWE
				SET IMWE.UploadVal = null
    			WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    			AND IMWE.Identifier = @T5BusTypeCodeID AND IMWE.RecordType = @rectype and @hqcodefaultcountry <> 'CA'

				UPDATE IMWE
				SET IMWE.UploadVal = null
    			WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@currrecseq
    			AND IMWE.Identifier = @T5PartnerFINID AND IMWE.RecordType = @rectype and @hqcodefaultcountry <> 'CA'
			END

		-- Clear dependent fields
		if @ynIATYN = 'N' or @hqcodefaultcountry <> 'US'
		begin
			UPDATE IMWE
    		SET IMWE.UploadVal = null
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier = @ISODestinationCountryCodeID and IMWE.RecordType = @rectype

			UPDATE IMWE
    		SET IMWE.UploadVal = null
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier = @RDFIBankNameID and IMWE.RecordType = @rectype

			UPDATE IMWE
    		SET IMWE.UploadVal = null
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier = @BranchCountryCodeID and IMWE.RecordType = @rectype

			UPDATE IMWE
    		SET IMWE.UploadVal = null
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier = @RDFIIdentNbrQualifierID and IMWE.RecordType = @rectype

			UPDATE IMWE
    		SET IMWE.UploadVal = null
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier = @GatewayOperatorRDFIIdentID and IMWE.RecordType = @rectype
		end

		if @ynAUVendorEFTYN = 'N' or @hqcodefaultcountry <> 'AU'
		begin
			UPDATE IMWE
    		SET IMWE.UploadVal = null
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier = @AUVendorAccountNumberID and IMWE.RecordType = @rectype
			
			UPDATE IMWE
    		SET IMWE.UploadVal = null
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier = @AUVendorBSBID and IMWE.RecordType = @rectype


			UPDATE IMWE
    		SET IMWE.UploadVal = null
    		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    		and IMWE.Identifier = @AUVendorReferenceID and IMWE.RecordType = @rectype
		end

		-- Clear fields based on Country
		UPDATE IMWE
		SET IMWE.UploadVal = null
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
		and IMWE.Identifier = @AusCorpNbrID and IMWE.RecordType = @rectype and @hqcodefaultcountry <> 'AU'
	
		UPDATE IMWE
		SET IMWE.UploadVal = null
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
		and IMWE.Identifier = @AusBusNbrID and IMWE.RecordType = @rectype and @hqcodefaultcountry <> 'AU'

		UPDATE IMWE
		SET IMWE.UploadVal = null
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
		and IMWE.Identifier = @CAClearanceCertID and IMWE.RecordType = @rectype and @hqcodefaultcountry <> 'CA'
	
		UPDATE IMWE
		SET IMWE.UploadVal = null
		where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
		and IMWE.Identifier = @CACertEffectiveDateID and IMWE.RecordType = @rectype and @hqcodefaultcountry <> 'CA'
		

    	-- set Current Req Seq to next @Recseq unless we are processing last record.
    	if @Recseq = -1
    		select @complete = 1	-- exit the loop
    	else
    		select @currrecseq = @Recseq
    
      end
    end
    
UPDATE IMWE
SET IMWE.UploadVal = UPPER(IMWE.UploadVal)
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordType = @rectype
and IMWE.Identifier = @SortNameID and isnull(IMWE.UploadVal,'') <> UPPER(isnull(IMWE.UploadVal,'')) 

    bspexit:
    
    	if @CursorOpen = 1
    	begin
    		close WorkEditCursor
    		deallocate WorkEditCursor	
    	end
    
        select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsAPVM]'
    
        return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsAPVM] TO [public]
GO
