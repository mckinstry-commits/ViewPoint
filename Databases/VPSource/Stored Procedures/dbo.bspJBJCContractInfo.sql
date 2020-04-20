SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBJCContractInfo    Script Date: 8/28/99 9:35:02 AM ******/
    CREATE  proc [dbo].[bspJBJCContractInfo]
    /***********************************************************
     * CREATED BY:   bc 09/24/99
     * MODIFIED By : bc 04/18/00 - added round option to output parameter list
     *		kb 9/24/1 - issue #14440
     *		kb 12/10/1 - issue #14440
     *		kb 2/25/2 - issue #15854
     *		TJL 03/06/08 - Issue #127077, International Addresses
     *
     * USAGE:
     * validates JC contract - returns jccm defaults for job billing progress
     *
     * an error is returned if any of the following occurs
     * no contract passed, no contract found in JCCM.
     *
     * INPUT PARAMETERS
     *  JBCo        JC Co to validate against
     *  Contract    Contract to validate
     *
     *
     * OUTPUT PARAMETERS
     *  customer        from JCCM
     *  process group       '
     *  taxcode             '
     *  payment terms       '
     *  billing addr        '
     *  addl addr           '
     *  city, state & zip   '
     *  rounding option     '
     *
     *
     *   @msg      error message if error occurs otherwise Description of Contract
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
    (@jbco bCompany = 0, @contract bContract = null,
     @customer bCustomer = null output, @processgroup varchar(20) = null output,
     @payterms bPayTerms = null output, @billaddress varchar(60) = null output,
     @addl_addr varchar(60) = null output, @billcity varchar(30) = null output,
     @billstate varchar(4) = null output, @billzip bZip = null output, @billcountry char(2) output,
     @appnum int output, @roundopt char(1) output, @rectype tinyint output,
     @customeraddr bYN = null output, @customerrectype bYN = null output,
     @msg varchar(60) output)
    as
    set nocount on
   
    declare @rcode int, @custgroup bGroup, @arco bCompany
    select @rcode = 0
   
   
    if @jbco is null
    	begin
    	select @msg = 'Missing JB Company!', @rcode = 1
    	goto bspexit
    	end
   
    if @contract is null
    	begin
    	select @msg = 'Missing Contract!', @rcode = 1
    	goto bspexit
    	end
   
    /* get the customer group */
    select @custgroup = CustGroup from HQCO where HQCo = @jbco
   
    select @arco = ARCo from bJCCO where JCCo = @jbco
   
    /* get the info we came in here for out of JCCM */
    select @msg = Description, @customer = Customer, @processgroup = ProcessGroup,
           @payterms = PayTerms, @billaddress = BillAddress, @addl_addr = BillAddress2,
           @billcity = BillCity, @billstate = BillState, @billzip = BillZip, @billcountry = BillCountry,
           @roundopt = RoundOpt, @rectype = RecType
    from bJCCM
    where JCCo = @jbco and Contract = @contract
    if @@rowcount = 0
    	begin
    	select @msg = 'Contract not on file!', @rcode = 1
    	goto bspexit
    	end
   
     select @customeraddr = 'N', @customerrectype = 'N'
    /* go for the second option (ARCM) if JCCM doesn't have the payment term or billing address info */
    if @payterms is null select @payterms = PayTerms from ARCM where CustGroup = @custgroup and Customer = @customer
    if @billaddress is null
       begin
       select @billaddress = BillAddress, @billcity = BillCity, @billstate = BillState,
         @billzip = BillZip, @billcountry = BillCountry, @addl_addr = BillAddress2
         from ARCM where CustGroup = @custgroup and Customer = @customer
       select @customeraddr = 'Y'
       end
    if @rectype is null
       begin
       select @rectype = RecType from ARCM where CustGroup = @custgroup and Customer = @customer
       if @@rowcount > 0
           begin
           select @customerrectype ='Y'
           end
       end
    if @rectype is null
       begin
       select @rectype = RecType from ARCO where ARCo = @arco
       select @customerrectype ='Y'
       end
   
    /* increment the application # for this contract */
    select @appnum = isnull(max(Application),0) + 1
    from JBIN
    where JBCo = @jbco and Contract = @contract
   
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBJCContractInfo] TO [public]
GO
