SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMDepositExists    Script Date: 8/28/99 9:32:37 AM ******/
   CREATE  proc [dbo].[bspCMDepositExists]
   
   /***********************************************************
    * CREATED BY: JM   12/5/97
    * MODIFIED By : 
    *
    * USAGE:
    * 	Determines if a CM Deposit Number exists in CMDT
    * 
    * INPUT PARAMETERS
    *   	CMCo		CM Co
    *	TransDate	Transaction Date - converted to mth
    *	CMTrans		Transaction
    *	CMRef		Deposit Number to search
    *	
    * OUTPUT PARAMETERS
    *   @msg If exists, error message, otherwise nothing
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
   
    *****************************************************/ 
   
   	(@cmco bCompany = 0, @transmth bDate = null, @cmtrans bTrans = null, 
   	@depno bCMRef = null, @msg varchar(60) output)
   as
   
   set nocount on
   declare @rcode int
   select @rcode = 0
   	
   if @cmco = 0
   	begin
   	select @msg = 'Missing CM Company#', @rcode = 1
   	goto bspexit
   	end
   
   if @cmtrans is null
   	begin
   	select @msg = 'Missing Transaction!', @rcode = 1
   	goto bspexit
   	end
   
   if @transmth is null
   	begin
   	select @msg = 'Missing Transaction Date!', @rcode = 1
   	goto bspexit
   	end
   
   if @depno is null
   	begin
   	select @msg = 'Missing Deposit Number!', @rcode = 1
   	goto bspexit
   	end
   
   if exists(select * from CMDT where CMCo = @cmco and Mth = @transmth
   	and CMTrans = @cmtrans and CMRef = @depno)
   	begin
   	select @msg = 'Deposit Number exists in CM Detail Transaction file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMDepositExists] TO [public]
GO
