SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/********************************************************
* CREATED BY: DANSO 05/02/08 - Issue #127878
* MODIFIED BY:	GF 01/15/2013 TK-20770 get em group from HQCo.
*
*
* 	Retrieves Information commonly used by EM Revenues
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
*	DefRevBDCode -> Default Revenue Breakdown Code (UseRevBkdwnCodeDefault)
*   emgroup -> EM Group (EMGroup)
*	userateorideyn -> Use Rate Override (UseRateOride)
*	
*
* RETURN VALUE:
* 	0 	Success
*	1	Failure
*
**********************************************************/
CREATE proc [dbo].[vspEMRevInfoGet]

(@emco bCompany, 
 @emgroup tinyint output,
 @userateorideyn bYN output,
 @DefRevBDCode bRevCode output,
 @msg varchar(255) output) 

AS 
SET NOCOUNT ON


DECLARE	@rcode	int

-----------------
-- PRIME VALUE --
-----------------
SET @rcode = 0

-------------------------------
-- CHECK FOR INCOMING VALUES --
-------------------------------
IF @emco IS NULL
	BEGIN
		SELECT @msg = 'Missing EM Company.', @rcode = 1
		GOTO vspexit
	END

-------------------------
-- GET REV INFORMATION --
-------------------------
----TK-20770
select  @emgroup = h.EMGroup,
		@DefRevBDCode = e.UseRevBkdwnCodeDefault,
		@userateorideyn = e.UseRateOride
from dbo.HQCO h with(nolock)
Inner join dbo.EMCO e with(nolock)on e.EMCo=h.HQCo
where h.HQCo = @emco
if @@rowcount = 0 
begin
  select @msg = 'EM Company does not exist.', @rcode=1, @emgroup=0
End

if @emgroup is Null 
begin
  select @msg = 'EM Group not setup for EM Co ' + dbo.vfToString(@emco) + ' in HQ!' , @rcode=1, @emgroup=0
End


vspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMRevInfoGet] TO [public]
GO
