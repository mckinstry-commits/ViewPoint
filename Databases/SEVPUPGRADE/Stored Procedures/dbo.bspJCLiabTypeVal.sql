SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCLiabTypeVal    Script Date: 8/28/99 9:32:59 AM ******/
   /****** Object:  Stored Procedure dbo.bspJCLiabTypeVal    Script Date: 2/12/97 3:25:05 PM ******/
   CREATE   proc [dbo].[bspJCLiabTypeVal]
   
   	(@jcco bCompany = 0, @liabtemplate smallint = null, @liabtype bLiabilityType = null, @msg varchar(60) output)
   as
   set nocount on
   /***********************************************************
    * CREATED BY: JRE  8/12/96
    * MODIFIED By : TV - 23061 added isnulls
    *
    * USAGE:
    * validates JC liablility tamplate.
    * an error is returned if any of the following occurs
    * no liability template passed, no liablility template found.
    *
    * INPUT PARAMETERS
    *   JCCo   JC Co to validate against 
    *   LiabTemplate  Insurance template to validate
    *   LiabType  Type to validate
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Template description
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   
   	declare @rcode int
   	select @rcode = 0
   
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @liabtemplate is null
   	begin
   	select @msg = 'Missing Liability Template!', @rcode = 1
   	goto bspexit
   	end
   
   if @liabtype is null
   	begin
   	select @msg = 'Missing Liability Type!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = HQLT.Description
   	from HQLT
   	where LiabType=@liabtype
   if @@rowcount = 0
   	begin
   	select @msg = 'Liability type not on file!', @rcode = 1
   	goto bspexit
   	end
   
   if not exists (select * from JCTL
   where JCCo=@jcco and LiabTemplate=@liabtemplate and LiabType=@liabtype)
   	begin
   	select @msg = 'Liability type not on the template!', @rcode = 1
   	goto bspexit
   	end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCLiabTypeVal] TO [public]
GO
