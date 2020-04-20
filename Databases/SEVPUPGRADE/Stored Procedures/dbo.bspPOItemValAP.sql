SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPOItemValAP    Script Date: 8/28/99 9:33:10 AM ******/
   CREATE   proc [dbo].[bspPOItemValAP]
   /***********************************************************
    * CREATED BY	: kf 7/3/97
    * MODIFIED BY	: kf 7/3/97
    *					MV 07/12/04 - #23834 - return description
    *					GF 7/27/2011 - TK-07144 changed to varchar(30)
    *					MV 08/17/11 - TK07237 AP project to use POItemLine 
    *					MV 09/19/11 - TK-08578 - validate PO Item 'in use'
    * USAGE:
    * Called by AP Invoice Programs (Recurring, Unapproved, Entry)
    * validates PO item, and flags PO item as inuse. 
    * Returns info for AP
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   POCo  PO Co to validate against - this is the same as the AP Co
    *   PO to validate
    *   PO Item to validate
    */
       (@poco bCompany = 0, @po VARCHAR(30) = null, @poitem bItem=null, @POItemLineOut INT OUTPUT, @msg varchar(60) output )
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
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
   
   
   IF EXISTS
		(
			SELECT * 
			FROM dbo.POIT
			WHERE POCo=@poco and PO=@po and POItem=@poitem
		)
	BEGIN
		-- validate for 'in use'
		IF EXISTS
			(
				SELECT * 
				FROM dbo.bPOIT
				WHERE POCo=@poco AND PO=@po AND POItem=@poitem 
				AND (InUseMth IS NOT NULL AND InUseBatchId IS NOT NULL)
			)
		BEGIN
			SELECT @msg='PO item is ''in use'' in PO Item Distribution!', @rcode=1
			GOTO bspexit
		END 
		
		IF 
			(
				SELECT COUNT(POItemLine)
				FROM dbo.vPOItemLine
				WHERE POCo=@poco AND PO=@po AND POItem=@poitem
			) = 1
		BEGIN
			SELECT @POItemLineOut = 1
		END
	END
	ELSE
	BEGIN
		SELECT @msg='PO item does not exist!', @rcode=1
		GOTO bspexit
	END
   
   
   --select @poitemtype=ItemType, @msg = Description from POIT with (nolock)
   --	 where POCo=@poco and PO=@po and POItem=@poitem
   
   
   --if @@rowcount=0
   
   --	begin
   --	select @msg='PO item does not exist!', @rcode=1
   --	goto bspexit
   --	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOItemValAP] TO [public]
GO
