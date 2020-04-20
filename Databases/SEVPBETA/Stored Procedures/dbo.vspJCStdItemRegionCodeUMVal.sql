SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARFCTypeVal    Script Date: 8/28/99 9:34:10 AM ******/
CREATE  PROC [dbo].[vspJCStdItemRegionCodeUMVal]
/*********************************************************************************************
* CREATED BY: DANF 04/06/2005
* MODIFIED By : 
* 
*
* USAGE:
*   Provide a warning to the client through (JC Standard Item Code) when a Unit of Measure has changed for a Standard Item Code that
*   is current being used on an existing contract item.
*
* INPUT PARAMETERS
*   @SIRegion:		Standard Item Region
*   @SICode:		Standard Item Code
*   @UM:			Unit Of Measure
*           
* OUTPUT PARAMETERS
*   @msg      error message if error occurs.
*
* RETURN VALUE
*   0         Success
*   1         Failure
**********************************************************************************************/
(@SIRegion varchar(6) = null, @SICode varchar(16) = null, @UM bUM = null, @msg varchar(250) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if isnull(@SIRegion,'')=''
	begin
  	select @msg = 'Missing Standard Item Region!', @rcode = 1
  	goto vspexit
  	end
if isnull(@SICode,'')=''
	begin
	select @msg = 'Missing Standard Item Code!', @rcode = 1
	goto vspexit
	end
if isnull(@UM,'')=''
	begin
	select @msg = 'Missing Unit of Measure!', @rcode = 1
	goto vspexit
	end


/*Warn user that a change ot the unit of measure may effect existing contract items. */

if exists(Select 1 from dbo.bJCCI with (nolock)where SIRegion = @SIRegion and SICode = @SICode and UM = @UM) 
	begin
		select @rcode = 1, @msg='Warning: Contract Items exist with the ' + isnull(@UM,'') + ' Unit of Measure.'
	end


vspexit:
if @rcode <> 0 select @msg = @msg
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCStdItemRegionCodeUMVal] TO [public]
GO
