SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBTemplateValForTMBill]
    /***********************************************************
     * CREATED BY: bc   05/16/00
     * MODIFIED By : kb 3/21/01 - changed datatype of billnum from int to varchar - Issue #12695
     *
     * USAGE:
     *
     * INPUT PARAMETERS
     *   JBCo      JB Co to validate against
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs otherwise Description of Contract
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/
   
    @jbco bCompany = 0, @template varchar(10), @billmonth bMonth, @billnum varchar(9),
    @sortorder char(1) output, @msg varchar(255) output
   
    as
    set nocount on
   
    	declare @rcode int
    	select @rcode = 0
   
   
    if @jbco is null
    	begin
    	select @msg = 'Missing JB Company!', @rcode = 1
    	goto bspexit
    	end
   
    if @template is null
    	begin
    	select @msg = 'Missing template!', @rcode = 1
    	goto bspexit
    	end
   
    if isnumeric(@billnum) = 1
       begin
        if exists(select * from bJBIL where JBCo = @jbco and BillMonth = @billmonth and
          BillNumber = @billnum)
           begin
           if exists(select * From bJBIN where JBCo = @jbco and BillMonth = @billmonth and
             BillNumber = @billnum and Template <> @template and Template is not null)
               begin
               select @msg = 'Template cannot be changed if lines exist', @rcode = 1
               goto bspexit
               end
           end
       end
   
   
   
    select @msg = Description, @sortorder = SortOrder
    from JBTM
    where JBCo = @jbco and Template = @template
    if @@rowcount = 0
    	begin
    	select @msg = 'Template not on file!', @rcode = 1
    	goto bspexit
    	end
   
   
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTemplateValForTMBill] TO [public]
GO
