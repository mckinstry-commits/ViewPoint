SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspAPURMissingData]
/***********************************************************
* CREATED BY:		MV	02/11/2009	- #132245
* MODIFIED By:		MV	04/07/2009	- #132245 - missing UM
*					MV	04/30/2009	- #132722 - don't join on ApprvdYN flag
*					CHS	08/24/2011	- TK-07939 adding POItemLine
*
* USAGE: Called from APUnappInvRev, checks for missing data on all lines
*					of an unapproved invoice returns a yn flag
*
* INPUT PARAMETERS
*		@apco bCompany, @uimth bMonth, @uiseq int
*
* RETURN VALUE
*   MissingDataYN
*   
*****************************************************/

(@apco bCompany = null, @uimth bMonth, @uiseq int, @reviewer varchar(3),
	@missinginfoyn bYN output, @msg varchar(255) output)

as
set nocount on

declare @rcode int

select @rcode = 0

	--check for missing info in common for all linetypes
		if exists(select 1 from bAPUL l with (nolock) 
			join bAPUR r with (nolock) on l.APCo=r.APCo and l.UIMth=r.UIMth and l.UISeq=r.UISeq
				and l.Line=r.Line and r.Reviewer=@reviewer --and r.ApprvdYN = 'N'
			where l.APCo=@apco and l.UIMth=@uimth and l.UISeq=@uiseq and 
				(GLCo is null or GLAcct is null or PayType is null or (UnitCost <> 0.0 and Units <> 0.0 and UM is null)))
			begin
				select @missinginfoyn='Y'
				goto vspexit
			end

	-- Job type lines
			if exists(select 1 from bAPUL l with (nolock) 
			join bAPUR r with (nolock) on l.APCo=r.APCo and l.UIMth=r.UIMth and l.UISeq=r.UISeq
				and l.Line=r.Line and r.Reviewer=@reviewer --and r.ApprvdYN = 'N'
			where l.APCo=@apco and l.UIMth=@uimth and l.UISeq=@uiseq and LineType=1 and
			(JCCo is null or Job is null or Phase is null or JCCType is null))
				begin
				select @missinginfoyn='Y'
				goto vspexit
				end
			
	--Inventory type lines
			if exists(select 1 from bAPUL l with (nolock) 
			join bAPUR r with (nolock) on l.APCo=r.APCo and l.UIMth=r.UIMth and l.UISeq=r.UISeq
				and l.Line=r.Line and r.Reviewer=@reviewer --and r.ApprvdYN = 'N'
			where l.APCo=@apco and l.UIMth=@uimth and l.UISeq=@uiseq and LineType=2 and
			(INCo is null or Loc is null or Material is null))
				begin
				select @missinginfoyn='Y'
				goto vspexit
				end
			
	-- Equipment type lines
			if exists(select 1 from bAPUL l with (nolock) 
			join bAPUR r with (nolock) on l.APCo=r.APCo and l.UIMth=r.UIMth and l.UISeq=r.UISeq
				and l.Line=r.Line and r.Reviewer=@reviewer --and r.ApprvdYN = 'N'
			where l.APCo=@apco and l.UIMth=@uimth and l.UISeq=@uiseq and LineType=4 and
			(EMCo is null or Equip is null or CostCode is null or EMCType is null))
				begin
				select @missinginfoyn='Y'
				goto vspexit
				end

	-- WO type lines
			if exists(select 1 from bAPUL l with (nolock) 
			join bAPUR r with (nolock) on l.APCo=r.APCo and l.UIMth=r.UIMth and l.UISeq=r.UISeq
				and l.Line=r.Line and r.Reviewer=@reviewer --and r.ApprvdYN = 'N'
			where l.APCo=@apco and l.UIMth=@uimth and l.UISeq=@uiseq and LineType=5 and
			(WO is null or WOItem is null or EMCo is null or Equip is null or
			 CostCode is null or EMCType is null))
				begin
				select @missinginfoyn='Y'
				goto vspexit
				end

	-- PO type lines
			if exists(select 1 from bAPUL l with (nolock) 
			join bAPUR r with (nolock) on l.APCo=r.APCo and l.UIMth=r.UIMth and l.UISeq=r.UISeq
				and l.Line=r.Line and r.Reviewer=@reviewer --and r.ApprvdYN = 'N'
			where l.APCo=@apco and l.UIMth=@uimth and l.UISeq=@uiseq and LineType=6 and --ItemType=1 and
			(PO is null or POItem is null or POItemLine is null ))
				begin
				select @missinginfoyn='Y'
				goto vspexit
				end
			-- Job PO
			if exists(select 1 from bAPUL l with (nolock) 
			join bAPUR r with (nolock) on l.APCo=r.APCo and l.UIMth=r.UIMth and l.UISeq=r.UISeq
				and l.Line=r.Line and r.Reviewer=@reviewer --and r.ApprvdYN = 'N'
			where l.APCo=@apco and l.UIMth=@uimth and l.UISeq=@uiseq and LineType=6 and ItemType=1 and
				(JCCo is null or Job is null or Phase is null or JCCType is null))
					begin
					select @missinginfoyn='Y'
					goto vspexit
					end
				
			--Inv PO
			if exists(select 1 from bAPUL l with (nolock) 
			join bAPUR r with (nolock) on l.APCo=r.APCo and l.UIMth=r.UIMth and l.UISeq=r.UISeq
				and l.Line=r.Line and r.Reviewer=@reviewer --and r.ApprvdYN = 'N'
			where l.APCo=@apco and l.UIMth=@uimth and l.UISeq=@uiseq and LineType=6 and ItemType=2 and 
				(INCo is null or Loc is null or Material is null))
					begin
					select @missinginfoyn='Y'
					goto vspexit
					end
			--Equip PO	
			if exists(select 1 from bAPUL l with (nolock) 
			join bAPUR r with (nolock) on l.APCo=r.APCo and l.UIMth=r.UIMth and l.UISeq=r.UISeq
				and l.Line=r.Line and r.Reviewer=@reviewer --and r.ApprvdYN = 'N'
			where l.APCo=@apco and l.UIMth=@uimth and l.UISeq=@uiseq and LineType=6 and ItemType=4 and 
				(EMCo is null or Equip is null or CostCode is null or EMCType is null))
					begin
					select @missinginfoyn='Y'
					goto vspexit
					end
				
			--WO PO
			if exists(select 1 from bAPUL l with (nolock) 
			join bAPUR r with (nolock) on l.APCo=r.APCo and l.UIMth=r.UIMth and l.UISeq=r.UISeq
				and l.Line=r.Line and r.Reviewer=@reviewer --and r.ApprvdYN = 'N'
			where l.APCo=@apco and l.UIMth=@uimth and l.UISeq=@uiseq and LineType=6 and ItemType=5 and 
				(WO is null or WOItem is null or EMCo is null or Equip is null or
				 CostCode is null or EMCType is null))
					begin
					select @missinginfoyn='Y'
					goto vspexit
					end
				

	--SL line type
			if exists(select 1 from bAPUL l with (nolock) 
			join bAPUR r with (nolock) on l.APCo=r.APCo and l.UIMth=r.UIMth and l.UISeq=r.UISeq
				and l.Line=r.Line and r.Reviewer=@reviewer --and r.ApprvdYN = 'N'
			where l.APCo=@apco and l.UIMth=@uimth and l.UISeq=@uiseq and LineType=7 and 
			(SL is null or SLItem is null or JCCo is null or Job is null or Phase is null or JCCType is null))
				begin
				select @missinginfoyn='Y'
				goto vspexit
				end
			


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPURMissingData] TO [public]
GO
