SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBCustomerValProcGroup    Script Date: 8/28/99 9:34:10 AM ******/
   CREATE      PROC [dbo].[bspJBCustomerValProcGroup]
   /***********************************************************
    * CREATED BY: kb 7/1/2
    * MODIFIED By : 
    *
    * USAGE:
    * validates Customer to make sure you can post to it
    * If customer is not found using ARCM.Customer then will try to find match using ARCM.Sortname
    * an error is returned if any of the following occurs
    *     Customer not found
    *
    * INPUT PARAMETERS
    *   CustGroup  Customer Group
    *   Customer# Customer to validate
    *   Option   null = any customer
    *            'A' = Active Only
    *            'H' = Not on Hold
    *            'X' = Active and Not on hold
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs, otherwise Name of customer
    * RETURN VALUE
    *   0         Success
    *   1         Failure
    *****************************************************/
   (@jbco bCompany, @sendprocgroup varchar(10), @CustGroup tinyint = null, 
     @Customer bSortName, @CustomerOutput bCustomer output, 
     @procgroup varchar(10) output, @msg varchar(60) output)
   as
   set nocount on
   BEGIN
   
   declare @rcode int
   
   declare @SortNameChk bSortName
   select @rcode = 0
   if @CustGroup is null
     	begin
   	select @msg = 'Missing Customer Group!', @rcode = 1
   	goto bspexit
   	end
   if @Customer is null
   	begin
   	select @msg = 'Missing Customer!', @rcode = 1
   	goto bspexit
   	end
   /* If @Customer is not numeric then it assuming a SortName*/
   if isnumeric((@Customer))<>0
      begin
      /* validate Customer to make sure it is valid to post entries to */
      select @CustomerOutput = Customer, @msg=Name
          from bARCM where CustGroup = @CustGroup and Customer = convert(int,convert(float, @Customer))
        end
   /* Check if customer entered is actually a sort name if customer not found*/
   if @@rowcount = 0
      begin
         select @SortNameChk = @Customer
         select @msg=Name, @CustomerOutput = Customer
            from bARCM where CustGroup = @CustGroup and SortName = @SortNameChk
         if @@rowcount = 0
            begin			/* If not a sortname then bring back the first one that is close to a match  */
   	   set rowcount 1
   	   select @SortNameChk = @SortNameChk + '%'
   	   select @msg=Name, @CustomerOutput = Customer
   		from bARCM
   		where CustGroup = @CustGroup and SortName like @SortNameChk
   	   if @@rowcount = 0   /* if there is not a match then display message */
   	   begin
   	     select @msg = 'Customer not valid!', @rcode = 1
   	     if isnumeric((@Customer))<>0
   	     	select @CustomerOutput = convert(int, @Customer)
   	     else
   	     	select @CustomerOutput = null
   	     goto bspexit
   	   end
   	   set rowcount 0
   	 end
      end
   select @procgroup = ProcessGroup from bJBGC where JBCo = @jbco and CustGroup = @CustGroup
     and Customer = @CustomerOutput
   if @@rowcount = 0
   	begin
   	select @procgroup = @sendprocgroup
   	end
   bspexit:
   	if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[bspJBCustomerValProcGroup]'
   	return @rcode
   END

GO
GRANT EXECUTE ON  [dbo].[bspJBCustomerValProcGroup] TO [public]
GO
