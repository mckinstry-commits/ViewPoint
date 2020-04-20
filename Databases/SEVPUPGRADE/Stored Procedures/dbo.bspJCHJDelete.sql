SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCHJDelete    Script Date: 6/11/2003 9:20:30 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspJCHJDelete    Script Date: 5/28/2003 7:53:41 AM ******/
   CREATE    proc [dbo].[bspJCHJDelete]
   /***********************************************************
      * CREATED BY:	DC 5/28/03  #18384
      * MODIFIED By :	TV - 23061 added isnulls 
      *
      * USAGE:
      * Purges Job History from bJCHJ and bJCHC
      * 
      *
      * 
      * INPUT PARAMETERS
      *   JCCo	
      *   Job Number or Contract Number
      *   
      * OUTPUT PARAMETERS
      *   @msg      error message if error occurs 
      *
      * RETURN VALUE
      *   0         success
      *   1         Failure
      *****************************************************/
   
      (@Company bCompany = 0, @Job bJob = null, @msg varchar(60) output)
   
     as
   
     set nocount on
     declare @rcode int
   
     select @rcode = 0
   
     -- Some initial validation
   
   	if @Company is null
     	begin
     	  select @msg = 'Missing JC Company!', @rcode = 1
     	  goto bspexit
     	end
   
   	if @Job is null
     	begin
     	  select @msg = 'Missing Job Number!', @rcode = 1
     	  goto bspexit
     	end
   
   	if exists(select 1 from bJCHJ where Contract = @Job and JCCo = @Company)
   	  	begin
   		Delete bJCHJ
   		where Contract = @Job and JCCo = @Company
   		Delete bJCHC
   		where Contract = @Job and JCCo = @Company
     		goto bspexit
   		end
   	IF exists(select 1 from bJCHJ where Job = @Job and JCCo = @Company)
   	  	begin
   		Delete bJCHC
   		from bJCHJ j join bJCHC c on c.Contract = j.Contract
   		where j.Job = @Job
   		Delete bJCHJ
   		where Job = @Job and JCCo = @Company
   	  	goto bspexit
     		end
   	IF exists(select 1 from bJCHC where Contract = @Job and JCCo = @Company)
   		BEGIN
   		Delete bJCHC
   		Where Contract = @Job and JCCo = @Company
   		goto bspexit
   		END
   
   	select @msg = 'Contract / Job Number not found!', @rcode = 1
   	goto bspexit
   	
   
     RETURN @rcode
   
   bspexit:
     return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCHJDelete] TO [public]
GO
