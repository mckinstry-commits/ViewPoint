SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCJMJobVal    Script Date: 5/29/2003 11:18:55 AM ******/
    
    
    /****** Object:  Stored Procedure dbo.bspJCJMJobVal  */  
    CREATE         procedure [dbo].[bspJCJMJobVal]
    /************************************************************
     * CREATED:     DC 05/29/03  Issue #18385
     * MODIFIED:    TV - 23061 added isnulls
     *					DC 06/21/04 - Issue 24893
     *
     * USAGE:
     * Check the Job Cost History table to see if the Job number has been used.
     *
     * CALLED FROM:
     *	JCJM , JCCM, PMProjects 
     *
     * INPUT PARAMETERS
     *   @jcco      JCCo
     *   @job	Job ID
     *   @callfrom	J for JCJM / C for JCCM / P for PMProjects
     *
     * OUTPUT PARAMETERS
     *   @errmsg     if something went wrong
     * RETURN VALUE
     *   0   success
     *   1   fail
     ************************************************************/
    	@jcco bCompany, @job bJob, @callfrom varchar(1), @errmsg varchar(255) output
    
    as
    set nocount on
    
    declare @rcode int,
    	@contract bContract
    
    select @rcode = 0
    
    /* verify Tax Year Ending Month */
    IF @job is null
    	BEGIN
    	select @errmsg = 'Job ID cannot be null.', @rcode = 1
    	goto bspexit
    	END
    IF @callfrom = 'C' 
    BEGIN
   	IF not exists(select 1 from bJCCM where Contract = @job and JCCo = @jcco)
   	BEGIN
   	 	IF exists(select 1 from bJCHC where Contract = @job and JCCo = @jcco)
    		BEGIN
   	 	select @errmsg = @job + ' was previously used.  Cannot use ' + isnull(@job,'')  + char(13) + 'until the contract is purged from Contract/Job' + char(13) + 'History- use JC Contract Purge form to purge contract.', @rcode = 1
    		goto bspexit
   		END
   	END
    END
    If @callfrom = 'J'
    BEGIN
   	IF not exists(select 1 from bJCJM where Job = @job and JCCo = @jcco)
    	BEGIN
   		IF exists(select 1 from bJCHJ where Job = @job and JCCo = @jcco)
    		BEGIN
   	 	select top 1 @contract = Contract from bJCHJ where Job = @job and JCCo = @jcco
    		select @errmsg = @job + ' was previously used with contract ' + isnull(@contract,'') + 
   							'.  Cannot' + char(13) + 'use ' + isnull(@job,'') + 
   							' until the contract is purged from Contract/Job' + char(13) + 
   							'History- use JC Contract Purge form to purge contract.', @rcode = 1
   	 	goto bspexit	
   		END
    	END
    END
    If @callfrom = 'P'
    BEGIN
   	IF not exists(select 1 from bJCJM where Job = @job and JCCo = @jcco)
    	BEGIN
    		IF exists(select 1 from bJCHJ where Job = @job and JCCo = @jcco)
   	 	BEGIN
    		select top 1 @contract = Contract from bJCHJ where Job = @job and JCCo = @jcco
   	 	select @errmsg = @job + ' was previously used with contract ' + isnull(@contract,'') + 
   							'.  Cannot' + char(13) + 'use ' + isnull(@job,'') + 
   							' until the contract is purged from Contract/Job' + char(13) + 
   							'History- use JC Contract Purge form to purge contract.', @rcode = 1
    		goto bspexit
   	 	END
   	END
    END
    
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCJMJobVal] TO [public]
GO
