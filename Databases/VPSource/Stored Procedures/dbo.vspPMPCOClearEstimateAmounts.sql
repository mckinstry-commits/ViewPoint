SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMPCOClearEstimateAmounts]
   /***********************************************************
    * Created By:		JG	07/13/2011 - V1# TK-06758
    * Code Reviewed By:	
    * Modified By:		
    * Purpose:		Called in PMPCOS when ImpactEstimate is unchecked to look for 
    *				PCO Items associated with the PCO. If found, prompt user
    *				and if reply is Yes, set all FixedAmountYN = 'Y' and FixedAmount values to zero.
    *****************************************************/
   (@PMCo bCompany, @Project bJob, @PCOType bDocType, @PCO bPCO, @clearAmounts char(1), 
   @amountsToClear char(1) output, @alreadyChecked char(1) output, @complete char(1) output, @msg varchar(255) output)
   as
   set nocount on
   
declare @rcode int

select @rcode = 0, @amountsToClear = 'N', @complete = 'N'

--------------
--VALIDATION--
--------------
if @PMCo is null
begin
	select @msg = 'Missing PM Company.', @rcode = 1
	goto vspexit
end

if @Project is null
begin
	select @msg = 'Missing Project.', @rcode = 1
	goto vspexit
end

if @PCOType is null
begin
	select @msg = 'Missing PCO Type.', @rcode = 1
	goto vspexit
end

if @PCO is null
begin
	select @msg = 'Missing PCO.', @rcode = 1
	goto vspexit
end


------------------------------------
--CHECK FOR ITEMS W/ ESTIMATE AMOUNTS--
------------------------------------
if @alreadyChecked = 'N'
begin
	if exists (select top 1 1 from dbo.PMOL where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO AND EstCost > 0)
	begin
		set @amountsToClear = 'Y'
	end
		
	set @alreadyChecked = 'Y'
	goto vspexit
end

-----------------------
--CLEAR ESTIMATE AMOUNTS--
-----------------------
if @clearAmounts = 'Y'
begin
	-- Clear the Estimate data
	update dbo.bPMOL
	set UM = 'LS', EstUnits = 0, UnitCost = 0, EstCost = 0, UnitHours = 0, EstHours = 0, HourCost = 0
	where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO
end

set @complete = 'Y'

   
vspexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOClearEstimateAmounts] TO [public]
GO
