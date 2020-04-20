SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspHQUDAddImport]
        /***********************************************************
        * CREATED BY	: danf 06/27/01
        * MODIFIED BY	: GG 10/29/01 - changed cursor type
    	* 	DANF 03/20/03 - Added Max identifier from DDUD before the Templates.
    	*	RT 12/01/03 - 23106, Removed references to DDUD 'Required' and 'BidtekDefault' fields.
        *	RBT 11/19/04 - #26220, Fix columns for IMTD, DDUD. 
   		*	RBT 02/02/05 - #26220 part deux, Do not add to IMTD/DDUD if column exists.
   		*	DANF 03/15/05 - #27294 - Remove scrollable cursor.
		*	JRK 11/07/06 - Use views instead of "b" tables for VP6.  So far the views still point at
		*		the "b" tables, but those may be migrated to "v" tables.  Then just update the views.
		*   DANF 12/6/07 - Issue 126353. Correction Import Form should not have returned form view name.
		*   AJW 09/17/12 - B-07373 Forms can be 30 characters
		*
        * Called from bspHQUDAdd
        *
        * USAGE: This bsp will add user memos to all import template for selected file.
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
            @nodatatype bYN, @sysdatatype varchar(30)= null,
            @columndatatype varchar(255) = null,
            @columndesc bDesc= null, @ddfiseq int, @msg varchar(30) output)
    
        as
    
        set nocount on
    
        declare @rcode int, @opencursorIMTR tinyint, @opencursorIMTRAdd tinyint,
        @Id int, @ImportForm varchar(30), @ImportTemplate varchar(10),
        @rcid int, @RecordType varchar(30)
    
        select @rcode = 0
    
        if @formname is null goto bspexit
    
        if @tablename is null goto bspexit
    
        if @columnname is null goto bspexit
    
    
    --  Find Id to Add to All Import Templates and DDUD.
      select @Id = 1000, @ImportForm = @formname
      --select @ImportForm = Form 
	  --from DDUF 
	  --where DestTable = substring(@tablename,2,4)
    
      select @rcid = isnull((select max(Identifier) from DDUD where Form = @ImportForm), 0)
      if @rcid >= @Id select @Id = @rcid + 5
    
      If @ImportForm is null goto bspexit
    
      declare bcIMTR cursor local fast_forward for
      select ImportTemplate, RecordType
      from IMTR where Form = @ImportForm
    
      /* open cursor */
      open bcIMTR
    
      /* set open cursor flag to true */
      select @opencursorIMTR = 1
    
      /* get first row */
      fetch next from bcIMTR into @ImportTemplate, @RecordType
      /* loop through all rows */
      while (@@fetch_status = 0)
       begin
    
        select @rcid = isnull((select max(Identifier) from IMTD where ImportTemplate = @ImportTemplate and RecordType = @RecordType), 0)
        if @rcid >= @Id select @Id = @rcid + 5
    
        GetNext:
        fetch next from bcIMTR into @ImportTemplate, @RecordType
       end
    
      /* Close Cursor*/
      if @opencursorIMTR=1
         begin
           close bcIMTR
           deallocate bcIMTR
           select @opencursorIMTR=0
         end
    --  Add Id  All Import Templates and DDUD.
   
   	--issue #26220
   	if not exists(select 1 from DDUD where Form = @ImportForm and TableName = substring(@tablename,2,30) and ColumnName = @columnname)
   	begin 
                
         insert DDUD (Form, Identifier, TableName, Seq, ColumnName,
                    Description, Datatype, ColType, BidtekDefaultValue, RequiredValue, UpdateKeyYN)
         values(@ImportForm, @Id, substring(@tablename,2,30), @ddfiseq, @columnname,
                @columndesc,  @sysdatatype, @columndatatype, 'N', 'N', 'N')
   	end
    
      declare bcIMTRAdd cursor local fast_forward for
      select ImportTemplate, RecordType
      from IMTR where Form = @ImportForm
    
      /* open cursor */
      open bcIMTRAdd
    
      /* set open cursor flag to true */
      select @opencursorIMTRAdd = 1
    
      /* get first row */
      fetch next from bcIMTRAdd into @ImportTemplate, @RecordType
      /* loop through all rows */
      while (@@fetch_status = 0)
       begin
   		-- All we have to go by is the coldesc because we've calculated a new identifier by now.
   		if not exists(select 1 from IMTD where ImportTemplate = @ImportTemplate and RecordType = @RecordType and ColDesc = @columndesc)
   		begin
   	     insert IMTD (ImportTemplate, RecordType, Seq, Identifier, DefaultValue, ColDesc, FormatInfo,
   	                 Required, XRefName, RecColumn, BegPos, EndPos, BidtekDefault, Datatype,
   	 				UpdateKeyYN, UpdateValueYN, ImportPromptYN)
   	      values(@ImportTemplate, @RecordType, @ddfiseq, @Id, Null, @columndesc, Null,
   	             0, Null, Null, Null, Null, Null, @sysdatatype, 'N', 'N', 'N')
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
    
        bspexit:
      /* reset the ending check to what we ended up using*/
      if @opencursorIMTR=1
         begin
           close bcIMTR
           deallocate bcIMTR
           select @opencursorIMTR=0
         end
      if @opencursorIMTRAdd=1
         begin
           close bcIMTRAdd
           deallocate bcIMTRAdd
           select @opencursorIMTRAdd=0
         end
        	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQUDAddImport] TO [public]
GO
