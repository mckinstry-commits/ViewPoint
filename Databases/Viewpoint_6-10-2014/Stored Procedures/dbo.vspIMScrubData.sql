SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMScrubData]
   /************************************************************************
   * CREATED:   RT 03/14/2006
   * MODIFIED:    CC 03/17/2008 - Issue 122980 Add note handling
   *
   * Purpose of Stored Procedure
   *
   *    Copy import data to upload data for fields where upload is still null.
   *    
   *           
   * Notes about Stored Procedure
   * returns 0 for success
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@importid varchar(20), @msg varchar(60) output)
   
   as
   set nocount on
   
    declare @rcode int
    select @rcode = 1
   
	update IMWE set UploadVal = ImportedVal
	where ImportId = @importid and UploadVal is null

	update IMWENotes set UploadVal = ImportedVal
	where ImportId = @importid and UploadVal is null

	select @rcode = 0

   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMScrubData] TO [public]
GO
