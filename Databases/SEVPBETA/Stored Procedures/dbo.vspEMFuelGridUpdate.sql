SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMFuelGridUpdate]
/************************************************************************
* CREATED:	DANF 08/02/07
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Update EMBF with Fuel Units and meter readings.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
(@emco bCompany=null,@batch bBatchID=null, @mth bMonth = null, @seq int = null,
 @units bUnits=null, @dollars bDollar = null, @odo bHrs=null, @hrs bHrs=null, @msg varchar(250) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @emco is null
	begin
		select @msg = 'Missing EM Company.', @rcode = 1
		goto vspexit
	end

	if @batch is null
	begin
		select @msg = 'Missing Batch ID.', @rcode = 1
		goto vspexit
	end

	if @mth is null
	begin
		select @msg = 'Missing batch Month.', @rcode = 1
		goto vspexit
	end

	if @seq is null
	begin
		select @msg = 'Missing batch Sequence.', @rcode = 1
		goto vspexit
	end
select * from EMBF
begin try
	Update EMBF
	set Units = @units, Dollars = @dollars, CurrentOdometer = @odo, CurrentHourMeter = @hrs
	where Co = @emco and Mth = @mth and BatchId = @batch and BatchSeq = @seq
end try

begin catch
	select @rcode = 1
	select @msg = ERROR_MESSAGE()
end catch

vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMFuelGridUpdate] TO [public]
GO
