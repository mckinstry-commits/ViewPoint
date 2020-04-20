SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMTemplatePurge]
   /************************************************************************
   * CREATED:	MH 10/31/01    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Purge Import Template    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@template varchar(10), @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @importid varchar(20)
   
       select @rcode = 0
   
   	if @template is null
   	begin
   		select @msg = 'Missing Import Template.', @rcode = 1
   		goto bspexit
   	end
   
   --delete work edit file.
   
   	begin transaction
   
   		delete IMWE where ImportTemplate = @template
   
   		if @@error <> 0
   		begin
   			select @msg = 'Unable to delete IM Work Edit.', @rcode = 1
   			rollback transaction
   			goto bspexit
   		end 
   
   	commit transaction
   
   	declare IMWE_curs cursor 
   	scroll
   	for 
   	select Distinct ImportId from IMWE where ImportTemplate = @template 
   
   	open IMWE_curs
   
   	fetch first from IMWE_curs into @importid
   
   	while @@fetch_status = 0
   	begin
   	
   		begin transaction
   		
   		delete IMBC where ImportId = @importid
   
   		if @@error <> 0 
   		begin 
   			select @msg = 'Unable to delete BatchControl info for ' + @importid, @rcode = 1
   			goto bspexit
   			rollback transaction
   		end
   		else
   			commit transaction
   
   		fetch next from IMWE_curs into @importid
   
   	end
   			
   --Reusing cursor for IMPR
   
   	fetch first from IMWE_curs into @importid
   
   	while @@fetch_status = 0
   	begin
   
   		begin transaction
   		
   		delete IMPR where ImportId = @importid
   
   		if @@error <> 0
   		begin
   			select @msg = 'Unable to delete IM PRGroup information.', @rcode = 1
   			rollback transaction
   			goto bspexit
   		end
   		else		
   			commit transaction
   
   		fetch next from IMWE_curs into @importid
   
   	end
   
   	close IMWE_curs
   	deallocate IMWE_curs
   
   	begin transaction
   		
   		delete IMWM where ImportTemplate = @template
   
   		if @@error <> 0
   		begin
   			select @msg = 'Unable to delete IMWM.', @rcode = 1
   			rollback transaction
   			goto bspexit
   		end
   
   		delete IMWH where ImportTemplate = @template
   
   		if @@error <> 0
   		begin
   			select @msg = 'Unable to delete IMWH.', @rcode = 1
   			rollback transaction
   			goto bspexit
   		end
   
   	commit transaction
   
   --delete the cross references
   	begin transaction
   
   		--First have to get rid of entries in IMTD
   		update IMTD set XRefName = null where ImportTemplate = @template
   
   		delete IMXF where ImportTemplate = @template
   
   		if @@error <> 0
   		begin
   			select @msg = 'Unable to delete IM Cross Reference Fields.', @rcode = 1
   			rollback transaction
   			goto bspexit
   		end
   
   		delete IMXD where ImportTemplate = @template
   
   		if @@error <> 0
   		begin
   			select @msg = 'Unable to delete IM Cross Reference Detail.', @rcode = 1
   			rollback transaction
   			goto bspexit
   		end
   
   		delete IMXH where ImportTemplate = @template
   
   		if @@error <> 0
   		begin
   			select @msg = 'Unable to delete IM Cross Reference Header.', @rcode = 1
   			rollback transaction
   			goto bspexit
   		end
   
   		--We have made it this far so IM Cross reference purge was successful.
   		--Commit what we have so far and start a new transacton.
   	commit transaction
   
   	begin transaction
   
   		delete IMTD where ImportTemplate = @template
   
   		if @@error <> 0
   		begin
   			select @msg = 'Unable to delete IM Template Detail.', @rcode = 1
   			rollback transaction
   			goto bspexit
   		end
   		
   		delete IMTR where ImportTemplate = @template
   
   		if @@error <> 0
   		begin
   			select @msg = 'Unable to delete IM Template Record Type.', @rcode = 1
   			rollback transaction
   			goto bspexit
   		end
   
   		delete IMTA where ImportTemplate = @template 
   
   		if @@error <> 0
   		begin
   			select @msg = 'Unable to delete IM Template Add Ons.', @rcode = 1
   			rollback transaction
   			goto bspexit
   		end
   
   		delete IMTH where ImportTemplate = @template
   
   
   		if @@error <> 0
   		begin
   			select @msg = 'Unable to delete IM Template Header.', @rcode =  1
   			rollback transaction	
   			goto bspexit
   		end
   
   	commit transaction
   		
   bspexit:
   
   	if @rcode = 1
   		select @msg = 'Unable to purge Import Template ' + @template + char(13) + @msg
   	
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMTemplatePurge] TO [public]
GO
