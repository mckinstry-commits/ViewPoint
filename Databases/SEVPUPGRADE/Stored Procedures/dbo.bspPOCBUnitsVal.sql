SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   CREATE  procedure [dbo].[bspPOCBUnitsVal]
   /**********************************************
   *	CREATED BY	: SR 06/19/02
   *MODIFIED BY:  TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
   *
   *	USED BY
   *		PO Change Orders
   *
   *	USAGE
   *		Validates Units to prevent changing them if a later CO where they were changed already exists
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
   	@um bUM = null, @changecurunits bUnits = null, @curunitcost bUnitCost, @msg varchar(250) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @COSeq int, @ThisCOSeq int, @pocdunitcost bUnitCost, @pocdmth bMonth, 
   @pocdtrans bTrans, @prevchangedunits bUnits
   
   
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
   
   --ISSUE 11657 -- don't allow them to change Units if they were changed on a later CO
   	If @um <> 'LS' and @potrans is not null
   	begin
   	select @COSeq=isnull(Max(Seq),0) from POCD where POCo=@poco and PO=@po and POItem=@poitem
   	select @prevchangedunits=CurUnitCost from POCD where POCo=@poco and PO=@po and POItem=@poitem and Seq=@COSeq
   	select @ThisCOSeq=Seq from POCD where POCo=@poco and PO=@po and POItem=@poitem and Mth=@mth and POTrans=@potrans
   		if @ThisCOSeq<@COSeq and @changecurunits<>0 --and @changecurunits<>@prevchangedunits 
   		begin
   			while @COSeq>@ThisCOSeq and @changecurunits<>0 and @prevchangedunits<>0
   			begin			 
   				select @pocdmth = Mth, @pocdtrans=POTrans from POCD where POCo=@poco and PO=@po and POItem=@poitem and Seq=@COSeq
   				select @msg = ' - you cannot change units because unit cost was changed on a later CO in Mth=' + convert(varchar(10),@pocdmth,1) + ' and POTrans=' + convert(varchar(10), @pocdtrans)
   				select @rcode=1
               	goto bspexit					
   				select @COSeq=@COSeq - 1	
   				select @prevchangedunits=ChangeCurUnits from POCD where POCo=@poco and PO=@po and POItem=@poitem and Seq=@COSeq
   			end		
   		end			
   	end
   ----END OF ISSUE 11657
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOCBUnitsVal] TO [public]
GO
