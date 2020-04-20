SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspIMTemplateDetail]
   /***********************************************************
    * CREATED BY:    GR 08/25/99
    * MODIFIED BY:   RT 11/24/03, change references to DDUD fields: 
    *						Required -> RequiredValue, BidtekDefault -> BidtekDefaultValue
    *
    * USAGE:
    * Loads template detail
    *
    * INPUT PARAMETERS
   
    *   Import Form
    *   Template
    *   Record Type
    * OUTPUT PARAMETERS
    *    Error Message if error occurs
    * RETURN VALUE
    *   0 Success
    *   1 fail
    ************************************************************************/
   	(@template varchar(10), @recordtype varchar(30), @form varchar(30), @msg varchar(60) output)
   
   as
   set nocount on
   declare @rcode int, @validcnt int, @opendetail int, @seq int, @columnname varchar(30), @reqyn bYN,
           @identifier int, @tablename varchar(30), @description bDesc
   
   select @rcode = 0
   select @opendetail = 0
   
   if @template is null
   
   	begin
   	select @msg = 'Missing Template!', @rcode = 1
   	goto bspexit
   	end
   
   if @recordtype is null
   
   	begin
   	select @msg = 'Missing Record Type!', @rcode = 1
   	goto bspexit
   	end
   
   if @form is null
   	begin
   	select @msg= 'Missing Form!', @rcode=1
   	goto bspexit
   	end
   
   
   --check to see whether IMTD has this Record Type info in the table
   select @validcnt=Count(*) from IMTD
   	where ImportTemplate=@template and RecordType=@recordtype
   
   -- now insert into IMTD
   if @validcnt=0
     begin
     	declare detail_cursor cursor for
    	select Identifier, Seq, RequiredValue, Description from DDUD where Form=@form
   
   	open detail_cursor
   	select @opendetail = 1
   
   	detail_cursor_loop:       --loop through all the records
   	fetch next from detail_cursor into @identifier, @seq, @reqyn, @description
   
   	if @@fetch_status=0
   		begin
   		insert IMTD (ImportTemplate, RecordType, Identifier, Seq, Required, ColDesc)
   		values (@template, @recordtype, @identifier, @seq, Case @reqyn WHEN 'Y' THEN -1 ELSE 0 END, @description)
   
   		goto detail_cursor_loop
   		end
     --close and deallocate cursor
   	if @opendetail=1
   		begin
   		close detail_cursor
   		deallocate detail_cursor
   		select @opendetail=0
   		end
     end
   
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'Template Detail') + char(13) + char(10) + '[bspIMTemplateDetail]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMTemplateDetail] TO [public]
GO
