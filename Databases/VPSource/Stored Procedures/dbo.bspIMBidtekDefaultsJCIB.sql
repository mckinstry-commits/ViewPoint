SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsJCIB]
   /***********************************************************
    * CREATED BY: Danf
    * MODIFIED BY: 
    *		CC	02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
    *		CC  05/29/09 - Issue #133516 - Correct defaulting of Company
    *		GF  09/13/2010 - issue #141031 change to use vfDateOnly
    *		AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
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
           @CompanyID int, @SourceID int, @TransTypeid int, @TransDateID int, @ARTransTypeID int,
           @custgroupid int, @paytermsid int, @rectypeid int, @discdateid int, @duedateid int,
   		@zcreditamtid int, @defaultvalue varchar(30),
   		@ToJCCoid int, @GLCoid int, @GLTransAcctid int, @GLOffsetAcctid int, @ReversalStatusid int,
   		@zBilledUnitsid int, @zBilledAmtid int
   
   
   /* check required input params */
   select @rcode = 0
   if @rectype <> 'JCIB' goto bspexit
   
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
			  @OverwriteTransType 	 	 bYN
			, @OverwriteJCTransType 	 bYN
			, @OverwriteActDate 	 	 bYN
			, @OverwriteReversalStatus 	 bYN
			, @OverwriteToJCCo 	 		 bYN
			, @OverwriteGLCo 	 		 bYN
			, @OverwriteGLTransAcct 	 bYN
			, @OverwriteGLOffsetAcct 	 bYN
			, @OverwriteCo				 bYN
			,	@IsCoEmpty 				 bYN
			,	@IsMthEmpty 			 bYN
			,	@IsBatchIdEmpty 		 bYN
			,	@IsBatchSeqEmpty 		 bYN
			,	@IsOrigMthEmpty 		 bYN
			,	@IsItemTransEmpty 		 bYN
			,	@IsTransTypeEmpty 		 bYN
			,	@IsJCTransTypeEmpty 	 bYN
			,	@IsToJCCoEmpty 			 bYN
			,	@IsContractEmpty 		 bYN
			,	@IsItemEmpty 			 bYN
			,	@IsDescriptionEmpty 	 bYN
			,	@IsActDateEmpty 		 bYN
			,	@IsGLCoEmpty 			 bYN
			,	@IsGLTransAcctEmpty 	 bYN
			,	@IsGLOffsetAcctEmpty 	 bYN
			,	@IsBilledUnitsEmpty 	 bYN
			,	@IsBilledAmtEmpty 		 bYN
			,	@IsARCoEmpty 			 bYN
			,	@IsARInvoiceEmpty 		 bYN
			,	@IsARCheckEmpty 		 bYN
			,	@IsReversalStatusEmpty 	 bYN

SELECT @OverwriteTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'TransType', @rectype);
SELECT @OverwriteJCTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'JCTransType', @rectype);
SELECT @OverwriteActDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActDate', @rectype);
SELECT @OverwriteReversalStatus = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ReversalStatus', @rectype);
SELECT @OverwriteToJCCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ToJCCo', @rectype);
SELECT @OverwriteGLCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
SELECT @OverwriteGLTransAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLTransAcct', @rectype);
SELECT @OverwriteGLOffsetAcct = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLOffsetAcct', @rectype);
SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
   
   
   select @CompanyID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Co', @rectype, 'Y')
   if isnull(@CompanyID ,99999) <> 99999 AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
    begin
   
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
      and IMWE.RecordType = @rectype
    end

   if isnull(@CompanyID ,99999) <> 99999 AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
    begin
   
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
      and IMWE.RecordType = @rectype
    end
   
   
   select @TransTypeid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'TransType', @rectype, 'Y')
   if isnull(@TransTypeid,0) <> 0 AND (ISNULL(@OverwriteTransType, 'Y') = 'Y')
    begin
   
      UPDATE IMWE
      SET IMWE.UploadVal = 'A'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @TransTypeid
      and IMWE.RecordType = @rectype
end
   if isnull(@TransTypeid,0) <> 0 AND (ISNULL(@OverwriteTransType, 'Y') = 'N')
    begin
   
      UPDATE IMWE
      SET IMWE.UploadVal = 'A'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @TransTypeid
      and IMWE.RecordType = @rectype
      AND IMWE.UploadVal IS NULL
    end
   
   select @ARTransTypeID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'JCTransType', @rectype, 'Y')
   if isnull(@ARTransTypeID,0) <> 0 AND (ISNULL(@OverwriteJCTransType, 'Y') = 'Y')
    begin
   
      UPDATE IMWE
      SET IMWE.UploadVal = 'JC'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ARTransTypeID
      and IMWE.RecordType = @rectype
    end

   if isnull(@ARTransTypeID,0) <> 0 AND (ISNULL(@OverwriteJCTransType, 'Y') = 'N')
    begin
   
      UPDATE IMWE
      SET IMWE.UploadVal = 'JC'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ARTransTypeID
      and IMWE.RecordType = @rectype
      AND IMWE.UploadVal IS NULL
    end

   
   select @TransDateID=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ActDate', @rectype, 'Y')
   if isnull(@TransDateID,0) <> 0 AND (ISNULL(@OverwriteActDate, 'Y') = 'Y')
    begin
   
      UPDATE IMWE
      ----#141031
      SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @TransDateID
      and IMWE.RecordType = @rectype
    end

   if isnull(@TransDateID,0) <> 0 AND (ISNULL(@OverwriteActDate, 'Y') = 'N')
    begin
   
      UPDATE IMWE
      ----#141031
      SET IMWE.UploadVal = convert(varchar(20), dbo.vfDateOnly(),101)
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @TransDateID
      and IMWE.RecordType = @rectype
      AND IMWE.UploadVal IS NULL
    end
   
   select @ReversalStatusid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ReversalStatus', @rectype, 'Y')
   if isnull(@ReversalStatusid,0) <> 0 AND (ISNULL(@OverwriteReversalStatus, 'Y') = 'Y')
    begin
   
      UPDATE IMWE
      SET IMWE.UploadVal = 0
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ReversalStatusid
      and IMWE.RecordType = @rectype
    end

   if isnull(@ReversalStatusid,0) <> 0 AND (ISNULL(@OverwriteReversalStatus, 'Y') = 'N')
    begin
   
      UPDATE IMWE
      SET IMWE.UploadVal = 0
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @ReversalStatusid
      and IMWE.RecordType = @rectype
      AND IMWE.UploadVal IS NULL
    end
   
   select @ToJCCoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'ToJCCo', @rectype, 'Y')
   
   select @GLCoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLCo', @rectype, 'Y')
   
   select @GLTransAcctid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLTransAcct', @rectype, 'Y')
   
   select @GLOffsetAcctid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'GLOffsetAcct', @rectype, 'Y')
   
   select @zBilledUnitsid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BilledUnits', @rectype, 'N')
   
   Select @zBilledAmtid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'BilledAmt', @rectype, 'N')
   
   declare  @Co bCompany, @Mth bMonth, @BatchId bBatchID, @BatchSeq int, @TransType char, @ItemTrans bTrans,
   @Contract bContract, @Item bContractItem, @ActDate bDate, @JCTransType char(2), @Description bTransDesc,
   @GLCo bCompany, @GLTransAcct bGLAcct, @GLOffsetAcct bGLAcct, @ReversalStatus smallint, @OrigMth bMonth,
   @OrigItemTrans bTrans, @BilledUnits bUnits, @BilledAmt bDollar, @ARCo bCompany, @ARInvoice varchar(10),
   @ARCheck varchar(10), @ToJCCo bCompany
   --#142350 renaming @company
   declare @Comp bCompany, @deftransglacct bGLAcct, @um bUM
   
   
   
   declare WorkEditCursor cursor local fast_forward for
   select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
       from IMWE
           inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
       where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form and
   	IMWE.RecordType = @rectype
       Order by IMWE.RecordSeq, IMWE.Identifier
   
   open WorkEditCursor
   -- set open cursor flag
    --#142350 removing @importid
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
   
       If @Column='Co' and isnumeric(@Uploadval) =1 select @Co = Convert( int, @Uploadval)
   	If @Column='Mth' and isdate(@Uploadval) =1 select @Mth = Convert( smalldatetime, @Uploadval)
   /*	If @Column='BatchId' and  isnumeric(@Uploadval) =1 select @BatchSeq = @Uploadval
   	If @Column='BatchSeq' select @BatchTransType = @Uploadval */
   	If @Column='TransType' select @TransType = @Uploadval
   --	If @Column='ItemTrans' and isnumeric(@Uploadval) =1 select @ItemTrans = Convert(int, @Uploadval)
   	If @Column='Contract' select @Contract = @Uploadval
   	If @Column='Item' select @Item = @Uploadval
       If @Column='ActDate' and isdate(@Uploadval) =1 select @ActDate = Convert( smalldatetime, @Uploadval)
   	If @Column='JCTransType' select @JCTransType = @Uploadval
   	If @Column='Description' select @Description = @Uploadval
   	If @Column='GLCo' and isnumeric(@Uploadval) =1 select @GLCo = Convert( int, @Uploadval)
   	If @Column='GLTransAcct' select @GLTransAcct = @Uploadval
   	If @Column='GLOffsetAcct' select @GLOffsetAcct = @Uploadval
   	If @Column='OrigMth' and isdate(@Uploadval) =1 select @OrigMth = convert(smalldatetime,@Uploadval)
   	If @Column='OrigItemTrans' and isnumeric(@Uploadval) =1 select @OrigItemTrans = convert(int,@Uploadval)
   	If @Column='BilledUnits' and isnumeric(@Uploadval) = 1 select @BilledUnits = convert(numeric(16,5),@Uploadval)
   	If @Column='BilledAmt' and isnumeric(@Uploadval) = 1 select @BilledAmt = convert(numeric(16,5),@Uploadval)
   	If @Column='ARCo' and isnumeric(@Uploadval) =1 select @ARCo = Convert( int, @Uploadval)
   	If @Column='ARInvoice' select @ARInvoice =  @Uploadval
   	If @Column='ARCheck' select ARCheck = @Uploadval
   	If @Column='ToJCCo' and isnumeric(@Uploadval) =1 select @ToJCCo = Convert( int, @Uploadval)
                       
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
	IF @Column='OrigMth' 
		IF @Uploadval IS NULL
			SET @IsOrigMthEmpty = 'Y'
		ELSE
			SET @IsOrigMthEmpty = 'N'
	IF @Column='ItemTrans' 
		IF @Uploadval IS NULL
			SET @IsItemTransEmpty = 'Y'
		ELSE
			SET @IsItemTransEmpty = 'N'
	IF @Column='TransType' 
		IF @Uploadval IS NULL
			SET @IsTransTypeEmpty = 'Y'
		ELSE
			SET @IsTransTypeEmpty = 'N'
	IF @Column='JCTransType' 
		IF @Uploadval IS NULL
			SET @IsJCTransTypeEmpty = 'Y'
		ELSE
			SET @IsJCTransTypeEmpty = 'N'
	IF @Column='ToJCCo' 
		IF @Uploadval IS NULL
			SET @IsToJCCoEmpty = 'Y'
		ELSE
			SET @IsToJCCoEmpty = 'N'
	IF @Column='Contract' 
		IF @Uploadval IS NULL
			SET @IsContractEmpty = 'Y'
		ELSE
			SET @IsContractEmpty = 'N'
	IF @Column='Item' 
		IF @Uploadval IS NULL
			SET @IsItemEmpty = 'Y'
		ELSE
			SET @IsItemEmpty = 'N'
	IF @Column='Description' 
		IF @Uploadval IS NULL
			SET @IsDescriptionEmpty = 'Y'
		ELSE
			SET @IsDescriptionEmpty = 'N'
	IF @Column='ActDate' 
		IF @Uploadval IS NULL
			SET @IsActDateEmpty = 'Y'
		ELSE
			SET @IsActDateEmpty = 'N'
	IF @Column='GLCo' 
		IF @Uploadval IS NULL
			SET @IsGLCoEmpty = 'Y'
		ELSE
			SET @IsGLCoEmpty = 'N'
	IF @Column='GLTransAcct' 
		IF @Uploadval IS NULL
			SET @IsGLTransAcctEmpty = 'Y'
		ELSE
			SET @IsGLTransAcctEmpty = 'N'
	IF @Column='GLOffsetAcct' 
		IF @Uploadval IS NULL
			SET @IsGLOffsetAcctEmpty = 'Y'
		ELSE
			SET @IsGLOffsetAcctEmpty = 'N'
	IF @Column='BilledUnits' 
		IF @Uploadval IS NULL
			SET @IsBilledUnitsEmpty = 'Y'
		ELSE
			SET @IsBilledUnitsEmpty = 'N'
	IF @Column='BilledAmt' 
		IF @Uploadval IS NULL
			SET @IsBilledAmtEmpty = 'Y'
		ELSE
			SET @IsBilledAmtEmpty = 'N'
	IF @Column='ARCo' 
		IF @Uploadval IS NULL
			SET @IsARCoEmpty = 'Y'
		ELSE
			SET @IsARCoEmpty = 'N'
	IF @Column='ARInvoice' 
		IF @Uploadval IS NULL
			SET @IsARInvoiceEmpty = 'Y'
		ELSE
			SET @IsARInvoiceEmpty = 'N'
	IF @Column='ARCheck' 
		IF @Uploadval IS NULL
			SET @IsARCheckEmpty = 'Y'
		ELSE
			SET @IsARCheckEmpty = 'N'
	IF @Column='ReversalStatus' 
		IF @Uploadval IS NULL
			SET @IsReversalStatusEmpty = 'Y'
		ELSE
			SET @IsReversalStatusEmpty = 'N'   
   
   
              --fetch next record
   
           if @@fetch_status <> 0
             select @complete = 1
   
           select @oldrecseq = @Recseq
   
           fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   
       end
   
     else
   
       begin
   
   
   	if @ToJCCoid <> 0 and isnull(@Co,'')<> ''  AND (ISNULL(@OverwriteToJCCo, 'Y') = 'Y' OR ISNULL(@IsToJCCoEmpty, 'Y') = 'Y')
    	  begin
          select @ToJCCo = @Co
   
          UPDATE IMWE
          SET IMWE.UploadVal = @ToJCCo
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
          and IMWE.Identifier = @ToJCCoid and IMWE.RecordType = @rectype
         end
   
   	if @GLCoid <> 0 and isnull(@Co,'')<> ''  AND (ISNULL(@OverwriteGLCo, 'Y') = 'Y' OR ISNULL(@IsGLCoEmpty, 'Y') = 'Y')
    	  begin
   	    if isnull(@ToJCCo,'')=''
            select @GLCo = GLCo from bJCCO where JCCo = @Co
    		else
            select @GLCo = GLCo from bJCCO where JCCo = @ToJCCo		 
   
          UPDATE IMWE
          SET IMWE.UploadVal = @GLCo
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
          and IMWE.Identifier = @GLCoid and IMWE.RecordType = @rectype
         end
   
   	-- Need Default GL Account 
   	 select @Comp = @Co
   	 if isnull(@ToJCCo,'') <> '' select @Comp = @ToJCCo
   	
   	 exec @rcode = bspJCCIValWithUM  @Comp, @Contract, @Item, @deftransglacct output, @um output, @msg output
   	
   
   
   	if @GLTransAcctid <> 0 and isnull(@Co,'')<> '' AND (ISNULL(@OverwriteGLTransAcct, 'Y') = 'Y' OR ISNULL(@IsGLTransAcctEmpty, 'Y') = 'Y')
    	  begin
   		select @GLTransAcct = @deftransglacct
   
          UPDATE IMWE
          SET IMWE.UploadVal = @GLTransAcct
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
          and IMWE.Identifier = @GLTransAcctid and IMWE.RecordType = @rectype
         end
   
   	if @zBilledUnitsid <> 0 and isnull(@um,'')= 'LS' 
    	  begin
   
          UPDATE IMWE
          SET IMWE.UploadVal = '0'
          where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq
          and IMWE.Identifier = @zBilledUnitsid and IMWE.RecordType = @rectype
         end
   
   
         select @currrecseq = @Recseq
         select @counter = @counter + 1
   
   		select  @Co = null, @Mth = null, @BatchId = null, @BatchSeq = null, @TransType = null, @ItemTrans = null,
   		@Contract = null, @Item = null, @ActDate = null, @JCTransType = null, @Description = null,
   		@GLCo = null, @GLTransAcct = null, @GLOffsetAcct = null, @ReversalStatus = null, @OrigMth = null,
   		@OrigItemTrans = null, @BilledUnits = null, @BilledAmt = null, @ARCo = null, @ARInvoice = null,
   		@ARCheck = null, @ToJCCo = null
   		
   		select @Comp = null, @deftransglacct = null, @um = null
   
           end
   
   end
   
   UPDATE IMWE
   SET IMWE.UploadVal = 0
   where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and isnull(IMWE.UploadVal,'')='' and
   (IMWE.Identifier = @zBilledUnitsid or IMWE.Identifier = @zBilledAmtid )
   
   close WorkEditCursor
   deallocate WorkEditCursor
   
   bspexit:
       select @msg = isnull(@desc,'JC Revenue Adjustments') + char(13) + char(10) + '[bspIMBidtekDefaultsJCIB]'
   
       return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsJCIB] TO [public]
GO
