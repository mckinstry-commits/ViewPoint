SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMImportIDVal    Script Date: 3/29/2002 2:49:08 PM ******/
   CREATE   Procedure [dbo].[bspIMImportIDVal]
   /***********************************************************
    * CREATED BY: MH 04/24/00
    * MODIFIED BY: RBT 06/09/03 - Issue 21463, check IMWE for existing records, not just IMWH.
    *
    * USAGE:
    * validates ImportID for a given template
    *
    * INPUT PARAMETERS
    *   ImportID
   
    * OUTPUT PARAMETERS
    *   @msg If Error, error message, otherwise description of ImportID
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   	(@importid varchar(20) = null, @template varchar(10) = null, @msg varchar(60)=null output)
   as
   
   set nocount on
   
   
   declare @rcode int
   select @rcode = 0
   
   if @importid is null
       begin
       select @msg = 'Missing ImportID!', @rcode = 1
       goto bspexit
       end
   
   if @template is null
       begin
       select @msg = 'Missing Import Template!', @rcode = 1
       goto bspexit
       end
   
   --We were allowing a user to reuse an Import ID as long as it was with a different
   --template.  This is creating problems.  Do not allow this any longer.
   --if exists(select ImportId from IMWH where ImportId = @importid and ImportTemplate = @template)
   --Issue 21463 - Also check IMWE, for records that are orphaned when an import fails.
   if exists(select ImportId from IMWH where ImportId = @importid) or 
   		exists(select ImportId from IMWE where ImportId = @importid)
       begin
   	    select @msg = 'Existing ImportId', @rcode = 1
   	    goto bspexit
       end
   else
       select @msg = 'New ImportID'
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMImportIDVal] TO [public]
GO
