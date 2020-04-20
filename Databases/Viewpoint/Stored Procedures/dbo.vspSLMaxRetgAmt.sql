SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/****** Object:  Stored Procedure dbo.vspSLMaxRetgAmt    Script Date: 8/28/99 9:36:38 AM ******/
CREATE proc [dbo].[vspSLMaxRetgAmt]      
/***********************************************************
* CREATED BY: DC	2/10/10
* MODIFIED By : GF 06/26/2010 - issue #135318 expanded SL to varchar(30)
*				GF 05/15/2012 TK-14929 issue #146439 item type in (1,2)
*
*
*
* USAGE:
* Called from SL procedures to return the max amount of retainage
*		that can be withheld on a subcontract
*
*
*  INPUT PARAMETERS
*	@slco	Current SL Co#
*	@sl		Subcontract 
*
* OUTPUT PARAMETERS
*		@maxretgamt maximum amount of retainage that can be withheld on the subcontract
*   	@msg     	error message if error occurs
*
* RETURN VALUE
*   	0         	success
*   	1         	failure
*****************************************************/   
	(@slco bCompany, @sl VARCHAR(30), @maxretgamt bDollar output, @msg varchar(200) output)
	as
	set nocount on
	
	DECLARE @rcode int
	
	select @rcode = 1	

	--Get subcontact max retainage amout for the subcontract.
	SELECT @maxretgamt = case when h.MaxRetgOpt = 'A' then h.MaxRetgAmt else case when h.InclACOinMaxYN = 'Y' then (h.MaxRetgPct * sum(isnull(t.CurCost, 0))) 
			else (h.MaxRetgPct * sum(isnull(t.OrigCost, 0))) end end 
	FROM dbo.bSLHD h with (nolock)
	LEFT JOIN dbo.bSLIT t with (nolock) on h.SLCo = t.SLCo and h.SL = t.SL and t.WCRetPct <> 0
	----TK-14929
	AND t.ItemType IN (1,2)
	WHERE h.SLCo = @slco and h.SL = @sl
	GROUP BY h.SLCo, h.SL, h.InclACOinMaxYN, h.MaxRetgPct, h.MaxRetgOpt, h.MaxRetgAmt

	SELECT @maxretgamt = isnull(@maxretgamt,0)
	SELECT @rcode = 0
	
RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspSLMaxRetgAmt] TO [public]
GO
