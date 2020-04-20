SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspEMTransactionNumberVal]
/***********************************************************
* CREATED By:	CHS	03/03/08
* MODIFIED By:
*
* USAGE:
* Called to test an EM Transaction # to see if there are any 
*	AttachedToTrans numbers relating to the given Trans value.
*
*  INPUT PARAMETERS
*   @emco             EM Company
*   @month            Batch Month
*   @trans            Transaction #
*
* OUTPUT PARAMETERS
*	@attachedtransyn		Y/N flag - Y if there are any 
*						AttachedToTrans numbers relating 
*						to the given Trans value
*
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         failure
************************************************************/
(@emco bCompany = null, @month bMonth = null, @trans bTrans = null, 
	@attachedtransyn bYN = 'N' output, @msg varchar(255) = null output)

   as
   set nocount on

declare @rcode int
select @rcode = 0


if @emco is null
	begin
		select @msg = 'Missing EM Company!', @rcode = 1
		goto bspexit
	end

if @month is null
	begin
		select @msg = 'Missing Month Parameter!', @rcode = 1
		goto bspexit
	end

if @trans is null
	begin
		select @msg = 'Missing Transaction Number!', @rcode = 1
		goto bspexit
	end


if exists(select top 1 1 from EMLH e with (nolock) where e.EMCo = @emco and e.Month = @month and AttachedToTrans = @trans)
	begin
		set @attachedtransyn = 'Y'
	end

bspexit:
   if @rcode<>0 select @msg=isnull(@msg,'')
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMTransactionNumberVal] TO [public]
GO
