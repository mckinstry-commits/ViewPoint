SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMClearIMWEImportId]
   /************************************************************************
   * CREATED:  mh (I don't remember when)   
   * MODIFIED: mh 11/11/02 - in a previous issue stopped allowing the usage of 
   * 							an ImportID across multiple Templates.  This created
   *							problems so we no longer allow an ImportID to be 
   *							reused until previous instances have been deleted.    
   *			RBT 05/20/03 - Issue #21321, delete records from IMBC and IMWM.
   *			CC 03/14/08	 - Issue #122980, delete records from IMWENotes
   *			
   * Purpose of Stored Procedure
   *
   *  Delete an import id from IMWE, IMWH, IMBC, IMWM.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successful
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@importid varchar(20) = null, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
       if @importid is null
           begin
               select @msg = 'Missing ImportId', @rcode = 1
               goto bspexit    
           end
   
       --delete IMWE where ImportId = @importid and ImportTemplate = @template
   	delete IMWE where ImportId = @importid   
	DELETE FROM IMWENotes WHERE ImportId = @importid 

       --delete IMWH where ImportId = @importid and ImportTemplate = @template
   	delete IMWH where ImportId = @importid
   
   	--Issue #21321
   	delete IMBC where ImportId = @importid
   	delete IMWM where ImportId = @importid
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMClearIMWEImportId] TO [public]
GO
