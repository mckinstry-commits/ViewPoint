SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspEMCompanyGetCountry] 
/********************************************************
* CREATED BY:	CHS	- 11/26/2008
* MODIFIED:	
*
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
*	EMGroup from bHQCO
*	GLCO from EMCO
*	
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@emco bCompany, @country varchar(10) output, @msg varchar(60) output) 
as 
set nocount on

select @country = c.DefaultCountry from HQCO c with (nolock) where c.HQCo = @emco

GO
GRANT EXECUTE ON  [dbo].[vspEMCompanyGetCountry] TO [public]
GO
