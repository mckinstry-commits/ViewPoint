SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPOHDPurgeList    Script Date: 02/28/06  ******/
   CREATE   proc [dbo].[vspPOHDPurgeList]
   /***********************************************************
    * CREATED BY	: DC 02/28/06
    * MODIFIED BY	: DC 01/08/2009 #127183  - Model Purge after PO Close form
    *					GF 7/27/2011 - TK-07144 changed to varchar(30)
    *
    * USAGE:
	* This routine is used to load listbox with PO's where Status = 2 i.e closed and
	* Closed Month is <= Purge through Month
	*
    *
    * INPUT PARAMETERS
    *   POCo  		PO Company
	*	MthClose	Closed Month
    *
	*
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
       (@poco bCompany = 0, @mthclosed bMonth, 
       @beginpo VARCHAR(30), @endpo VARCHAR(30), @getjcco bCompany, @getjob bJob)  --DC #127183
   as
   
   set nocount on
   
	If @beginpo is null select @beginpo = ''
	If @endpo is null select @endpo = '~~~~~~~~~~'


	If (@getjcco is not null and @getjob is not null)
		BEGIN
		Select PO, ': ' + isnull(Description,'') 
		from POHD with (NOLOCK)
		where POCo = @poco 
			And Status = 2 
			And InUseBatchId is null 
			And MthClosed <= @mthclosed
			And PO >= @beginpo And PO <= @endpo
			And JCCo = @getjcco And Job = @getjob
		END	
	ELSE
		BEGIN
		Select PO, ': ' + isnull(Description,'') 
		from POHD with (NOLOCK)
		where POCo = @poco 
			And Status = 2 
			And InUseBatchId is null 
			And MthClosed <= @mthclosed
			And PO >= @beginpo And PO <= @endpo
		END
   
   return 0

GO
GRANT EXECUTE ON  [dbo].[vspPOHDPurgeList] TO [public]
GO
