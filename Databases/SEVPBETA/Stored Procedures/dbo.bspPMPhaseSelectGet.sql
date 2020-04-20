SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspPMPhaseSelectGet]
   /************************************************************************
   * Created By:	GF 08/02/2002    
   * Modified By:    
   *
   * Purpose of Stored Procedure
   *    Get list of phases from JCPM for copying into selected project
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   (@pmco bCompany, @project bJob, @phasegroup bGroup)
   as
   set nocount on
   
   declare @rcode int, @msg varchar(255) 
   
   select @rcode = 0, @msg = null
   
   if @pmco is null
   	begin
   	select @msg = 'Missing PM Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @project is null
   	begin
   	select @msg = 'Missing PM Project!', @rcode = 1
   	goto bspexit
   	end
   
   if @phasegroup is null
   	begin
   	select @msg = 'Missing Vendor Group!', @rcode = 1
   	goto bspexit
   	end
   
   
   -- get phases from JCPM
   Select JCPM.Phase, JCPM.Description
   from JCPM with (nolock) 
   where JCPM.PhaseGroup=@phasegroup
   and not exists(select JCCo from JCCH where JCCo=@pmco and Job=@project and Phase=JCPM.Phase)
   
   
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPhaseSelectGet] TO [public]
GO
