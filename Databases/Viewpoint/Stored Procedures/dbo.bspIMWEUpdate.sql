SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspIMWEUpdate]
   /*******************************************************************************
   * Created By:   GR 9/28/99
   * Modified By:
   *
   * This SP will updats work table IMWE. First checks whether cross reference
   * has set up or not.
   *
   * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
   *
   * Pass In
   *
   *   Template		Template for this record type
   *   RecordType		Record Type
   *   Identifier		Identifier
   *   Seq             Seq
   *   XRefName        XRefName
   *
   * RETURN PARAMS
   *   msg           Error Message, or Success message
   *
   * Returns
   *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
   *
   ********************************************************************************/
   
    (@template varchar(10), @recordtype varchar(30), @identifier int, @seq int, @xrefname varchar(30),
     @msg varchar(255) output)
   
    as
    set nocount on
   
    declare @rcode int, @validcnt int, @importval1 varchar(60), @importval2 varchar(60),
           @bidtekval varchar(60), @openimportval int, @identifier1 int, @openimportval2 int,
           @recordseq int
   
    select @rcode=0
    select @openimportval = 0
    select @openimportval2 = 0
   
    if @template is null
       begin
       select @msg='Missing Template!', @rcode=1
       goto bspexit
       end
   
    If @recordtype is null
       begin
       select @msg='Missing RecordType!', @rcode=1
       goto bspexit
       end
   
    if @identifier is null
       begin
       select @msg='Missing Identifier!', @rcode=1
       goto bspexit
       end
   
    if @seq is null
       begin
       select @msg='Missing Seq!', @rcode=1
       goto bspexit
       end
   
    if @xrefname is null
       begin
       select @msg='Missing XRefName!', @rcode=1
       goto bspexit
       end
   
   --check cross reference header, raise the error if not set up
    select @validcnt=Count(*) from IMXH
    where ImportTemplate=@template and XRefName=@xrefname
       if @validcnt = 0
           begin
           select @msg='Cross Reference Header not set up!', @rcode=1
           goto bspexit
           end
   
   --check cross reference detail, raise the error if not set up
    select @validcnt=Count(*) from IMXD
    where ImportTemplate=@template and XRefName=@xrefname
       if @validcnt = 0
           begin
           select @msg='Cross Reference Detail not set up!', @rcode=1
           goto bspexit
           end
   
    -- check whether the work table is loaded
    select @validcnt=Count(*) from IMWE where RecordType=@recordtype and ImportTemplate=@template
   
    if @validcnt = 0
       begin
           goto bspexit
       end
   
   --update work table
   declare importval_cursor cursor for
       select distinct(ImportedVal) from IMWE
       where ImportTemplate=@template and RecordType=@recordtype and Identifier=@identifier and Seq=@seq
   
       open importval_cursor
       select @openimportval = 1
   
       importval_cursor_loop:                 --loop through all the records
   
       fetch next from importval_cursor into @importval1
            if @@fetch_status = 0
               begin
               if @importval1 <> '' and @importval1 is not null         --ColPos specified in template detail for this identifier with XRefname
                   begin
                   --get bidtek value for this XRefName
                   select @validcnt=Count(*) from IMXD
                   where ImportTemplate=@template and XRefName=@xrefname
                   if @validcnt > 0
                       begin
                       select @bidtekval=BidtekValue from IMXD
                       where ImportTemplate=@template and XRefName=@xrefname and ImportValue=@importval1
   
                       if @@rowcount = 0    -- if no Xref exisits for this importedval
                         begin
                         select @bidtekval=''
                         end
   
                       --now update IMWE
                       update IMWE set UploadVal=@bidtekval
                       where ImportTemplate=@template and RecordType=@recordtype
                           and Identifier=@identifier and Seq=@seq and ImportedVal=@importval1
   
                       end
                   else
                       begin
                           select @msg='The import value in cross reference detail does not match with textfile', @rcode=1
                           goto bspexit
                   end
                   end
   
               else       --import value is null
   
                   begin
                   --first get identifier from cross reference header /// Needs corrected ///
                   --select @identifier1=ImportField1 from IMXH
                   --where ImportTemplate=@template and XRefName=@xrefname and RecordType=@recordtype
   
                   --get imported value for this identifier from IMWE
                   declare importval2_cursor cursor for
                   select ImportedVal, RecordSeq from IMWE
                   where ImportTemplate=@template and RecordType=@recordtype and Identifier=@identifier1
   
                   open importval2_cursor
                   select @openimportval2 = 1
   
                   importval2_cursor_loop:             --loop through all the records
   
                   fetch next from importval2_cursor into @importval2, @recordseq
   
                   if @@fetch_status=0
                       begin
                       select @bidtekval=BidtekValue from IMXD
                       where ImportTemplate=@template and XRefName=@xrefname and ImportValue=@importval2
   
                       --update first with import value
                       update IMWE set ImportedVal=@importval2
                       where ImportTemplate=@template and RecordType=@recordtype
                           and Identifier=@identifier and Seq=@seq and RecordSeq=@recordseq
                       --now update IMWE
                       update IMWE set UploadVal=@bidtekval
                       where ImportTemplate=@template and RecordType=@recordtype and RecordSeq=@recordseq
                       and Identifier=@identifier and Seq=@seq and ImportedVal=@importval2
   
                       goto importval2_cursor_loop   --get the next record
                       end
                   -- close and deallocate cursor
                       if @openimportval2 = 1
   	                   begin
   	                       close importval2_cursor
   	                       deallocate importval2_cursor
     	                       select @openimportval2 = 0
   	                   end
                   goto bspexit
                   end
            goto importval_cursor_loop           --get the next record
            end
   
   
    -- close and deallocate cursor
   	if @openimportval = 1
   	  begin
   	    close importval_cursor
   	    deallocate importval_cursor
     	    select @openimportval = 0
   	  end
   
   bspexit:
        -- close and deallocate cursor
   	if @openimportval = 1
   	  begin
   	    close importval_cursor
   	    deallocate importval_cursor
     	    select @openimportval = 0
   	  end
   
          if @openimportval2 = 1
   	       begin
   	           close importval2_cursor
   	           deallocate importval2_cursor
     	           select @openimportval2 = 0
   	       end
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMWEUpdate] TO [public]
GO
