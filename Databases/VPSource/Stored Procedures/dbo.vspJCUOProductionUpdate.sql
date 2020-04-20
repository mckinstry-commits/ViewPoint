SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/******************************************************/
CREATE   proc [dbo].[vspJCUOProductionUpdate]
/***********************************************************
* CREATED BY	: DANF 07/25/07
* Modified By:	GF 02/20/2009 - column widths for JC projection grid
*
*
* USAGE:
*  Updates the Production setting in bJCUO
*
*
* INPUT PARAMETERS
*	JCCo		JC Company
*	Form		JC Form Name
*	UserName	VP UserName
*	Production	Production setting
*	GridColWidth	JC Projection Grid column widths string using ';' as separator
*
* OUTPUT PARAMETERS
*   @msg

* RETURN VALUE
*   0         success
*   1         Failure  'if Fails THEN it fails.
*****************************************************/
(@jcco bCompany, @form varchar(30), @username bVPUserName, @production char(1),
 @gridcolwidth varchar(max) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode integer

select @rcode = 0

-- insert projection user options record
update dbo.bJCUO set Production = @production, ColumnWidth = @gridcolwidth
where JCCo=@jcco and Form=@form and UserName=@username

bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCUOProductionUpdate] TO [public]
GO
