SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMPurgeAutoClearFile    Script Date: 11/21/2001 1:59:36 PM ******/
   
   /****** Object:  Stored Procedure dbo.bspCMPurgeAutoClearFile    Script Date: 11/21/2001 11:21:46 AM ******/
   
   
   CREATE    procedure [dbo].[bspCMPurgeAutoClearFile]
   /************************************************************************
   * CREATED:	MH 8/21/01    
   * MODIFIED: MH 11/21/01  Added purge thru functionality   
   *
   * Purpose of Stored Procedure
   *
   *    Clear out entries in CMCE (CM Auto Clearing file)
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@co bCompany, @cmacct bCMAcct, @purgethru bDate, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @bankacct varchar(30), @trancount int
   
       select @rcode = 0
   
   	if @co is null 
   	begin
   		select @msg = 'Missing Company.', @rcode = 1
   		goto bspexit
   	end
   
   	if @cmacct is null
   	begin
   		select @msg = 'Missing CMAccount.', @rcode = 1
   		goto bspexit
   	end
   
   
   	select @bankacct = BankAcct from CMAC where CMCo = @co and CMAcct = @cmacct
   
   	begin  transaction
   
   	--If @purgethru is null then assume all should be deleted.
   	if @purgethru is not null
   		begin
   			select @trancount = count(*) from CMCE where CMCo = @co and BankAcct = @bankacct and UploadDate <= @purgethru
   			delete CMCE where CMCo = @co and BankAcct = @bankacct and UploadDate <= @purgethru
   		end
   	else
   		begin
   			select @trancount = count(*) from CMCE where CMCo = @co and BankAcct = @bankacct
   			delete CMCE where CMCo = @co and BankAcct = @bankacct
   		end
   
   	if @@error = 0 
   		begin
   			select @msg = convert(varchar(10), @trancount) + ' entries deleted from Auto Clearing file.'
   			commit transaction
   		end
   
   	else
   		begin
   			rollback transaction
   			select @msg = 'Error occured deleting from Auto Clearing file', @rcode = 1
   			goto bspexit
   		end
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMPurgeAutoClearFile] TO [public]
GO
