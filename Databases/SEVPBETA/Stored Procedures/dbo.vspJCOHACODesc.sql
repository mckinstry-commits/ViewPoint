SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCOHACODesc   *****/
CREATE     proc [dbo].[vspJCOHACODesc]
/*************************************
 * Created By:	DANF 10/24/2005
 * Modified By:	GP	 05/28/2008 Issue #128463 Changed date conversion from style code 103 to 101, mm/dd/yyyy.
 *				GF	11/26/2010 - issue #142119 use HQCO Report Date Format
 *
 *
 * USAGE:
 * Called from JCOH to return ACO Description
 *
 *
 * INPUT PARAMETERS
 * @jcco
 * @job
 * @aco
 * @warning 
 * @msg
 *
 * Success returns:
 * 0, Billing warning, ACO description
 *
 * Error returns:
 * 1 and error message
 **************************************/
(@jcco bCompany, @job bJob, @aco varchar(10), @warning varchar(255) output, @acoseq varchar(10) output, @msg varchar(255) output)
as
set nocount on

declare @rc int, @rcode int, @rvalue int, @errortext varchar(255)

select @rc = 0, @rcode = 0, @rvalue = 0, @msg = ''

 	if @jcco is not null and  isnull(@job,'') <> '' and isnull(@aco,'')<>''
		begin

		  select @msg = Description 
		  from dbo.JCOH with (nolock)
		  where JCCo = @jcco and Job = @job and ACO = @aco
		  
		---- #142119
		 ----select top 1  @warning = 'Warning: This ACO has been billed in Job Billing for Bill Month ' + convert(varchar(10),BillMonth, 101) + ' and Bill Number ' + convert(varchar(3),BillNumber) + '.'
		 select top 1  @warning = 'Warning: This ACO has been billed in Job Billing for Bill Month ' + dbo.vfDateOnlyAsStringUsingStyle(BillMonth,@jcco,DEFAULT) + ' and Bill Number ' + convert(varchar(3),BillNumber) + '.'
 
		 from dbo.JBCC with (nolock)
		 where JBCo = @jcco and Job = @job and ACO = @aco
         order by JBCo, BillMonth, BillNumber, Job, ACO DESC


		-- return next aco sequence for new change order items
		exec @rvalue = bspJCMaxACOSeq @jcco, @job, @acoseq output

		select @acoseq = 1 + isnull(@acoseq,0)

		end

select @rc = @rcode

bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rc

GO
GRANT EXECUTE ON  [dbo].[vspJCOHACODesc] TO [public]
GO
