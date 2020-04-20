SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.bspPOHDNextPO    Script Date: 8/28/99 9:35:25 AM ******/
   CREATE  proc [dbo].[bspPOHDNextPO]
   /***********************************************************
    * CREATED BY	: SE 4/8/97
    * MODIFIED BY	: kb 11/30/99 - fixed so if the LastPO # in POCO is not numeric then don't return the default,
    *                  this will elminate user getting error if the LastPO field has an alpha character in it.
    *				DC 01/25/08 #125339 - PO Company - Last Used PO#, needs to validate as numeric
	*				DC 08/04/08 #129188 - Same PO number assigned to 2 PO's
	*				DC 09/08/08 #129690 - If not automatically generating PO#'s error is returned for new PO
	*				DC 12/09/08 #130129 - Combine RQ and PO into a single module
	*				DC 5/19/09 #133612 - Permission error on bPOCO when app role security is turned on
	*				GF 7/27/2011 - TK-07144 changed to varchar(30)
	*				GP 4/4/2012 - TK-13774 added check against POUnique view
	*
    * USAGE:
    * looks at the POCO AutoPO flag to get the next PO
    * If AutoPO flag is 'Y' then get the PO Increment it and write it back out
    *
    * INPUT PARAMETERS
    *   POCo  PO Co to get next PO from
    *
    * OUTPUT PARAMETERS
    *   @PO    the next PO number to use, if AutoPO is N then ''
    * RETURN VALUE
    *   0         success
    *   1         Failure
   
    *****************************************************/
       (@poco bCompany = 0, @po VARCHAR(30) output)
   as
   
   set nocount on
   
   declare @rcode int,
			@lastpo numeric(30,0),  --DC #125339
       		@bpolen int,  -- DC #125339
       		@autopo char(1)  --DC #129690

   	SELECT @bpolen = 30 --DC #125339
   
   /* if AutoPO is Y then update the Current PO then read what the PO should be*/
   
   select @po=''

   --DC #125339 
   -- if (select ISNUMERIC(LastPO) from bPOCO where POCo = @poco) = 1  --added this 11/30/99 kb
       --begin
	
	SELECT @lastpo = LastPO,
			@autopo = AutoPO --DC #129690
	FROM POCO with (nolock)
	Where POCo = @poco 
	
	IF @autopo = 'N' return  --DC #129690
	
	POLoop:
	
	IF exists (select 1 from dbo.POUnique where POCo = @poco and PO = cast(@lastpo as varchar(30)))
	BEGIN
		IF len(@lastpo + 1) > @bpolen 
		BEGIN				
			SELECT @lastpo = 1
			GOTO POLoop
		END
		ELSE
		BEGIN					
			SELECT @lastpo = @lastpo + 1
			GOTO POLoop
		END
	END
	ELSE
	BEGIN
		SELECT @po = @lastpo
	END

	BEGIN
		--DC #133612
		update bPOCO
		Set ByPassTriggers = 'Y'
		Where POCo = @poco
		
		--ALTER TABLE bPOCO DISABLE TRIGGER ALL  --DC #130129
		update bPOCO
		set LastPO = @lastpo + 1 --DC #129188
   		where AutoPO='Y' and POCo=@poco      	       	
		--ALTER TABLE bPOCO ENABLE TRIGGER ALL  --DC #130129	
		
		--DC #133612
		update bPOCO
		Set ByPassTriggers = 'N'
		Where POCo = @poco	   
	END
		   
   
   return 0



GO
GRANT EXECUTE ON  [dbo].[bspPOHDNextPO] TO [public]
GO
