SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE      proc [dbo].[bspJCJMPostValForAP]    
/***************************************************************************************
* CREATED BY:	GR	05/12/2000
* Modified By:	GR	11/01/2000 - fixed to dispaly job description
*				GF	01/05/2001 - added check for base tax on by job or vendor
*				RT	08/21/2003 - #21582, added column "Address2".
*				RT	09/18/2003 - #21582 fix, moved @address2 from parameters to local var.
*				TV				- 23061 added isnulls
*				MV				- #30147 - if taxrate is invalid don't throw err, return 0 rate 
*				MV				- #119810 - don't get taxrate if taxgroup is null 
*				MV				- #120283 - isnull wrap @taxgroup for null test 
*				MV				- #29702	- return ReviewerGroup for Unapproved enhancement project
*				GF	03/11/2008	- issue #127076 added country as output parameter
*				GP	10/23/2008	- Issue 130759, if @compdate is null set a default date.
*				DC	06/03/2009	- Issue #132805 added @UseDefaultTax output parameter to bspJCJMPostVal
*				CHS 11/16/2009	- issue #135565
*
* USAGE:
* validates JC Job
*
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against
*   Job    Job to validate
*
* OUTPUT PARAMETERS
*   @contract returns the contract for this job.
*   @status   Status of job, Open, SoftClose,Close
*   @lockphases  weather or not lockphases flag is set
*   @taxcode  tax code for job
*   @address  Shipping address of the job
*   @city     Shipping City of job
*   @state    state of address of job
*   @zip      zip code
*	 @address2 second address line
*		@country	Shipping Country of job
*
*   @msg      error message if error occurs otherwise Description of Job
* RETURN VALUE
*   0         success
*   1         Failure
*************************************************************************************/
(@jcco bCompany = 0, @job bJob = null, @taxgroup bGroup = null,  @compdate bDate = null,
@vendorgroup bGroup = null, @vendor bVendor = null, @contract bContract  = null output,
@status tinyint =null output,@lockphases bYN = null output, @taxcode bTaxCode = null output,
@address varchar(60)=null output, @city varchar(30)=null output, @state varchar(4) = null output,
@zip bZip=null output, @pocompgroup varchar(10)=null output, @slcompgroup varchar(10)=null output,
@taxrate bRate output, @reviewergroup varchar(10)=null output, @country char(2) output,
@msg varchar(255) output)
  as
  set nocount on
  
  declare @rcode int, @errmsg varchar(60), @taxphase bPhase, @taxjcctype bJCCType, @basetaxon varchar(1),
  @address2 varchar (60)
  
  select @rcode = 0
  
  if @jcco is null
  	begin
  	select @msg = 'Missing JC Company!', @rcode = 1
  	goto bspexit
  	end
  
  if @job is null
  	begin
  	select @msg = 'Missing Job!', @rcode = 1
  	goto bspexit
  	end

  -- if Compdate is null then always use New Rate, issue 130759
  if @compdate is null
   	begin
   	select @compdate='12/31/2070'
   	end
  
--   if @taxgroup is null
--   	begin
--   	select @msg = 'Missing Tax Group', @rcode = 1
--   	goto bspexit
--   	end
  
  exec @rcode = bspJCJMPostVal @jcco, @job, @contract output, @status output, @lockphases output,
		@taxcode output, @address output, @city output, @state output, @zip output,
		@pocompgroup output, @slcompgroup output, @address2 output, @country output, 
		null, --DC #132805
		@errmsg output
      select @msg = @errmsg
      if @rcode <> 0
          begin
          --select @msg = @errmsg
          goto bspexit
          end
 
  
	select @basetaxon=BaseTaxOn, @reviewergroup=RevGrpInv, @taxcode=TaxCode -- issue #135565
	from bJCJM where JCCo=@jcco and Job=@job
	if @basetaxon = 'V'
	  begin
	  select @taxcode=TaxCode
	  from bAPVM where VendorGroup=@vendorgroup and Vendor=@vendor
	  end
  
	if @basetaxon = 'O'	-- issue #135565
		begin
		select @taxcode=isnull(TaxCode, @taxcode)
		from bAPVM where VendorGroup=@vendorgroup and Vendor=@vendor
		end
		    
      
  
  if isnull(@taxcode, '') <> '' and isnull(@taxgroup,0) <> 0 --#120283, #119788
      begin
      exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @compdate, @taxrate output,
                    @taxphase output, @taxjcctype output, @errmsg output
      if @rcode <> 0
          begin
 		 	select @taxrate = 0, @rcode = 0
 --          select @msg = @errmsg
          	goto bspexit
          end
      end
  
  bspexit:
      if @rcode<>0 select @msg=@msg
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCJMPostValForAP] TO [public]
GO
