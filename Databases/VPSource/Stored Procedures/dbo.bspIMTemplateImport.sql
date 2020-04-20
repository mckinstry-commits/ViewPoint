SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspIMTemplateImport]
     /***********************************************************
      * CREATED BY: DANF 02/15/02
      * MODIFIED BY : RT 10/02/03 - Issue #22620, moved code to reset reccolumn for fixed-length 
      *							imports.  Added code to run through all record types for template.
      *				DANF 10/03/03 - #22620, changed to remove one cursor, simplify.
      *				RT 11/30/04 - #26334, Return BegPos and EndPos for fixed width record type indicator.
      *
      * USAGE:
      * validates template
      *
      * INPUT PARAMETERS
      *
      *   template
      *
      * OUTPUT PARAMETERS
      *    Default routine
      *    Form
      *    Error Message if error occurs
      * RETURN VALUE
      *   0 Success
      *   1 fail
      ************************************************************************/
     	(@template varchar(10), @btkroutine varchar(30) output, @form varchar(30) output, @filetype varchar(1) output,
             @delim varchar(1) output, @otherdelim varchar(2) output, @importroutine varchar(30) output, @rectypecol int output, 
     		@rectypebegpos int output, @rectypeendpos int output, @userroutine varchar(30) output, @msg varchar(60) output)
     
     as
     set nocount on
     declare @rcode int, @validcnt int, @ident int, @reccolumn int, @begpos int, @rectype varchar(30), @reccount int
     select @rcode = 0
     
     if @template is null
     
     	begin
     	select @msg = 'Missing Template!', @rcode = 1
     	goto bspexit
     	end
     
     select @validcnt=Count(*) from IMTH with (nolock)
     	where ImportTemplate=@template
     if @validcnt=0
       begin
         select @msg = 'Template not on file!', @rcode = 1
         goto bspexit
       end
     
     select @filetype = FileType, @delim = Delimiter, @otherdelim = OtherDelim, @rectypecol = RecordTypeCol,
     @msg=Description, @btkroutine = BidtekRoutine, @form = Form, @userroutine = UserRoutine, @importroutine = ImportRoutine, 
     @rectypebegpos = BegPos, @rectypeendpos = EndPos
     from IMTH with (nolock)
     where ImportTemplate = @template
     
     --RT 10/02/03 #22620 - moved from bsp IMImportIMWE....
     
     --mh 4/15/03...Check RecColumn.  Update if null.  This really only applies to Fixed Width imports
     --because RecColumn is invisible.  Issue 19626
     
     if (select FileType from bIMTH with (nolock) where ImportTemplate = @template) = 'F'
     begin
     	--loop through all record types for this template...
     	declare cRecTypes cursor local fast_forward for
     	select a.RecordType 
     	from IMTR a
     	where a.ImportTemplate = @template
     
     	open cRecTypes
     	fetch next from cRecTypes into @rectype
     
     	while @@fetch_status = 0
     	begin
     
     		-- Issue 22191 Reset Record Column to null and repopulate to account for any changes in template.
     		update bIMTD set RecColumn = null
     		where ImportTemplate = @template and RecordType = @rectype
     		
     		select @reccount = 0
     
     		update bIMTD set @reccount=@reccount+1, RecColumn = @reccount
     		where ImportTemplate = @template and 
     		RecordType = @rectype and BegPos is not null
     		  
     		fetch next from cRecTypes into @rectype
     	end
     	close cRecTypes 
     	deallocate cRecTypes
     end
     --end Issue 19626
     
     bspexit:
     	if @rcode<>0 select @msg=isnull(@msg,'Template Import') + char(13) + char(10) + '[bspIMTemplateImport]'
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMTemplateImport] TO [public]
GO
