SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsARCM]
    /***********************************************************
     * CREATED BY:   RBT 02/20/04 for issue #23724
     * MODIFIED BY:  RBT 03/14/05, issue #27383, check IMWE for SortName duplicates.
     *				 DANF 04/16/07 - Issue 122202 Upper case sort name
     *				 CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
     *				 GF 09/11/2010 - issue #141031 change to use function vfDateOnly
     *				 AMR 01/12/11 - #142350, making case sensitive by removing unused vars and renaming same named variables
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
    declare @CustGroupID int, @TaxGroupID int, @DateOpenedID int, @MarkupDiscPctID int, @RecTypeID int,
    	@FCPctID int, @FCTypeID int, @StatusID int, @CreditLimitID int, @StmtTypeID int, @HaulTaxOptID int, 
    	@InvLvlID int, @PrintLvlID int, @SubtotalLvlID int, @SepHaulID int, @TempYNID int, 
    	@SelPurgeID int, @StmntPrintID int, @MiscOnInvID int, @MiscOnPayID int, 
    	@ExclContFromFCID int, @SortNameID int
    
    --Values
    declare @DefCustGroup bGroup, @DefTaxGroup bGroup, @DefRecType tinyint, @DefFCPct bPct, 
    	@CustGroup bGroup, @Customer bCustomer, @SortName bSortName, @ynSortName bYN,
    	@CustName varchar(30)
    
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
			  @OverwriteCustGroup 	 	 bYN
			, @OverwriteTaxGroup 	 	 bYN
			, @OverwriteRecType 	 	 bYN
			, @OverwriteFCType 	 	 	 bYN
			, @OverwriteFCPct 	 	 	 bYN
			, @OverwriteMarkupDiscPct 	 bYN
			, @OverwriteDateOpened 	 	 bYN
			, @OverwriteStatus 	 		 bYN
			, @OverwriteCreditLimit 	 bYN
			, @OverwriteStmtType 	 	 bYN
			, @OverwriteHaulTaxOpt 	 	 bYN
			, @OverwriteInvLvl 	 		 bYN
			, @OverwritePrintLvl 	 	 bYN
			, @OverwriteSubtotalLvl 	 bYN
			, @OverwriteSepHaul 	 	 bYN
			, @OverwriteTempYN 	 		 bYN
			, @OverwriteSelPurge 	 	 bYN
			, @OverwriteStmntPrint 	 	 bYN
			, @OverwriteMiscOnInv 	 	 bYN
			, @OverwriteMiscOnPay 	 	 bYN
			, @OverwriteExclContFromFC 	 bYN
			, @OverwriteSortName 	 	 bYN
			,	@IsCustGroupEmpty 		 bYN
			,	@IsTaxGroupEmpty 		 bYN
			,	@IsCustomerEmpty 		 bYN
			,	@IsNameEmpty 			 bYN
			,	@IsTempYNEmpty 			 bYN
			,	@IsSortNameEmpty 		 bYN
			,	@IsAddressEmpty 		 bYN
			,	@IsCityEmpty 			 bYN
			,	@IsStateEmpty 			 bYN
			,	@IsCountryEmpty 		 bYN
			,	@IsZipEmpty 			 bYN
			,	@IsAddress2Empty 		 bYN
			,	@IsBillAddressEmpty 	 bYN
			,	@IsBillCityEmpty 		 bYN
			,	@IsBillStateEmpty 		 bYN
			,	@IsBillCountryEmpty 	 bYN
			,	@IsBillZipEmpty 		 bYN
			,	@IsBillAddress2Empty 	 bYN
			,	@IsPhoneEmpty 			 bYN
			,	@IsFaxEmpty 			 bYN
			,	@IsContactEmpty 		 bYN
			,	@IsContactExtEmpty 		 bYN
			,	@IsEMailEmpty 			 bYN
			,	@IsURLEmpty 			 bYN
			,	@IsStatusEmpty 			 bYN
			,	@IsPayTermsEmpty 		 bYN
			,	@IsRecTypeEmpty 		 bYN
			,	@IsTaxCodeEmpty 		 bYN
			,	@IsMiscDistCodeEmpty 	 bYN
			,	@IsDateOpenedEmpty 		 bYN
			,	@IsCreditLimitEmpty 	 bYN
			,	@IsMarkupDiscPctEmpty 	 bYN
			,	@IsFCPctEmpty 			 bYN
			,	@IsFCTypeEmpty 			 bYN
			,	@IsExclContFromFCEmpty 	 bYN
			,	@IsStmtTypeEmpty 		 bYN
			,	@IsStmntPrintEmpty 		 bYN
			,	@IsSelPurgeEmpty 		 bYN
			,	@IsMiscOnInvEmpty 		 bYN
			,	@IsMiscOnPayEmpty 		 bYN
			,	@IsPriceTemplateEmpty 	 bYN
			,	@IsDiscTemplateEmpty 	 bYN
			,	@IsHaulTaxOptEmpty 		 bYN
			,	@IsInvLvlEmpty 			 bYN
			,	@IsBillFreqEmpty 		 bYN
			,	@IsPrintLvlEmpty 		 bYN
			,	@IsSubtotalLvlEmpty 	 bYN
			,	@IsSepHaulEmpty 		 bYN
			,	@IsNotesEmpty 			 bYN


	SELECT @OverwriteCustGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CustGroup', @rectype);
	SELECT @OverwriteTaxGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TaxGroup', @rectype);
	SELECT @OverwriteRecType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RecType', @rectype);
	SELECT @OverwriteFCType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'FCType', @rectype);
	SELECT @OverwriteFCPct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'FCPct', @rectype);
	SELECT @OverwriteMarkupDiscPct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MarkupDiscPct', @rectype);
	SELECT @OverwriteDateOpened = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'DateOpened', @rectype);
	SELECT @OverwriteStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Status', @rectype);
	SELECT @OverwriteCreditLimit = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CreditLimit', @rectype);
	SELECT @OverwriteStmtType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StmtType', @rectype);
	SELECT @OverwriteHaulTaxOpt = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'HaulTaxOpt', @rectype);
	SELECT @OverwriteInvLvl = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InvLvl', @rectype);
	SELECT @OverwritePrintLvl = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PrintLvl', @rectype);
	SELECT @OverwriteSubtotalLvl = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SubtotalLvl', @rectype);
	SELECT @OverwriteSepHaul = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SepHaul', @rectype);
	SELECT @OverwriteTempYN = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TempYN', @rectype);
	SELECT @OverwriteSelPurge = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SelPurge', @rectype);
	SELECT @OverwriteStmntPrint = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'StmntPrint', @rectype);
	SELECT @OverwriteMiscOnInv = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MiscOnInv', @rectype);
	SELECT @OverwriteMiscOnPay = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'MiscOnPay', @rectype);
	SELECT @OverwriteExclContFromFC = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ExclContFromFC', @rectype);
    SELECT @OverwriteSortName = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'SortName', @rectype);
    
    --get database default values
    select @DefCustGroup = CustGroup, @DefTaxGroup = TaxGroup from bHQCO with (nolock) where HQCo = @Company
    select @DefRecType = RecType, @DefFCPct = FCPct from bARCO with (nolock) where ARCo = @Company
    
    --set common defaults
    select @CustGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CustGroup'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCustGroup, 'Y') = 'Y')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = @DefCustGroup
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @CustGroupID
    end
    
    select @TaxGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxGroup'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = @DefTaxGroup
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @TaxGroupID
    end
    
    select @RecTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RecType'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteRecType, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = @DefRecType
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @RecTypeID
    end
    
    select @FCTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'FCType'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteFCType, 'Y') = 'Y') 
    begin
 UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @FCTypeID
    end
    
    select @FCPctID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'FCPct'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteFCPct, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = isnull(@DefFCPct,'0')
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @FCPctID
    end
    
    select @MarkupDiscPctID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MarkupDiscPct'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteMarkupDiscPct, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @MarkupDiscPctID
    end
    
    select @DateOpenedID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'DateOpened'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteDateOpened, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        ----#141031
        SET IMWE.UploadVal = convert(varchar(10), dbo.vfDateOnly(),101)
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @DateOpenedID
    end
    
    select @StatusID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Status'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteStatus, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'A'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @StatusID
    end
    
    select @CreditLimitID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CreditLimit'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteCreditLimit, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @CreditLimitID
    end
    
    select @StmtTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'StmtType'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteStmtType, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'O'	-- "O", not zero
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @StmtTypeID
    end
    
    select @HaulTaxOptID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HaulTaxOpt'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteHaulTaxOpt, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @HaulTaxOptID
    end
    
    select @InvLvlID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'InvLvl'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteInvLvl, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'	
    
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @InvLvlID
    end
    
    select @PrintLvlID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PrintLvl'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwritePrintLvl, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '1'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @PrintLvlID
    end
    
    select @SubtotalLvlID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SubtotalLvl'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteSubtotalLvl, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '1'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @SubtotalLvlID
    end
    
    select @SepHaulID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SepHaul'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteSepHaul, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'Y'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @SepHaulID
    end
    
    select @TempYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TempYN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteTempYN, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @TempYNID
    end
    
    select @SelPurgeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SelPurge'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSelPurge, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @SelPurgeID
    end
    
    select @StmntPrintID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'StmntPrint'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteStmntPrint, 'Y') = 'Y') 
    begin
 UPDATE IMWE
        SET IMWE.UploadVal = 'N'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @StmntPrintID
    end
    
    select @MiscOnInvID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MiscOnInv'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMiscOnInv, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @MiscOnInvID
    end
    
    select @MiscOnPayID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MiscOnPay'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMiscOnPay, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @MiscOnPayID
    end
    
    select @ExclContFromFCID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ExclContFromFC'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteExclContFromFC, 'Y') = 'Y') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @ExclContFromFCID
    end

-------------------------
    select @CustGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CustGroup'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCustGroup, 'Y') = 'N')
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = @DefCustGroup
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @CustGroupID
    	AND IMWE.UploadVal IS NULL
    end

    select @TaxGroupID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TaxGroup'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteTaxGroup, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = @DefTaxGroup
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @TaxGroupID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @RecTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'RecType'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteRecType, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = @DefRecType
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @RecTypeID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @FCTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'FCType'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteFCType, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @FCTypeID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @FCPctID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'FCPct'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteFCPct, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = isnull(@DefFCPct,'0')
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @FCPctID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @MarkupDiscPctID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MarkupDiscPct'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteMarkupDiscPct, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @MarkupDiscPctID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @DateOpenedID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'DateOpened'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteDateOpened, 'Y') = 'N') 
    begin
        UPDATE IMWE
        ----#141031
        SET IMWE.UploadVal = convert(varchar(10), dbo.vfDateOnly(),101)
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @DateOpenedID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @StatusID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Status'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteStatus, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'A'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @StatusID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @CreditLimitID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CreditLimit'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteCreditLimit, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @CreditLimitID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @StmtTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'StmtType'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteStmtType, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'O'	-- "O", not zero
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @StmtTypeID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @HaulTaxOptID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'HaulTaxOpt'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteHaulTaxOpt, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @HaulTaxOptID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @InvLvlID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'InvLvl'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteInvLvl, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '0'	
    
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @InvLvlID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @PrintLvlID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PrintLvl'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwritePrintLvl, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '1'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @PrintLvlID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @SubtotalLvlID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SubtotalLvl'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteSubtotalLvl, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = '1'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @SubtotalLvlID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @SepHaulID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SepHaul'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteSepHaul, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'Y'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @SepHaulID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @TempYNID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'TempYN'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteTempYN, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @TempYNID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @SelPurgeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'SelPurge'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteSelPurge, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @SelPurgeID
    	AND IMWE.UploadVal IS NULL
    end
    
    
    select @StmntPrintID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'StmntPrint'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteStmntPrint, 'Y') = 'N') 
    begin
 UPDATE IMWE
        SET IMWE.UploadVal = 'N'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @StmntPrintID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @MiscOnInvID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MiscOnInv'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMiscOnInv, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @MiscOnInvID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @MiscOnPayID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'MiscOnPay'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteMiscOnPay, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @MiscOnPayID
    	AND IMWE.UploadVal IS NULL
    end
    
    select @ExclContFromFCID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
    inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
    Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ExclContFromFC'
    if @@rowcount <> 0 and @defaultvalue = '[Bidtek]'  AND (ISNULL(@OverwriteExclContFromFC, 'Y') = 'N') 
    begin
        UPDATE IMWE
        SET IMWE.UploadVal = 'N'	
        where IMWE.ImportTemplate=@ImportTemplate and 
    	IMWE.ImportId=@ImportId and IMWE.Identifier = @ExclContFromFCID
    	AND IMWE.UploadVal IS NULL
    end    
    
    --Get Identifiers for dependent defaults.
    select @ynSortName = 'N'
    select @SortNameID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'SortName', @rectype, 'Y')
    if @SortNameID <> 0 select @ynSortName = 'Y'
    
    
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
	-- #142350 - removing @importid, @seq, @Identifier
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
    
        If @Column = 'Customer' select @Customer = @Uploadval
        If @Column = 'Name' select @CustName = @Uploadval
        If @Column = 'CustGroup' select @CustGroup = @Uploadval

IF @Column='CustGroup' 
	IF @Uploadval IS NULL
		SET @IsCustGroupEmpty = 'Y'
	ELSE
		SET @IsCustGroupEmpty = 'N'
IF @Column='TaxGroup' 
	IF @Uploadval IS NULL
		SET @IsTaxGroupEmpty = 'Y'
	ELSE
		SET @IsTaxGroupEmpty = 'N'
IF @Column='Customer' 
	IF @Uploadval IS NULL
		SET @IsCustomerEmpty = 'Y'
	ELSE
		SET @IsCustomerEmpty = 'N'
IF @Column='Name' 
	IF @Uploadval IS NULL
		SET @IsNameEmpty = 'Y'
	ELSE
		SET @IsNameEmpty = 'N'
IF @Column='TempYN' 
	IF @Uploadval IS NULL
		SET @IsTempYNEmpty = 'Y'
	ELSE
		SET @IsTempYNEmpty = 'N'
IF @Column='SortName' 
	IF @Uploadval IS NULL
		SET @IsSortNameEmpty = 'Y'
	ELSE
		SET @IsSortNameEmpty = 'N'
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
IF @Column='BillAddress' 
	IF @Uploadval IS NULL
		SET @IsBillAddressEmpty = 'Y'
	ELSE
		SET @IsBillAddressEmpty = 'N'
IF @Column='BillCity' 
	IF @Uploadval IS NULL
		SET @IsBillCityEmpty = 'Y'
	ELSE
		SET @IsBillCityEmpty = 'N'
IF @Column='BillState' 
	IF @Uploadval IS NULL
		SET @IsBillStateEmpty = 'Y'
	ELSE
		SET @IsBillStateEmpty = 'N'
IF @Column='BillCountry' 
	IF @Uploadval IS NULL
		SET @IsBillCountryEmpty = 'Y'
	ELSE
		SET @IsBillCountryEmpty = 'N'
IF @Column='BillZip' 
	IF @Uploadval IS NULL
		SET @IsBillZipEmpty = 'Y'
	ELSE
		SET @IsBillZipEmpty = 'N'
IF @Column='BillAddress2' 
	IF @Uploadval IS NULL
		SET @IsBillAddress2Empty = 'Y'
	ELSE
		SET @IsBillAddress2Empty = 'N'
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
IF @Column='Contact' 
	IF @Uploadval IS NULL
		SET @IsContactEmpty = 'Y'
	ELSE
		SET @IsContactEmpty = 'N'
IF @Column='ContactExt' 
	IF @Uploadval IS NULL
		SET @IsContactExtEmpty = 'Y'
	ELSE
		SET @IsContactExtEmpty = 'N'
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
IF @Column='Status' 
	IF @Uploadval IS NULL
		SET @IsStatusEmpty = 'Y'
	ELSE
		SET @IsStatusEmpty = 'N'
IF @Column='PayTerms' 
	IF @Uploadval IS NULL
		SET @IsPayTermsEmpty = 'Y'
	ELSE
		SET @IsPayTermsEmpty = 'N'
IF @Column='RecType' 
	IF @Uploadval IS NULL
		SET @IsRecTypeEmpty = 'Y'
	ELSE
		SET @IsRecTypeEmpty = 'N'
IF @Column='TaxCode' 
	IF @Uploadval IS NULL
		SET @IsTaxCodeEmpty = 'Y'
	ELSE
		SET @IsTaxCodeEmpty = 'N'
IF @Column='MiscDistCode' 
	IF @Uploadval IS NULL
		SET @IsMiscDistCodeEmpty = 'Y'
	ELSE
		SET @IsMiscDistCodeEmpty = 'N'
IF @Column='DateOpened' 
	IF @Uploadval IS NULL
		SET @IsDateOpenedEmpty = 'Y'
	ELSE
		SET @IsDateOpenedEmpty = 'N'
IF @Column='CreditLimit' 
	IF @Uploadval IS NULL
		SET @IsCreditLimitEmpty = 'Y'
	ELSE
		SET @IsCreditLimitEmpty = 'N'
IF @Column='MarkupDiscPct' 
	IF @Uploadval IS NULL
		SET @IsMarkupDiscPctEmpty = 'Y'
	ELSE
		SET @IsMarkupDiscPctEmpty = 'N'
IF @Column='FCPct' 
	IF @Uploadval IS NULL
		SET @IsFCPctEmpty = 'Y'
	ELSE
		SET @IsFCPctEmpty = 'N'
IF @Column='FCType' 
	IF @Uploadval IS NULL
		SET @IsFCTypeEmpty = 'Y'
	ELSE
		SET @IsFCTypeEmpty = 'N'
IF @Column='ExclContFromFC' 
	IF @Uploadval IS NULL
		SET @IsExclContFromFCEmpty = 'Y'
	ELSE
		SET @IsExclContFromFCEmpty = 'N'
IF @Column='StmtType' 
	IF @Uploadval IS NULL
		SET @IsStmtTypeEmpty = 'Y'
	ELSE
		SET @IsStmtTypeEmpty = 'N'
IF @Column='StmntPrint' 
	IF @Uploadval IS NULL
		SET @IsStmntPrintEmpty = 'Y'
	ELSE
		SET @IsStmntPrintEmpty = 'N'
IF @Column='SelPurge' 
	IF @Uploadval IS NULL
		SET @IsSelPurgeEmpty = 'Y'
	ELSE
		SET @IsSelPurgeEmpty = 'N'
IF @Column='MiscOnInv' 
	IF @Uploadval IS NULL
		SET @IsMiscOnInvEmpty = 'Y'
	ELSE
		SET @IsMiscOnInvEmpty = 'N'
IF @Column='MiscOnPay' 
	IF @Uploadval IS NULL
		SET @IsMiscOnPayEmpty = 'Y'
	ELSE
		SET @IsMiscOnPayEmpty = 'N'
IF @Column='PriceTemplate' 
	IF @Uploadval IS NULL
		SET @IsPriceTemplateEmpty = 'Y'
	ELSE
		SET @IsPriceTemplateEmpty = 'N'
IF @Column='DiscTemplate' 
	IF @Uploadval IS NULL
		SET @IsDiscTemplateEmpty = 'Y'
	ELSE
		SET @IsDiscTemplateEmpty = 'N'
IF @Column='HaulTaxOpt' 
	IF @Uploadval IS NULL
		SET @IsHaulTaxOptEmpty = 'Y'
	ELSE
		SET @IsHaulTaxOptEmpty = 'N'
IF @Column='InvLvl' 
	IF @Uploadval IS NULL
		SET @IsInvLvlEmpty = 'Y'
	ELSE
		SET @IsInvLvlEmpty = 'N'
IF @Column='BillFreq' 
	IF @Uploadval IS NULL
		SET @IsBillFreqEmpty = 'Y'
	ELSE
		SET @IsBillFreqEmpty = 'N'
IF @Column='PrintLvl' 
	IF @Uploadval IS NULL
		SET @IsPrintLvlEmpty = 'Y'
	ELSE
		SET @IsPrintLvlEmpty = 'N'
IF @Column='SubtotalLvl' 
	IF @Uploadval IS NULL
		SET @IsSubtotalLvlEmpty = 'Y'
	ELSE
		SET @IsSubtotalLvlEmpty = 'N'
IF @Column='SepHaul' 
	IF @Uploadval IS NULL
		SET @IsSepHaulEmpty = 'Y'
	ELSE
		SET @IsSepHaulEmpty = 'N'
IF @Column='Notes' 
	IF @Uploadval IS NULL
		SET @IsNotesEmpty = 'Y'
	ELSE
		SET @IsNotesEmpty = 'N'
    
        select @oldrecseq = @Recseq
    
        --fetch next record
        fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
    
    	-- if this is the last record, set the sequence to -1 to process last record.
    	if @@fetch_status <> 0 
    	   select @Recseq = -1
    
end
      else
      begin
    	-- set values that depend on other columns
   
    	if @ynSortName = 'Y' AND (ISNULL(@OverwriteSortName, 'Y') = 'Y' OR ISNULL(@IsSortNameEmpty, 'Y') = 'Y')
    	begin
    	    declare @reccount int, @custtemp varchar(10)
    	    select @SortName = left(upper(@CustName),15)	--bSortName datatype is varchar(15).
    	    --check if the sortname is in use by another Customer
    	    select @reccount = count(*) from bARCM where CustGroup = @CustGroup and SortName = @SortName
    		and Customer <> @Customer	--exclude existing record for this Customer
    	    if @reccount > 0	--if sortname is already in use, append customer number
    	    begin	--(max length of SortName is 15 characters)
   	 		select @custtemp = convert(varchar(10),@Customer)	--max val is 10 digits
   	 		select @SortName = upper(left(@CustName, 15-len(@custtemp))) + @custtemp
    	    end
   		else
   		begin
   			--issue #27383, also check IMWE for existing SortName.
   			select @reccount = count(*) from IMWE where IMWE.ImportTemplate = @ImportTemplate and 
   			IMWE.Identifier = @SortNameID and IMWE.RecordType = @rectype and 
   			IMWE.UploadVal = @SortName
   
   			if @reccount > 0	--if sortname is already in use, append customer number
   			begin	--(max length of SortName is 15 characters)
   		 		select @custtemp = convert(varchar(10),@Customer)	--max val is 10 digits
   		 		select @SortName = upper(left(@CustName, 15-len(@custtemp))) + @custtemp
   	 	    end
   		end
   
    	    UPDATE IMWE
    	    SET IMWE.UploadVal = @SortName
    	    where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
    	        and IMWE.Identifier = @SortNameID and IMWE.RecordType = @rectype
    	end
    
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
    
        select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[bspIMViewpointDefaultsARCM]'
    
        return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsARCM] TO [public]
GO
