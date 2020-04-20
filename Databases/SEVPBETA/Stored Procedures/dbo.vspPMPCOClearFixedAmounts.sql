SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMPCOClearFixedAmounts]
   /***********************************************************
    * Created By:		GP	03/12/2011 - V1# B03061
    * Code Reviewed By:	JG	03/12/2011
    * Modified By:		JG	07/11/2011 - TK-06758 - Added a check to see if the amounts are already 0.
	*									 TK-06758 - Reset all contract values to Null or 0.
	*									 TK-06758 - Also clear out Add-Ons and Markups.
	*									 
    *				GPT #TK-06476 Modified to set all associated PCOItems.
    * Purpose:		Called in PMPCOS when ImpactContract is unchecked to look for 
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
--CHECK FOR ITEMS W/ FIXED AMOUNTS--
------------------------------------
if @alreadyChecked = 'N'
begin
	if exists (select top 1 1 from dbo.PMOI where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO AND (FixedAmountYN = 'N' OR FixedAmount <> 0 OR Units <> 0 OR UnitPrice <> 0 OR ContractItem IS NOT NULL)) ----TK-06758
	begin
		set @amountsToClear = 'Y'
	end
	ELSE if exists (select top 1 1 from dbo.PMOA where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO AND AddOnPercent > 0)
	BEGIN
		set @amountsToClear = 'Y'
	END
	ELSE if exists (select top 1 1 from dbo.PMOM where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO AND (IntMarkUp > 0 OR ConMarkUp > 0))
	BEGIN
		set @amountsToClear = 'Y'
	END
		
	set @alreadyChecked = 'Y'
	goto vspexit
end

-----------------------
--CLEAR FIXED AMOUNTS--
-----------------------
if @clearAmounts = 'Y'
begin
	-- Clear the Detail data
	update dbo.bPMOI
	set FixedAmountYN = 'Y', FixedAmount = 0, 
	UM = 'LS', Units = 0, UnitPrice = 0, PendingAmount = 0
	where PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO

	-- Clear the Add-Ons amounts
	UPDATE dbo.bPMOA
	SET AddOnPercent = 0, AddOnAmount = 0
	WHERE PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO
	
	-- Clear the Markups amounts
	UPDATE dbo.bPMOM
	SET IntMarkUp = 0, ConMarkUp = 0
	WHERE PMCo = @PMCo and Project = @Project and PCOType = @PCOType and PCO = @PCO
end

set @complete = 'Y'

   
vspexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOClearFixedAmounts] TO [public]
GO
