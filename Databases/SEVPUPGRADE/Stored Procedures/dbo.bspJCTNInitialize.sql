SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       procedure [dbo].[bspJCTNInitialize]
   /*******************************************************************
    * CREATED By:	GF 03/01/2002
    * MODIFIED By: TV - 23061 added isnulls
    *
    * USAGE
    * Pass in Template and beginning and ending phase range.
    * It will copy phases from JCPM to JCTI that fall within the range.
    * Will only add phases that do not exist.
    * 
    * PASS IN
    *	Company			JC Company to be doing initialize in
    *	PhaseGroup		JC Phase Group
    *  Template		Insurance Template to initialize phases into     
    *	BegPhase		Beginning phase to add
    *	EndPhase		Ending phase to add
    *	InsCode			Insurance code to insert into JCTI with phases
    *
    * returns 0 and message reporting successful copy              
    * Returns 1 and error message if unable to process.
    ********************************************************************/
   (@jcco bCompany, @phasegroup bGroup, @template smallint, @begphase bPhase,
    @endphase bPhase, @inscode varchar(10), @errmsg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @phasecount int
   	 
   select @rcode = 0, @phasecount = 0
   
   -- validate parameters
   if isnull(@jcco,0) = 0
   	begin
   	select @errmsg = 'Missing JC company!', @rcode = 1
   	goto bspexit
   	end
   
   if isnull(@phasegroup,0) = 0
   	begin
   	select @errmsg = 'Missing JC phase group!', @rcode = 1
   	goto bspexit
   	end
   
   if isnull(@template,'') = ''
   	begin
   	select @errmsg = 'Missing Insurance Template!', @rcode =1 
   	goto bspexit
   	end
   
   if isnull(@inscode,'') = ''
   	begin
   	select @errmsg = 'Missing Insurance code!', @rcode =1 
   	goto bspexit
   	end
   
   if isnull(@begphase,'') = ''
   	begin
   	select @errmsg = 'Missing Beginning phase!', @rcode =1 
   	goto bspexit
   	end
   
   if isnull(@endphase,'') = ''
   	begin
   	select @errmsg = 'Missing Ending phase!', @rcode =1 
   	goto bspexit
   	end
   
   
   -- validate insurance template
   if not exists(select * from bJCTN where JCCo=@jcco and InsTemplate=@template)
   	begin
   	select @errmsg = 'The insurance template you are trying to initialize phases for does not exits.', @rcode = 1
   	goto bspexit
   	end
   
   
   -- initialize range of phases into JCTI
   insert into bJCTI(JCCo, InsTemplate, PhaseGroup, Phase, InsCode)
   select @jcco, @template, @phasegroup, b.Phase, @inscode
   from bJCPM b where b.PhaseGroup=@phasegroup
   and b.Phase >= isnull(@begphase,'') and b.Phase <= isnull(@endphase,'ZZZZZZZZZZZZZZZZZZZ')
   and not exists(select JCCo from bJCTI where JCCo=@jcco and InsTemplate=@template
   				and PhaseGroup=@phasegroup and Phase=b.Phase)
   
   select @phasecount = @@rowcount
   select @errmsg = 'Template phases initialized : ' + isnull(convert(varchar(8),@phasecount),'') + ' '
   
   
   
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCTNInitialize] TO [public]
GO
