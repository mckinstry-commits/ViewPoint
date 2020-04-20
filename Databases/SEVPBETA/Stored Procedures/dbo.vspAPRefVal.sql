SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspAPRefVal    Script Date: 8/28/99 9:33:10 AM ******/
   CREATE  proc [dbo].[vspAPRefVal]
   /***********************************************************
    * CREATED BY: DC  2/10/09
    * MODIFIED By : 
    *
    *
    *
    * USAGE:
    * validates APRef for SL Compliance
    * An error is returned if the APRef does not exists in APHB, APTH, APUI
    *
    * INPUT PARAMETERS
    *   Co		Co to validate against
    *   APRef	APRef to validate
    *
	*
	*
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of EarnCode
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@co bCompany = 0, @apref bAPReference = null, @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @co is null
   	begin
   	select @msg = 'Missing Company!', @rcode = 1
   	goto vspexit
   	end
   
   if @apref is null
   	begin
   	select @msg = 'Missing AP Reference!', @rcode = 1
   	goto vspexit
   	end
   
   if not exists (select 1 from APRefUnionforSL where APCo = @co and APRef = @apref)
   	begin
   	select @msg='Invalid AP Reference!', @rcode=1   	
   	goto vspexit
   	end 
      
   
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPRefVal] TO [public]
GO
