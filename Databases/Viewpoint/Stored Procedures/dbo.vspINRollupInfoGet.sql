SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[vspINRollupInfoGet]

  /*************************************
  * CREATED BY:  TRL 08/29/06
  * Modified By:
  *
  * Used INRollup Load Proc
  * Gets the IN  and HQ Company Info and Oldest IN Month with transactions
  *
  * Pass:
  *   INCo - Inventory Company
  *  
  *
  * Success returns:
  *
  *
  * Error returns:
  *	1 and error message
  **************************************/
  (@inco bCompany = null, 
 @glco bCompany output, 
 @glLastMthSubClosed bMonth output,
 @oldestmth smalldatetime output,
 @msg varchar(100) output)
  as
  set nocount on
  
  declare @rcode int
  
  select @rcode = 0
  
    
	if @inco is null
  		begin
	  		select @msg = 'Missing IN Company', @rcode = 1
  			goto vspexit
  		end
	else
		begin
			select top 1 1 
			from dbo.INCO with (nolock)
			where INCo = @inco
			if @@rowcount = 0
			begin
				select @msg = 'Company# ' + convert(varchar,@inco) + ' not setup in IN.', @rcode = 1
				goto vspexit
			end
		end    


  --Get INCO information
  select @glco=dbo.INCO.GLCo, @glLastMthSubClosed=GLCO.LastMthSubClsd
  from dbo.INCO with (nolock) 
  Left Join dbo.GLCO with(nolock) on GLCO.GLCo=INCO.GLCo
  where INCo = @inco
  if @@rowcount = 0
      begin
		select @msg='Not a valid IN Company:  ' + convert(varchar(3),IsNull(@inco,0)), @rcode=1 
		goto vspexit
      end

	Select @oldestmth= min(Mth)
	from dbo.INDT with (nolock) where
	Source <> 'IN Rollup' and INCo = @inco
	If @@rowcount = 0
		begin
			select @msg = 'No transactions to roll up.',@rcode=1
			goto vspexit
		end

 if @glco is Null
	begin
	  	select @msg = 'Missing GL Company', @rcode = 1
  		goto vspexit
  	end
  else
	begin
		select top 1 1 
		from dbo.GLCO with (nolock)
		where GLCo = @glco
		if @@rowcount = 0
			begin
				select @msg = 'Company# ' + convert(varchar,@glco) + ' not setup in GL.', @rcode = 1
				goto vspexit
			end
	end
  vspexit:
      --if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[vspINRollupInfoGet]'
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINRollupInfoGet] TO [public]
GO
