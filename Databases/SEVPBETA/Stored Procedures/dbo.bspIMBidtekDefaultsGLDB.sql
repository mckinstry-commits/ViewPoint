SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsGLDB]
   /***********************************************************
    * CREATED BY: Danf
    *             DANF 03/19/02 - Added Record Type
    *             DANF 10/15/02 - Added InterCo column default
    *		CC	02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null
    *		JVH	1/14/10	- Issue #136522 - Added defaulting for source column.
    *		GF 09/12/2010 - issue #141031 changed to use function vfDateOnly
	*		AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
    *
    * and @Co is not null and @Co <> ''
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
   
   declare @rcode int, @desc varchar(120), @ynactdate bYN, @Today varchar(60), @CompanyID int, @SourceID int, @defaultvalue varchar(30),
   @actdateid int, @GLRefid int, @ynGLRef bYN, @Descriptionid int, @ynDescription bYN, @intercoid int
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

----#141031
select @Today = CONVERT(VARCHAR(60), dbo.vfDateOnly(),101)
   --
   -- Check ImportTemplate detail for columns to set Bidtek Defaults
   select IMTD.DefaultValue
   From IMTD
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
   
   if @@rowcount = 0
     begin
     select @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.', @rcode=0
     goto bspexit
     end
   
   DECLARE 
				  @OverwriteActDate 	 	 bYN
				, @OverwriteInterCo 	 	 bYN
				, @OverwriteCo 	 			 bYN
				, @OverwriteSource 	 		 bYN
				,	@IsCoEmpty 				 bYN
				,	@IsMthEmpty 			 bYN
				,	@IsBatchIdEmpty 		 bYN
				,	@IsBatchSeqEmpty 		 bYN
				,	@IsBatchTransTypeEmpty 	 bYN
				,	@IsGLTransEmpty 		 bYN
				,	@IsActDateEmpty 		 bYN
				,	@IsInterCoEmpty 		 bYN
				,	@IsJrnlEmpty 			 bYN
				,	@IsGLRefEmpty 			 bYN
				,	@IsDescriptionEmpty 	 bYN
				,	@IsGLAcctEmpty 			 bYN
				,	@IsAmountEmpty 			 bYN
				,	@IsSourceEmpty 			 bYN

	SELECT @OverwriteActDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'ActDate', @rectype);
	SELECT @OverwriteInterCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'InterCo', 'GLDB');   
	SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Co', @rectype);
	SELECT @OverwriteSource = ISNULL(dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'Source', @rectype), 'Y');

   select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
    end
   
   select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
      AND IMWE.UploadVal IS NULL
    end   
   
   
   select @defaultvalue = IMTD.DefaultValue, @actdateid = DDUD.Identifier From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'ActDate'
   if @@rowcount <> 0 select @ynactdate ='Y'
   
   select @intercoid=dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'InterCo', 'GLDB', 'Y')
   
   
   /*select @defaultvalue = IMTD.DefaultValue, @actdateid = DDUD.Identifier From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'GLRef'
   if @@rowcount <> 0 select @ynGLRef ='Y'
   
   select @defaultvalue = IMTD.DefaultValue, @actdateid = DDUD.Identifier From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'Description'
   if @@rowcount <> 0 select @ynDescription ='Y'*/
   
	SELECT @SourceID = dbo.bfIMTemplateDefaults(@ImportTemplate, @Form, 'Source', @rectype, 'Y')

	IF @SourceID IS NOT NULL
	BEGIN
		UPDATE IMWE
		SET IMWE.UploadVal = 'GL Jrnl'
		WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId=@ImportId AND 
			IMWE.Identifier = @SourceID AND IMWE.RecordType = @rectype
			AND (IMWE.UploadVal IS NULL OR @OverwriteSource = 'Y')
  	END
   
    declare WorkEditCursor cursor for
    select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
        from IMWE
        inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
        where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
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
   
   declare @Co bCompany, @Jrnl bJrnl, @ActDate bDate, @GLRef bGLRef, @Description bTransDesc, @InterCo bCompany
   
   
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
       If @Column='Jrnl' select @Jrnl = @Uploadval
       If @Column='GLRef' select @GLRef = @Uploadval
       If @Column='Description' select @Description = @Uploadval
       If @Column='InterCo' and  isnumeric(@Uploadval) =1 select @InterCo = Convert( int, @Uploadval)
   
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
		IF @Column='GLTrans' 
			IF @Uploadval IS NULL
				SET @IsGLTransEmpty = 'Y'
			ELSE
				SET @IsGLTransEmpty = 'N'
		IF @Column='ActDate' 
			IF @Uploadval IS NULL
				SET @IsActDateEmpty = 'Y'
			ELSE
				SET @IsActDateEmpty = 'N'
		IF @Column='InterCo' 
			IF @Uploadval IS NULL
				SET @IsInterCoEmpty = 'Y'
			ELSE
				SET @IsInterCoEmpty = 'N'
		IF @Column='Jrnl' 
			IF @Uploadval IS NULL
				SET @IsJrnlEmpty = 'Y'
			ELSE
				SET @IsJrnlEmpty = 'N'
		IF @Column='GLRef' 
			IF @Uploadval IS NULL
				SET @IsGLRefEmpty = 'Y'
			ELSE
				SET @IsGLRefEmpty = 'N'
		IF @Column='Description' 
			IF @Uploadval IS NULL
				SET @IsDescriptionEmpty = 'Y'
			ELSE
				SET @IsDescriptionEmpty = 'N'
		IF @Column='GLAcct' 
			IF @Uploadval IS NULL
				SET @IsGLAcctEmpty = 'Y'
			ELSE
				SET @IsGLAcctEmpty = 'N'
		IF @Column='Amount' 
			IF @Uploadval IS NULL
				SET @IsAmountEmpty = 'Y'
			ELSE
				SET @IsAmountEmpty = 'N'
		IF @Column='Source' 
			IF @Uploadval IS NULL
				SET @IsSourceEmpty = 'Y'
			ELSE
				SET @IsSourceEmpty = 'N'   
   
              --fetch next record
   
           if @@fetch_status <> 0
             select @complete = 1
   
           select @oldrecseq = @Recseq
   
           fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   
       end
   
     else
   
       begin
   
   
    /*   If @ynGLRef ='Y'
    	     begin
   
            select @GLRef = GLRef
            from bGLAJ
            where @Co = GLCo and @Jrnl = Jrnl
   
            UPDATE IMWE
   	     SET IMWE.UploadVal = @GLRef
   	     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @GLRefid
           end
   
       If @ynDescription ='Y'
    	     begin
   
            select @Description = TransDesc
            from bGLAJ
            where @Co = GLCo and @Jrnl = Jrnl
   
            UPDATE IMWE
   	     SET IMWE.UploadVal = @Description
   	     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Descriptionid
           end */
   
   
       If @intercoid <> 0 and isnull(@Co,999) <> 999 AND (ISNULL(@OverwriteInterCo, 'Y') = 'Y' OR ISNULL(@IsInterCoEmpty, 'Y') = 'Y') 
    	     begin
   
            UPDATE IMWE
   	     SET IMWE.UploadVal = @Co
   	     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @intercoid
           end
   
   
       If @ynactdate ='Y' AND (ISNULL(@OverwriteActDate, 'Y') = 'Y' OR ISNULL(@IsActDateEmpty, 'Y') = 'Y')
    	     begin
   
            UPDATE IMWE
   	     SET IMWE.UploadVal = @Today
   	     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @actdateid
           end
   
   
               select @currrecseq = @Recseq
               select @counter = @counter + 1
   
           end
   
   end
   
   
   
   close WorkEditCursor
   deallocate WorkEditCursor
   
   bspexit:
       select @msg = isnull(@desc,'General Ledger') + char(13) + char(10) + '[bspIMBidtekDefaultsGLDB]'
   
       return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsGLDB] TO [public]
GO
