SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMBidtekDefaultsCMCE]
   /***********************************************************
    * CREATED BY:  Danf
    *              DANF 03/19/02 - Added Record Type
    *				DANF 02/21/03 - 14861 IF CM Ref is null set value to 'MISSING'
    *		CC	02/18/09 - Issue #24531 - Use default only if set to overwrite or value is null    
    *		GF 09/12/2010 - issue #141031 changed to use vfDateOnly
    *		AMR 01/12/11 - #142350, making case sensitive by removing unused vars and renaming same named variables

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
   
   declare @rcode int, @desc varchar(120), @ynuploaddate bYN, @Today varchar(60), @CompanyID int, @defaultvalue varchar(30),
   		@ChkNoID int
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
set @Today = CONVERT(VARCHAR(60), dbo.vfDateOnly(),101)

   -- Check ImportTemplate detail for columns to set Bidtek Defaults
   select IMTD.DefaultValue
   From IMTD
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
   
   if @@rowcount = 0
     begin
     select @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.', @rcode=1
     goto bspexit
     end
   
		DECLARE		@OverwriteUploadDate 	bYN
				,	@OverwriteCMCo	 	 	bYN
				,	@IsCMCoEmpty 		 	bYN
				,	@IsUploadDateEmpty 	 	bYN
				,	@IsSeqEmpty 		 	bYN
				,	@IsBankAcctEmpty 	 	bYN
				,	@IsChkNoEmpty 		 	bYN
				,	@IsAmountEmpty 		 	bYN
				,	@IsClearDateEmpty 	 	bYN
		
		SELECT @OverwriteCMCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'CMCo', @rectype);		
		SELECT @OverwriteUploadDate = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'UploadDate', @rectype);
   
   
   select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CMCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCMCo, 'Y') = 'Y')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
    end
   
    select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'CMCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCMCo, 'Y') = 'N')
    begin
      UPDATE IMWE
      SET IMWE.UploadVal = @Company
      where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
      AND IMWE.UploadVal IS NULL
    end
   
   
   select @ChkNoID = DDUD.Identifier From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'ChkNo'
   
   select IMTD.DefaultValue, DDUD.ColumnName, DDUD.Identifier
   From IMTD
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'UploadDate'
   if @@rowcount <> 0 select @ynuploaddate ='Y'
   
    declare WorkEditCursor cursor for
    select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
        from IMWE
        inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
        where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
        Order by IMWE.RecordSeq, IMWE.Identifier
   
   open WorkEditCursor
   -- set open cursor flag
   -- #142350 - @importid not used removed it
   declare @Recseq int, @Tablename varchar(20), @Column varchar(30), @Uploadval varchar(60), @Ident int,
        @seq int, @Identifier int
   
   declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
           @columnlist varchar(255), @complete int, @counter int, @records int, @oldrecseq int
   
   declare @CMCo bCompany, @UploadDate bDate, @BankAcct varchar(10), @ChkNo varchar(10), @Amount bDollar, @ClearDate bDate
   
   declare @ctdesc varchar(60),@trackhours bYN, @costtypeout bJCCType, @retainpct bPct
   
   
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
   
       If @Column='CMCo' and  isnumeric(@Uploadval) =1 select @CMCo = Convert( int, @Uploadval)
   	If @Column='UploadDate' and isdate(@Uploadval) =1 select @UploadDate = Convert( smalldatetime, @Uploadval)
   /*	If @Column='BankAcct' and  isnumeric(@Uploadval) =1 select @BankAcct = @Uploadval
   	If @Column='ChkNo' select @ChkNo = @Uploadval
   	If @Column='Amount' and isnumeric(@Uploadval) =1 select @Amount = @Uploadval
   	If @Column='ClearDate' and isdate(@Uploadval) =1 select @ClearDate = Convert( smalldatetime, @Uploadval)*/
		IF @Column='CMCo' 
			IF @Uploadval IS NULL
				SET @IsCMCoEmpty = 'Y'
			ELSE
				SET @IsCMCoEmpty = 'N'
		IF @Column='UploadDate' 
			IF @Uploadval IS NULL
				SET @IsUploadDateEmpty = 'Y'
			ELSE
				SET @IsUploadDateEmpty = 'N'
		IF @Column='Seq' 
			IF @Uploadval IS NULL
				SET @IsSeqEmpty = 'Y'
			ELSE
				SET @IsSeqEmpty = 'N'
		IF @Column='BankAcct' 
			IF @Uploadval IS NULL
				SET @IsBankAcctEmpty = 'Y'
			ELSE
				SET @IsBankAcctEmpty = 'N'
		IF @Column='ChkNo' 
			IF @Uploadval IS NULL
				SET @IsChkNoEmpty = 'Y'
			ELSE
				SET @IsChkNoEmpty = 'N'
		IF @Column='Amount' 
			IF @Uploadval IS NULL
				SET @IsAmountEmpty = 'Y'
			ELSE
				SET @IsAmountEmpty = 'N'
		IF @Column='ClearDate' 
			IF @Uploadval IS NULL
				SET @IsClearDateEmpty = 'Y'
			ELSE
				SET @IsClearDateEmpty = 'N'
   
              --fetch next record
   
           if @@fetch_status <> 0
             select @complete = 1
   
           select @oldrecseq = @Recseq
   
           fetch next from WorkEditCursor into @Recseq, @Ident, @Tablename, @Column, @Uploadval
   
       end
   
     else
   
       begin
   
   
       If @ynuploaddate ='Y'  AND (ISNULL(@OverwriteUploadDate, 'Y') = 'Y' OR ISNULL(@IsUploadDateEmpty, 'Y') = 'Y')
    	     begin
   
      	     select @Identifier = DDUD.Identifier
   	     From DDUD
   	     inner join IMTD ON IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
            Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'AND DDUD.ColumnName = 'UploadDate'
   
            UPDATE IMWE
   	     SET IMWE.UploadVal = @Today
   	     where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and IMWE.RecordSeq=@currrecseq and IMWE.Identifier = @Identifier
           end
   
               select @currrecseq = @Recseq
               select @counter = @counter + 1
   
           end
   
   end
   
   -- If missing CM Reference number, (null or empty), update refernce to MISSING
   
   UPDATE IMWE
   SET IMWE.UploadVal = 'MISSING'
   where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and isnull(IMWE.UploadVal,'')='' and
   	IMWE.Identifier = @ChkNoID
   
   close WorkEditCursor
   deallocate WorkEditCursor
   
   bspexit:
       select @msg = isnull(@desc,'Clear')
   
       return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsCMCE] TO [public]
GO
