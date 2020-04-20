SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsPORB]
    /***********************************************************
     * CREATED BY: Danf
     * MODIFIED BY: RBT 07/22/05 - Issue #28927, Provide default for Description field.
	 *				DC 06/02/08  - #127180 Add the Auto Add PO Item to the PO Change Order batch program 
	 *				CC 08/08/08  - #128296 Changed conversion of uploadval to match bUnits definition
	 *				CC	02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
	 *				CC  05/29/09 - Issue #133516 - Correct defaulting of Company
	 *				GF 09/14/2010 - issue #141031 change to use function vfDateOnly
     *				AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
     *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
     *
     * Usage:
     *	Used by Imports to create values for needed or missing
     *      data based upon Bidtek default rules.
     * Defaults:
     *  Co, BatchTransType, RecvdDate, RecvdCost, BOUnits, BOCost, UnitCost, ECM, InvdFlag
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
            @ynco bYN, @ynbatchtranstype bYN, @ynrecvddate bYN, @ynrecvdcost bYN, @ynbounits bYN, @ynbocost bYN, @ynunitcost bYN, @ynemc bYN, @yninvdflag bYN,
            @coid int, @batchtranstypeid int, @recvddateid int, @recvdcostid int, @bounitsid int, @bocostid int, @unitcostid int, @ecmid int, @invdflagid int,
            @defaultvalue varchar(30), @descriptionid int, @vendor bVendor, @source bSource
    
    select @ynco ='N', @ynbatchtranstype ='N', @ynrecvddate = 'N', @ynrecvdcost = 'N', @ynbounits ='N', @ynbocost ='N', @ynunitcost ='N', @ynemc ='N', @yninvdflag ='N'
    
    /* check required input params */
    if @rectype <> 'PORB' goto bspexit
    
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
    
    select @source = 'PO Receipt'
   
    select IMTD.DefaultValue
    From IMTD
    Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
    and IMTD.RecordType = @rectype
    
    if @@rowcount = 0
      begin
      select @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.'
      goto bspexit
      end
    
    
    DECLARE 
			  @OverwriteBatchTransType 	 bYN
			, @OverwriteRecvdDate 	 	 bYN
			, @OverwriteInvdFlag 	 	 bYN
			, @OverwriteRecvdCost 	 	 bYN
			, @OverwriteBOUnits 	 	 bYN
			, @OverwriteBOCost 	 		 bYN
			, @OverwriteUnitCost 	 	 bYN
			, @OverwriteECM 	 		 bYN
			, @OverwriteDescription 	 bYN
			, @OverwriteCo				 bYN
			,	@IsCoEmpty 				 bYN
			,	@IsMthEmpty 			 bYN
			,	@IsBatchIdEmpty 		 bYN
			,	@IsBatchSeqEmpty 		 bYN
			,	@IsBatchTransTypeEmpty 	 bYN
			,	@IsPOTransEmpty 		 bYN
			,	@IsPOEmpty 				 bYN
			,	@IsPOItemEmpty 			 bYN
			,	@IsRecvdDateEmpty 		 bYN
			,	@IsRecvdByEmpty 		 bYN
			,	@IsDescriptionEmpty 	 bYN
			,	@IsReceiver#Empty 		 bYN
			,	@IsRecvdUnitsEmpty 		 bYN
			,	@IsRecvdCostEmpty 		 bYN
			,	@IsBOUnitsEmpty 		 bYN
			,	@IsBOCostEmpty 			 bYN
			,	@IsUnitCostEmpty 		 bYN
			,	@IsECMEmpty 			 bYN
			,	@IsInvdFlagEmpty 		 bYN
			,	@IsNotesEmpty 			 bYN
			
		SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype);
		SELECT @OverwriteRecvdDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RecvdDate', @rectype);
		SELECT @OverwriteInvdFlag = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InvdFlag', @rectype);
		SELECT @OverwriteRecvdCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'RecvdCost', @rectype);
		SELECT @OverwriteBOUnits = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BOUnits', @rectype);
		SELECT @OverwriteBOCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BOCost', @rectype);
		SELECT @OverwriteUnitCost = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UnitCost', @rectype);
		SELECT @OverwriteECM = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ECM', @rectype);
		SELECT @OverwriteDescription = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Description', @rectype);
		SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
    
    select @coid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Co', @rectype, 'Y')
    if isnull(@coid ,99999) <> 99999 AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
     begin
    
       UPDATE IMWE
       SET IMWE.UploadVal = @Company
       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @coid
       and IMWE.RecordType = @rectype
     end
    
    
    select @batchtranstypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BatchTransType', @rectype, 'Y')
    if isnull(@batchtranstypeid,0) <> 0 AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'Y')
     begin
    
       UPDATE IMWE
       SET IMWE.UploadVal = 'A'
       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @batchtranstypeid
       and IMWE.RecordType = @rectype
     end
    if isnull(@batchtranstypeid,0) <> 0 AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'N')
     begin
    
       UPDATE IMWE
       SET IMWE.UploadVal = 'A'
       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @batchtranstypeid
       and IMWE.RecordType = @rectype
       AND IMWE.UploadVal IS NULL
     end 
    
    select @recvddateid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RecvdDate', @rectype, 'Y')
    if isnull(@recvddateid,0) <> 0 AND (ISNULL(@OverwriteRecvdDate, 'Y') = 'Y')
     begin
    
       UPDATE IMWE
       ----#141031
       SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @recvddateid
       and IMWE.RecordType = @rectype
     end
     
     ------------------
    if isnull(@coid ,99999) <> 99999 AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
     begin
    
       UPDATE IMWE
       SET IMWE.UploadVal = @Company
       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @coid
       and IMWE.RecordType = @rectype
     end
     
    if isnull(@recvddateid,0) <> 0 AND (ISNULL(@OverwriteRecvdDate, 'Y') = 'N')
     begin
    
       UPDATE IMWE
       ----#141031
       SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @recvddateid
       and IMWE.RecordType = @rectype
       AND IMWE.UploadVal IS NULL
     end
     
    select @invdflagid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'InvdFlag', @rectype, 'Y')
    if isnull(@invdflagid,0) <> 0 AND (ISNULL(@OverwriteInvdFlag, 'Y') = 'Y')
     begin
    
       UPDATE IMWE
       SET IMWE.UploadVal = 'N'
       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @invdflagid
       and IMWE.RecordType = @rectype
     end
    if isnull(@invdflagid,0) <> 0 AND (ISNULL(@OverwriteInvdFlag, 'Y') = 'N')
     begin
    
       UPDATE IMWE
       SET IMWE.UploadVal = 'N'
       where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @invdflagid
       and IMWE.RecordType = @rectype
       AND IMWE.UploadVal IS NULL
     end
    
    select @recvdcostid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'RecvdCost', @rectype, 'Y')
    
    select @bounitsid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BOUnits', @rectype, 'Y')
    
    select @bocostid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BOCost', @rectype, 'Y')
    
    select @unitcostid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'UnitCost', @rectype, 'Y')
    
    select @ecmid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ECM', @rectype, 'Y')
    
    select @descriptionid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Description', @rectype, 'Y')
    
    declare  @co bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @batchtranstype char, @potrans bTrans,
    @po varchar(30), @poitem bItem, @recvddate bDate, @recvdby varchar, @description bDesc, @unitcost bUnitCost,
    @ecm bECM, @recvdunits bUnits, @recvdcost bDollar, @bounits bUnits, @bocost bDollar, @receiver# varchar,
    @invdflag bYN --, @notes bNotes
    --#142350 renaming @UnitCost,@ECM
    DECLARE @UM bUM,
			@UnitCostCur bUnitCost,
			@ECMCur bECM,
			@ECMFact int,
			@CurUnits bUnits,
			@CurCost bDollar
    
    
    declare WorkEditCursor cursor local fast_forward for
    select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
        from IMWE
            inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
        where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form and
    	IMWE.RecordType = @rectype
        Order by IMWE.RecordSeq, IMWE.Identifier
    
    open WorkEditCursor
    -- set open cursor flag
    
    --	#142350 removing @importid,@seq,@IdentityID
    DECLARE @Recseq int,
			@Tablename varchar(20),
			@Column varchar(30),
			@Uploadval varchar(60),
			@Ident int
            
    
    declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
            @columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int
    
    
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
    
        If @Column='Co' and isnumeric(@Uploadval) =1 select @co = Convert( int, @Uploadval)
    	If @Column='Mth' and isdate(@Uploadval) =1 select @mth = Convert( smalldatetime, @Uploadval)
    	If @Column='BatchId' and  isnumeric(@Uploadval) =1 select @batchid = @Uploadval
    	If @Column='BatchSeq' select @batchseq = @Uploadval 
    	If @Column='BatchTransType' select @batchtranstype = @Uploadval
    	If @Column='PO' select @po = @Uploadval
    	If @Column='POItem' and isnumeric(@Uploadval) =1 select @poitem = Convert( int, @Uploadval)
    	If @Column='RecvdDate' and isdate(@Uploadval) =1 select @recvddate =  Convert( smalldatetime, @Uploadval)
    	If @Column='RecvdBy' select @recvdby = @Uploadval
    	If @Column='Description' select @description = @Uploadval
    	If @Column='UnitCost' and isnumeric(@Uploadval) =1 select @unitcost = convert(decimal(10,5),@Uploadval)
    	If @Column='ECM' select @ecm = @Uploadval
    	If @Column='RecvdUnits' and isnumeric(@Uploadval) =1 select @recvdunits = convert(decimal(12,3),@Uploadval)
    	If @Column='RecvdCost' and isnumeric(@Uploadval) =1 select @recvdcost = convert(decimal(10,5),@Uploadval)
    	If @Column='BOUnits' and isnumeric(@Uploadval) =1 select @bounits = convert(decimal(12,3),@Uploadval)
    	If @Column='BOCost' and isnumeric(@Uploadval) =1 select @bocost = convert(decimal(10,5),@Uploadval)
    	If @Column='Receiver#' select @receiver# = @Uploadval
    	If @Column='InvdFlag' select @invdflag = @Uploadval
        --If @Column='Notes' select @notes = @Uploadval
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
		IF @Column='POTrans' 
			IF @Uploadval IS NULL
				SET @IsPOTransEmpty = 'Y'
			ELSE
				SET @IsPOTransEmpty = 'N'
		IF @Column='PO' 
			IF @Uploadval IS NULL
				SET @IsPOEmpty = 'Y'
			ELSE
				SET @IsPOEmpty = 'N'
		IF @Column='POItem' 
			IF @Uploadval IS NULL
				SET @IsPOItemEmpty = 'Y'
			ELSE
				SET @IsPOItemEmpty = 'N'
		IF @Column='RecvdDate' 
			IF @Uploadval IS NULL
				SET @IsRecvdDateEmpty = 'Y'
			ELSE
				SET @IsRecvdDateEmpty = 'N'
		IF @Column='RecvdBy' 
			IF @Uploadval IS NULL
				SET @IsRecvdByEmpty = 'Y'
			ELSE
				SET @IsRecvdByEmpty = 'N'
		IF @Column='Description' 
			IF @Uploadval IS NULL
				SET @IsDescriptionEmpty = 'Y'
			ELSE
				SET @IsDescriptionEmpty = 'N'
		IF @Column='Receiver#' 
			IF @Uploadval IS NULL
				SET @IsReceiver#Empty = 'Y'
			ELSE
				SET @IsReceiver#Empty = 'N'
		IF @Column='RecvdUnits' 
			IF @Uploadval IS NULL
				SET @IsRecvdUnitsEmpty = 'Y'
			ELSE
				SET @IsRecvdUnitsEmpty = 'N'
		IF @Column='RecvdCost' 
			IF @Uploadval IS NULL
				SET @IsRecvdCostEmpty = 'Y'
			ELSE
				SET @IsRecvdCostEmpty = 'N'
		IF @Column='BOUnits' 
			IF @Uploadval IS NULL
				SET @IsBOUnitsEmpty = 'Y'
			ELSE
				SET @IsBOUnitsEmpty = 'N'
		IF @Column='BOCost' 
			IF @Uploadval IS NULL
				SET @IsBOCostEmpty = 'Y'
			ELSE
				SET @IsBOCostEmpty = 'N'
		IF @Column='UnitCost' 
			IF @Uploadval IS NULL
				SET @IsUnitCostEmpty = 'Y'
			ELSE
				SET @IsUnitCostEmpty = 'N'
		IF @Column='ECM' 
			IF @Uploadval IS NULL
				SET @IsECMEmpty = 'Y'
			ELSE
				SET @IsECMEmpty = 'N'
		IF @Column='InvdFlag' 
			IF @Uploadval IS NULL
				SET @IsInvdFlagEmpty = 'Y'
			ELSE
				SET @IsInvdFlagEmpty = 'N'
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
    
       -- select needed PO information
       select @CurUnits = CurUnits, @CurCost = CurCost, @UnitCostCur = CurUnitCost, @ECMCur = CurECM, @UM = UM from bPOIT
       where POCo=@co and PO = @po and POItem = @poitem
     
    	if @unitcostid <> 0 and isnull(@po,'')<> ''  AND (ISNULL(@OverwriteUnitCost, 'Y') = 'Y' OR ISNULL(@IsUnitCostEmpty, 'Y') = 'Y')
     	  begin
           select @unitcost = @UnitCostCur
    
           UPDATE IMWE
           SET IMWE.UploadVal = @unitcost
           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
           and IMWE.Identifier = @unitcostid and IMWE.RecordType = @rectype
          end
    
    	if @ecmid <> 0 and isnull(@po,'')<> ''  AND (ISNULL(@OverwriteECM, 'Y') = 'Y' OR ISNULL(@IsECMEmpty, 'Y') = 'Y')
     	  begin
           select @ecm = @ECMCur
    
           UPDATE IMWE
           SET IMWE.UploadVal = @ecm
           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
           and IMWE.Identifier = @ecmid and IMWE.RecordType = @rectype
          end
    
    	if @recvdcostid <> 0 and isnull(@po,'')<> '' and @UM<>'LS'  AND (ISNULL(@OverwriteRecvdCost, 'Y') = 'Y' OR ISNULL(@IsRecvdCostEmpty, 'Y') = 'Y')
     	  begin
           select @ECMFact =  CASE @ECMCur WHEN 'M' then  1000
                                        WHEN 'C' then  100
                                        else  1 end  
    
           select @recvdcost = (isnull(@recvdunits,0)/ @ECMFact) * isnull(@unitcost,0)
    
           UPDATE IMWE
           SET IMWE.UploadVal = @recvdcost
           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
           and IMWE.Identifier = @recvdcostid and IMWE.RecordType = @rectype
          end
    
    	if @bounitsid <> 0 and isnull(@po,'')<> '' AND (ISNULL(@OverwriteBOUnits, 'Y') = 'Y' OR ISNULL(@IsBOUnitsEmpty, 'Y') = 'Y')
     	  begin
    	   select @bounits = 0
           if isnull(@CurUnits,0)<>0 and @UM <> 'LS' select @bounits = -@recvdunits
    
           UPDATE IMWE
           SET IMWE.UploadVal = @bounits
           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
           and IMWE.Identifier = @bounitsid and IMWE.RecordType = @rectype
          end
    
    	if @bocostid <> 0 and isnull(@po,'')<> ''  AND (ISNULL(@OverwriteBOCost, 'Y') = 'Y' OR ISNULL(@IsBOCostEmpty, 'Y') = 'Y')
     	  begin
           select @bocost = 0
           if isnull(@CurCost,0) <> 0 and @UM = 'LS' select @bocost = - @recvdcost
    
           UPDATE IMWE
           SET IMWE.UploadVal = @bocost
           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
           and IMWE.Identifier = @bocostid and IMWE.RecordType = @rectype
          end
   
   	if @descriptionid <> 0	 AND (ISNULL(@OverwriteDescription, 'Y') = 'Y' OR ISNULL(@IsDescriptionEmpty, 'Y') = 'Y') 	--issue #28927
   	begin
   		--get the vendor
   		select @vendor = null
   		exec @recode = bspPOValVendInUse @co, @po, @batchid, @mth, @vendor output, null, null, @msg output
   		--get the description
   		select @msg = null
   		exec @recode = bspPOItemVal @co, @po, @poitem, @batchid, @mth, @source, @vendor, null, null, @msg output --DC #127180
   
   		select @description = @msg
   
           UPDATE IMWE
           SET IMWE.UploadVal = @description
           where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
           and IMWE.Identifier = @descriptionid and IMWE.RecordType = @rectype
   	end
    
          select @currrecseq = @Recseq
          select @counter = @counter + 1
    
            end
    
    end
    
    
    close WorkEditCursor
    deallocate WorkEditCursor
    
    bspexit:
        select @msg = isnull(@desc,'PO Receiving') + char(13) + char(10) + '[bspBidtekDefaultPORB]'
    
        return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsPORB] TO [public]
GO
