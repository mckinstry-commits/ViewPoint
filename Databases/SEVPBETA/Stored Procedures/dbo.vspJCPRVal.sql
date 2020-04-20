SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE proc [dbo].[vspJCPRVal]
/***********************************************************
* CREATED BY:	CHS	04/03/2009
*
* USAGE:
* validates JCPR 
* 
* an error is returned if any of the following occurs
* no job passed, no job found in JCJM, no reviewer found,
* duplicate reviewer 
*
* INPUT PARAMETERS
*   JCCo		JC Co to validate against 
*	Mth			month
*	Source		source form
*	ResTrans	Transaction code
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of Job
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@jcco bCompany = null, @mth bMonth = null, @source bSource = null, 
	@restrans bTrans = null, @msg varchar(255) output)

   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @mth is null
   	begin
   	select @msg = 'Missing Month!', @rcode = 1
   	goto bspexit
   	end
   
   if @source is null
   	begin
   	select @msg = 'Missing Source!', @rcode = 1
   	goto bspexit
   	end
      
   if @restrans is null
   	begin
   	select @msg = 'Missing Transaction Code!', @rcode = 1
   	goto bspexit
   	end

   -- validate Transaction Code
   if not exists (select 1 from bJCPR where JCCo = @jcco and Mth = @mth and Source = @source and ResTrans = @restrans and InUseBatchId is Null)
       begin
       select @msg = 'Transaction code is Invalid ', @rcode = 1
       goto bspexit
   	end

   
bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCPRVal] TO [public]
GO
