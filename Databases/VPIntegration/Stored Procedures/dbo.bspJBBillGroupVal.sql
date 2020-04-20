SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBBillGroupVal    Script Date: 8/28/99 9:34:29 AM ******/
   CREATE  procedure [dbo].[bspJBBillGroupVal]
   /*************************************
   *
   * Created:  bc 09/22/99
   * Modified:  allenn 01/02/02  Issue #15456 Added optional parameter for Contract
   *		TJL 03/28/03 - Issue #20039, Change error message for invalid BillGroup
   *
   * validates Bill Group
   *
   * Pass:
   *	JBCo, Bill Group
   * Issue 15456
   * 	added optional parameter for Contract
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   * 
   **************************************/
   (@jbco bCompany, @billgroup varchar(20), @contract bContract = null, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @jbco is null
   	begin
   	select @msg = 'Missing JB Company', @rcode = 1
   	goto bspexit
   	end
   
   if @billgroup is null
   	begin
   	select @msg = 'Missing bill group', @rcode = 1
   	goto bspexit
   	end

   /*Issue 15456*/
   if @contract is not null
   	begin
   	select @contract = ltrim(rtrim(@contract))
   	select @msg = Description 
   	from bJBBG 
   	where JBCo = @jbco and BillGroup = @billgroup and ltrim(rtrim(Contract)) = @contract
   	if @@rowcount = 0
    		begin
    		select @msg = 'BillGroup Not Setup - Filter only.', @rcode = 1
    		end

   	goto bspexit
   	end
   
   select @msg = Description from bJBBG where JBCo = @jbco and BillGroup = @billgroup
   if @@rowcount = 0
   	begin
      	select @msg = 'BillGroup Not Setup - Filter only.', @rcode = 1
      	end
   
   bspexit:

    	if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[bspJBBillGroupVal]'
   

    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBBillGroupVal] TO [public]
GO
