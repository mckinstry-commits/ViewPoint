SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[mspIMViewpointDefaultsGLBD]
   /***********************************************************
    * CREATED BY:   RBT 09/25/03 for issue #17257
    * MODIFIED BY: 
    *				CC  05/29/09 - Issue #133516 - Correct defaulting of Company
    *				AMR 01/12/11 - #142350, making case sensitive by removing unused vars and renaming same named variables
    *				LWO 05/01/14 - Fixing BudgetCode datatype to char instead of int.  bBudgetCode is char(10)
    *
    * Usage:
    *	Used by Imports to create values for needed or missing
    *      data based upon Viewpoint default rules.
    *
    * Input params:
    *	@ImportId	     Import Identifier
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
   
   declare @rcode int, @desc varchar(120), @status int, 
   		@defaultvalue varchar(30), @CursorOpen int,	@CompanyID int
   
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
   
   --Co
   DECLARE  @OverwriteCo				 bYN
   SELECT @OverwriteCo = dbo.vfIMTemplateOverwrite(@ImportTemplate, @Form, 'GLCo', @rectype);
   
   select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'Y') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = @Company
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
   end
   
   -----------------

   select @CompanyID = DDUD.Identifier, @defaultvalue = IMTD.DefaultValue From IMTD with (nolock)
   inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
   Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLCo'
   if @@rowcount <> 0 and @defaultvalue = '[Bidtek]' AND (ISNULL(@OverwriteCo, 'Y') = 'N') 
   begin
       UPDATE IMWE
       SET IMWE.UploadVal = @Company
       where IMWE.ImportTemplate=@ImportTemplate and 
   	IMWE.ImportId=@ImportId and IMWE.Identifier = @CompanyID
   end
   
   
   
   DECLARE WorkEditCursor CURSOR LOCAL FAST_FORWARD FOR
   SELECT IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
   FROM IMWE with (nolock)
   INNER join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
   WHERE IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
   ORDER BY IMWE.RecordSeq, IMWE.Identifier
   
   open WorkEditCursor
   -- set open cursor flag
   select @CursorOpen = 1
   --#142350 removing  @importid varchar(10), @seq int, @Identifier int,
	DECLARE @Recseq int,
			@Tablename varchar(20),
			@Column varchar(30),
			@Uploadval varchar(60),
			@Ident int,
			@complete int
   
   declare @currrecseq int, @allownull int, @error int, @tsql varchar(255), @valuelist varchar(255),
           @columnlist varchar(255), @records int, @oldrecseq int
   
   declare @GLCo bCompany, @GLAcct bGLAcct, @BudgetCode bBudgetCode, @Mth bMonth, @BudgetAmt bDollar
   
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
   
       If @Column = 'GLCo' and isnumeric(@Uploadval) = 1 select @GLCo = Convert(int, @Uploadval)
   	If @Column = 'GLAcct' select @GLAcct = @Uploadval
   	If @Column = 'BudgetCode' /* and isnumeric(@Uploadval) = 1 */ select @BudgetCode = @Uploadval
   	If @Column = 'Mth' and isdate(@Uploadval) = 1 select @Mth = Convert(smalldatetime, @Uploadval)
   	If @Column = 'BudgetAmt' and isnumeric(@Uploadval) = 1 select @BudgetAmt = @Uploadval
   
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
   
   	-- set Current Req Seq to next @Recseq unless we are processing last record.
   	if @Recseq = -1
   		select @complete = 1	-- exit the loop
   	else
   		select @currrecseq = @Recseq
   
     end
   end
   
   bspexit:
   
   	if @CursorOpen = 1
   	begin
   		close WorkEditCursor
   		deallocate WorkEditCursor	
   	end
   
       select @msg = isnull(@desc,'Clear') + char(13) + char(10) + '[mspIMViewpointDefaultsGLBD]'
   
       return @rcode



GO
