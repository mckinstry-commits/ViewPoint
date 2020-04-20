SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMImportIDVal    Script Date: 3/29/2002 2:49:08 PM ******/
   CREATE   Procedure [dbo].[vspIMImportIDVal]
   /***********************************************************
    * CREATED BY: MH 04/24/00
    * MODIFIED BY: RBT 06/09/03 - Issue 21463, check IMWE for existing records, not just IMWH.
	*			   DANF 11/20/06 - Recode for 6.x
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
   	(@importid varchar(20) = null, @detailexists char(1) = null output, @msg varchar(60)=null output)
   as
   
   set nocount on
   
   
   declare @rcode int
   select @rcode = 0, @detailexists = 'N'
   
   if @importid is null
       begin
       select @msg = 'Missing ImportID!', @rcode = 1
       goto bspexit
       end
  
  
   --We were allowing a user to reuse an Import ID as long as it was with a different
   --template.  This is creating problems.  Do not allow this any longer.
   --if exists(select ImportId from IMWH where ImportId = @importid and ImportTemplate = @template)
   --Issue 21463 - Also check IMWE, for records that are orphaned when an import fails.
   if exists(select ImportId from IMWH with (nolock) where ImportId = @importid) or 
   		exists(select ImportId from IMWE with (nolock) where ImportId = @importid)
       begin
   	    select @msg = 'Existing ImportId', @detailexists = 'Y'
   	    goto bspexit
       end
   else
       select @msg = 'New ImportID'
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMImportIDVal] TO [public]
GO
