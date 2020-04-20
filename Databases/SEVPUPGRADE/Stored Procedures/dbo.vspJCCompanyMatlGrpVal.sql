SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCCompanyMatlGrpVal    Script Date: 2/20/06 ******/
   CREATE    proc [dbo].[vspJCCompanyMatlGrpVal]
   /*************************************
   *	Created by:  DC 2/20/06
   *	
   *
   * validates JC Company number and returns Description and Material Group from HQCo
   *	
   * Pass:
   *	JC Company number
   *
   * Success returns:
   *	0 and Company name and Material Group from bHQCO
   *
   * Error returns:
   *	1 and error message
   *
   * Notes:
   * 	In 5.x the form would use bspJCCompanyVal to validate the JC Company
   *	then in code it would call a sql statement to validate the material group.
   *	I thought it made more sense to put both into the validation procedure, and 
   *	I created a new sp.
   **************************************/
   	(@jcco bCompany = 0, @matlgrp bGroup output, @msg varchar(60) output)

   as 
   set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @jcco = 0
   	begin
   	select @msg = 'Missing JC Company#', @rcode = 1
   	goto bspexit
   	end
   
   if exists(select top 1 1 from bJCCO WITH (NOLOCK) where @jcco = JCCo)
   	begin
   	select @msg = Name, @matlgrp = MatlGroup from bHQCO where HQCo = @jcco
   	goto bspexit
   	end
   else
   	begin
   	select @msg = 'Not a valid JC Company', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCCompanyMatlGrpVal] TO [public]
GO
