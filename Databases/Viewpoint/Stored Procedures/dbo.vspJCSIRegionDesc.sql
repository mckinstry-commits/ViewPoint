SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspJCSIRegionDesc]
  /***********************************************************
   * CREATED BY: DANF 04/27/2005 
   * MODIFIED By : 
   *				
   * USAGE:
   * Used in JC SI Region Codes to return a description to the key field.
   *
   * INPUT PARAMETERS
   *   SI Region		
   *   SI Code
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of SI Region Code if found.
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@siregion varchar(6) = null, @sicode varchar(16) = null, @msg varchar(60) output)
  as
  set nocount on
  
  	declare @rcode int
  	select @rcode = 0, @msg=''

 	if isnull(@siregion,'')<>'' and  isnull(@sicode,'')<>''
		begin
			select @msg = Description 
			from dbo.JCSI
			where SIRegion = @siregion and SICode = @sicode
		end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCSIRegionDesc] TO [public]
GO
