SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
   CREATE  PROC [dbo].[bspMSQHCopySrcCustVal]
   /***********************************************************
     * Created By: 	GF 03/31/2000
     * Modified By:	GF 06/08/2004 - issue #24737 problem with arithmetic overflow error
     *				GF 09/07/2004 - fix for issue #24737 - leading spaces with numeric. need to trim.
     *
     * USAGE:
     *  Validates Customer to make sure you can use.
     *  Then checks to make sure used on a quote.
     *  If customer is not found using ARCM.Customer, then will
     *  try to find match using ARCM.Sortname. An error is
     *  returned if any of the following occurs:
     *  Customer not found
     *
     * INPUT PARAMETERS
     *  MS Company, CustGroup, Combination Level, Customer, CustJob, CustPO
     *
     * OUTPUT PARAMETERS
     *  @msg      error message if error occurs, otherwise Name of customer
     * RETURN VALUE
     *  0         Success
     *  1         Failure
     *****************************************************/
    (@msco bCompany = null, @custgroup tinyint = null, @level char(1) = '1',
     @customer bSortName, @custjob varchar(20) = null, @custpo varchar(20) = null,
     @custout bCustomer output, @msg varchar(255) output)
    as
    set nocount on
    declare @rcode int, @validcnt int, @status char(1), @sortnamecheck bSortName
    select @rcode = 0
    
    if @msco is null
        begin
        select @msg = 'Missing MS Company!', @rcode = 1
        goto bspexit
        end
    
    if @custgroup is null
      	begin
    	select @msg = 'Missing Customer Group!', @rcode = 1
    	goto bspexit
    	end
    
    if @customer is null
    	begin
    	select @msg = 'Missing Customer!', @rcode = 1
    	goto bspexit
    	end
   
   
   -- if customer is not numeric then assume a SortName
   if dbo.bfIsInteger(ltrim(rtrim(@customer))) = 1
   -- -- -- if isnumeric((@customer))<>0
   	begin
   	if len(ltrim(rtrim(@customer))) < 7
   		begin
   		-- validate customer to make sure it is valid to use
   		select @custout=Customer, @status=Status, @msg=Name
   		from bARCM where CustGroup=@custgroup and Customer=convert(int,convert(float, @customer))
   		end
   	else
   		begin
   		select @msg = 'Invalid customer number, length must be 6 digits or less.', @rcode = 1
   		goto bspexit
   		end
   	end
   
    -- Check if customer entered is actually a sort name if customer not found
    if @@rowcount = 0
       begin
       select @sortnamecheck=@customer, @custout=Customer, @msg=Name
       from bARCM where CustGroup=@custgroup and SortName=@customer
       if @@rowcount = 0
          begin
          -- if not a sortname then bring back the first one that is close to a match
    	  set rowcount 1
    	  select @sortnamecheck=@sortnamecheck + '%'
    	  select @msg=Name, @custout=Customer, @status=Status
    	  from bARCM where CustGroup=@custgroup and SortName like @sortnamecheck
    	  if @@rowcount = 0
           	begin
           	-- if there is not a match then display message
    	  	select @msg='Customer not valid!', @rcode = 1
   		goto bspexit
   		end
   -- -- --  	     if isnumeric((@customer))<>0
   -- -- --  	     	select @custout=convert(int, @customer)
   -- -- --  	     else
   -- -- --  	     	select @custout=null
   -- -- --           goto bspexit
   -- -- -- 		end
    	  end
       end
    
    -- check if customer is assigned to a MS Quote
    IF @level='1'
        begin
        select @validcnt=count(*) from bMSQH
        where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@custout
        if @validcnt = 0
            begin
            select @msg='No valid quote for customer!', @rcode = 1
            goto bspexit
            end
        end
    ELSE
    IF @level='2'
        begin
        select @validcnt=count(*) from bMSQH
        where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup
        and Customer=@custout and CustJob=@custjob
        if @validcnt = 0
            begin
            select @msg='No valid quote for customer/job combination!', @rcode = 1
            goto bspexit
            end
        end
    ELSE
    IF @level='3'
        begin
        select @validcnt=count(*) from bMSQH
        where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@custout
        and CustJob=@custjob and CustPO=@custpo
        if @validcnt = 0
            begin
            select @msg='No valid quote for customer/job/po combination!', @rcode = 1
            goto bspexit
            end
        end
   
   
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQHCopySrcCustVal] TO [public]
GO
