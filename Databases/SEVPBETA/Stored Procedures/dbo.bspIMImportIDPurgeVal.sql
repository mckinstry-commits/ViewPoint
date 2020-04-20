SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMImportIDPurgeVal]
    /************************************************************************
    * CREATED:	 MH 11/1/01   
    * MODIFIED: RT 10/08/03 - Issue #22592, check IMWE for purge, not IMWH.   
    *
    * Purpose of Stored Procedure
    *
    *   Validate ImportId for entered in IMPurge.  Kind of the reverse
    *	of the validation in IMImport.
    *    
    *           
    * Notes about Stored Procedure
    * 
    *
    * returns 0 if successfull 
    * returns 1 and error msg if failed
    *
    *************************************************************************/
    
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
    
    
    if exists(select distinct ImportId from IMWE where ImportId = @importid and ImportTemplate = @template)
        begin
        select @msg = (select distinct ImportId from IMWE where ImportId = @importid and ImportTemplate = @template)
        goto bspexit
        end
    else
        select @msg = 'Invalid Import Id.', @rcode = 1
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMImportIDPurgeVal] TO [public]
GO
