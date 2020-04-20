SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROC [dbo].[bspIMCrossRefVal]
    /***********************************************************
     * CREATED BY: MH 8/24/99
     * modified:	mh 5/16/03 - added @rectype parameter
     *				RT 04/26/04 - #24408, removed comments about DDUX.
     *
     * USAGE:
     * Validates Cross Reference against IMXH
     *
     * INPUT PARAMETERS
     *   xrefname
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs, otherwise name of template
     * RETURN VALUE
     *   0         Success
     *   1         Failure
     *****************************************************/
   
    (@template varchar(30) = null, @xrefname varchar(30) = null, @rectype varchar(30), @pmcrossreference bYN output, @pmtemplate varchar(10) output, @msg varchar(60) output)
    
    as
    set nocount on
    begin
    
    declare @rcode integer
    
    select @rcode = 0
   
   
   if @template is null
       begin
           select @msg = 'Missing Import Template!', @rcode = 1
           goto bspexit
       end
   
   if @xrefname is null
       begin
           select @msg = 'Missing Cross Reference!', @rcode = 1
   	 	goto bspexit
       end
   
   if @rectype is null
   	begin
   		select @msg = 'Missing Record Type!', @rcode = 1
   		goto bspexit
   	end
   
   --Look up @xrefname in IMXH
   select @msg = XRefName, @pmcrossreference = PMCrossReference, @pmtemplate = PMTemplate 
   from IMXH 
   where ImportTemplate = @template and XRefName = @xrefname and RecordType = @rectype
   
    if @@rowcount = 1
       begin
       select @msg = @xrefname
       goto bspexit
       end
    else
       begin
       select @msg = 'Invalid Cross Reference'
       select @rcode = 1
       goto bspexit
       end
   
    bspexit:
    	if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[bspIMCrossRefVal]'
    	return @rcode
    END

GO
GRANT EXECUTE ON  [dbo].[bspIMCrossRefVal] TO [public]
GO
