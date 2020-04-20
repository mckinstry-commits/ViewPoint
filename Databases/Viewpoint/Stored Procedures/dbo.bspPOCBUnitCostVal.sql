SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspPOCBUnitCostVal]
   /**********************************************
   *	CREATED BY	: SR 06/19/02
   *	MODIFIED BY:   TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
   *		
   *	USED BY
   *		PO Change Orders
   *
   *	USAGE
   *		Validates Unit Cost to prevent changing them if a later CO where they were changed already exists
   *			per ISSUE 11657
   *	
   *	INPUT PARAMETERS
   *		POCo, PO, POItem, POTrans
   *
   *	OUTPUT PARAMETERS
   *		@msg error message if doesn't pass validation
   *
   *	RETURN VALUE
   *		0	success
   *		1 	Failure
   ************************************************************/
   (@poco bCompany = 0, @mth bMonth=null, @po varchar(30) = null, @poitem bItem = null, @potrans bTrans = null, 
   	@um bUM = null, @curunitcost bUnitCost = null, @msg varchar(250) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @COSeq int, @ThisCOSeq int, @pocdunitcost bUnitCost, @pocdmth bMonth, 
   @pocdtrans bTrans, @prevchangedcost bUnitCost
   
   
   select @rcode=0
   
   
   if @poco is null
   	begin
   	select @msg = 'Missing PO Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @po is null
   	begin
   
   	select @msg = 'Missing PO!', @rcode = 1
   	goto bspexit
   	end
   
   
   if @poitem is null
   	begin
   	select @msg = 'Missing PO Item#!', @rcode = 1
   	goto bspexit
   	end
   
   --ISSUE 11657 -- don't allow them to change Unit Cost if they were changed on a later CO
   	If @um <> 'LS' and @potrans is not null
   	begin
   	select @COSeq=isnull(Max(Seq),0) from POCD where POCo=@poco and PO=@po and POItem=@poitem
   	select @prevchangedcost=CurUnitCost from POCD where POCo=@poco and PO=@po and POItem=@poitem and Seq=@COSeq  
   	select @ThisCOSeq=Seq from POCD where POCo=@poco and PO=@po and POItem=@poitem and Mth=@mth and POTrans=@potrans	
   		if @ThisCOSeq<@COSeq and @curunitcost<>0 --and @curunitcost<>@prevchangedcost
   		begin
   			while @COSeq>@ThisCOSeq and @curunitcost<>0 and @prevchangedcost<>0
   			begin			 
   				select @pocdmth = Mth, @pocdtrans=POTrans from POCD where POCo=@poco and PO=@po and POItem=@poitem and Seq=@COSeq
   				select @msg = ' - you cannot change unit cost because unit cost was changed on a later CO in Mth=' + convert(varchar(10),@pocdmth,1) + ' and POTrans=' + convert(varchar(10), @pocdtrans)
   				select @rcode=1
               	goto bspexit					
   				select @COSeq=@COSeq - 1	
   				select @prevchangedcost=CurUnitCost from POCD where POCo=@poco and PO=@po and POItem=@poitem and Seq=@COSeq  
   			end		
   		end			
   	end
   ----END OF ISSUE 11657
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOCBUnitCostVal] TO [public]
GO
