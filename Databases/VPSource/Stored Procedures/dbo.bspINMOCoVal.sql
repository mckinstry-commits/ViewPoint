SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspINMOCoVal]
   /************************************************
    * Created By RM 02/15/02
	* Modified By: Dan So 07/31/08 - Issue 129195 - need to return Phase Group
    *
    * validates Company number in a INMOEntry Record, 
    *
    *  The validation is based on type, makes sure its a valid CO and that
    *  the batch month is open
    *
    * USED IN
    *	MO Entry
    *
    * PASS IN
    *   Company#
   
    *   BatchMonth
    *
    * RETURN PARAMETERS
    *   TaxGrp   Tax Group from this post to company
    *
    *
    * RETURNS
    *   0 on Success
    *   1 on ERROR and places error message in msg
   
    **********************************************************/
   	(@co bCompany = 0,@batchmth bMonth,  @taxgrp bGroup output, @glco bCompany output, 
	 @overridegl bYN output, @PhaseGroup tinyint = null output,
     @msg varchar(256) output)

   as
   	set nocount on
   
   	declare @rcode int
   
   select @rcode = 0
   
   -- ISSUE 129195 - RETURNING PhaseGroup --
   select @msg = Name, @taxgrp=TaxGroup, @PhaseGroup = PhaseGroup
   from dbo.HQCO with(nolock)
   where @co = HQCo
   if @@rowcount = 0
      begin
      select @msg = 'Not a valid HQ Company!', @rcode = 1
      goto bspexit
      end
   
   select @glco=GLCo,@overridegl = GLCostOveride
   from dbo.JCCO with(nolock)
   where @co=JCCo
   if @@rowcount = 0
      begin
      select @msg = 'Not a valid Job Cost Company!', @rcode = 1
      goto bspexit
      end
  
   
   /*
    * if we've made it this far then we have a valid GLCompay
    * so make sure batch is in an open month
    */
    if @batchmth is not null /*Dont validate if open month if month is passed in as null (like in APRecurInv) */
   	begin
   	exec @rcode = bspHQBatchMonthVal @glco, @batchmth, 'AP Entry', @msg output
	If @rcode = 1
	begin
		select @msg = 'GL Validation Error for JC Company ' + Convert(varchar,@co) + '! ' + char(13)+Char(10) + @msg
	end
   	end
   
   bspexit:
	
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMOCoVal] TO [public]
GO
