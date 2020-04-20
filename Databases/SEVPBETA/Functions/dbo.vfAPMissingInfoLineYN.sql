SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    function [dbo].[vfAPMissingInfoLineYN]
  (@apco bCompany, @uimth bMonth, @uiseq int, @line int)
      returns bYN
   /***********************************************************
    * CREATED BY	: MV 01/04/2008
    * MODIFIED BY	: 
    *
    * USAGE:
    * checks if line info is missing in bAPUL for APUnappInvRev
	* returns a flag of Y
    *
    * INPUT PARAMETERS
    * 	@apco
    * 	@udmth
    * 	@uiseq
    *	@line
    *
    * OUTPUT PARAMETERS
    *  @missinginfoyn      
    *
    *****************************************************/
      as
      begin
          
        declare @missinginfoyn bYN,@linetype tinyint,@itemtype int
		 
		--initialize missing flag
		select @missinginfoyn = 'N'

			--check for missing info in common for all linetypes
		if exists(select 1 from bAPUL with (nolock) where APCo=@apco and UIMth=@uimth 
			and UISeq=@uiseq and Line=@line and
			(GLCo is null or GLAcct is null or UM is null or PayType is null))
			begin
				select @missinginfoyn='Y'
				goto exitfunction
			end
		--get linetype info from APUL
		select @linetype=LineType,@itemtype=ItemType from bAPUL with (nolock) where APCo=@apco and UIMth=@uimth 
			and UISeq=@uiseq and Line=@line 
		--check linetype for missing info
		if @linetype = 1 --Job
			begin
			if exists(select 1 from bAPUL with (nolock) where APCo=@apco and UIMth=@uimth 
			and UISeq=@uiseq and Line=@line and 
			(JCCo is null or Job is null or Phase is null or JCCType is null))
				begin
				select @missinginfoyn='Y'
				goto exitfunction
				end
			end
		if @linetype = 2 --Inv
			begin
			if exists(select 1 from bAPUL with (nolock) where APCo=@apco and UIMth=@uimth 
			and UISeq=@uiseq and Line=@line and 
			(INCo is null or Loc is null or Material is null))
				begin
				select @missinginfoyn='Y'
				goto exitfunction
				end
			end
		-- LineType 3 - Exp requires GLCo and GLAcct which is checked above.
		if @linetype = 4 --Equip
			begin
			if exists(select 1 from bAPUL with (nolock) where APCo=@apco and UIMth=@uimth 
			and UISeq=@uiseq and Line=@line and 
			(EMCo is null or Equip is null or CostCode is null or EMCType is null))
				begin
				select @missinginfoyn='Y'
				goto exitfunction
				end
			end
		if @linetype = 5 --WO
			begin
			if exists(select 1 from bAPUL with (nolock) where APCo=@apco and UIMth=@uimth 
			and UISeq=@uiseq and Line=@line and 
			(WO is null or WOItem is null or EMCo is null or Equip is null or
			 CostCode is null or EMCType is null))
				begin
				select @missinginfoyn='Y'
				goto exitfunction
				end
			end
		if @linetype = 6 --PO
			begin
			--check for missing PO info
			if exists(select 1 from bAPUL with (nolock) where APCo=@apco and UIMth=@uimth 
			and UISeq=@uiseq and Line=@line and 
			(PO is null or POItem is null))
				begin
				select @missinginfoyn='Y'
				goto exitfunction
				end
			if @itemtype = 1 --Job PO
				begin
				if exists(select 1 from bAPUL with (nolock) where APCo=@apco and UIMth=@uimth 
				and UISeq=@uiseq and Line=@line and 
				(JCCo is null or Job is null or Phase is null or JCCType is null))
					begin
					select @missinginfoyn='Y'
					goto exitfunction
					end
				end
			if @itemtype = 2 --Inv PO
				begin
				if exists(select 1 from bAPUL with (nolock) where APCo=@apco and UIMth=@uimth 
				and UISeq=@uiseq and Line=@line and 
				(INCo is null or Loc is null or Material is null))
					begin
					select @missinginfoyn='Y'
					goto exitfunction
					end
				end
			if @itemtype = 4 --Equip PO
				begin
				if exists(select 1 from bAPUL with (nolock) where APCo=@apco and UIMth=@uimth 
				and UISeq=@uiseq and Line=@line and 
				(EMCo is null or Equip is null or CostCode is null or EMCType is null))
					begin
					select @missinginfoyn='Y'
					goto exitfunction
					end
				end
			if @itemtype = 5 --WO PO
				begin
				if exists(select 1 from bAPUL with (nolock) where APCo=@apco and UIMth=@uimth 
				and UISeq=@uiseq and Line=@line and 
				(WO is null or WOItem is null or EMCo is null or Equip is null or
				 CostCode is null or EMCType is null))
					begin
					select @missinginfoyn='Y'
					goto exitfunction
					end
				end
			end
		if @linetype = 7 --SL
			begin
			--check for missing PO info
			if exists(select 1 from bAPUL with (nolock) where APCo=@apco and UIMth=@uimth 
			and UISeq=@uiseq and Line=@line and 
			(SL is null or SLItem is null or JCCo is null or Job is null or Phase is null or JCCType is null))
				begin
				select @missinginfoyn='Y'
				goto exitfunction
				end
			end
 
  	exitfunction:
  			
  	return @missinginfoyn
      
    end

GO
GRANT EXECUTE ON  [dbo].[vfAPMissingInfoLineYN] TO [public]
GO
