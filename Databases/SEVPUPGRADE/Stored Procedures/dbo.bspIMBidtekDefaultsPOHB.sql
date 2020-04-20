SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsPOHB]
  /***********************************************************
   * CREATED BY: Danf
   * MODIFIED BY: CMW 04/03/02 - increased InvId from 5 char to 10 (issue # 16366)
   *				RBT 09/09/03 - 20131, Allow rectypes <> tablenames.
   *				RBT 01/26/06 - 120057, fix company default.
   *				CC	02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
   *				CC  05/29/09 - Issue #133516 - Correct defaulting of Company
   *				GF 09/14/2010 - issue #141031 change to use vfDateOnly
   *				AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
   *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
   *				
   * Usage:
   *	Used by Imports to ALTER values for needed or missing
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
          @CompanyID int, @BatchTransTypeID int, @vendorgroupid int, @incoid int, @orddateID int,
          @jccoid int, @paytermsid int, @defaultvalue varchar(30), @statusid int, @poid int, 
  		@expdateID int, @compgroupid int
  
  select @rcode = 0
  
  /* check required input params */
  --20131
  --if @rectype <> 'POHB' goto bspexit
  
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
  
  
  -- Check ImportTemplate detail for columns to set Bidtek Defaults
  	if not exists(select IMTD.DefaultValue From IMTD
  	Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
  	and IMTD.RecordType = @rectype)
  	goto bspexit
  
  
  DECLARE 
			  @OverwriteBatchTransType 	 bYN
			, @OverwriteExpDate 	 	 bYN
			, @OverwriteOrderDate 	 	 bYN
			, @OverwriteVendorGroup 	 bYN
			, @OverwritePO 	 			 bYN
			, @OverwriteStatus 	 	 	 bYN
			, @OverwriteINCo 	 	 	 bYN
			, @OverwriteJCCo 	 	 	 bYN
			, @OverwritePayTerms 	 	 bYN
			, @OverwriteCompGroup 	 	 bYN
			, @OverwriteCo				 bYN
			,	@IsCoEmpty 				 bYN
			,	@IsMthEmpty 			 bYN
			,	@IsBatchIdEmpty 		 bYN
			,	@IsBatchSeqEmpty 		 bYN
			,	@IsBatchTransTypeEmpty 	 bYN
			,	@IsPOEmpty 				 bYN
			,	@IsVendorGroupEmpty 	 bYN
			,	@IsVendorEmpty 			 bYN
			,	@IsDescriptionEmpty 	 bYN
			,	@IsOrderDateEmpty 		 bYN
			,	@IsOrderedByEmpty 		 bYN
			,	@IsExpDateEmpty 		 bYN
			,	@IsStatusEmpty 			 bYN
			,	@IsINCoEmpty 			 bYN
			,	@IsLocEmpty 			 bYN
			,	@IsJCCoEmpty 			 bYN
			,	@IsJobEmpty 			 bYN
			,	@IsShipLocEmpty 		 bYN
			,	@IsHoldCodeEmpty 		 bYN
			,	@IsCountryEmpty 		 bYN
			,	@IsPayTermsEmpty 		 bYN
			,	@IsCompGroupEmpty 		 bYN
			,	@IsAttentionEmpty 		 bYN
			,	@IsAddressEmpty 		 bYN
			,	@IsCityEmpty 			 bYN
			,	@IsStateEmpty 			 bYN
			,	@IsZipEmpty 			 bYN
			,	@IsShipInsEmpty 		 bYN
			,	@IsPayAddressSeqEmpty 	 bYN
			,	@IsPOAddressSeqEmpty 	 bYN
			,	@IsNotesEmpty 			 bYN
  
	SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype);
	SELECT @OverwriteExpDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ExpDate', @rectype);
	SELECT @OverwriteOrderDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'OrderDate', @rectype);
	SELECT @OverwriteVendorGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'VendorGroup', @rectype);
	SELECT @OverwritePO = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PO', @rectype);
	SELECT @OverwriteStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Status', @rectype);
	SELECT @OverwriteINCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'INCo', @rectype);
	SELECT @OverwriteJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCCo', @rectype);
	SELECT @OverwritePayTerms = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'PayTerms', @rectype);
	SELECT @OverwriteCompGroup = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CompGroup', @rectype);
	SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
  
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
  
  
  select @BatchTransTypeID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BatchTransType', @rectype, 'Y')
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
  
  select @expdateID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ExpDate', @rectype, 'Y')
  if isnull(@expdateID,0) <> 0  AND (ISNULL(@OverwriteExpDate, 'Y') = 'Y')
   begin
  
     UPDATE IMWE
     ----#141031
     SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @expdateID
     and IMWE.RecordType = @rectype
   end
  
  if isnull(@expdateID,0) <> 0  AND (ISNULL(@OverwriteExpDate, 'Y') = 'N')
   begin
  
     UPDATE IMWE
     ----#141031
     SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @expdateID
     and IMWE.RecordType = @rectype
    AND IMWE.UploadVal IS NULL 
   end
  
  select @orddateID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'OrderDate', @rectype, 'Y')
  if isnull(@orddateID,0) <> 0  AND (ISNULL(@OverwriteOrderDate, 'Y') = 'Y')
   begin
  
     UPDATE IMWE
     ----#141031
     SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @orddateID
  
     and IMWE.RecordType = @rectype
   end
  
  if isnull(@orddateID,0) <> 0  AND (ISNULL(@OverwriteOrderDate, 'Y') = 'N')
   begin
  
     UPDATE IMWE
     ----#141031
     SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @orddateID
  
     and IMWE.RecordType = @rectype
     AND IMWE.UploadVal IS NULL
   end
  
  
  
  select @vendorgroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'VendorGroup', @rectype, 'Y')
  
  select @poid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PO', @rectype, 'Y')
 
  select @statusid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Status', @rectype, 'Y')
  
  select @incoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'INCo', @rectype, 'Y')
  
  select @jccoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCCo', @rectype, 'Y')
  
  select @paytermsid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'PayTerms', @rectype, 'Y')
  
  select @compgroupid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'CompGroup', @rectype, 'Y')
  
  declare @Co bCompany, @Mth bMonth, @BatchId bBatchID, @BatchSeq int, @BatchTransType char,
  
   		@PO varchar(30), @VendorGroup bGroup, @Vendor bVendor, @Description bDesc, @OrderDate bDate,
  		@OrderedBy varchar(10), @ExpDate bDate, @Status tinyint, @JCCo bCompany, @Job bJob, @INCo bCompany, @Loc bLoc,
  		@ShipLoc varchar(10), @Address varchar(60), @City varchar(30), @State bState, @Zip bZip, @ShipIns varchar(60),
  		@HoldCode bHoldCode, @PayTerms bPayTerms, @CompGroup varchar(10), @Attention bDesc, @PayAddressSeq tinyint, @POAddressSeq tinyint
  
  
  declare WorkEditCursor cursor local fast_forward for
  select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
      from IMWE
          inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
      where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form and
  	IMWE.RecordType = @rectype
      Order by IMWE.RecordSeq, IMWE.Identifier
  
  open WorkEditCursor
	-- set open cursor flag
	--#142350 -- remvoing @importid, @seq, @Identifier
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
  
      If @Column='Co' and isnumeric(@Uploadval) =1 select @Co = Convert( int, @Uploadval)
  	If @Column='Mth' and isdate(@Uploadval) =1 select @Mth = Convert( smalldatetime, @Uploadval)
  /*	If @Column='BatchId' and  isnumeric(@Uploadval) =1 select @BatchSeq = @Uploadval
  	If @Column='BatchSeq' select @BatchTransType = @Uploadval */
  	If @Column='BatchTransType' select @BatchTransType = @Uploadval
  	If @Column='PO' select @PO = @Uploadval
      If @Column='VendorGroup' and isnumeric(@Uploadval) =1 select @VendorGroup = Convert( int, @Uploadval)
  	If @Column='Vendor' and isnumeric(@Uploadval) =1 select @Vendor = Convert( int, @Uploadval)
  	If @Column='Description' select @Description = @Uploadval
  	If @Column='OrderDate' and isdate(@Uploadval) =1 select @OrderDate = @Uploadval
  	If @Column='OrderedBy' select @OrderedBy =  @Uploadval
  	If @Column='ExpDate' and isdate(@Uploadval) =1 select @ExpDate =  Convert( smalldatetime, @Uploadval)
  	If @Column='Status' and isnumeric(@Uploadval) =1 select @Status = Convert( int, @Uploadval)
  	If @Column='JCCo' and isnumeric(@Uploadval) =1 select @JCCo = @Uploadval
   	If @Column='Job' select @Job = @Uploadval
  	If @Column='INCo' and isnumeric(@Uploadval) =1  select @INCo = @Uploadval
  	If @Column='Loc' select @Loc = @Uploadval
  	If @Column='ShipLoc' select @ShipLoc = @Uploadval
  	If @Column='Address' select @Address = @Uploadval
  	If @Column='City' select @City = @Uploadval
  	If @Column='State' select @State = @Uploadval
      If @Column='Zip' select @Zip = @Uploadval
  	If @Column='ShipIns' select @ShipIns = @Uploadval
  	If @Column='HoldCode' and isnumeric(@Uploadval) =1 select @HoldCode = convert(numeric,@Uploadval)
  	If @Column='PayTerms' select @PayTerms = @Uploadval
  	If @Column='CompGroup' select @CompGroup = @Uploadval
  	If @Column='Attention' select @Attention = @Uploadval
  	If @Column='PayAddressSeq' select @PayAddressSeq = @Uploadval
  	If @Column='POAddressSeq' select @POAddressSeq = @Uploadval
  
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
	IF @Column='PO' 
		IF @Uploadval IS NULL
			SET @IsPOEmpty = 'Y'
		ELSE
			SET @IsPOEmpty = 'N'
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
	IF @Column='Description' 
		IF @Uploadval IS NULL
			SET @IsDescriptionEmpty = 'Y'
		ELSE
			SET @IsDescriptionEmpty = 'N'
	IF @Column='OrderDate' 
		IF @Uploadval IS NULL
			SET @IsOrderDateEmpty = 'Y'
		ELSE
			SET @IsOrderDateEmpty = 'N'
	IF @Column='OrderedBy' 
		IF @Uploadval IS NULL
			SET @IsOrderedByEmpty = 'Y'
		ELSE
			SET @IsOrderedByEmpty = 'N'
	IF @Column='ExpDate' 
		IF @Uploadval IS NULL
			SET @IsExpDateEmpty = 'Y'
		ELSE
			SET @IsExpDateEmpty = 'N'
	IF @Column='Status' 
		IF @Uploadval IS NULL
			SET @IsStatusEmpty = 'Y'
		ELSE
			SET @IsStatusEmpty = 'N'
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
	IF @Column='ShipLoc' 
		IF @Uploadval IS NULL
			SET @IsShipLocEmpty = 'Y'
		ELSE
			SET @IsShipLocEmpty = 'N'
	IF @Column='HoldCode' 
		IF @Uploadval IS NULL
			SET @IsHoldCodeEmpty = 'Y'
		ELSE
			SET @IsHoldCodeEmpty = 'N'
	IF @Column='Country' 
		IF @Uploadval IS NULL
			SET @IsCountryEmpty = 'Y'
		ELSE
			SET @IsCountryEmpty = 'N'
	IF @Column='PayTerms' 
		IF @Uploadval IS NULL
			SET @IsPayTermsEmpty = 'Y'
		ELSE
			SET @IsPayTermsEmpty = 'N'
	IF @Column='CompGroup' 
		IF @Uploadval IS NULL
			SET @IsCompGroupEmpty = 'Y'
		ELSE
			SET @IsCompGroupEmpty = 'N'
	IF @Column='Attention' 
		IF @Uploadval IS NULL
			SET @IsAttentionEmpty = 'Y'
		ELSE
			SET @IsAttentionEmpty = 'N'
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
	IF @Column='Zip' 
		IF @Uploadval IS NULL
			SET @IsZipEmpty = 'Y'
		ELSE
			SET @IsZipEmpty = 'N'
	IF @Column='ShipIns' 
		IF @Uploadval IS NULL
			SET @IsShipInsEmpty = 'Y'
		ELSE
			SET @IsShipInsEmpty = 'N'
	IF @Column='PayAddressSeq' 
		IF @Uploadval IS NULL
			SET @IsPayAddressSeqEmpty = 'Y'
		ELSE
			SET @IsPayAddressSeqEmpty = 'N'
	IF @Column='POAddressSeq' 
		IF @Uploadval IS NULL
			SET @IsPOAddressSeqEmpty = 'Y'
		ELSE
			SET @IsPOAddressSeqEmpty = 'N'
	IF @Column='Notes' 
		IF @Uploadval IS NULL
			SET @IsNotesEmpty = 'Y'
		ELSE
			SET @IsNotesEmpty = 'N'  
  
  
             --fetch next record
  
          if @@fetch_status <> 0
            select @complete = 1
  
          select @oldrecseq = @Recseq
  
          fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
  
      end
  
    else
  
      begin
  
  
  	if @vendorgroupid <> 0 and isnull(@Co,'')<> ''  AND (ISNULL(@OverwriteVendorGroup, 'Y') = 'Y' OR ISNULL(@IsVendorGroupEmpty, 'Y') = 'Y')
   	  begin
         select @VendorGroup = VendorGroup
         from bHQCO where HQCo = @Co
  
         UPDATE IMWE
         SET IMWE.UploadVal = @VendorGroup
         where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
         and IMWE.Identifier = @vendorgroupid and IMWE.RecordType = @rectype
        end
  
  
  
  	if @poid <> 0 and isnull(@Co,'')<> '' AND (ISNULL(@OverwritePO, 'Y') = 'Y' OR ISNULL(@IsPOEmpty, 'Y') = 'Y')
   	  begin
  
  		exec @recode = bspPOHDNextPO @Co, @PO output
  
         UPDATE IMWE
         SET IMWE.UploadVal = @PO
         where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
         and IMWE.Identifier = @poid and IMWE.RecordType = @rectype
        end
  
  
  
  	if @statusid <> 0  AND (ISNULL(@OverwriteStatus, 'Y') = 'Y' OR ISNULL(@IsStatusEmpty, 'Y') = 'Y')
   	  begin
  
         UPDATE IMWE
         SET IMWE.UploadVal = '0'
         where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
         and IMWE.Identifier = @statusid and IMWE.RecordType = @rectype
        end
  
  
  	if @incoid <> 0  AND (ISNULL(@OverwriteINCo, 'Y') = 'Y' OR ISNULL(@IsINCoEmpty, 'Y') = 'Y')
   	  begin
  
         UPDATE IMWE
         SET IMWE.UploadVal = @Co
         where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
         and IMWE.Identifier = @incoid and IMWE.RecordType = @rectype
        end
  
  
  	if @jccoid <> 0 AND (ISNULL(@OverwriteJCCo, 'Y') = 'Y' OR ISNULL(@IsJCCoEmpty, 'Y') = 'Y')
   	  begin
  
         UPDATE IMWE
         SET IMWE.UploadVal = @Co
         where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
         and IMWE.Identifier = @jccoid and IMWE.RecordType = @rectype
        end
  
  	if @paytermsid <> 0 AND (ISNULL(@OverwritePayTerms, 'Y') = 'Y' OR ISNULL(@IsPayTermsEmpty, 'Y') = 'Y')
   	  begin
  		select @PayTerms=PayTerms 
  		from APVM with (nolock)
  		where VendorGroup = @VendorGroup and Vendor = @Vendor
  
         UPDATE IMWE
         SET IMWE.UploadVal = @PayTerms
         where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
         and IMWE.Identifier = @paytermsid and IMWE.RecordType = @rectype
        end
  
  
  	if @compgroupid <> 0 and isnull(@JCCo,'')<> '' and isnull(@Job,'')<>'' AND (ISNULL(@OverwriteCompGroup, 'Y') = 'Y' OR ISNULL(@IsCompGroupEmpty, 'Y') = 'Y')
   	  begin
  
  		select @CompGroup = POCompGroup
  		from JCJM with (nolock)
  		where JCCo = @JCCo and Job = @Job
  
         UPDATE IMWE
         SET IMWE.UploadVal = @CompGroup
         where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
         and IMWE.Identifier = @compgroupid and IMWE.RecordType = @rectype
        end
  
  
        select @currrecseq = @Recseq
        select @counter = @counter + 1
  
        select @Co =null, @Mth =null, @BatchId =null, @BatchSeq =null, @BatchTransType =null,
   		@PO =null, @VendorGroup =null, @Vendor =null, @Description =null, @OrderDate =null,
  		@OrderedBy =null, @ExpDate =null, @Status =null, @JCCo =null, @Job =null, @INCo =null, @Loc =null,
  		@ShipLoc =null, @Address =null, @City =null, @State =null, @Zip =null, @ShipIns =null,
  		@HoldCode =null, @PayTerms =null, @CompGroup =null, @Attention =null, @PayAddressSeq =null, 
  		@POAddressSeq =null
  
  
          end
  
  end
  
  
  
  close WorkEditCursor
  deallocate WorkEditCursor
  
  bspexit:
    select @msg = isnull(@desc,'Header ') + char(13) + char(13) + '[bspBidtekDefaultPOHB]'
  
      return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsPOHB] TO [public]
GO
