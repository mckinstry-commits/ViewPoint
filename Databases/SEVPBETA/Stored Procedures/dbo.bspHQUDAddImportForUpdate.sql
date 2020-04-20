SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[bspHQUDAddImportForUpdate]
        /***********************************************************
         * CREATED BY	: danf 06/27/01
         * MODIFIED BY	: danf 06/13/02 - Added @DefaultValue setting for template
         *				  RBT 11/19/04 - #26220, Fix columns for IMTD, DDUD.
   		 *       			DANF 03/15/05 - #27294 - Remove scrollable cursor.
		 *					GP 03/13/09 - 132371, @ImportForm was checking DestTable=@tablename not @viewname.
   		 *
         * Called from bspHQUDAddForUpdate
         *
         * USAGE: This bsp will added user memos during an Update process.
         *
         * INPUT PARAMETERS
         *
         * OUTPUT PARAMETERS
         *   @msg      error message if error occurs
         * RETURN VALUE
         *   0         success
         *   1         Failure
         *****************************************************/
    
           (@formname varchar(30), @tablename varchar(30),
           @viewname varchar(30), @columnname varchar(30),
           @sysdatatype varchar(30)= null,
           @columndesc bDesc= null, @Id int, 
   		@DefaultValue varchar(20) = null, 
   		@UserDefault varchar(20) = null, @OverrideYN bYN = 'N',
   		@msg varchar(30) output)
    
        as
    
        set nocount on
    
        declare @rcode int, @opencursorIMTR tinyint, @opencursorIMTRAdd tinyint,
        @ImportForm varchar(30), @ImportTemplate varchar(10),
        @rcid int, @RecordType varchar(10)
    
        select @rcode = 0
 
        if @formname is null goto bspexit
    
        if @tablename is null goto bspexit
    
        if @columnname is null goto bspexit
   
    
    --  Find Id to Add to All Import Templates and DDUD.
      select @ImportForm = null
      select @ImportForm = Form from DDUF where DestTable = @viewname and Form = @formname
  
      If @ImportForm is null goto bspexit
  
    --  Add Id  All Import Templates and DDUD.
    
    --     insert DDUD (Form, Identifier, TableName, Seq, ColumnName, Required, BidtekDefault,
    --                  Description, Datatype, ColType, BidtekDefaultValue, RequiredValue)
    --     values(@ImportForm, @Id, substring(@tablename,2,4), 0, @columnname, 0, 0,
    --            @columndesc,  @sysdatatype, @columndatatype, 'N', 'N')
    
      declare bcIMTRAdd cursor local fast_forward for
      select ImportTemplate, RecordType
      from bIMTR where Form = @ImportForm
  
      /* open cursor */
      open bcIMTRAdd
  
      /* set open cursor flag to true */
      select @opencursorIMTRAdd = 1
    
      /* get first row */
      fetch next from bcIMTRAdd into @ImportTemplate, @RecordType
      /* loop through all rows */
      while (@@fetch_status = 0)
       begin
  
   	 if not exists(select Seq from bIMTD where @ImportTemplate = ImportTemplate and @RecordType = RecordType and @Id = Identifier)
   		begin
   	     insert bIMTD (ImportTemplate, RecordType, Seq, Identifier, DefaultValue, ColDesc, FormatInfo,
   	                Required, XRefName, RecColumn, BegPos, EndPos, BidtekDefault, Datatype, UserDefault, OverrideYN,
   					UpdateKeyYN, UpdateValueYN, ImportPromptYN)
   	      values(@ImportTemplate, @RecordType, 0, @Id, @DefaultValue, @columndesc, Null,
   	             -1, Null, Null, Null, Null, Null, @sysdatatype, @UserDefault, @OverrideYN, 'N', 'N', 'N')
   	 	end
    
        GetNextAdd:
        fetch next from bcIMTRAdd into @ImportTemplate, @RecordType
       end
    
      /* Close Cursor*/
      if @opencursorIMTRAdd=1
         begin
           close bcIMTRAdd
           deallocate bcIMTRAdd
           select @opencursorIMTRAdd=0
         end
    
    
    
    --
        bspexit:
      /* reset the ending check to what we ended up using*/
      if @opencursorIMTRAdd=1
         begin
           close bcIMTRAdd
           deallocate bcIMTRAdd
           select @opencursorIMTRAdd=0
         end
        	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspHQUDAddImportForUpdate] TO [public]
GO
