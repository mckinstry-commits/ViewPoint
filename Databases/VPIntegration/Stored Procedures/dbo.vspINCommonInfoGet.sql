SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[vspINCommonInfoGet]

  /*************************************
  * CREATED BY:  TRL 09/19/05
  * Modified By:
  *
  * Gets the IN  and HQ Company Info
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
  (@INCo bCompany = null, 
 @glco bCompany output, 
 @usageopt varchar(1) output, 
 @costover bYN output,
 @negwarn bYN output,
 @burdenyn bYN output,
 @valmethod tinyint output,
 @costmethod tinyint output,
 @TaxGroup tinyint = null output,
 @MatlGroup tinyint output,
 @PhaseGroup tinyint output,
 @glLastMthSubClosed bMonth output,
 @VendorGroup tinyint output,
 @msg varchar(100) output)
  as
  set nocount on
  
  declare @rcode int
  
  select @rcode = 0
  
  if @INCo is null
  	begin
	  	select @msg = 'Missing IN Company', @rcode = 1
  		goto vspexit
  	end
  else
	begin
		select top 1 1 
		from dbo.INCO with (nolock)
		where INCo = @INCo
		if @@rowcount = 0
			begin
				select @msg = 'Company# ' + convert(varchar,@INCo) + ' not setup in IN.', @rcode = 1
				goto vspexit
			end
	end

  --Get INCO information
  select @glco=INCO.GLCo, @usageopt=UsageOpt, @costover=CostOver, @negwarn=NegWarn,
  @burdenyn = BurdenCost, @valmethod = ValMethod, @costmethod= CostMethod, 
   @glLastMthSubClosed=GLCO.LastMthSubClsd
  from dbo.INCO with (nolock) 
  Left Join dbo.GLCO with(nolock) on GLCO.GLCo=INCO.GLCo
  where INCo = @INCo
  if @@rowcount = 0
      begin
	      select @msg='Not a valid IN Company:  ' + convert(varchar(3),IsNull(@INCo,0)), @rcode=1 
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

  --Get HQCO Information  
    select @TaxGroup = IsNull(TaxGroup,0),  @MatlGroup = IsNull(MatlGroup,0), @PhaseGroup=IsNull(PhaseGroup,0), @VendorGroup = IsNull(VendorGroup,0) 
 from dbo.HQCO with (nolock) where HQCo = @INCo
  if @@rowcount = 1
     select @rcode=0
  else
     select @msg = 'HQ company does not exist.', @rcode=1, @TaxGroup=0
    goto  vspexit
  
  if @TaxGroup is Null
     select @msg = 'Tax group not setup for company ' + isnull(convert(varchar(3),@INCo),'') , @rcode=1, @TaxGroup=0
      
  if @MatlGroup is Null 
     select @msg = 'Material group not setup for company ' + isnull(convert(varchar(3),@INCo),'') , @rcode=1, @MatlGroup=0
  
  if @MatlGroup is Null 
     select @msg = 'Phase group not setup for company ' + isnull(convert(varchar(3),@INCo),'') , @rcode=1, @PhaseGroup=0

  vspexit:
   --   if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[vspINCommonInfoGot]'
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINCommonInfoGet] TO [public]
GO
