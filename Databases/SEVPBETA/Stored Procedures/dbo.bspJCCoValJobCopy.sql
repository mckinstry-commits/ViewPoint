SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspJCCoValJobCopy]
    /*************************************
    *	created by:  TV 05/29/01
    *  modified by: GF 07/17/2001 - Need destination customer group for customer lookup.
    *				TV - 23061 added isnulls
    * validates JC Company number and returns Description from HQCo
    *
    * Pass:
    *	JC Company number
    *
    * Success returns:
    *	0 and Company name from bJCCO
    *
    * Error returns:
    *	1 and error message
    **************************************/
    	(@jcco bCompany = 0, @taxgroup bGroup output,
    	@phasegroup bGroup output, @arco bCompany output, @custgroup bGroup output, @msg varchar(60) output)
    as
    set nocount on
    	declare @rcode int
    	select @rcode = 0
   
    if @jcco = 0
    	begin
    	select @msg = 'Missing  Company#', @rcode = 1
    	goto bspexit
    	end
   
   -- get ARCo from JCCO
    select @arco = (Select ARCo from bJCCO where JCCo = @jcco)
   	if @@rowcount = 0
   	begin
   	select @msg = 'ARCO is not set up in JCCO', @rcode = 1
   	goto bspexit
   	end
   
    if exists(select * from bHQCO where @jcco = HQCo)
    	begin
    	select @msg = Name from bHQCO where HQCo = @jcco
    	--Return Phase and Tax Group for new Company
    	select @taxgroup=TaxGroup, @phasegroup = PhaseGroup
    	from bHQCO where HQCo=@jcco
    	if @@rowcount <> 1
        		begin
        		select @msg='Invalid HQ Company ' + isnull(convert(varchar(3),@jcco),'') + '!', @rcode=1
        		goto bspexit
        		end
       -- return customer group for Destination AR company
    	select @custgroup=CustGroup
    	from bHQCO where HQCo=@arco
    	if @@rowcount <> 1
        		begin
        		select @msg='Invalid HQ Company ' + isnull(convert(varchar(3),@arco),'') + '!', @rcode=1
        		goto bspexit
        		end
    	goto bspexit
    	end
    else
    	begin
    	select @msg = 'Not a valid  Company', @rcode = 1
    	end
   
    --Return Phase and Tax Group for new Company
    select @taxgroup=TaxGroup, @phasegroup = PhaseGroup
    from bHQCO where HQCo=@jcco
    if @@rowcount <> 1
        begin
        select @msg='Invalid HQ Company ' + isnull(convert(varchar(3),@jcco),'') + '!', @rcode=1
        goto bspexit
        end
   
    --Return Customer Group for AR company
    select @custgroup=CustGroup
    from bHQCO where HQCo=@arco
    if @@rowcount <> 1
        begin
        select @msg='Invalid HQ Company ' + isnull(convert(varchar(3),@arco),'') + '!', @rcode=1
        goto bspexit
        end
   
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCoValJobCopy] TO [public]
GO
