SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMImportIDPurge]
   /************************************************************************
   * CREATED:	MH 10/31/01    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Delete all ImportIds for a specified Template.    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@importid varchar(20), @template varchar(10), @msg varchar(100) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   
   	if @importid is null
   	begin
   		select @msg = 'Missing ImportId', @rcode = 1
   		goto bspexit
   	end
   
   	if @template is null
   	begin
   		select @msg = 'Missing ImportTemplate', @rcode = 1
   		goto bspexit
   	end
   
   	begin transaction
   
   	delete IMBC where ImportId = @importid 
   
   	if @@error <> 0
   	begin
   		select @msg = 'Unable to delete entries from IM BatchID', @rcode = 1
   		rollback transaction
   		goto bspexit
   	end
   
   	delete IMPR where ImportId = @importid
   
   	if @@error <> 0
   	begin
   		select @msg = 'Unable to delete entries from IM PRGroup', @rcode = 1
   		rollback transaction
   		goto bspexit
   	end
   
   	delete IMWM where ImportId = @importid and ImportTemplate = @template
   
   	if @@error <> 0
   	begin
   		select @msg = 'Unable to delete entries from IMWM', @rcode = 1 --is there a form for this????
   		rollback transaction
   		goto bspexit
   	end
   
   	commit transaction
   
   	--imwe can get quite large, commiting transactions. 
   
   	begin transaction
   
   	delete IMWE where ImportId = @importid and ImportTemplate = @template
   
   	if @@error <> 0
   	begin
   		select @msg = 'Unable to delete IM Work Edit.  IM Work Edit and IM Work Header have not been purged.'
   		select @rcode = 1
   		rollback transaction
   		goto bspexit
   	end
   
   	delete IMWH where ImportId = @importid and ImportTemplate = @template
   
   	if @@error <> 0
   	begin
   		select @msg = 'Unable to delete IM Work Header.  IM Work Edit and IM Work Header have not been purged.'				
   		select @rcode = 1	
   		rollback transaction
   		goto bspexit
   	end
   
   	commit transaction
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMImportIDPurge] TO [public]
GO
