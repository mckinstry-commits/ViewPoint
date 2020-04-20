SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspINPhyCntLoad]
     /*************************************
     * CREATED BY: ??
     * Modified By:  TRL 09/28/06
     *             
     *
     * validates IN Locations and returns First IN Location or First INLocation in PhyCnt worksheet
     *
     * Pass:
     *   INCo - Inventory Company
     *   Loc - Location to be Validated
     *
     *
     * Success returns:
     *   Description of Location
     *
     * Error returns:
     *	1 and error message
     **************************************/
     	(@INCo bCompany = null, @Loc bLoc = null output, @override varchar(1)=null output, @matlgroup int = 0 output, @msg varchar(100) output)
     as
     	set nocount on
     	declare @rcode int, @phycntloc varchar(10)
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

	select @override = IsNull(INCO.CostOver,'N') ,@matlgroup = HQCO.MatlGroup
	From dbo.INCO with(nolock)
	Inner Join dbo.HQCO with(nolock)on HQCO.HQCo=INCO.INCo
	Where INCO.INCo=@INCo
	
     select top 1 @Loc=Loc, @msg = Description 
     from dbo.INLM with(nolock)
	 where INCo = @INCo and Loc = @Loc
    
	 select top 1 @Loc=IsNull(INCW.Loc,@Loc), @msg = INLM.Description 
     from dbo.INCW with(nolock)
	 Inner Join dbo.INLM with(nolock)on INLM.INCo = INCW.INCo and INLM.Loc=INCW.Loc
	 where INCW.INCo = @INCo  and INCW.UserName=suser_sname()
    
     if  @Loc is null
         begin
         select @msg='No IN Locations to select.', @rcode=1
         goto vspexit
         end

     vspexit:
         --if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[vspINPhyCntLoad]'
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINPhyCntLoad] TO [public]
GO
