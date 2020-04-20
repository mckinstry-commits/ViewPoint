SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[vspHQTXMultiLevelMembers]
/********************************
* Created: kb 8/22/5
* Modified:	GG 3/7/07 - cleanup, ansi joins, nolocks, comments, removed params
*
* Called from the HQ Tax Setup form to retrieve
* tax codes linked to the specfied multi-level taxcode
*
* Input:
*	@taxgroup	Tax Group
*	@taxcode	Tax Code
*
* Output:
*	resultset - current report type information
*	
* Return code:
*	none
*
********************************/
(@taxgroup bGroup, @taxcode bTaxCode)

as	
set nocount on

-- resultset of linked Tax Codes  --
Select l.TaxCode, t.Description
from dbo.bHQTX t (NOLOCK)
JOIN dbo.bHQTL l (NOLOCK) ON t.TaxGroup = l.TaxGroup AND t.TaxCode = l.TaxCode
where l.TaxGroup = @taxgroup and l.TaxLink = @taxcode

vspexit:
	return

GO
GRANT EXECUTE ON  [dbo].[vspHQTXMultiLevelMembers] TO [public]
GO
