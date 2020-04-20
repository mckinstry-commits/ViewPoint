SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspMSDHDesc    Script Date: 12/01/2005 ******/
CREATE proc [dbo].[vspMSDHDesc]
/*************************************
 * Created By:	GF 12/01/2005
 * Modified by:
 *
 * called from MSDiscTemplates to return discount template code key description
 *
 * Pass:
 * MSCo				MS Company
 * DiscTemplate		MS Discount Template
 *
 * Returns:
 * Description
 * MSDD_Exists		MS Discount Template Rates Exists
 *
 * Success returns:
 *	0 and Description from MSPC
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@msco bCompany, @disctemplate smallint, @msdd_exists bYN = 'N' output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@disctemplate,0) <> 0
	begin
	select @msg = Description
	from MSDH with (nolock) where MSCo=@msco and DiscTemplate=@disctemplate
	-- -- -- check for rates in MSPR
	if exists(select top 1 1 from MSDD with (nolock) where MSCo=@msco and DiscTemplate=@disctemplate)
		select @msdd_exists = 'Y'
	else
		select @msdd_exists = 'N'
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSDHDesc] TO [public]
GO
