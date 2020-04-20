SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQUDDeleteImport    Script Date: 8/28/99 9:32:34 AM ******/
       CREATE     proc [dbo].[bspHQUDDeleteImport]
       /***********************************************************
        * CREATED BY	: danf 06/27/01
        * MODIFIED BY	: DANF - RICK 02/13/03  Correct Table NAME on delete of DDUD
        *  DANF 03/15/05 - #27294 - Remove scrollable cursor.
	    *  JRK 01/03/07 - No changes.  Just a note that for VP6.0 we continue to use "DDUD" and "DDUF", not "v" tables.
		*  JRK 7/19/07 @formname is not used so dropped from arg list.
		*  AJW 9/17/12 - B-07373 RecordType = 30 characters
        *
        * Only called from vspHQUDDelete.
        *
        * USAGE: This bsp will added user memos to all import template for selected file.
        *
        * INPUT PARAMETERS
        *
        * OUTPUT PARAMETERS
        *   @msg      error message if error occurs
        * RETURN VALUE
        *   0         success
        *   1         Failure
        *****************************************************/
   
           (@tablename varchar(30),
           @viewname varchar(30), @columnname varchar(30),
           @msg varchar(30) output)
   
       as
   
       set nocount on
   
       declare @rcode int, @opencursorIMTR tinyint, @opencursorIMTRDelete tinyint,
       @Id int, @ImportForm varchar(30), @ImportTemplate varchar(10),
       @rcid int, @RecordType varchar(30)
   
       select @rcode = 0
   
       --if @formname is null goto bspexit -- @formname was not used.
   
       if @tablename is null goto bspexit
   
       if @columnname is null goto bspexit
   
   
   --  Find Form to Delete to All Import Templates and DDUD.
     select @ImportForm = null
     select @ImportForm = Form from DDUF where DestTable = substring(@tablename,2,30)
   
     If @ImportForm is null goto bspexit
   
       select @Id = Identifier from DDUD
       where Form = @ImportForm and TableName = substring(@tablename,2,30) and ColumnName = @columnname
   
   --  Delete Column from  All Import Templates and DDUD.
   
     declare bcIMTRDelete cursor local fast_forward for
     select ImportTemplate, RecordType
     from bIMTR where Form = @ImportForm
   
     /* open cursor */
     open bcIMTRDelete
   
     /* set open cursor flag to true */
     select @opencursorIMTRDelete = 1
   
     /* get first row */
     fetch next from bcIMTRDelete into @ImportTemplate, @RecordType
     /* loop through all rows */
     while (@@fetch_status = 0)
      begin
   
		--print '@ImportTemplate=' + @ImportTemplate + ', @RecordType=' + @RecordType + ', @id=' + @Id

       delete bIMTD
       where ImportTemplate = @ImportTemplate and RecordType = @RecordType and Identifier = @Id
   
   
       GetNextAdd:
       fetch next from bcIMTRDelete into @ImportTemplate, @RecordType
      end
   
     /* Close Cursor*/
     if @opencursorIMTRDelete=1
        begin
          close bcIMTRDelete
          deallocate bcIMTRDelete
          select @opencursorIMTRDelete=0
        end
   
       delete DDUD
       where Form = @ImportForm and TableName = substring(@tablename,2,30) and ColumnName = @columnname
   
   --
       bspexit:
     /* reset the ending check to what we ended up using*/
     if @opencursorIMTR=1
        begin
          close bcIMTR
          deallocate bcIMTR
          select @opencursorIMTR=0
        end
     if @opencursorIMTRDelete=1
        begin
          close bcIMTRDelete
          deallocate bcIMTRDelete
          select @opencursorIMTRDelete=0
        end
       	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQUDDeleteImport] TO [public]
GO
