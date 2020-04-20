SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMViewpointDefaultsCMTB]
   /***********************************************************
    * CREATED BY:  DANF 06/20/2003
    *		CC	 02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
    *		CC  05/29/09 - Issue #133516 - Correct defaulting of Company
    *		GF  09/11/2010 - issue #141031 changed to use vfDateOnly
    *		AMR 01/12/11 - #142350, making case sensitive by removing unused vars and renaming same named variables
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
   
   declare @rcode int, @desc varchar(120), @ynActDate bYN, @Today varchar(60), @CompanyID int, @defaultvalue varchar(30),
   		@ActDateid int, @BatchTransTypeID int
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
   
    select @rcode = 0
    ----#141031
    set @Today = CONVERT(VARCHAR(60), dbo.vfDateOnly(),101)
   --
   -- Check ImportTemplate detail for columns to set Bidtek Defaults
   	if not exists(select IMTD.DefaultValue From IMTD with (nolock)
   	Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
   	and IMTD.RecordType = @rectype)
   	goto bspexit
   
   
   DECLARE 
			 @OverwriteBatchTransType 	 bYN
			,@OverwriteActDate 	 		 bYN
			,@OverwriteCo				 bYN
			,	@IsCoEmpty 				 bYN
			,	@IsMthEmpty 			 bYN
			,	@IsBatchIdEmpty 		 bYN
			,	@IsBatchSeqEmpty 		 bYN
			,	@IsBatchTransTypeEmpty 	 bYN
			,	@IsFromCMCoEmpty 		 bYN
			,	@IsFromCMAcctEmpty 		 bYN
			,	@IsToCMCoEmpty 			 bYN
			,	@IsToCMAcctEmpty 		 bYN
			,	@IsCMRefEmpty 			 bYN
			,	@IsActDateEmpty 		 bYN
			,	@IsAmountEmpty 			 bYN
			,	@IsDescriptionEmpty 	 bYN

	SELECT @OverwriteBatchTransType = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'BatchTransType', @rectype);
	SELECT @OverwriteActDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActDate', @rectype);
	SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
   
   select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
    end
   
   
   
   select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'Y') 
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'A'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
    end

--------------

   select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
    end

   select @BatchTransTypeID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD  with (nolock) on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'BatchTransType'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteBatchTransType, 'Y') = 'N') 
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = 'A'
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @BatchTransTypeID
      AND IMWE.UploadVal IS NULL
    end   
   
   select @ActDateid=dbo.bfIMTemplateDefaults(@ImportTemplate, 'CMTR', 'ActDate', @rectype, 'Y')
   
    declare WorkEditCursor cursor local fast_forward for
    select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
        from IMWE
        inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
        where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
        Order by IMWE.RecordSeq, IMWE.Identifier
   
   open WorkEditCursor
   -- set open cursor flag
	--#142350 removing @importid,@seq
	DECLARE @Recseq int,
			@Tablename varchar(20),
			@Column varchar(30),
			@Uploadval varchar(60),
			@Ident int
           
   
   declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
           @columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int
   
   declare @Co bCompany, @ActDate bDate, @BankAcct varchar(10), @ChkNo varchar(10), @Amount bDollar, @ClearDate bDate
   
   
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
   
       If @Column='Co' and  isnumeric(@Uploadval) =1 select @Co = Convert( int, @Uploadval)
   	If @Column='ActDate' and isdate(@Uploadval) =1 select @ActDate = Convert( smalldatetime, @Uploadval)
   /*	If @Column='BankAcct' and  isnumeric(@Uploadval) =1 select @BankAcct = @Uploadval
   	If @Column='ChkNo' select @ChkNo = @Uploadval
   	If @Column='Amount' and isnumeric(@Uploadval) =1 select @Amount = @Uploadval
   	If @Column='ClearDate' and isdate(@Uploadval) =1 select @ClearDate = Convert( smalldatetime, @Uploadval)*/
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
		IF @Column='FromCMCo' 
			IF @Uploadval IS NULL
				SET @IsFromCMCoEmpty = 'Y'
			ELSE
				SET @IsFromCMCoEmpty = 'N'
		IF @Column='FromCMAcct' 
			IF @Uploadval IS NULL
				SET @IsFromCMAcctEmpty = 'Y'
			ELSE
				SET @IsFromCMAcctEmpty = 'N'
		IF @Column='ToCMCo' 
			IF @Uploadval IS NULL
				SET @IsToCMCoEmpty = 'Y'
			ELSE
				SET @IsToCMCoEmpty = 'N'
		IF @Column='ToCMAcct' 
			IF @Uploadval IS NULL
				SET @IsToCMAcctEmpty = 'Y'
			ELSE
				SET @IsToCMAcctEmpty = 'N'
		IF @Column='CMRef' 
			IF @Uploadval IS NULL
				SET @IsCMRefEmpty = 'Y'
			ELSE
				SET @IsCMRefEmpty = 'N'
		IF @Column='ActDate' 
			IF @Uploadval IS NULL
				SET @IsActDateEmpty = 'Y'
			ELSE
				SET @IsActDateEmpty = 'N'
		IF @Column='Amount' 
			IF @Uploadval IS NULL
				SET @IsAmountEmpty = 'Y'
			ELSE
				SET @IsAmountEmpty = 'N'
		IF @Column='Description' 
			IF @Uploadval IS NULL
				SET @IsDescriptionEmpty = 'Y'
			ELSE
				SET @IsDescriptionEmpty = 'N'   
              --fetch next record
   
           if @@fetch_status <> 0
select @complete = 1
   
           select @oldrecseq = @Recseq
   
           fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   
       end
   
     else
   
       begin
   
   
       If @ActDateid <> 0  AND (ISNULL(@OverwriteActDate, 'Y') = 'Y' OR ISNULL(@IsActDateEmpty, 'Y') = 'Y')
    	     begin
   
            UPDATE IMWE
   	     SET IMWE.UploadVal = @Today
   	     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @ActDateid
           end
   
               select @currrecseq = @Recseq
               select @counter = @counter + 1
   
           end
   
   end
   
   
   close WorkEditCursor
   deallocate WorkEditCursor
   
   bspexit:
       select @msg = isnull(@desc,'CM Transfers') + char(13) + char(10) + '[bspBidtekDefaultCMCE]'
   
       return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspIMViewpointDefaultsCMTB] TO [public]
GO
